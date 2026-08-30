#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Pull manifest, local manifest and sync
_sync() {
  if [[ ! -d "${ROM_DIR}"/.repo/local_manifests ]]; then
    mkdir --parents "${ROM_DIR}"/.repo/local_manifests
  fi
  cd "${ROM_DIR}" || exit
  repo init -u "${ROM_MANIFEST}" -b "${ROM_BRANCH}" --depth=1 -g default,-darwin --git-lfs --no-clone-bundle 2>&1 | tee --append "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  # Pull the latest repo tool
  cd "${ROM_DIR}"/.repo/repo || exit
  git pull
  cd "${ROM_DIR}" || exit
  # Remove local manifests
  find "${ROM_DIR}"/.repo/local_manifests/ -type f -exec rm {} \;
  if [[ -n "${LOCAL_MANIFEST}" ]]; then
    if grep -q ',' <<< "${LOCAL_MANIFEST}"; then
      # Merge local manifests into one to avoid conflicts with duplicate dependencies
      "${SCRIPT_DIR}"/_01_xml_manifest_gen.py "${LOCAL_MANIFEST}" > "${ROM_DIR}"/.repo/local_manifests/manifest.xml
    else
      curl_cmd "${LOCAL_MANIFEST}" --output "${ROM_DIR}"/.repo/local_manifests/manifest.xml
    fi
  elif [[ -z "${CLONE_REPOS}" ]] && [[ -n "${FETCH_MUPPETS}" ]]; then
    # Generate vendor manifest, so that official lineage just builds
    "${SCRIPT_DIR}"/01_xml_roomservice.py "${DEVICE}" "${ROM_BRANCH}" > "${ROM_DIR}"/.repo/local_manifests/manifest.xml
  fi
  local threads
  threads=$(nproc)
  repo forall -c "rm .git/*.lock" || true
  repo sync --current-branch --force-remove-dirty --force-sync --no-tags --no-clone-bundle --retry-fetches=25 --jobs="${threads}" --jobs-network=$((threads < 16 ? threads : 16)) 2>&1 | tee --append "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  if grep --quiet "Failing repos" "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  then
    # Extract failing repositories from the error message and echo the deletion path
    while IFS= read -r line; do
        # Extract repository name and path from the error message
        local repo_info repo_path repo_name
        repo_info=$(echo "${line}" | awk -F': ' '{print $NF}')
        repo_path=$(dirname "${repo_info}")
        repo_name=$(basename "${repo_info}")
        # Delete the repository
        rm --recursive --force "${repo_path:?}/${repo_name}"
        rm --recursive --force "${ROM_DIR}"/.repo/project/"${repo_path}"/"${repo_name}"/*.git
    done <<< "$(awk '/Failing repos.*:/ {flag=1; next} /Try/ {flag=0} flag' < "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt | sort -u)"
  fi

  # Check if there are any failing repositories due to uncommitted changes
  if grep --quiet "uncommitted changes are present" "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt ; then
      # Extract failing repositories from the error message and echo the deletion path
      while IFS= read -r line; do
          # Extract repository name and path from the error message
          repo_info=$(echo "${line}" | awk -F': ' '{print $2}')
          repo_path=$(dirname "${repo_info}")
          repo_name=$(basename "${repo_info}")
          # Delete the repository
          rm --recursive --force "${repo_path:?}/${repo_name}"
          rm --recursive --force "${ROM_DIR}"/".repo/project/${repo_path}/${repo_name}"/*.git
      done <<< "$(grep 'uncommitted changes are present' < "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt)"
  fi

  repo sync --current-branch --force-remove-dirty --force-sync --no-tags --no-clone-bundle --retry-fetches=25 --jobs="${threads}" --jobs-network=$((threads < 16 ? threads : 16)) 2>&1 | tee --append "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  repo forall -c 'git lfs pull'
  if [[ -n "${CLONE_REPOS}" ]]; then
   _clone_all
  fi
  unset ROM_MANIFEST LOCAL_MANIFEST CLONE_REPOS
}

# Clone a repo
_clone() {
  full_repo_name="${1}"
  repo_name=$(rev <<< "${full_repo_name}" | cut --delimiter='/' --fields=3- | rev)
  branch=$(rev <<< "${full_repo_name}" | cut --delimiter='/' --fields=-1 | rev)
  target_path=$(rev <<< "${full_repo_name}" | cut --delimiter='/' --fields=3 | rev | sed 's/android_//g; s/proprietary_//g; s|_|/|g')
  rm --recursive --force "${target_path}" || true
  git clone "${repo_name}" --branch "${branch}" "${ANDROID_BUILD_TOP}"/"${target_path}"
}

# Wrapper to clone all repos defined in $CLONE_REPOS
_clone_all() {
  IFS=',' read -r -a "CLONE_REPOS" <<< "${CLONE_REPOS}"
  for repo in "${CLONE_REPOS[@]}"; do
    _clone "${repo}"
  done
}

_cleanup_fail() {
  _print_sync_fail
  exit 1
}

trap _cleanup_fail ERR

_print_sync_start
_sync
_print_sync_success

source "${SCRIPT_DIR}"/02_setup.sh
