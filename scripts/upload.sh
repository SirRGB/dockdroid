#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

_upload_check() {
  set +u
  UPLOAD_TARGET=
  if [[ -n "${GITHUB_TOKEN}" ]] && [[ -n "${GH_RELEASES_REPO}" ]]; then
    UPLOAD_TARGET="gh"
  elif [[ -n $(ls "${HOME}"/.ssh/id_*) ]] && [[ -n "${SF_USER}" ]] && [[ -n "${SF_RELEASES_REPO}" ]]; then
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
  local tag desc release_repo upload_url
  tag="$(date +%Y%m%d%H%M)"-"${PACKAGE_NAME//.zip/}"
  desc="${ROM_PREFIX}-${ROM_VERSION} for ${DEVICE}"
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

  # Upload Recovery
  curl -L \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: $(file -b --mime-type "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}")" \
    --data-binary @"${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" \
    "${upload_url}"?name="${PACKAGE_NAME//.zip/-recovery.img}"
}

_upload_sf() {
  scp "${OUT}"/"${PACKAGE_NAME}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/"${DEVICE}"/"${ROM_PREFIX}"
  scp "${OUT}"/"${PACKAGE_NAME//.zip/-recovery.img}" "${SF_USER}"@frs.sourceforge.net:/home/frs/project/"${SF_RELEASES_REPO}"/"${DEVICE}"/"${ROM_PREFIX}"
  DL_OTA_URL=https://sourceforge.net/projects/"${SF_RELEASES_REPO}"/files/"${DEVICE}"/"${ROM_PREFIX}"/"${PACKAGE_NAME}"/download
}

# Create/print ota json
_ota_info() {
  local file_size id datetime custom_build_type
  file_size=$(stat -c%s "${OUT}"/"${PACKAGE_NAME}")
  id=$(sha256sum "${OUT}"/"${PACKAGE_NAME}" | cut -d" " -f1)
  datetime=$(grep ro\.build\.date\.utc "${OUT}"/system/build.prop | cut -d"=" -f2)
  custom_build_type="UNOFFICIAL"
  jq -n "{\"response\": [{\"datetime\": ${datetime},\"filename\": \"${PACKAGE_NAME}\",\"id\": \"${id}\",\"romtype\": \"${custom_build_type}\", \"size\": ${file_size}, \"url\": \"${DL_OTA_URL}\", \"version\": \"${ROM_VERSION}\"}]}" > "${OUT}"/"${PACKAGE_NAME}".json
  echo "OTA JSON: ${OUT}/${PACKAGE_NAME}.json"
}

# Push OTA info
# TODO create branch conditionally
# TODO only add device json
_push_ota_info() {
  if [[ ! -d "${OTA_DIR}" ]]; then
    git clone "${OTA_REPO_URL}" "${OTA_DIR}" -b "${ROM_BRANCH}"
  fi

  cd "${OTA_DIR}" || exit
  git checkout "${ROM_BRANCH}"

  cp "${OUT}"/"${PACKAGE_NAME}".json ./"${DEVICE}".json
  git add .
  # Sign
  if [[ -n "${GPG_PASSPHRASE}" ]] && [[ -n $(ls "${HOME}"/.gnupg/) ]] ; then
    git commit -m -S "${DEVICE}: ${BUILD_DATE} update" --passphrase "${GPG_PASSPHRASE}"
  elif [[ -n $(ls "${HOME}"/.gnupg/) ]]; then
    git commit -m -S "${DEVICE}: ${BUILD_DATE} update"
  else
    git commit -m "${DEVICE}: ${BUILD_DATE} update"
  fi

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
