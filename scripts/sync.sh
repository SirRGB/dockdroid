#!/bin/bash

source "${SCRIPT_DIR}"/print.sh

# Pull manifest, local manifest and sync
_sync() {
  cd "${ROM_DIR}"
  repo init -u "${ROM_MANIFEST}" -b "${ROM_BRANCH}" --depth=1 --git-lfs
  mkdir -p .repo/local_manifests
  if [[ -n $(ls .repo/local_manifests/) ]]; then
    rm .repo/local_manifests/*
  fi
  curl "${LOCAL_MANIFEST}" > .repo/local_manifests/manifest.xml
  local THREADS
  THREADS=$(nproc)
  repo forall -c 'git reset --hard; git clean -fdx' > /dev/null || true
  repo sync --no-tags --no-clone-bundle -c --force-sync --retry-fetches=25 -j"${THREADS}" --jobs-network=$((THREADS < 16 ? THREADS : 16))
  unset ROM_DIR ROM_BRANCH ROM_MANIFEST LOCAL_MANIFEST
}

cleanup() {
  _print_sync_fail
  _telegram_separator
}
trap cleanup ERR

_telegram_check_token
_print_sync_start
_sync
_print_sync_success

source "${SCRIPT_DIR}"/lunch.sh
