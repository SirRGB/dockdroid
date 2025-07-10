#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Skelleton for posting to telegram
_telegram() {
  if [[ -n "${TELEGRAM_TOKEN}" ]]; then
    curl -fsSL \
      --request POST https://api.telegram.org/bot"${TELEGRAM_TOKEN}"/sendMessage \
      --data chat_id="${TELEGRAM_CHAT}" \
      --data parse_mode="Markdown" \
      --data text="$1"
  fi
}

_telegram_separator() {
  if [[ -n "${TELEGRAM_TOKEN}" ]]; then
    curl -fsSL \
      --request POST https://api.telegram.org/bot"${TELEGRAM_TOKEN}"/sendSticker \
      --data chat_id="${TELEGRAM_CHAT}" \
      --data parse_mode=HTML \
      --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE
  fi
}

# Skelleton for printing to stdout
_print_success() {
  echo -e "${GREEN}$*${NC}"
  _telegram "$*"
}

_print_error() {
  echo -e "${RED}$*${NC}"
  _telegram "$*"
  _telegram_separator
}


# Syncing
_print_sync_start() {
  SYNC_START=$(date +"%s")
  _print_success "Sync started for ${ROM_MANIFEST//.git/}/tree/${ROM_BRANCH}"
}

_print_sync_success() {
  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  _print_success "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}

_print_sync_fail() {
  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  _print_error "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}


# Building
_print_build_start() {
  BUILD_START=$(date +"%s")
  _print_success "Build started for ${TARGET_DEVICE}"
}

_print_build_success() {
  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  _print_success "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_print_build_fail() {
  BUILD_END=$(date +"%s")
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
  _print_error "Upload failed"
}

# Ota
_print_ota_fail() {
  _print_error "Ota info failed"
}


_print_done() {
  _print_success "Completed successfully"
  _telegram_separator
}
