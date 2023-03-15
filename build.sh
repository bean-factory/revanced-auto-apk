#!/usr/bin/env bash

set -eu -o pipefail

source build.conf
source utils.sh

: >build.md
mkdir -p "$BUILD_DIR" "$TEMP_DIR"

if [ "$UPDATE_PREBUILTS" = true ]; then get_prebuilts; else set_prebuilts; fi
log "**App Versions:**"
build_youtube &
build_music &
build_twitter &
build_reddit &
build_twitch &
build_tiktok &
build_spotify &
build_ticktick &
build_warn_wetter &
build_backdrops &
build_windy &
build_tasker &
build_citra &
build_instagram &
build_nova &
wait
hash_gen
echo "Done"
