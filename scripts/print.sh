_telegram_check_token() {
  TELEGRAM_SET="false"
  set +u
  if [[ -n ${TELEGRAM_TOKEN} ]]; then
    TELEGRAM_SET="true"
  fi
  set -u
}

_print_sync_start() {
  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_sync_start
  fi
}

_print_sync_success() {
  local GREEN='\033[0;32m'

  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  echo -e "${GREEN}Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"

  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_sync_success
  fi
}

_print_sync_fail() {
  local RED='\033[0;31m'

  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))
  echo -e "${RED}Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"

  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_sync_fail
  fi
}

_telegram_sync_start() {
  telegram -M "Sync started for ${ROM_MANIFEST}/tree/${ROM_BRANCH}"
}

_telegram_sync_success() {
  telegram -M "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
}

_telegram_sync_fail() {
  telegram -M "Sync failed successfully"
}

# Print build success
_print_build_success() {
  local GREEN='\033[0;32m'

  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  echo -e "${GREEN}Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
  echo -e "${GREEN}Package: $OUT/$PACKAGE_NAME"

  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_build_success
  fi
}

_print_build_start() {
  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_build_start
  fi
}

# Print build success
_print_build_fail() {
  local RED='\033[0;31m'

  BUILD_END=$(date +"%s")
  BUILD_DIFF=$((BUILD_END - BUILD_START))
  echo -e "${RED}Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_build_fail
  fi
}

_telegram_build_start() {
  telegram -M "Build started for ${DEVICE}"
}

_telegram_build_success() {
  telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_telegram_build_fail() {
  telegram -M "Build failed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
}

_print_upload_start() {
  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_upload_start
  fi
}

_print_upload_success() {
  if [[ ${TELEGRAM_SET} = "true" ]]; then
    _telegram_upload_success
  fi
}

_telegram_upload_start() {
  telegram -M "Upload started"
}

_telegram_upload_success() {
  local custom_recovery_url=$(echo $custom_ota_url | sed "s/.zip/-recovery.img/g")
  telegram -M "Build successfully uploaded:
ROM:
${custom_ota_url}
Recovery:
${custom_recovery_url}"
}

_telegram_separator() {
  if [[ ${TELEGRAM_SET} = "true" ]]; then
    curl --data parse_mode=HTML --data chat_id=${TELEGRAM_CHAT} --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendSticker
  fi
}
