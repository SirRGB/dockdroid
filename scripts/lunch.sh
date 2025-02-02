#!/bin/bash

set +u

source "$SCRIPT_DIR"/print.sh

# Set up ccache
_ccache() {
  if [[ -n ${CCACHE_SIZE} ]] && [[ ${CCACHE_SIZE} -gt 0 ]]; then
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=/mnt/ccache
    ccache -M ${CCACHE_SIZE}G
    ccache -o compression=true
  fi
}

_lunch() {
  source build/envsetup.sh

  # Append release codename, if exists (A14+)
  local RELEASE_CODENAME=
  if [[ -d "$ANDROID_BUILD_TOP/build/release/aconfig/" ]]; then
    local RELEASE_CODENAME="-$(ls -1 -I trunk* -I root $ANDROID_BUILD_TOP/build/release/aconfig/)"
  fi

  # Extract lunch prefix from AndroidProducts
  local PRODUCT=$(egrep "$DEVICE" "$ANDROID_BUILD_TOP"/device/*/"$DEVICE"/AndroidProducts.mk | cut -d"/" -f2 | cut -d"." -f1)

  # It's all coming together
  BUILD_START=$(date +"%s")
  lunch "$PRODUCT""$RELEASE_CODENAME"-"$BUILD_TYPE"
}

_ccache
_lunch
_print_build_start

source "$SCRIPT_DIR"/build.sh
