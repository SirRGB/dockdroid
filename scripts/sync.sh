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
  find "${ROM_DIR}"/.repo/local_manifests/ -type f -exec rm {} \;
  curl "${LOCAL_MANIFEST}" --output .repo/local_manifests/manifest.xml
  local threads
  threads=$(nproc)
  repo forall -c "rm .git/*.lock" || true
  repo sync --current-branch --force-remove-dirty --force-sync --no-tags --no-clone-bundle --retry-fetches=25 --jobs="${threads}" --jobs-network=$((threads < 16 ? threads : 16)) 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  set +e
  repo forall -c "git lfs pull"
  set -e
  unset ROM_MANIFEST LOCAL_MANIFEST
}

cleanup() {
  _print_sync_fail
}
trap cleanup ERR

_print_sync_start
_sync
_print_sync_success

source "${SCRIPT_DIR}"/lunch.sh
