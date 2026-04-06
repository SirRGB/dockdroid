#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Check for tokens to decide the upload target
_upload() {
  UPLOAD_TARGET=''
  DL_OTA_URL=''
  if [[ -n "${GITHUB_TOKEN}" ]] && [[ -n "${OTA_REPO_URL}" ]]; then
    UPLOAD_TARGET='github'
    _print_upload_start "${UPLOAD_TARGET}"
    _upload_gh
  elif [[ -n $(find "${HOME}"/.ssh -name "id_*") ]] && [[ -n "${SF_USER}" ]] && [[ -n "${SF_RELEASES_REPO}" ]]; then
    UPLOAD_TARGET='sourceforge'
    _print_upload_start "${UPLOAD_TARGET}"
    _upload_sf
  elif [[ -n $(find "${HOME}"/.ssh -name "id_*") ]] && [[ -n "${SSH_USER}" ]] && [[ -n "${SSH_UPLOAD_URL}" ]] && [[ -n "${SSH_DOWNLOAD_URL}" ]]; then
    UPLOAD_TARGET='ssh'
    _print_upload_start "${UPLOAD_TARGET}"
    _upload_generic
  fi
}

# Upload to GitHub
_upload_gh() {
  local tag desc release_repo upload_url
  tag=$(env TZ="${TIME_ZONE}" date --date=@"${BUILD_DATE_UNIX}" '+%Y%m%d%H%M')-"${PACKAGE_NAME//.zip/}"
  desc="${ROM_PREFIX}${ROM_VERSION} for ${TARGET_DEVICE}"
  release_repo="${OTA_REPO_URL//git@github.com:/}"

  # Create a release and get url
  upload_url=$(curl_cmd \
    --url "https://api.github.com/octocat" \
    --request POST \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    --header 'content-type: application/json' \
    https://api.github.com/repos/"${release_repo}"/releases \
    --data "{ \"tag_name\": \"${tag}\", \"body\": \"${desc}\" }" \
    | tr --delete '\n' | "${SCRIPT_DIR}"/json_arg_parser.py "upload_url" \
    | cut --delimiter='{' --fields=1)

  # Upload ROM
  DL_OTA_URL=$(curl_cmd \
    --header 'Accept: application/vnd.github.v3+json' \
    --header "Content-Length: $(stat -c%s "${OUT}"/"${PACKAGE_NAME}")" \
    --header "Authorization: token ${GITHUB_TOKEN}" \
    --header "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME}")" \
    --upload-file "${OUT}"/"${PACKAGE_NAME}" \
    "${upload_url}"?name="${PACKAGE_NAME}" \
    | tr --delete '\n' | "${SCRIPT_DIR}"/json_arg_parser.py "browser_download_url")

  # Upload Recovery
  curl_cmd \
    --header 'Accept: application/vnd.github.v3+json' \
    --header "Content-Length: $(stat -c%s "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}")" \
    --header "Authorization: token ${GITHUB_TOKEN}" \
    --header "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}")" \
    --upload-file "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" \
    "${upload_url}"?name="${PACKAGE_NAME//.zip/-recovery.img}"


  # Upload Recovery
  if [[ -n "${BL_RELOCK}" ]]; then
    curl_cmd \
      --header 'Accept: application/vnd.github.v3+json' \
      --header "Content-Length: $(stat -c%s "${OUT}"/"${PACKAGE_NAME//.zip/-pkmd.bin}")" \
      --header "Authorization: token ${GITHUB_TOKEN}" \
      --header "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME//.zip/-pkmd.bin}")" \
      --upload-file "${OUT}"/"${PACKAGE_NAME//.zip/-pkmd.bin}" \
      "${upload_url}"?name="${PACKAGE_NAME//.zip/-pkmd.bin}"
  fi
}

_upload_ssh() {
  scp "${OUT}"/"${PACKAGE_NAME}" "${1}"@"${2}"
  scp "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" "${1}"@"${2}"
  if [[ -n "${BL_RELOCK}" ]]; then
    scp "${OUT}"/"${PACKAGE_NAME//.zip/-pkmd.bin}" "${1}"@"${2}"
  fi

  DL_OTA_URL="${3}"
}

# Upload to SourceForge
_upload_sf() {
  _upload_ssh "${SF_USER}" frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/ https://sourceforge.net/projects/"${SF_RELEASES_REPO}"/files/"${PACKAGE_NAME}"/download
}

_upload_generic() {
  _upload_ssh "${SSH_USER}" "${SSH_UPLOAD_URL}" "${SSH_DOWNLOAD_URL}"
}

_cleanup_fail() {
  _print_upload_fail
  exit 1
}

_upload
if [[ -n "${UPLOAD_TARGET}" ]]; then
  _print_upload_success
fi

source "${SCRIPT_DIR}"/ota.sh
