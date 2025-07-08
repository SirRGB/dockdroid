#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Pull manifest, local manifest and sync
_sync() {
  if [[ ! -d "${ROM_DIR}"/.repo/local_manifests ]]; then
    mkdir -p "${ROM_DIR}"/.repo/local_manifests
  fi
  cd "${ROM_DIR}" || exit
  repo init -u "${ROM_MANIFEST}" -b "${ROM_BRANCH}" --depth=1 -g default,-darwin --git-lfs --no-clone-bundle 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  cd "${ROM_DIR}"/.repo/repo || exit
  git pull
  cd "${ROM_DIR}" || exit
  find "${ROM_DIR}"/.repo/local_manifests/ -type f -exec rm {} \;
  if [[ -n "${LOCAL_MANIFEST}" ]]; then
    _merge_local_manifests
  fi
  local threads
  threads=$(nproc)
  repo forall -c "rm .git/*.lock" || true
  repo sync --current-branch --force-remove-dirty --force-sync --no-tags --no-clone-bundle --retry-fetches=25 --jobs="${threads}" --jobs-network=$((threads < 16 ? threads : 16)) 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  repo forall -c "git lfs pull"
  if [[ -n "${CLONE_REPOS}" ]]; then
   _clone_all
  fi
  unset ROM_MANIFEST LOCAL_MANIFEST CLONE_REPOS
}

# Merge local manifests into one
# to avoid conflicts with duplicate dependencies
_merge_local_manifests() {
  echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest>" > "${ROM_DIR}"/.repo/local_manifests/manifest.xml
  IFS=',' read -r -a "LOCAL_MANIFEST" <<< "${LOCAL_MANIFEST}"
  for url in "${LOCAL_MANIFEST[@]}"; do
    curl -fsSL "${url}" | sed "/<?xml version=\"1.0\" encoding=\"UTF-8\"?>/d; /<manifest>/d; /<\/manifest>/d; /<!--/d; /-->/d; /^$/d" >> "${ROM_DIR}"/.repo/local_manifests/.merge.txt
  done
  sort < "${ROM_DIR}"/.repo/local_manifests/.merge.txt | uniq >> "${ROM_DIR}"/.repo/local_manifests/manifest.xml
  find "${ROM_DIR}"/.repo/local_manifests/ -type f ! -name "*.xml" -exec rm -r {} \; || true
  echo "</manifest>" >> "${ROM_DIR}"/.repo/local_manifests/manifest.xml
}

# Clone repos one by one
_clone() {
  full_repo_name="$1"
  repo_name=$(echo "${full_repo_name}" | rev | cut -d"/" -f3- | rev)
  branch=$(echo "${full_repo_name}" | rev | cut -d"/" -f-1 | rev)
  target_path=$(echo "${full_repo_name}" | rev | cut -d"/" -f3 | rev | sed 's/android_//g; s/proprietary_//g; s|_|/|g')
  rm -rf "${target_path}" || true
  git clone "${repo_name}" -b "${branch}" "${target_path}"
}

_clone_all() {
  IFS=',' read -r -a "CLONE_REPOS" <<< "${CLONE_REPOS}"
  for repo in "${CLONE_REPOS[@]}"; do
    _clone "${repo}"
  done
}

trap _print_sync_fail ERR

_print_sync_start
_sync
_print_sync_success

source "${SCRIPT_DIR}"/setup.sh
