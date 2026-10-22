#!/bin/bash

# shellcheck source=scripts/print.sh
source "${SCRIPT_DIR}"/print.sh

# Create/print ota json
_ota_info() {
  if [[ 15 -lt "${ANDROID_VERSION}"  ]]; then
    _ota_info_new
  else
    _ota_info_old
  fi
}

_extract_meta() {
  sed -n "s/^${1}=//;T;p;q" <<<"${metadata}"
}

_ota_info_new() {
  local metadata date datetime filename filepath os_patch_level os_sdk_level ota_property_files sha1 sha256 file_size type url
  metadata="$(unzip -p "${OUT}"/"${PACKAGE_NAME}" META-INF/com/android/metadata 2>/dev/null || true)"
  [[ -n "${metadata}" ]] || echo "no META-INF/com/android/metadata in ${PACKAGE_NAME} — is this really an OTA zip?"

  date=$(grep ro\.build\.date\.utc "${OUT}"/system/build.prop | cut --delimiter='=' --fields=2)
  datetime=$(grep ro\.build\.date\.utc "${OUT}"/system/build.prop | cut --delimiter='=' --fields=2)
  filename="${PACKAGE_NAME}"
  filepath=$(cut --delimiter='/' --fields=4- <<< "${DL_OTA_URL}"/"${PACKAGE_NAME}")
  os_patch_level="$(_extract_meta 'post-security-patch-level')"
  os_sdk_level="$(_extract_meta 'post-sdk-level')"
  ota_property_files="$(_extract_meta 'ota-property-files')"
  sha1=$(sha1sum "${OUT}"/"${PACKAGE_NAME}" | cut --delimiter=' ' --fields=1)
  sha256=$(sha256sum "${OUT}"/"${PACKAGE_NAME}" | cut --delimiter=' ' --fields=1)
  file_size=$(stat --format=%s "${OUT}"/"${PACKAGE_NAME}")
  type='UNOFFICIAL'
  url="${DL_OTA_URL}"
  version="${ROM_VERSION}"

  python3 -m json.tool --indent 2 <<< "[{\"date\": \"${date}\",\"datetime\": ${datetime},\"files\":[{\"date\": \"${date}\",\"datetime\": ${datetime},\"filename\": \"${filename}\",\"filepath\": \"${filepath}\",\"os_patch_level\": ${os_patch_level},\"os_sdk_level\": ${os_sdk_level},\"os_property_files\": \"${ota_property_files}\",\"sha1\": \"${sha1}\",\"sha256\": \"${sha256}\",\"size\": ${file_size},\"type\": \"${type}\",\"url\": \"${url}\"}],\"type\": \"${type}\",\"version\": \"${version}\"}]" > "${OUT}"/"${PACKAGE_NAME}".json
}

_ota_info_old() {
  local datetime file_id filename file_size romtype url version
  datetime=$(grep ro\.build\.date\.utc "${OUT}"/system/build.prop | cut --delimiter='=' --fields=2)
  filename="${PACKAGE_NAME}"
  file_id=$(sha256sum "${OUT}"/"${PACKAGE_NAME}" | cut --delimiter=' ' --fields=1)
  romtype='UNOFFICIAL'
  file_size=$(stat --format=%s "${OUT}"/"${PACKAGE_NAME}")
  url="${DL_OTA_URL}"
  version="${ROM_VERSION}"

  python3 -m json.tool --indent 2 <<< "{\"response\": [{\"datetime\": ${datetime},\"filename\": \"${filename}\",\"id\": \"${file_id}\",\"romtype\": \"${romtype}\",\"size\": ${file_size},\"url\": \"${url}\",\"version\": \"${version}\"}]}" > "${OUT}"/"${PACKAGE_NAME}".json
}

# Push OTA info
_push_ota_info() {
  local target_ota_repo_url target_ota_branch
  if [[ -d "${ROM_DIR}"_ota ]]; then
    rm --recursive --force "${ROM_DIR}"_ota
  fi

  mkdir "${ROM_DIR}"_ota
  cd "${ROM_DIR}"_ota || exit
  git init

  # Specify a fallback, so that roms, that purely rely on android numbers do not collide
  if [[ -n "${ROM_OTA_BRANCH_FALLBACK}" ]]; then
    target_ota_branch="${ROM_OTA_BRANCH_FALLBACK}"
  else
    target_ota_branch="${ROM_BRANCH}"
  fi

  # Append extraversion to avoid collision of different flavours
  if [[ -n "${ROM_EXTRAVERSION}" ]]; then
    target_ota_branch="${target_ota_branch}"-"$(tr --delete '-' <<< "${ROM_EXTRAVERSION,,}")"
  fi

  git pull "${OTA_REPO_URL}" "${target_ota_branch}"

  cp "${OUT}"/"${PACKAGE_NAME}".json "${ROM_DIR}"_ota/"${TARGET_DEVICE}".json
  git add "${ROM_DIR}"_ota/"${TARGET_DEVICE}".json
  git commit --message="${TARGET_DEVICE}: ${BUILD_DATE} update"

  # Use ssh primarily, fallback to github tokens
  if [[ -n $(find "${HOME}"/.ssh -name "id_*") ]]; then
    target_ota_repo_url="${OTA_REPO_URL}"
  elif [[ -n "${GITHUB_TOKEN}" ]]; then
    target_ota_repo_url="${OTA_REPO_URL//git@github.com:/https://${GITHUB_TOKEN}@github.com/}"
  else
    _cleanup_fail
  fi

  if [[ -n "${target_ota_repo_url}" ]]; then
    git push "${target_ota_repo_url}" HEAD:"${target_ota_branch}"
  fi
}

_cleanup_fail() {
  _print_ota_fail
  exit 1
}

_ota_info
if [[ -n "${OTA_REPO_URL}" ]]; then
  _push_ota_info
fi
_print_done
