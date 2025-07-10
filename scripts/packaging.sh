#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Only works for PRODUCT_VERSION_MAJOR|MINOR
# Planned to work on Leaf OS/Lineage OS/CyanogenMOD/amyROM
_version() {
  local major_version_regex minor_version_regex
  major_version_regex='^PRODUCT_VERSION_MAJOR[[:space:]]:?=[[:space:]][[:digit:]]{1,2}'
  minor_version_regex='^PRODUCT_VERSION_MINOR[[:space:]]:?=[[:space:]][[:digit:]]{1,2}'
  readonly major_version_regex minor_version_regex

  # Search for line containing the regex inside *[V|v]ersion.mk|common.mk, cut that number and set points in between
  if [[ -z "${ROM_PREFIX_FALLBACK}" ]]; then
    ROM_PREFIX=$(find "${ANDROID_BUILD_TOP}"/vendor/*/build/tasks/* "${ANDROID_BUILD_TOP}"/build/core/Makefile -exec grep '_TARGET_PACKAGE[[:space:]]:=' {} \; | cut -d"=" -f2 | cut -d"/" -f2 | cut -d"$" -f1)
  else
    ROM_PREFIX="${ROM_PREFIX_FALLBACK}"
  fi
  if [[ -z "${ROM_VERSION_FALLBACK}" ]]; then
    ROM_VERSION=$(find "${ANDROID_BUILD_TOP}"/vendor/*/config/ \( -name "*[vV]ersion.mk" -o -name common.mk \) -exec grep -E "${major_version_regex}" {} \; | tr -d 'A-z:= \n').\
$(find "${ANDROID_BUILD_TOP}"/vendor/*/config/ \( -name "*[vV]ersion.mk" -o -name common.mk \) -exec grep -E "${minor_version_regex}" {} \; | tr -d 'A-z:= \n')
  else
    ROM_VERSION="${ROM_VERSION_FALLBACK}"
  fi
  ROM_EXTRAVERSION=""
  if [[ -n $(find "${OUT}" -mindepth 2 -name "FakeStore.apk" -print -quit) ]]; then
    ROM_EXTRAVERSION="MICROG-"
  elif [[ -n $(find "${OUT}" -mindepth 2 -name "GmsCore.apk" -print -quit) ]]; then
    ROM_EXTRAVERSION="GMS-"
  fi
  PACKAGE_NAME="${ROM_PREFIX}""${ROM_VERSION}"-"${ROM_EXTRAVERSION}"$(env TZ="${TIME_ZONE}" date -d @"${BUILD_DATE_UNIX}" +%Y%m%d)-"${TARGET_DEVICE}"-signed.zip
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
  if ! "${releasetools_prefix}"ota_from_target_files -k "${KEYS_DIR}"/releasekey \
      "${OUT}"/signed-target_files.zip \
      "${OUT}"/"${PACKAGE_NAME}" 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/packaging.txt
  then
    _cleanup_fail
  fi
  set -eu
}

# Extract signed recovery from signed target files
_extract_recovery() {
  unzip -p "${OUT}"/signed-target_files.zip IMAGES/recovery.img > "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" ||
    unzip -p "${OUT}"/signed-target_files.zip IMAGES/boot.img > "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}"
}

_cleanup_fail() {
  _print_build_fail
  exit 1
}

trap _cleanup_fail ERR

_packaging
_extract_recovery
_print_build_success

# shellcheck source=scripts/upload.sh
source "${SCRIPT_DIR}"/upload.sh
