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
  upload_url=$(
    "${SCRIPT_DIR}"/07_create_github_release.py --repo "${release_repo}" --token "${GITHUB_TOKEN}" --name "${tag}" --desc "${desc}"
  )

  # Upload ROM
  DL_OTA_URL=$("${SCRIPT_DIR}"/07_upload_github.py --url "${upload_url}" --token "${GITHUB_TOKEN}" --file "${OUT}"/"${PACKAGE_NAME}")

  # Upload Recovery
  "${SCRIPT_DIR}"/07_upload_github.py --url "${upload_url}" --token "${GITHUB_TOKEN}" --file "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}"

  # Upload Keys
  if [[ -n "${BL_RELOCK}" ]]; then
    "${SCRIPT_DIR}"/07_upload_github.py --url "${upload_url}" --token "${GITHUB_TOKEN}" --file "${OUT}"/"${PACKAGE_NAME//.zip/-pkmd.bin}"
  fi
}

_upload_ssh() {
  scp "${OUT}"/"${PACKAGE_NAME}" "${1}"@"${2}"
  scp "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" "${1}"@"${2}"
  if [[ -n "${BL_RELOCK}" ]]; then
    scp "${OUT}"/"${PACKAGE_NAME//.zip/-pkmd.bin}" "${1}"@"${2}"
  fi

  export DL_OTA_URL="${3}"
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

source "${SCRIPT_DIR}"/08_ota.sh
