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
log "\n**App Hashes:**"
log "\`\`\`"
for FILE in build/*.apk; do
	echo "$(echo $FILE | cut -d / -f 2): $(sha256sum $FILE | cut -d ' ' -f 1)"
done
log "\`\`\`"
wait
echo "Done"
