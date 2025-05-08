#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Drop old builds
_cleanup() {
  set +eu
  m installclean | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/build.txt
  set -eu
}

# Decide for signing method
_determine_signing() {
  export SDK_VERSION
  set +eu
  m target-files-package otatools | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/build.txt
  set -eu
  # Read SDK Version, version_defaults doesnt exist on A14+
  if [[ -f "${ANDROID_BUILD_TOP}"/build/make/core/version_defaults.mk ]]; then
    SDK_VERSION=$(grep -E "PLATFORM_SDK_VERSION :=" "${ANDROID_BUILD_TOP}"/build/make/core/version_defaults.mk | tr -d "A-z:= ")
  # Android 14+ fallback
  else
    SDK_VERSION=34
  fi

  # If Android version greater than 11, use apex signing
  if [[ "${SDK_VERSION}" -gt 30 ]]; then
    echo "APEX Signing"
    _sign_new
  else
    echo "Legacy Signing"
    _sign_old
  fi
}

# Old signing process, A11/below
_sign_old() {
  set +eu
  croot
  "${ANDROID_BUILD_TOP}"/build/tools/releasetools/sign_target_files_apks -o -d "${KEYS_DIR}" \
      "${OUT}"/obj/PACKAGING/target_files_intermediates/*-target_files-*.zip \
      "${OUT}"/signed-target_files.zip | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sign-legacy.txt
  set -eu
}

# New signing process (APEX), A12/up
_sign_new() {
  set +eu
  croot
  sign_target_files_apks -o -d "${KEYS_DIR}" \
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
      --extra_apks com.android.adbd.apex="${KEYS_DIR}"/com.android.adbd \
      --extra_apks com.android.adservices.apex="${KEYS_DIR}"/com.android.adservices \
      --extra_apks com.android.adservices.api.apex="${KEYS_DIR}"/com.android.adservices.api \
      --extra_apks com.android.appsearch.apex="${KEYS_DIR}"/com.android.appsearch \
      --extra_apks com.android.art.apex="${KEYS_DIR}"/com.android.art \
      --extra_apks com.android.bluetooth.apex="${KEYS_DIR}"/com.android.bluetooth \
      --extra_apks com.android.btservices.apex="${KEYS_DIR}"/com.android.btservices \
      --extra_apks com.android.cellbroadcast.apex="${KEYS_DIR}"/com.android.cellbroadcast \
      --extra_apks com.android.compos.apex="${KEYS_DIR}"/com.android.compos \
      --extra_apks com.android.configinfrastructure.apex="${KEYS_DIR}"/com.android.configinfrastructure \
      --extra_apks com.android.connectivity.resources.apex="${KEYS_DIR}"/com.android.connectivity.resources \
      --extra_apks com.android.conscrypt.apex="${KEYS_DIR}"/com.android.conscrypt \
      --extra_apks com.android.devicelock.apex="${KEYS_DIR}"/com.android.devicelock \
      --extra_apks com.android.extservices.apex="${KEYS_DIR}"/com.android.extservices \
      --extra_apks com.android.graphics.pdf.apex="${KEYS_DIR}"/com.android.graphics.pdf \
      --extra_apks com.android.hardware.biometrics.face.virtual.apex="${KEYS_DIR}"/com.android.hardware.biometrics.face.virtual \
      --extra_apks com.android.hardware.biometrics.fingerprint.virtual.apex="${KEYS_DIR}"/com.android.hardware.biometrics.fingerprint.virtual \
      --extra_apks com.android.hardware.boot.apex="${KEYS_DIR}"/com.android.hardware.boot \
      --extra_apks com.android.hardware.cas.apex="${KEYS_DIR}"/com.android.hardware.cas \
      --extra_apks com.android.hardware.wifi.apex="${KEYS_DIR}"/com.android.hardware.wifi \
      --extra_apks com.android.healthfitness.apex="${KEYS_DIR}"/com.android.healthfitness \
      --extra_apks com.android.hotspot2.osulogin.apex="${KEYS_DIR}"/com.android.hotspot2.osulogin \
      --extra_apks com.android.i18n.apex="${KEYS_DIR}"/com.android.i18n \
      --extra_apks com.android.ipsec.apex="${KEYS_DIR}"/com.android.ipsec \
      --extra_apks com.android.media.apex="${KEYS_DIR}"/com.android.media \
      --extra_apks com.android.media.swcodec.apex="${KEYS_DIR}"/com.android.media.swcodec \
      --extra_apks com.android.mediaprovider.apex="${KEYS_DIR}"/com.android.mediaprovider \
      --extra_apks com.android.nearby.halfsheet.apex="${KEYS_DIR}"/com.android.nearby.halfsheet \
      --extra_apks com.android.networkstack.tethering.apex="${KEYS_DIR}"/com.android.networkstack.tethering \
      --extra_apks com.android.neuralnetworks.apex="${KEYS_DIR}"/com.android.neuralnetworks \
      --extra_apks com.android.ondevicepersonalization.apex="${KEYS_DIR}"/com.android.ondevicepersonalization \
      --extra_apks com.android.os.statsd.apex="${KEYS_DIR}"/com.android.os.statsd \
      --extra_apks com.android.permission.apex="${KEYS_DIR}"/com.android.permission \
      --extra_apks com.android.resolv.apex="${KEYS_DIR}"/com.android.resolv \
      --extra_apks com.android.rkpd.apex="${KEYS_DIR}"/com.android.rkpd \
      --extra_apks com.android.runtime.apex="${KEYS_DIR}"/com.android.runtime \
      --extra_apks com.android.safetycenter.resources.apex="${KEYS_DIR}"/com.android.safetycenter.resources \
      --extra_apks com.android.scheduling.apex="${KEYS_DIR}"/com.android.scheduling \
      --extra_apks com.android.sdkext.apex="${KEYS_DIR}"/com.android.sdkext \
      --extra_apks com.android.support.apexer.apex="${KEYS_DIR}"/com.android.support.apexer \
      --extra_apks com.android.telephony.apex="${KEYS_DIR}"/com.android.telephony \
      --extra_apks com.android.telephonymodules.apex="${KEYS_DIR}"/com.android.telephonymodules \
      --extra_apks com.android.tethering.apex="${KEYS_DIR}"/com.android.tethering \
      --extra_apks com.android.tzdata.apex="${KEYS_DIR}"/com.android.tzdata \
      --extra_apks com.android.uwb.apex="${KEYS_DIR}"/com.android.uwb \
      --extra_apks com.android.uwb.resources.apex="${KEYS_DIR}"/com.android.uwb.resources \
      --extra_apks com.android.virt.apex="${KEYS_DIR}"/com.android.virt \
      --extra_apks com.android.vndk.current.apex="${KEYS_DIR}"/com.android.vndk.current \
      --extra_apks com.android.vndk.current.on_vendor.apex="${KEYS_DIR}"/com.android.vndk.current.on_vendor \
      --extra_apks com.android.wifi.apex="${KEYS_DIR}"/com.android.wifi \
      --extra_apks com.android.wifi.dialog.apex="${KEYS_DIR}"/com.android.wifi.dialog \
      --extra_apks com.android.wifi.resources.apex="${KEYS_DIR}"/com.android.wifi.resources \
      --extra_apks com.google.pixel.camera.hal.apex="${KEYS_DIR}"/com.google.pixel.camera.hal \
      --extra_apks com.google.pixel.vibrator.hal.apex="${KEYS_DIR}"/com.google.pixel.vibrator.hal \
      --extra_apks com.qorvo.uwb.apex="${KEYS_DIR}"/com.qorvo.uwb \
      --extra_apex_payload_key com.android.adbd.apex="${KEYS_DIR}"/com.android.adbd.pem \
      --extra_apex_payload_key com.android.adservices.apex="${KEYS_DIR}"/com.android.adservices.pem \
      --extra_apex_payload_key com.android.adservices.api.apex="${KEYS_DIR}"/com.android.adservices.api.pem \
      --extra_apex_payload_key com.android.appsearch.apex="${KEYS_DIR}"/com.android.appsearch.pem \
      --extra_apex_payload_key com.android.art.apex="${KEYS_DIR}"/com.android.art.pem \
      --extra_apex_payload_key com.android.bluetooth.apex="${KEYS_DIR}"/com.android.bluetooth.pem \
      --extra_apex_payload_key com.android.btservices.apex="${KEYS_DIR}"/com.android.btservices.pem \
      --extra_apex_payload_key com.android.cellbroadcast.apex="${KEYS_DIR}"/com.android.cellbroadcast.pem \
      --extra_apex_payload_key com.android.compos.apex="${KEYS_DIR}"/com.android.compos.pem \
      --extra_apex_payload_key com.android.configinfrastructure.apex="${KEYS_DIR}"/com.android.configinfrastructure.pem \
      --extra_apex_payload_key com.android.connectivity.resources.apex="${KEYS_DIR}"/com.android.connectivity.resources.pem \
      --extra_apex_payload_key com.android.conscrypt.apex="${KEYS_DIR}"/com.android.conscrypt.pem \
      --extra_apex_payload_key com.android.devicelock.apex="${KEYS_DIR}"/com.android.devicelock.pem \
      --extra_apex_payload_key com.android.extservices.apex="${KEYS_DIR}"/com.android.extservices.pem \
      --extra_apex_payload_key com.android.graphics.pdf.apex="${KEYS_DIR}"/com.android.graphics.pdf.pem \
      --extra_apex_payload_key com.android.hardware.biometrics.face.virtual.apex="${KEYS_DIR}"/com.android.hardware.biometrics.face.virtual.pem \
      --extra_apex_payload_key com.android.hardware.biometrics.fingerprint.virtual.apex="${KEYS_DIR}"/com.android.hardware.biometrics.fingerprint.virtual.pem \
      --extra_apex_payload_key com.android.hardware.boot.apex="${KEYS_DIR}"/com.android.hardware.boot.pem \
      --extra_apex_payload_key com.android.hardware.cas.apex="${KEYS_DIR}"/com.android.hardware.cas.pem \
      --extra_apex_payload_key com.android.hardware.wifi.apex="${KEYS_DIR}"/com.android.hardware.wifi.pem \
      --extra_apex_payload_key com.android.healthfitness.apex="${KEYS_DIR}"/com.android.healthfitness.pem \
      --extra_apex_payload_key com.android.hotspot2.osulogin.apex="${KEYS_DIR}"/com.android.hotspot2.osulogin.pem \
      --extra_apex_payload_key com.android.i18n.apex="${KEYS_DIR}"/com.android.i18n.pem \
      --extra_apex_payload_key com.android.ipsec.apex="${KEYS_DIR}"/com.android.ipsec.pem \
      --extra_apex_payload_key com.android.media.apex="${KEYS_DIR}"/com.android.media.pem \
      --extra_apex_payload_key com.android.media.swcodec.apex="${KEYS_DIR}"/com.android.media.swcodec.pem \
      --extra_apex_payload_key com.android.mediaprovider.apex="${KEYS_DIR}"/com.android.mediaprovider.pem \
      --extra_apex_payload_key com.android.nearby.halfsheet.apex="${KEYS_DIR}"/com.android.nearby.halfsheet.pem \
      --extra_apex_payload_key com.android.networkstack.tethering.apex="${KEYS_DIR}"/com.android.networkstack.tethering.pem \
      --extra_apex_payload_key com.android.neuralnetworks.apex="${KEYS_DIR}"/com.android.neuralnetworks.pem \
      --extra_apex_payload_key com.android.ondevicepersonalization.apex="${KEYS_DIR}"/com.android.ondevicepersonalization.pem \
      --extra_apex_payload_key com.android.os.statsd.apex="${KEYS_DIR}"/com.android.os.statsd.pem \
      --extra_apex_payload_key com.android.permission.apex="${KEYS_DIR}"/com.android.permission.pem \
      --extra_apex_payload_key com.android.resolv.apex="${KEYS_DIR}"/com.android.resolv.pem \
      --extra_apex_payload_key com.android.rkpd.apex="${KEYS_DIR}"/com.android.rkpd.pem \
      --extra_apex_payload_key com.android.runtime.apex="${KEYS_DIR}"/com.android.runtime.pem \
      --extra_apex_payload_key com.android.safetycenter.resources.apex="${KEYS_DIR}"/com.android.safetycenter.resources.pem \
      --extra_apex_payload_key com.android.scheduling.apex="${KEYS_DIR}"/com.android.scheduling.pem \
      --extra_apex_payload_key com.android.sdkext.apex="${KEYS_DIR}"/com.android.sdkext.pem \
      --extra_apex_payload_key com.android.support.apexer.apex="${KEYS_DIR}"/com.android.support.apexer.pem \
      --extra_apex_payload_key com.android.telephony.apex="${KEYS_DIR}"/com.android.telephony.pem \
      --extra_apex_payload_key com.android.telephonymodules.apex="${KEYS_DIR}"/com.android.telephonymodules.pem \
      --extra_apex_payload_key com.android.tethering.apex="${KEYS_DIR}"/com.android.tethering.pem \
      --extra_apex_payload_key com.android.tzdata.apex="${KEYS_DIR}"/com.android.tzdata.pem \
      --extra_apex_payload_key com.android.uwb.apex="${KEYS_DIR}"/com.android.uwb.pem \
      --extra_apex_payload_key com.android.uwb.resources.apex="${KEYS_DIR}"/com.android.uwb.resources.pem \
      --extra_apex_payload_key com.android.virt.apex="${KEYS_DIR}"/com.android.virt.pem \
      --extra_apex_payload_key com.android.vndk.current.apex="${KEYS_DIR}"/com.android.vndk.current.pem \
      --extra_apex_payload_key com.android.vndk.current.on_vendor.apex="${KEYS_DIR}"/com.android.vndk.current.on_vendor.pem \
      --extra_apex_payload_key com.android.wifi.apex="${KEYS_DIR}"/com.android.wifi.pem \
      --extra_apex_payload_key com.android.wifi.dialog.apex="${KEYS_DIR}"/com.android.wifi.dialog.pem \
      --extra_apex_payload_key com.android.wifi.resources.apex="${KEYS_DIR}"/com.android.wifi.resources.pem \
      --extra_apex_payload_key com.google.pixel.camera.hal.apex="${KEYS_DIR}"/com.google.pixel.camera.hal.pem \
      --extra_apex_payload_key com.google.pixel.vibrator.hal.apex="${KEYS_DIR}"/com.google.pixel.vibrator.hal.pem \
      --extra_apex_payload_key com.qorvo.uwb.apex="${KEYS_DIR}"/com.qorvo.uwb.pem \
      "${OUT}"/obj/PACKAGING/target_files_intermediates/*-target_files*.zip \
      "${OUT}"/signed-target_files.zip | tee -a "${LOGS_DIR}"/"${BUILD_DATE}"/sign.txt
  set -eu
}

cleanup() {
  _print_build_fail
}
trap cleanup ERR

_cleanup
_determine_signing # _sign_new, _sign_old

source "${SCRIPT_DIR}"/packaging.sh
