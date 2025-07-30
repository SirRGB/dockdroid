#!/bin/bash

set -eEuo pipefail #-x

# Add our functions
export PATH="${BIN_DIR}":"${PATH}"

# Set up logs
find "${LOGS_DIR}"/ -type d -ctime +1 -exec rm -r {} \; || true
BUILD_DATE_UNIX=$(date "+%s")
BUILD_DATE=$(env TZ="${TIME_ZONE}" date -d @"${BUILD_DATE_UNIX}" "+%Y%m%d-%H%M%S")
mkdir "${LOGS_DIR}"/"${BUILD_DATE}"
unset BIN_DIR

# shellcheck source=scripts/sync.sh
source "${SCRIPT_DIR}"/sync.sh
