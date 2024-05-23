#!/usr/bin/env bash

set -xeuf -o pipefail

# these are exported within this script
export $(xargs < .env)

export WASTE_ENDPOINT

sed -e "s/\$\$AUDIO_DEVICE/$AUDIO_DEVICE/" \
    -e "s/\$\$LANGS/$LANGS/" \
    -e "s|\$\$WASTE_ENDPOINT|${WASTE_ENDPOINT}|" \
    -e "s|\$\$PATTERNS_FILE|${PATTERNS_FILE:-/dev/null}|" \
    < tpl_rofi-waste-request > ./output/rofi-waste-request

chmod +x ./output/rofi-waste-request