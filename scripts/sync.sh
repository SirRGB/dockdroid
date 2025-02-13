#!/bin/bash

source "${SCRIPT_DIR}"/print.sh

# Logs
_setup_logs() {
  BUILD_DATE=$(date -u +%Y%m%d-%H%M)
  mkdir "${LOGS_DIR}"/"${BUILD_DATE}"
}

# Pull manifest, local manifest and sync
_sync() {
  cd "${ROM_DIR}"
  repo init -u "${ROM_MANIFEST}" -b "${ROM_BRANCH}" --depth=1 --git-lfs | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  mkdir -p .repo/local_manifests
  if [[ -n $(ls .repo/local_manifests/) ]]; then
    rm .repo/local_manifests/*
  fi
  curl "${LOCAL_MANIFEST}" > .repo/local_manifests/manifest.xml
  local threads
  threads=$(nproc)
  repo forall -c 'git reset --hard; git clean -fdx' > /dev/null || true
  repo sync --no-tags --no-clone-bundle -c --force-sync --retry-fetches=25 -j"${threads}" --jobs-network=$((threads < 16 ? threads : 16)) | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  unset ROM_DIR ROM_BRANCH ROM_MANIFEST LOCAL_MANIFEST
}

cleanup() {
  _print_sync_fail
}
trap cleanup ERR

_setup_logs
_telegram_check_token
_print_sync_start
_sync
_print_sync_success

source "${SCRIPT_DIR}"/lunch.sh
