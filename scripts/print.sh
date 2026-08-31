#!/bin/bash

# Skeleton for printing to stdout
_print_success() {
  args=()
  if [[ -n "${TELEGRAM_TOKEN}" ]] && [[ -n "${TELEGRAM_CHAT}" ]]; then
    args=("${args[@]}" "--token" "${TELEGRAM_TOKEN}" "--chat" "${TELEGRAM_CHAT}")
  fi
  "${SCRIPT_DIR}"/print.py --action print_message --message "$*" "${args[@]}"
}

_print_error() {
    if [[ -n "${TELEGRAM_TOKEN}" ]] && [[ -n "${TELEGRAM_CHAT}" ]]; then
      args=("${args[@]}" "--token" "${TELEGRAM_TOKEN}" "--chat" "${TELEGRAM_CHAT}")
    fi
   "${SCRIPT_DIR}"/print.py --action print_message --message "$*" --failed "true" "${args[@]}"
}


# Syncing
_print_sync_start() {
  SYNC_START=$(date '+%s')
  _print_success "Sync started for ${ROM_MANIFEST//.git/}/tree/${ROM_BRANCH}"
}

_print_sync_success() {
  SYNC_END=$(date '+%s')
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  _print_success "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}

_print_sync_fail() {
  SYNC_END=$(date '+%s')
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  _print_error "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}


# Building
_print_build_start() {
  BUILD_START=$(date +"%s")
  _print_success "Build started for ${TARGET_DEVICE/_/\\_}"
}

_print_build_success() {
  BUILD_END=$(date '+%s')
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  _print_success "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_print_build_fail() {
  BUILD_END=$(date '+%s')
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  _print_error "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_print_signing_method() {
  _print_success "$* Signing"
}


# Uploading
_print_upload_start() {
  _print_success "$* Upload started"
}

_print_upload_success() {
  _print_success "Build successfully uploaded:
[ROM](${DL_OTA_URL})
[Recovery](${DL_OTA_URL//.zip/-recovery.img})"
}

_print_upload_fail() {
  _print_error 'Upload failed'
}


# Ota
_print_ota_fail() {
  _print_error 'Ota info failed'
}


# End
_print_done() {
  _print_success 'Completed successfully'
  "${SCRIPT_DIR}"/print.py -a send_telegram_end
}
