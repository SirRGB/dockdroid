#!/bin/bash

set -eEuo pipefail #-x

# Add our functions
export PATH="${BIN_DIR}":"${PATH}"

# Fetch Tokens for Telegram/GitHub/SourceForge
if [[ -f "${SECRETS_DIR}"/tokens.sh ]]; then
  # We check if this exists above this
  # shellcheck source=/dev/null
  source "${SECRETS_DIR}"/tokens.sh
fi

# Set up logs
BUILD_DATE_UNIX=$(date "+%s")
BUILD_DATE=$(env TZ="${TIME_ZONE}" date -d @"${BUILD_DATE_UNIX}" "+%Y%m%d-%H%M%S")
mkdir "${LOGS_DIR}"/"${BUILD_DATE}"

unset ROOT_DIR SECRETS_DIR BIN_DIR
# shellcheck source=scripts/sync.sh
source "${SCRIPT_DIR}"/sync.sh
