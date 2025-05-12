#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

_telegram() {
  if [[ -n "${TELEGRAM_TOKEN}" ]]; then
    curl -s https://api.telegram.org/bot"${TELEGRAM_TOKEN}"/sendMessage \
      -d "chat_id=\"${TELEGRAM_CHAT}\"" \
      -d "parse_mode=Markdown" \
      -d "text=\"$1\""
  fi
}

_telegram_check_token() {
  TELEGRAM_SET="false"
  set +u
  if [[ -n "${TELEGRAM_TOKEN}" ]]; then
    TELEGRAM_SET="true"
  fi
  set -u
}

_print_sync_start() {
  _telegram_check_token
  SYNC_START=$(date +"%s")
  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_sync_start
  fi
}

_print_sync_success() {
  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  echo -e "${GREEN}Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds${NC}"

  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_sync_success
  fi
}

_print_sync_fail() {
  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  echo -e "${RED}Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds${NC}"

  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_sync_fail
  fi
}

_telegram_sync_start() {
  _telegram "Sync started for ${ROM_MANIFEST//.git//}/tree/${ROM_BRANCH}"
}

_telegram_sync_success() {
  _telegram "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}

_telegram_sync_fail() {
  _telegram "Sync failed successfully"
  _telegram_separator
}

# Print build success
_print_build_success() {
  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  echo -e "${GREEN}Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds${NC}"

  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_build_success
  fi
}

_print_build_start() {
  BUILD_START=$(date +"%s")
  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_build_start
  fi
}

# Print build success
_print_build_fail() {
  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  echo -e "${RED}Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds${NC}"

  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_build_fail
  fi
}

_telegram_build_start() {
  _telegram "Build started for ${DEVICE}"
}

_telegram_build_success() {
  _telegram "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_telegram_build_fail() {
  _telegram "Build failed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
  _telegram_separator
}

_print_upload_start() {
  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_upload_start
  fi
}

_print_upload_success() {
  echo -e "${GREEN}Upload completed successfully${NC}"
  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    _telegram_upload_success
  fi
}

_telegram_upload_start() {
  _telegram "Upload started"
}

_telegram_upload_success() {
  _telegram "Build successfully uploaded:
ROM:
${CUSTOM_OTA_URL}
Recovery:
${CUSTOM_OTA_URL//.zip/-recovery.img}"
}

_print_done() {
  echo -e "${GREEN}Completed successfully${NC}"
  _telegram_separator
}

_telegram_separator() {
  if [[ "${TELEGRAM_SET}" = "true" ]]; then
    curl --data parse_mode=HTML --data chat_id="${TELEGRAM_CHAT}" --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot"${TELEGRAM_TOKEN}"/sendSticker
  fi
}
