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

unset ROOT_DIR SECRETS_DIR BIN_DIR
# shellcheck source=scripts/sync.sh
source "${SCRIPT_DIR}"/sync.sh
