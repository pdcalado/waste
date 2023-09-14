#!/usr/bin/env bash

set -euf -o pipefail

# these are exported within this script
export $(xargs < .env)

WASTE_SOCKET="$(pwd)/sock"
export WASTE_SOCKET

sed -e "s/\$\$AUDIO_DEVICE/$AUDIO_DEVICE/" \
    -e "s/\$\$LANGS/$LANGS/" \
    -e "s/\$\$PROXY_REMOTE_ENDPOINT/$PROXY_REMOTE_ENDPOINT/" \
    -e "s/\$\$WASTE_SOCKET/$WASTE_SOCKET/" \
    < tpl_rofi-whisper-request > ./output/rofi-whisper-request