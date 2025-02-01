#!/bin/bash

set -euo pipefail #-x

# Check for executing user
#if [[ "$(whoami)" = root ]]; then
#  echo "Only users can run this script."
#  sleep 3
#  exit 1
#fi

export PATH="$PATH":"$BIN_DIR"

# Fetch Tokens for Telegram/GitHub/SourceForge
if [[ -f "$SECRETS_DIR"/tokens.sh ]]; then
  source "$SECRETS_DIR"/tokens.sh
fi

source "$SCRIPT_DIR"/sync.sh
