#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Drop old builds
_cleanup() {
  cd "${ROM_DIR}" || exit
  set +eu
  if ! m installclean -j"$(nproc)" 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/build.txt
  then
    _cleanup_fail
  fi
  set -eu
  rm "${OUT}"/*.zip "${OUT}"/*.zip.json || true
}

# Decide for signing method
_determine_signing() {
  set +eu
  if ! m target-files-package otatools -j"$(nproc)" "$@" 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/build.txt
  then
    _cleanup_fail
  fi
  if ! croot
  then
    _cleanup_fail
  fi
  set -eu

  # If Android version greater than 11, use apex signing
  if [[ "${ANDROID_VERSION}" -gt 11 ]]; then
    _print_signing_method "APEX"
    _sign_new
  else
    _print_signing_method "Legacy"
    _sign_old
  fi
}

# Old signing process, A11/below
_sign_old() {
  local releasetools_prefix=""
  if [[ "${ANDROID_VERSION}" -lt 11 ]]; then
    releasetools_prefix="${ANDROID_BUILD_TOP}"/build/tools/releasetools/
  fi
  set +eu
  if ! "${releasetools_prefix}"sign_target_files_apks -o -d "${KEYS_DIR}" \
      "${OUT}"/obj/PACKAGING/target_files_intermediates/*-target_files-*.zip \
      "${OUT}"/signed-target_files.zip 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sign-legacy.txt
  then
    _cleanup_fail
  fi
  set -eu
}

# New signing process (APEX), A12/up
_sign_new() {
  for apex_key in "${APEX_KEYS[@]}"; do
    APEX_ARGS+=("--extra_apks" "${apex_key}.apex=${KEYS_DIR}/${apex_key}" "--extra_apex_payload_key" "${apex_key}.apex=${KEYS_DIR}/${apex_key}.pem")
  done

  set +eu
  if ! sign_target_files_apks -o -d "${KEYS_DIR}" \
      --extra_apks AdServicesApk.apk="${KEYS_DIR}"/releasekey \
      --extra_apks FederatedCompute.apk="${KEYS_DIR}"/releasekey \
      --extra_apks HalfSheetUX.apk="${KEYS_DIR}"/releasekey \
      --extra_apks HealthConnectBackupRestore.apk="${KEYS_DIR}"/releasekey \
      --extra_apks HealthConnectController.apk="${KEYS_DIR}"/releasekey \
      --extra_apks OsuLogin.apk="${KEYS_DIR}"/releasekey \
      --extra_apks SafetyCenterResources.apk="${KEYS_DIR}"/releasekey \
      --extra_apks ServiceConnectivityResources.apk="${KEYS_DIR}"/releasekey \
      --extra_apks ServiceUwbResources.apk="${KEYS_DIR}"/releasekey \
      --extra_apks ServiceWifiResources.apk="${KEYS_DIR}"/releasekey \
      --extra_apks WifiDialog.apk="${KEYS_DIR}"/releasekey \
      "${APEX_ARGS[@]}" \
      "${OUT}"/obj/PACKAGING/target_files_intermediates/*-target_files*.zip \
      "${OUT}"/signed-target_files.zip 2>&1 | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sign.txt
  then
    _cleanup_fail
  fi
  set -eu
  unset APEX_ARGS
}

_cleanup_fail() {
  _print_build_fail
  exit 1
}

trap _cleanup_fail ERR

_cleanup
if [[ -n "${ROM_BUILD_FLAGS}" ]]; then
  IFS=',' read -r -a "ROM_BUILD_FLAGS" <<< "${ROM_BUILD_FLAGS}"
  for flags in "${ROM_BUILD_FLAGS[@]}"; do
    IFS=' ' read -r -a "TARGET_BUILD_FLAGS" <<< "${flags}"
    _print_success "Current build flags: ${flags}"
    _determine_signing "${TARGET_BUILD_FLAGS[@]}"
    source "${SCRIPT_DIR}"/packaging.sh
  done
else
  _determine_signing
  source "${SCRIPT_DIR}"/packaging.sh
fi
