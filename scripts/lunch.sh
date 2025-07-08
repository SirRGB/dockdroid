#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Define build target
_lunch() {
  cd "${ROM_DIR}" || exit

  # Append release codename, if exists (A14+)
  local release_codename
  release_codename=
  if [[ -d "${ANDROID_BUILD_TOP}"/build/release/aconfig/ ]]; then
    release_codename=-$(find "${ANDROID_BUILD_TOP}"/build/release/aconfig/* -maxdepth 0 -type d -name "[a-z][a-z][0-9][a-z]" -printf '%f\n' | tail -n1)
  fi

  # Extract lunch prefix from AndroidProducts
  local product
  if [[ -n "${LUNCH_PREFIX_FALLBACK}" ]]; then
    product="${LUNCH_PREFIX_FALLBACK}"_"${TARGET_DEVICE}"
  else
    product=$(grep -E "${TARGET_DEVICE}" "${ANDROID_BUILD_TOP}"/device/*/"${TARGET_DEVICE}"/AndroidProducts.mk | cut -d"/" -f2 | cut -d"." -f1 | head -n1)
  fi

  # It's all coming together
  set +eu
  lunch "${product}""${release_codename}"-"${BUILD_TYPE}"
  set -eu
}

# Iterate over device array
IFS=',' read -r -a "DEVICE" <<< "${DEVICE}"
for device in "${DEVICE[@]}"; do
  export TARGET_DEVICE="${device}"
  _lunch
  _print_build_start

  source "${SCRIPT_DIR}"/sign.sh
done
