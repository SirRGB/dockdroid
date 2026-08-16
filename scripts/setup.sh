#!/bin/bash

# Set up ccache for build caching
_ccache() {
  if [[ "${CCACHE_SIZE}" -gt 0 ]]; then
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=/mnt/ccache
    ccache --max-size "${CCACHE_SIZE}"G
    ccache --set-config compression=true
  fi
  unset CCACHE_SIZE
}

# Generate keys if they do not exist
_keysgen() {
  for cert in bluetooth cyngn-app cyngn-priv-app media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity; do
    if [[ ! -f "${KEYS_DIR}"/"${cert}".x509.pem ]]; then
      make_key "${KEYS_DIR}"/"${cert}" "${KEYS_SUBJECT}"
    fi
  done

  APEX_KEYS=(
    com.android.adbd
    com.android.adservices
    com.android.adservices.api
    com.android.appsearch
    com.android.art
    com.android.bluetooth
    com.android.bt
    com.android.btservices
    com.android.cellbroadcast
    com.android.compos
    com.android.configinfrastructure
    com.android.connectivity.resources
    com.android.conscrypt
    com.android.crashrecovery
    com.android.devicelock
    com.android.extservices
    com.android.hardware.authsecret
    com.android.hardware.biometrics.face.virtual
    com.android.hardware.biometrics.fingerprint.virtual
    com.android.hardware.boot
    com.android.hardware.cas
    com.android.hardware.contexthub
    com.android.hardware.drm.clearkey
    com.android.hardware.dumpstate
    com.android.hardware.gatekeeper.nonsecure
    com.android.hardware.neuralnetworks
    com.android.hardware.power
    com.android.hardware.rebootescrow
    com.android.hardware.thermal
    com.android.hardware.threadnetwork
    com.android.hardware.uwb
    com.android.hardware.vibrator
    com.android.hardware.wifi
    com.android.healthfitness
    com.android.hotspot2.osulogin
    com.android.i18n
    com.android.ipsec
    com.android.media
    com.android.media.swcodec
    com.android.mediaprovider
    com.android.nearby.halfsheet
    com.android.networkstack.tethering
    com.android.neuralnetworks
    com.android.nfcservices
    com.android.npumanager
    com.android.ondevicepersonalization
    com.android.os.statsd
    com.android.permission
    com.android.profiling
    com.android.resolv
    com.android.rkpd
    com.android.runtime
    com.android.safetycenter.resources
    com.android.scheduling
    com.android.sdkext
    com.android.support.apexer
    com.android.telephony
    com.android.telephonycore
    com.android.telephonymodules
    com.android.tethering
    com.android.tzdata
    com.android.uprobestats
    com.android.uwb
    com.android.uwb.resources
    com.android.virt
    com.android.vndk.current
    com.android.vndk.current.on_vendor
    com.android.webapp
    com.android.wifi
    com.android.wifi.dialog
    com.android.wifi.resources
    com.google.pixel.vibrator.hal
    com.qorvo.uwb
  )

  for apex in "${APEX_KEYS[@]}"; do
    if [[ ! -f "${KEYS_DIR}"/"${apex}".x509.pem ]] || [[ ! -f "${KEYS_DIR}"/"${apex}".pem ]] ; then
      subject="${KEYS_SUBJECT//CN=Android/CN=\$\{apex\}}"
      make_key "${KEYS_DIR}"/"${apex}" "${subject}"
      openssl pkcs8 -in "${KEYS_DIR}"/"${apex}".pk8 -inform DER -nocrypt -out "${KEYS_DIR}"/"${apex}".pem
    fi
  done

  if [[ -n "${BL_RELOCK}" ]]; then
    if [[ ! -f "${KEYS_DIR}"/avbkey_4096.x509.pem ]] || [[ ! -f "${KEYS_DIR}"/avbkey_4096.pem ]] ; then
      subject="${KEYS_SUBJECT//CN=Android/CN=\$\{apex\}}"
      make_key "${KEYS_DIR}"/avbkey_4096 "${subject}"
      openssl pkcs8 -in "${KEYS_DIR}"/avbkey_4096.pk8 -inform DER -nocrypt -out "${KEYS_DIR}"/avbkey_4096.pem
    fi
  fi

  unset KEYS_SUBJECT
}

# Get android version for legacy workarounds and signing
_get_android_version() {
  ANDROID_VERSION=$(< "${ROM_DIR}"/cts/tests/tests/os/assets/platform_versions.txt tr --delete 'A-z' | cut --delimiter='.' --fields=1 | sort | tail --lines=1)
}

# Prepare Android build env
_run_envsetup() {
  set +eu
  # shellcheck source=/dev/null
  source "${ROM_DIR}"/build/envsetup.sh || true
  croot
  set -eu
}

# Fetch patches from gerrit
_repopick() {
  export TOP="${ROM_DIR}"
  if [[ -n "${REPOPICK_PICKS}" ]]; then
    repopick --force "${REPOPICK_PICKS}" || true
  fi

  if [[ -n "${REPOPICK_TOPICS}" ]]; then
    repopick --force --topic "${REPOPICK_TOPICS}" || true
  fi

  if [[ -n "${REPOPICK_PULLS}" ]]; then
    repopick --force --pull "${REPOPICK_PULLS}" || true
  fi
}

_ccache
_keysgen
_get_android_version
# shellcheck source=scripts/compat.sh
source "${SCRIPT_DIR}"/compat.sh
_run_envsetup
_repopick

# shellcheck source=scripts/lunch.sh
source "${SCRIPT_DIR}"/lunch.sh
