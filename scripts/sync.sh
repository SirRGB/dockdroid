#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Logs
_setup_logs() {
  BUILD_DATE=$(date -u +%Y%m%d-%H%M)
  mkdir "${LOGS_DIR}"/"${BUILD_DATE}"
}

# Pull manifest, local manifest and sync
_sync() {
  cd "${ROM_DIR}" || exit
  repo init -u "${ROM_MANIFEST}" -b "${ROM_BRANCH}" --depth=1 -g default,-darwin --git-lfs --no-clone-bundle | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  if test -f .repo/local_manifests/* ; then
    rm .repo/local_manifests/*
  fi
  curl "${LOCAL_MANIFEST}" --create-dirs --output .repo/local_manifests/manifest.xml
  local threads
  threads=$(nproc)
  repo forall -c "rm .git/*.lock" || true
  repo sync --current-branch --force-remove-dirty --force-sync --no-tags --no-clone-bundle --retry-fetches=25 --jobs="${threads}" --jobs-network=$((threads < 16 ? threads : 16)) | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sync.txt
  set +e
  repo forall -c "git lfs pull"
  set -e
  unset ROM_MANIFEST LOCAL_MANIFEST
}

cleanup() {
  _print_sync_fail
}
trap cleanup ERR

_setup_logs
_print_sync_start
_sync
_print_sync_success

source "${SCRIPT_DIR}"/lunch.sh
