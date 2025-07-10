#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Create/print ota json
_ota_info() {
  local file_size id datetime custom_build_type
  file_size=$(stat -c%s "${OUT}"/"${PACKAGE_NAME}")
  id=$(sha256sum "${OUT}"/"${PACKAGE_NAME}" | cut -d" " -f1)
  datetime=$(grep ro\.build\.date\.utc "${OUT}"/system/build.prop | cut -d"=" -f2)
  custom_build_type="UNOFFICIAL"
  jq -n "{\"response\": [{\"datetime\": ${datetime},\"filename\": \"${PACKAGE_NAME}\",\"id\": \"${id}\",\"romtype\": \"${custom_build_type}\", \"size\": ${file_size}, \"url\": \"${DL_OTA_URL}\", \"version\": \"${ROM_VERSION}\"}]}" > "${OUT}"/"${PACKAGE_NAME}".json
}

# Push OTA info
_push_ota_info() {
  local target_ota_repo_url target_ota_branch
  if [[ ! -d "${ROM_DIR}"_ota ]]; then
    mkdir "${ROM_DIR}"_ota
  fi
  cd "${ROM_DIR}"_ota || exit
  git init
  git pull "${OTA_REPO_URL}" "${ROM_BRANCH}"

  cp "${OUT}"/"${PACKAGE_NAME}".json "${ROM_DIR}"_ota/"${TARGET_DEVICE}".json
  git add "${ROM_DIR}"_ota/"${TARGET_DEVICE}".json
  git commit -m "${TARGET_DEVICE}: ${BUILD_DATE} update"

  # Use ssh primarely, fallback to github tokens
  if [[ -n $(find "${HOME}"/.ssh -name "id_*") ]]; then
    target_ota_repo_url="${OTA_REPO_URL}"
  elif [[ -n "${GITHUB_TOKEN}" ]]; then
    target_ota_repo_url="${OTA_REPO_URL//git@github.com:/https://${GITHUB_TOKEN}@github.com/}"
  fi

  # Append extraversion to avoid collision of different flavours
  if [[ -n "${ROM_OTA_BRANCH_FALLBACK}" ]]; then
    target_ota_branch="${ROM_OTA_BRANCH_FALLBACK}"
  else
    target_ota_branch="${ROM_BRANCH}"
  fi

  if [[ -n "${ROM_EXTRAVERSION}" ]]; then
    target_ota_branch="${target_ota_branch}"-"${ROM_EXTRAVERSION,,}"
  fi

  if [[ -n "${target_ota_repo_url}" ]]; then
    git push "${target_ota_repo_url}" HEAD:"${target_ota_branch}"
  fi
}

_cleanup_fail() {
  _print_ota_fail
  exit 1
}

trap _cleanup_fail ERR

_ota_info
if [[ -n "${OTA_REPO_URL}" ]]; then
  _push_ota_info
fi
_print_done
