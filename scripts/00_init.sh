#!/bin/bash

set -eEuo pipefail
if [[ 'true' == "${DEBUG}" ]]; then
  set -x
  unset DEBUG
fi

# Set up logs
find "${LOGS_DIR}"/ -type d -ctime +1 -exec rm --recursive {} \; || true
BUILD_DATE_UNIX="$(date '+%s')"
BUILD_DATE=$(env TZ="${TIME_ZONE}" date --date=@"${BUILD_DATE_UNIX}" '+%Y%m%d-%H%M%S')
mkdir "${LOGS_DIR}"/"${BUILD_DATE}"
unset BIN_DIR

# shellcheck source=scripts/01_sync.sh
source "${SCRIPT_DIR}"/01_sync.sh
