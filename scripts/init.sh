#!/bin/bash

set -eEuo pipefail #-x

export PATH="${PATH}":"${BIN_DIR}"

# Fetch Tokens for Telegram/GitHub/GitLab/SourceForge
if [[ -f "${SECRETS_DIR}"/tokens.sh ]]; then
  # We check if this exists above this
  # shellcheck source=/dev/null
  source "${SECRETS_DIR}"/tokens.sh
fi

unset SECRETS_DIR BIN_DIR
# shellcheck source=scripts/sync.sh
source "${SCRIPT_DIR}"/sync.sh
