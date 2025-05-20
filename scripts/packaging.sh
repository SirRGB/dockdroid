#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Only works for PRODUCT_VERSION_MAJOR|MINOR
# Planned to work on Leaf OS/Lineage OS/CyanogenMOD/amyROM
_version() {
  local major_version_regex minor_version_regex rom_extraversion
  major_version_regex='^PRODUCT_VERSION_MAJOR[[:space:]]:?=[[:space:]][[:digit:]]{1,2}'
  minor_version_regex='^PRODUCT_VERSION_MINOR[[:space:]]:?=[[:space:]][[:digit:]]{1,2}'
  readonly major_version_regex minor_version_regex

  # Search for line containing the regex inside *[V|v]ersion.mk|common.mk, cut that number and set points in between
  ROM_PREFIX=$(grep -E '_TARGET_PACKAGE[[:space:]]:=' "${ANDROID_BUILD_TOP}"/vendor/*/build/tasks/* | cut -d"=" -f2 | cut -d"/" -f2 | cut -d"$" -f1)
  ROM_VERSION=$(find "${ANDROID_BUILD_TOP}"/vendor/*/config/ \( -name "*[vV]ersion.mk" -o -name common.mk \) -exec grep -E "${major_version_regex}" {} \; | tr -d 'A-z:= \n').\
$(find "${ANDROID_BUILD_TOP}"/vendor/*/config/ \( -name "*[vV]ersion.mk" -o -name common.mk \) -exec grep -E "${minor_version_regex}" {} \; | tr -d 'A-z:= \n')
  rom_extraversion=
  set +u
  if [[ "${WITH_GMS}" = "true" ]]; then
    rom_extraversion="GMS-"
  elif [[ "${WITH_MICROG}" = "true" ]]; then
    rom_extraversion="MICROG-"
  fi
  set -u
  PACKAGE_NAME="${ROM_PREFIX}""${ROM_VERSION}"-"${rom_extraversion}"$(env tz="${TIME_ZONE}" date +%Y%m%d)-"${DEVICE}"-signed.zip
}

# Create flashable zip from target files
_packaging() {
  _version
  set +eu
  local releasetools_prefix=""
  # A10 and below need this prepended for signing to work
  if [[ "${ANDROID_VERSION}" -lt 11 ]]; then
    releasetools_prefix="${ANDROID_BUILD_TOP}"/build/tools/releasetools/
  fi
  "${releasetools_prefix}"ota_from_target_files -k "${KEYS_DIR}"/releasekey \
      "${OUT}"/signed-target_files.zip \
      "${OUT}"/"${PACKAGE_NAME}" 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/packaging.txt
  set -eu
  unset KEYS_DIR LOGS_DIR
}

# Extract signed recovery from signed target files
_extract_recovery() {
  unzip -p "${OUT}"/signed-target_files.zip IMAGES/recovery.img > "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}"
}

cleanup() {
  _print_build_fail
}
trap cleanup ERR

_packaging # _version
_extract_recovery
_print_build_success

# shellcheck source=scripts/upload.sh
source "${SCRIPT_DIR}"/upload.sh
