#!/bin/bash

#set -euxo pipefail

source "$SCRIPT_DIR"/print.sh

# Pull manifest, local manifest and sync
_sync() {
#  ls "$ROM_DIR"
  echo "$ROM_DIR"
  cd "$ROM_DIR"
  SYNC_START=$(date +"%s")
  repo init -u "$ROM_MANIFEST" -b "$ROM_BRANCH" --depth=1 --git-lfs
  mkdir -p .repo/local_manifests
  if [[ -f .repo/local_manifests/* ]]; then
    rm .repo/local_manifests/*
  fi
  curl "$LOCAL_MANIFEST" > .repo/local_manifests/manifest.xml
  local THREADS=$(nproc)
  repo forall -c 'git reset --hard; git clean -fdx' > /dev/null || true
  repo sync --no-tags --no-clone-bundle -c --force-sync --retry-fetches=25 -j"$THREADS" --jobs-network=$((THREADS < 16 ? THREADS : 16))
}

cleanup() {
  _print_sync_fail
}
trap cleanup ERR

_print_sync_start
_sync
_print_sync_sucess

source "$SCRIPT_DIR"/lunch.sh
