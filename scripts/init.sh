#!/bin/bash

set -eEuo pipefail #-x

export PATH="$PATH":"$BIN_DIR"

# Fetch Tokens for Telegram/GitHub/SourceForge
if [[ -f "$SECRETS_DIR"/tokens.sh ]]; then
  source "$SECRETS_DIR"/tokens.sh
fi

source "$SCRIPT_DIR"/sync.sh
