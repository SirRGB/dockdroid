#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Only works for PRODUCT_VERSION_MAJOR|MINOR
# Planned to work on Leaf OS/Lineage OS/CyanogenMOD/amyROM
_version() {
  local major_version_regex minor_version_regex rom_extraversion partition_search
  major_version_regex='^PRODUCT_VERSION_MAJOR[[:space:]]:?=[[:space:]][[:digit:]]{1,2}'
  minor_version_regex='^PRODUCT_VERSION_MINOR[[:space:]]:?=[[:space:]][[:digit:]]{1,2}'
  readonly major_version_regex minor_version_regex

  # Search for line containing the regex inside *[V|v]ersion.mk|common.mk, cut that number and set points in between
  if [[ -z "${ROM_PREFIX_FALLBACK}" ]]; then
    ROM_PREFIX=$(find "${ANDROID_BUILD_TOP}"/vendor/*/build/tasks/* "${ANDROID_BUILD_TOP}"/build/core/Makefile -exec grep '_TARGET_PACKAGE[[:space:]]:=' {} \; | cut -d"=" -f2 | cut -d"/" -f2 | cut -d"$" -f1)
  else
    ROM_PREFIX="${ROM_PREFIX_FALLBACK}"
    unset ROM_PREFIX_FALLBACK
  fi
  if [[ -z "${ROM_VERSION_FALLBACK}" ]]; then
    ROM_VERSION=$(find "${ANDROID_BUILD_TOP}"/vendor/*/config/ \( -name "*[vV]ersion.mk" -o -name common.mk \) -exec grep -E "${major_version_regex}" {} \; | tr -d 'A-z:= \n').\
$(find "${ANDROID_BUILD_TOP}"/vendor/*/config/ \( -name "*[vV]ersion.mk" -o -name common.mk \) -exec grep -E "${minor_version_regex}" {} \; | tr -d 'A-z:= \n')
  else
    ROM_VERSION="${ROM_VERSION_FALLBACK}"
    unset ROM_VERSION_FALLBACK
  fi
  partition_search="${OUT}"/system
  if [[ "${ANDROID_VERSION}" -gt 8 ]]; then
    partition_search[1]="${OUT}"/product
  fi
  rom_extraversion=
  if [[ -n $(find "${partition_search[@]}" -name "FakeStore") ]]; then
    rom_extraversion="MICROG-"
  elif [[ -n $(find "${partition_search[@]}" -name "GmsCore") ]]; then
    rom_extraversion="GMS-"
  fi
  PACKAGE_NAME="${ROM_PREFIX}""${ROM_VERSION}"-"${rom_extraversion}"$(env TZ="${TIME_ZONE}" date -d @"${BUILD_DATE_UNIX}" +%Y%m%d)-"${DEVICE}"-signed.zip
}

# Create flashable zip from target files
_packaging() {
  _version
  local releasetools_prefix=""
  # A10 and below need this prepended for signing to work
  if [[ "${ANDROID_VERSION}" -lt 11 ]]; then
    releasetools_prefix="${ANDROID_BUILD_TOP}"/build/tools/releasetools/
  fi
  set +eu
  "${releasetools_prefix}"ota_from_target_files -k "${KEYS_DIR}"/releasekey \
      "${OUT}"/signed-target_files.zip \
      "${OUT}"/"${PACKAGE_NAME}" 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/packaging.txt
  set -eu
  unset KEYS_DIR LOGS_DIR
}

# Extract signed recovery from signed target files
_extract_recovery() {
  unzip -p "${OUT}"/signed-target_files.zip IMAGES/recovery.img > "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" ||
    unzip -p "${OUT}"/signed-target_files.zip IMAGES/boot.img > "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}"
}

_cleanup_fail() {
  _print_build_fail
}
trap _cleanup_fail ERR

_packaging # _version
_extract_recovery
_print_build_success

# shellcheck source=scripts/upload.sh
source "${SCRIPT_DIR}"/upload.sh
