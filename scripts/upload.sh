#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

_upload_check() {
  UPLOAD_TARGET=""
  if [[ -n "${GITHUB_TOKEN}" ]] && [[ -n "${OTA_REPO_URL}" ]]; then
    UPLOAD_TARGET="gh"
  elif [[ -n $(find "${HOME}"/.ssh -name "id_*") ]] && [[ -n "${SF_USER}" ]] && [[ -n "${SF_RELEASES_REPO}" ]]; then
    UPLOAD_TARGET="sf"
  fi
}

_upload() {
  DL_OTA_URL=""
  if [[ "${UPLOAD_TARGET}" = "gh" ]]; then
    _upload_gh
  elif [[ "${UPLOAD_TARGET}" = "sf" ]]; then
    _upload_sf
  fi
}

_upload_gh() {
  local tag desc release_repo upload_url
  tag=$(env TZ="${TIME_ZONE}" date -d @"${BUILD_DATE_UNIX}" "+%Y%m%d%H%M")-"${PACKAGE_NAME//.zip/}"
  desc="${ROM_PREFIX}${ROM_VERSION} for ${TARGET_DEVICE}"
  release_repo="${OTA_REPO_URL//git@github.com:/}"

  # Create a release and get url
  upload_url=$(curl -L \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "content-type: application/json" \
    https://api.github.com/repos/"${release_repo}"/releases \
    -d "{ \"tag_name\": \"${tag}\", \"body\": \"${desc}\" }" \
    | jq -r .upload_url \
    | cut -d"{" -f1)

  # Upload ROM
  DL_OTA_URL=$(curl -L \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME}")" \
    --data-binary @"${OUT}"/"${PACKAGE_NAME}" \
    "${upload_url}"?name="${PACKAGE_NAME}" \
    | jq -r .browser_download_url)
  export DL_OTA_URL

  # Upload Recovery
  curl -L \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}")" \
    --data-binary @"${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" \
    "${upload_url}"?name="${PACKAGE_NAME//.zip/-recovery.img}"
}

_upload_sf() {
  scp "${OUT}"/"${PACKAGE_NAME}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/"${TARGET_DEVICE}"/"${ROM_PREFIX//-/}"/
  scp "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/"${TARGET_DEVICE}"/"${ROM_PREFIX//-/}"/
  DL_OTA_URL=https://sourceforge.net/projects/"${SF_RELEASES_REPO}"/files/"${TARGET_DEVICE}"/"${ROM_PREFIX//-/}"/"${PACKAGE_NAME}"/download
  export DL_OTA_URL
}

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
# TODO create branch conditionally
# TODO fallback for clashing rom branches
_push_ota_info() {
  if [[ ! -d "${ROM_DIR}"_ota ]]; then
    mkdir "${ROM_DIR}"_ota
    git init
    git pull "${OTA_REPO_URL}" "${ROM_BRANCH}"
  fi
  cd "${ROM_DIR}"_ota || exit

  cp "${OUT}"/"${PACKAGE_NAME}".json "${ROM_DIR}"_ota/"${TARGET_DEVICE}".json
  git add "${ROM_DIR}"_ota/"${TARGET_DEVICE}".json
  git commit -m "${TARGET_DEVICE}: ${BUILD_DATE} update"
  git push "${OTA_REPO_URL}" HEAD:"${ROM_BRANCH}"
}

_cleanup_fail() {
  _print_upload_fail
}
trap _cleanup_fail ERR

# Check for tokens before attempting upload
_upload_check
if [[ -n "${UPLOAD_TARGET}" ]]; then
  _print_upload_start "${UPLOAD_TARGET}"
fi
_upload
if [[ -n "${UPLOAD_TARGET}" ]]; then
  _print_upload_success
fi
_ota_info
if [[ -n "${OTA_REPO_URL}" ]]; then
  _push_ota_info
fi
_print_done
