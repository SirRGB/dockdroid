#!/bin/bash

#set -x

source "$SCRIPT_DIR"/print.sh

# Set up ccache
_ccache() {
  if [[ -n "${CCACHE_SIZE}" ]] && [[ "${CCACHE_SIZE}" -gt 0 ]]; then
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=/mnt/ccache
    ccache -M "${CCACHE_SIZE}"G
    ccache -o compression=true
  fi
}

_keysgen() {
  if [[ ! -f "${KEYS_DIR}"/releasekey.pk8 ]]; then
    for cert in bluetooth cyngn-app media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity; do \
      make_key "${KEYS_DIR}"/"${cert}" "${KEYS_SUBJECT}"; \
    done

    for apex in com.android.adbd com.android.adservices com.android.adservices.api com.android.appsearch com.android.appsearch.apk com.android.art com.android.bluetooth com.android.btservices com.android.cellbroadcast com.android.compos com.android.configinfrastructure com.android.connectivity.resources com.android.conscrypt com.android.devicelock com.android.extservices com.android.graphics.pdf com.android.hardware.authsecret com.android.hardware.biometrics.face.virtual com.android.hardware.biometrics.fingerprint.virtual com.android.hardware.boot com.android.hardware.cas com.android.hardware.neuralnetworks com.android.hardware.rebootescrow com.android.hardware.wifi com.android.healthfitness com.android.hotspot2.osulogin com.android.i18n com.android.ipsec com.android.media com.android.media.swcodec com.android.mediaprovider com.android.nearby.halfsheet com.android.networkstack.tethering com.android.neuralnetworks com.android.nfcservices com.android.ondevicepersonalization com.android.os.statsd com.android.permission com.android.profiling com.android.resolv com.android.rkpd com.android.runtime com.android.safetycenter.resources com.android.scheduling com.android.sdkext com.android.support.apexer com.android.telephony com.android.telephonymodules com.android.tethering com.android.tzdata com.android.uwb com.android.uwb.resources com.android.virt com.android.vndk.current com.android.vndk.current.on_vendor com.android.wifi com.android.wifi.dialog com.android.wifi.resources com.google.pixel.camera.hal com.google.pixel.vibrator.hal com.qorvo.uwb; do \
      #subject=$(echo "${KEYS_SUBJECT}" | sed 's/CN=Android/CN=${apex}/g'); \
      subject="${KEYS_SUBJECT//CN=Android/CN=\$\{apex\}}"
      make_key "${KEYS_DIR}"/"${apex}" "${subject}"; \
      openssl pkcs8 -in "${KEYS_DIR}"/"${apex}".pk8 -inform DER -nocrypt -out "${KEYS_DIR}"/"${apex}".pem; \
    done
  fi
}

_lunch() {
  set +eu
  source build/envsetup.sh
  set -eu

  # Append release codename, if exists (A14+)
  RELEASE_CODENAME=
  if [[ -d "${ANDROID_BUILD_TOP}"/build/release/aconfig/ ]]; then
    RELEASE_CODENAME=-$(ls -1 -I trunk* -I root "${ANDROID_BUILD_TOP}"/build/release/aconfig/)
  fi
  local RELEASE_CODENAME

  # Extract lunch prefix from AndroidProducts
  PRODUCT=$(grep -E "${DEVICE}" "${ANDROID_BUILD_TOP}"/device/*/"${DEVICE}"/AndroidProducts.mk | cut -d"/" -f2 | cut -d"." -f1)
  local PRODUCT

  # It's all coming together
  set +eu
  lunch "${PRODUCT}""${RELEASE_CODENAME}"-"${BUILD_TYPE}"
  set -eu
}

_ccache
_keysgen
_lunch
_print_build_start

source "${SCRIPT_DIR}"/build.sh
