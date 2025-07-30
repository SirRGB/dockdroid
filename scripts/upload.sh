#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Check for tokens to decide the upload target
_upload() {
  UPLOAD_TARGET=""
  DL_OTA_URL=""
  if [[ -n "${GITHUB_TOKEN}" ]] && [[ -n "${OTA_REPO_URL}" ]]; then
    UPLOAD_TARGET="github"
    _print_upload_start "${UPLOAD_TARGET}"
    _upload_gh
  elif [[ -n $(find "${HOME}"/.ssh -name "id_*") ]] && [[ -n "${SF_USER}" ]] && [[ -n "${SF_RELEASES_REPO}" ]]; then
    UPLOAD_TARGET="sourceforge"
    _print_upload_start "${UPLOAD_TARGET}"
    _upload_sf
  fi
}

# Upload to GitHub
_upload_gh() {
  local tag desc release_repo upload_url
  tag=$(env TZ="${TIME_ZONE}" date -d @"${BUILD_DATE_UNIX}" "+%Y%m%d%H%M")-"${PACKAGE_NAME//.zip/}"
  desc="${ROM_PREFIX}${ROM_VERSION} for ${TARGET_DEVICE}"
  release_repo="${OTA_REPO_URL//git@github.com:/}"

  # Create a release and get url
  upload_url=$(curl -fsSL \
    -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "content-type: application/json" \
    https://api.github.com/repos/"${release_repo}"/releases \
    -d "{ \"tag_name\": \"${tag}\", \"body\": \"${desc}\" }" \
    | jq -r .upload_url \
    | cut -d"{" -f1)

  # Upload ROM
  DL_OTA_URL=$(curl -fSL \
    -H "Content-Length: $(stat -c%s "${OUT}"/"${PACKAGE_NAME}")" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME}")" \
    -T "${OUT}"/"${PACKAGE_NAME}" \
    -H "Accept: application/vnd.github.v3+json" \
    "${upload_url}"?name="${PACKAGE_NAME}" \
    | jq -r .browser_download_url)

  # Upload Recovery
  curl -fSL \
    -H "Content-Length: $(stat -c%s "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}")" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}")" \
    -T "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" \
    -H "Accept: application/vnd.github.v3+json" \
    "${upload_url}"?name="${PACKAGE_NAME//.zip/-recovery.img}"
}

# Upload to SourceForge
_upload_sf() {
  scp "${OUT}"/"${PACKAGE_NAME}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/
  scp "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/
  DL_OTA_URL=https://sourceforge.net/projects/"${SF_RELEASES_REPO}"/files/"${PACKAGE_NAME}"/download
}

_cleanup_fail() {
  _print_upload_fail
  exit 1
}

trap _cleanup_fail ERR

_upload
if [[ -n "${UPLOAD_TARGET}" ]]; then
  _print_upload_success
fi

source "${SCRIPT_DIR}"/ota.sh
