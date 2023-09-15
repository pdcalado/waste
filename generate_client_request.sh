#!/usr/bin/env bash

set -xeuf -o pipefail

# these are exported within this script
export $(xargs < .env)

WASTE_SOCKET="$(pwd)/sock"
export WASTE_SOCKET

sed -e "s/\$\$AUDIO_DEVICE/$AUDIO_DEVICE/" \
    -e "s/\$\$LANGS/$LANGS/" \
    -e "s/\$\$PROXY_REMOTE_ENDPOINT/${PROXY_REMOTE_ENDPOINT:-}/" \
    -e "s|\$\$WASTE_SOCKET|${WASTE_SOCKET}|" \
    -e "s|\$\$PATTERNS_FILE|${PATTERNS_FILE:-/dev/null}|" \
    < tpl_rofi-whisper-request > ./output/rofi-whisper-request