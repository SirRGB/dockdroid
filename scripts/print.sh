#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Skelleton for posting to telegram
_telegram() {
  if [[ -n "${TELEGRAM_TOKEN}" ]]; then
    curl --request POST https://api.telegram.org/bot"${TELEGRAM_TOKEN}"/sendMessage \
      --data chat_id="${TELEGRAM_CHAT}" \
      --data parse_mode="Markdown" \
      --data text="$1"
  fi
}

_telegram_separator() {
  if [[ -n "${TELEGRAM_TOKEN}" ]]; then
    curl --request POST https://api.telegram.org/bot"${TELEGRAM_TOKEN}"/sendSticker \
      --data parse_mode=HTML \
      --data chat_id="${TELEGRAM_CHAT}" \
      --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE
  fi
}

# Syncing
_print_sync_start() {
  SYNC_START=$(date +"%s")
  _telegram "Sync started for ${ROM_MANIFEST//.git/}/tree/${ROM_BRANCH}"
}

_print_sync_success() {
  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  echo -e "${GREEN}Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds${NC}"
  _telegram "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}

_print_sync_fail() {
  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  echo -e "${RED}Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds${NC}"
  _telegram "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
  _telegram_separator
}

# Building
_print_build_start() {
  BUILD_START=$(date +"%s")
  _telegram "Build started for ${TARGET_DEVICE}"
}

_print_build_success() {
  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  echo -e "${GREEN}Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds${NC}"
  _telegram "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_print_build_fail() {
  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  echo -e "${RED}Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds${NC}"
  _telegram "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
  _telegram_separator
}

# Uploading
_print_upload_start() {
  echo -e "${GREEN}Upload started${NC}"
  _telegram "Upload started"
}

_print_upload_success() {
  echo -e "${GREEN}Upload completed successfully${NC}"
  _telegram "Build successfully uploaded:
[ROM](${DL_OTA_URL})
[Recovery](${DL_OTA_URL//.zip/-recovery.img})"
}

_print_done() {
  echo -e "${GREEN}Completed successfully${NC}"
  _telegram_separator
}
