#!/bin/bash

source "${SCRIPT_DIR}"/print.sh

_upload_check() {
  set +u
  UPLOAD_TARGET=
  if [[ -n "${GITHUB_TOKEN}" ]] && [[ -n "${GH_RELEASES_REPO}" ]]; then
    UPLOAD_TARGET="gh"
  elif [[ -n $(ls .ssh/id_*) ]] && [[ -n "${SF_USER}" ]] && [[ -n "${SF_RELEASES_REPO}" ]]; then
    UPLOAD_TARGET="sf"
  fi
  set -u
}

_upload() {
  if [[ "${UPLOAD_TARGET}" = "gh" ]]; then
    _upload_gh
  elif [[ "${UPLOAD_TARGET}" = "sf" ]]; then
    _upload_sf
  fi
}

_upload_gh() {
  local DESC
  TAG=$(echo "$(date +%Y%m%d%H%M)"-"${PACKAGE_NAME//.zip/}")
  DESC="${ROM_PREFIX}-${ROM_VERSION} for ${DEVICE}"

  github-release "${OTA_REPO_URL//git@github.com:/}" "${TAG}" "main" "${DESC}" "${OUT}"/"${PACKAGE_NAME}"
  github-release "${OTA_REPO_URL//git@github.com:/}" "${TAG}" "main" "${DESC}" "${OUT}"/"${RECOVERY_NAME}"
}

_upload_sf() {
  scp "${OUT}"/"${PACKAGE_NAME}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/"${DEVICE}"/"${ROM_PREFIX}"
  scp "${OUT}"/"${RECOVERY_NAME}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/"${DEVICE}"/"${ROM_PREFIX}"
}

# Create/print ota json
_ota_info() {
  local file_size id datetime custom_build_type
  file_size=$(stat -c%s "${OUT}"/"${PACKAGE_NAME}")
  id=$(sha256sum "${OUT}"/"${PACKAGE_NAME}" | cut -d" " -f1)
  datetime=$(grep ro\.build\.date\.utc "${OUT}"/system/build.prop | cut -d"=" -f2)
  custom_build_type="UNOFFICIAL"
  if [[ "${UPLOAD_TARGET}" = "gh" ]]; then
    custom_ota_url="https://github.com/${GH_RELEASES_REPO}/releases/download/${TAG}/${PACKAGE_NAME}"
  elif [[ "${UPLOAD_TARGET}" = "sf" ]]; then
    custom_ota_url="https://sourceforge.net/projects/${SF_RELEASES_REPO}/files/${DEVICE}/${ROM_PREFIX}/${PACKAGE_NAME}/download"
  fi
  echo -e "{\n  \"response\": [\n    {\n      \"datetime\": ${datetime},\n      \"filename\": \"${PACKAGE_NAME}\",\n      \"id\": \"${id}\",\n      \"romtype\": \"${custom_build_type}\",\n      \"size\": ${file_size},\n      \"url\": \"${custom_ota_url}\",\n      \"version\": \"${ROM_VERSION}\"\n    }\n  ]\n}" > "${OUT}"/"${PACKAGE_NAME}".json
  echo "OTA JSON: ${OUT}/${PACKAGE_NAME}.json"
}

# Push OTA info
_push_ota_info() {
  if [[ ! -d "${OTA_DIR}" ]]; then
    git clone "${OTA_REPO_URL}" "${OTA_DIR}" -b "${ROM_BRANCH}"
    cd "${OTA_DIR}"
  else
    cd "${OTA_DIR}"
    git checkout "${ROM_BRANCH}"
  fi

  cp "${OUT}"/"${PACKAGE_NAME}".json ./"${DEVICE}".json
  git add .
  git commit -m "${DEVICE}: automated ${ROM_BRANCH} update"
  git push origin HEAD:"${ROM_BRANCH}"
}

# Check for tokens before attempting upload
_upload_check
if [[ -n "${UPLOAD_TARGET}" ]]; then
  _print_upload_start
  _upload
  _ota_info
  _push_ota_info
  _print_upload_success
fi
_print_done
