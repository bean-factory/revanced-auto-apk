#!/usr/bin/env bash

set -eu -o pipefail

source build.conf
source utils.sh

: >build.md
mkdir -p "$BUILD_DIR" "$TEMP_DIR"

if [ "$UPDATE_PREBUILTS" = true ]; then get_prebuilts; else set_prebuilts; fi
log "**App Versions:**"
build_youtube &
wait
hash_gen
echo "Done"
