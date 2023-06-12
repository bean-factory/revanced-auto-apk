#!/usr/bin/env bash
TEMP_DIR="temp"
BUILD_DIR="build"

if [ "${GITHUB_TOKEN:-}" ]; then GH_HEADER="Authorization: token ${GITHUB_TOKEN}"; else GH_HEADER=; fi
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-$"beans-321/revanced-auto-apk"}
NEXT_VER_CODE=${NEXT_VER_CODE:-$(date +'%Y%m%d')}
WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0"

json_get() {
	grep -o "\"${1}\":[^\"]*\"[^\"]*\"" | sed -E 's/".*".*"(.*)"/\1/' | if [ $# -eq 2 ]; then grep "$2"; else cat; fi || echo ""
}
get_prebuilts() {
	echo "Getting prebuilts"
	RV_CLI=$(gh_req https://api.github.com/repos/revanced/revanced-cli/releases/latest - )
	RV_CLI_URL=$(echo "$RV_CLI" | json_get 'browser_download_url')
	RV_CLI_JAR="${TEMP_DIR}/${RV_CLI_URL##*/}"
	RV_CLI_TAG=$(echo "$RV_CLI" | json_get 'tag_name')
	log "**ReVanced Versions:**"
	log "CLI: [${RV_CLI_URL##*/}](https://github.com/revanced/revanced-cli/releases/tag/$RV_CLI_TAG)"
	
	RVE_INTEGRATIONS=$(gh_req https://api.github.com/repos/inotia00/revanced-integrations/releases/latest -)
	RVE_INTEGRATIONS_URL=$(echo "$RVE_INTEGRATIONS" | json_get 'browser_download_url')
	RVE_INTEGRATIONS_APK=${RVE_INTEGRATIONS_URL##*/}
	RVE_INTEGRATIONS_TAG=$(echo "$RVE_INTEGRATIONS" | json_get 'tag_name')
	log "Integrations (Extended): [$RVE_INTEGRATIONS_APK](https://github.com/inotia00/revanced-integrations/releases/tag/$RVE_INTEGRATIONS_TAG)"
	RVE_INTEGRATIONS_APK=$(echo ${RVE_INTEGRATIONS_URL##*/} | sed 's/unsigned/unsigned-extended/g')
	RVE_INTEGRATIONS_APK="${TEMP_DIR}/${RVE_INTEGRATIONS_APK}"
	
	RV_INTEGRATIONS=$(gh_req https://api.github.com/repos/revanced/revanced-integrations/releases/latest -)
	RV_INTEGRATIONS_URL=$(echo "$RV_INTEGRATIONS" | json_get 'browser_download_url')
	RV_INTEGRATIONS_APK=${RV_INTEGRATIONS_URL##*/}
	RV_INTEGRATIONS_TAG=$(echo "$RV_INTEGRATIONS" | json_get 'tag_name')
	log "Integrations: [$RV_INTEGRATIONS_APK](https://github.com/revanced/revanced-integrations/releases/tag/$RV_INTEGRATIONS_TAG)"
	RV_INTEGRATIONS_APK="${TEMP_DIR}/${RV_INTEGRATIONS_APK}"

	RVE_PATCHES=$(gh_req https://api.github.com/repos/inotia00/revanced-patches/releases/latest -)
	RVE_PATCHES_DL=$(json_get 'browser_download_url' <<<"$RVE_PATCHES")
	RVE_PATCHES_JSON="${TEMP_DIR}/extended-patches-$(json_get 'tag_name' <<<"$RVE_PATCHES").json"
	RVE_PATCHES_CHANGELOG=$(echo "$RVE_PATCHES" | json_get 'body' | sed 's/\(\\n\)\+/\\n/g')
	RVE_PATCHES_URL=$(grep 'jar' <<<"$RVE_PATCHES_DL")
	RVE_PATCHES_TAG=$(echo "$RVE_PATCHES" | json_get 'tag_name')
	RVE_PATCHES_JAR="${TEMP_DIR}/${RVE_PATCHES_URL##*/}"
	log "Patches (Extended): [${RVE_PATCHES_URL##*/}](https://github.com/inotia00/revanced-patches/releases/tag/$RVE_PATCHES_TAG)"
	RVE_PATCHES_JAR="$(echo ${TEMP_DIR}/${RVE_PATCHES_URL##*/} | sed 's/revanced/revanced-extended/g')"
	
	RV_PATCHES=$(gh_req https://api.github.com/repos/revanced/revanced-patches/releases/latest -)
	RV_PATCHES_DL=$(json_get 'browser_download_url' <<<"$RV_PATCHES")
	RV_PATCHES_JSON="${TEMP_DIR}/patches-$(json_get 'tag_name' <<<"$RV_PATCHES").json"
	RV_PATCHES_CHANGELOG=$(echo "$RV_PATCHES" | json_get 'body' | sed 's/\(\\n\)\+/\\n/g')
	RV_PATCHES_URL=$(grep 'jar' <<<"$RV_PATCHES_DL")
	RV_PATCHES_TAG=$(echo "$RV_PATCHES" | json_get 'tag_name')
	RV_PATCHES_JAR="${TEMP_DIR}/${RV_PATCHES_URL##*/}"
	log "Patches: [${RV_PATCHES_URL##*/}](https://github.com/revanced/revanced-patches/releases/tag/$RV_PATCHES_TAG)"
	log "\n**Patches Changelog**: "
	log "ReVanced Extended Patches:"
	log "\n\`\`\`"
	log "${RVE_PATCHES_CHANGELOG//# [/### [}"
	log "\`\`\`\n"
	log "ReVanced Patches: "
	log "\n\`\`\`"
	log "${RV_PATCHES_CHANGELOG//# [/### [}"
	log "\`\`\`\n"

	dl_if_dne "$RV_CLI_JAR" "$RV_CLI_URL"
	dl_if_dne "$RVE_INTEGRATIONS_APK" "$RVE_INTEGRATIONS_URL"
	dl_if_dne "$RV_INTEGRATIONS_APK" "$RV_INTEGRATIONS_URL"
	dl_if_dne "$RVE_PATCHES_JAR" "$RVE_PATCHES_URL"
	dl_if_dne "$RVE_PATCHES_JSON" "$(grep 'json' <<<"$RVE_PATCHES_DL")"
	dl_if_dne "$RV_PATCHES_JAR" "$RV_PATCHES_URL"
	dl_if_dne "$RV_PATCHES_JSON" "$(grep 'json' <<<"$RV_PATCHES_DL")"
}

abort() { echo "abort: $1" && exit 1; }

set_prebuilts() {
	[ -d "$TEMP_DIR" ] || abort "${TEMP_DIR} directory could not be found"
	RV_CLI_JAR=$(find "$TEMP_DIR" -maxdepth 1 -name "revanced-cli-*" | tail -n1)
	[ -z "$RV_CLI_JAR" ] && abort "revanced cli not found"
	log "CLI: ${RV_CLI_JAR#"$TEMP_DIR/"}"
	RVE_INTEGRATIONS_APK=$(find "$TEMP_DIR" -maxdepth 1 -name "app-release-unsigned-*" | tail -n1)
	[ -z "$RV_CLI_JAR" ] && abort "revanced integrations not found"
	log "Integrations: ${RVE_INTEGRATIONS_APK#"$TEMP_DIR/"}"
	RVE_PATCHES_JAR=$(find "$TEMP_DIR" -maxdepth 1 -name "revanced-patches-*" | tail -n1)
	[ -z "$RV_CLI_JAR"  && abort "revanced patches not found"
	log "Patches: ${RVE_PATCHES_JAR#"$TEMP_DIR/"}"
}


_req() {
	if [ "$2" = - ]; then
		wget -nv -O "$2" --header="$3" "$1"
	else
		local dlp
		dlp="$(dirname "$2")/tmp.$(basename "$2")"
		wget -nv -O "$dlp" --header="$3" "$1"
		mv -f "$dlp" "$2"
	fi
}
req() { _req "$1" "$2" "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:108.0) Gecko/20100101 Firefox/108.0"; }
gh_req() { _req "$1" "$2" "$GH_HEADER"; }
log() { echo -e "$1  " >>build.md; }

get_largest_ver() {
	local vers m
	vers=$(tee)
	m=$(head -1 <<<"$vers")
	if ! semver_validate "$m"; then echo "$m"; else sort -rV <<<"$vers" | head -1; fi
}
semver_validate() {
	local a="${1%-*}"
	local ac="${a//[.0-9]/}"
	[ ${#ac} = 0 ]
}
get_patch_last_supported_ver() {
	if [ ${1} == "com.google.android.youtube" ] || [ ${1} == "com.google.android.apps.youtube.music" ];then
		jq -r ".[] | select(.compatiblePackages[].name==\"${1}\" and .excluded==false) | .compatiblePackages[].versions" "$RVE_PATCHES_JSON" |
		tr -d ' ,\t[]"' | sort -u | grep -v '^$' | get_largest_ver || return 1
	else
		jq -r ".[] | select(.compatiblePackages[].name==\"${1}\" and .excluded==false) | .compatiblePackages[].versions" "$RV_PATCHES_JSON" |
		tr -d ' ,\t[]"' | sort -u | grep -v '^$' | get_largest_ver || return 1
	fi

}

dl_if_dne() {
	if [ ! -f "$1" ]; then
		echo -e "\nGetting '$1' from '$2'"
		req "$2" "$1"
	fi
}

# if you are here to copy paste this piece of code, acknowledge it:)
dl_apkmirror() {
	local url=$1 version=$2 regexp=$3 output=$4
	url="https://www.apkmirror.com/apk/${url}/${url##*/}-${version//./-}-release/"
	resp=$(req "$url" -) || return 1
	url="https://www.apkmirror.com$(echo "$resp" | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
	url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
	url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
	req "$url" "$output"
}
get_apkmirror_vers() {
	local apkmirror_category=$1
	req "https://www.apkmirror.com/uploads/?appcategory=${apkmirror_category}" - | sed -n 's;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p'
}
get_uptodown_ver() {
	local app_name=$1
	req "https://${app_name}.en.uptodown.com/android/download" - | json_get 'softwareVersion'
}
dl_uptodown() {
	local app_name=$1 output=$2
	url=$(req "https://${app_name}.en.uptodown.com/android/download" - | sed -n 's;.*data-url="\(.*\)".*;\1;p')
	req "$url" "$output"
}

patch_apk() {
	local stock_input=$1 patched_apk=$2 patcher_args=$3
	declare -r tdir=$(mktemp -d -p $TEMP_DIR)
	local cmd="java -jar $RV_CLI_JAR --temp-dir=$tdir -c -a $stock_input -o $patched_apk -b $RV_PATCHES_JAR --keystore=ks.keystore -i predictive-back-gesture $patcher_args --options=./options.json"
	echo "$cmd"
	eval "$cmd"
}

build_rv() {
	local -n args=$1
	local version patcher_args dl_from build_mode_arr
	local mode_arg=${args[mode]%/*} version_mode=${args[mode]#*/}
	local arch=${args[arch]:-all} app_name_l=${args[app_name],,}
	local app_name=${args[app_name]}
	if [ "${args[apkmirror_dlurl]:-}" ] && [ "${args[regexp]:-}" ]; then dl_from=apkmirror; else dl_from=uptodown; fi

	if [ "$mode_arg" = none ]; then
		return
	elif [ "$mode_arg" = apk ]; then
		build_mode_arr=(apk)
	else
		echo "ERROR: undefined build mode for ${args[app_name]}: '${mode_arg}'"
		return
	fi

	for build_mode in "${build_mode_arr[@]}"; do
		patcher_args="${args[patcher_args]:-}"
		printf "Building '%s' (%s) in " "${args[app_name]}" "${arch}"
		echo "'APK' mode"
		local apkmirror_category=${args[apkmirror_dlurl]##*/}
		if [ "$version_mode" = auto ] && [ $dl_from = apkmirror ]; then
			version=$(get_patch_last_supported_ver "${args[pkg_name]}")
			if [ -z "$version" ]; then
				version=$(get_apkmirror_vers "$apkmirror_category" | if [ "${args[pkg_name]}" = "com.twitter.android" ]; then grep release; else cat; fi | get_largest_ver)
			fi
		elif [ "$version_mode" = latest ]; then
			if [ $dl_from = apkmirror ]; then
				version=$(get_apkmirror_vers "$apkmirror_category" | if [ "${args[pkg_name]}" = "com.twitter.android" ]; then grep release; else cat; fi | get_largest_ver)
			elif [ $dl_from = uptodown ]; then
				version=$(get_uptodown_ver "${app_name_l}")
			fi
			patcher_args="$patcher_args --experimental"
		else
			version=$version_mode
			patcher_args="$patcher_args --experimental"
		fi
		echo "Choosing version '${version}' for ${args[app_name]}"

		local stock_apk="${TEMP_DIR}/${app_name_l}-stock-v${version}-${arch}.apk"
		local apk_output="${BUILD_DIR}/${app_name}-v${version}-${arch}.apk"
		if [ "${args[microg_patch]:-}" ]; then
			local patched_apk="${TEMP_DIR}/${app_name_l}-v${version}-${arch}-${build_mode}.apk"
		else
			local patched_apk="${TEMP_DIR}/${app_name_l}-v${version}-${arch}.apk"
		fi
		if [ ! -f "$stock_apk" ]; then
			if [ $dl_from = apkmirror ]; then
				echo "Downloading from APKMirror"
				if ! dl_apkmirror "${args[apkmirror_dlurl]}" "$version" "${args[regexp]}" "$stock_apk"; then
					echo "ERROR: Could not find version '${version}' for ${args[app_name]}"
					return 1
				fi
			elif [ $dl_from = uptodown ]; then
				echo "Downloading the latest version from Uptodown"
				if ! dl_uptodown "$app_name_l" "$stock_apk"; then
					echo "ERROR: Could not download ${args[app_name]}"
					return 1
				fi
			else
				abort "UNREACHABLE $LINENO"
			fi
		fi

		if [ "${arch}" = "all" ]; then
			! grep -q "${args[app_name]}:" build.md && log "${args[app_name]}: ${version}"
		else
			! grep -q "${args[app_name]} (${arch}):" build.md && log "${args[app_name]} (${arch}): ${version}"
		fi

		[ ! -f "$patched_apk" ] && patch_apk "$stock_apk" "$patched_apk" "$patcher_args"
		if [ ! -f "$patched_apk" ]; then
			echo "BUILDING FAILED"
			return
		fi
		if [ "$build_mode" = apk ]; then
			cp -f "$patched_apk" "${apk_output}"
			echo "Built ${args[app_name]} (${arch}): '${apk_output}'"
			continue
		fi
		declare -r base_template=$(mktemp -d -p $TEMP_DIR)
	done
}

join_args() {
	echo "$1" | tr -d '\t\r' | tr ' ' '\n' | grep -v '^$' | sed "s/^/${2} /" | paste -sd " " - || echo ""
}

build_youtube() {
	declare -A youtube_args
	youtube_args[app_name]="YouTube"
	youtube_args[patcher_args]="-m ${RVE_INTEGRATIONS_APK} $(join_args "${YOUTUBE_EXCLUDED_PATCHES}" -e) $(join_args "${YOUTUBE_INCLUDED_PATCHES}" -i)"
	youtube_args[mode]="$YOUTUBE_MODE"
	youtube_args[microg_patch]="microg-support"
	youtube_args[pkg_name]="com.google.android.youtube"
	youtube_args[rip_all_libs]=true
	youtube_args[apkmirror_dlurl]="google-inc/youtube"
	youtube_args[regexp]="APK</span>[^@]*@\([^#]*\)"
	RV_PATCHES_JAR_BAK=$RV_PATCHES_JAR
	RV_PATCHES_JAR=$RVE_PATCHES_JAR
	build_rv youtube_args
	youtube_args[mode]="$YOUTUBE_MMT_MODE"
	youtube_args[app_name]="YouTube-MMT-Icon"
	youtube_args[patcher_args]="-m ${RVE_INTEGRATIONS_APK} $(join_args "${YOUTUBE_EXCLUDED_PATCHES}" -e) $(join_args "${YOUTUBE_INCLUDED_PATCHES}" -i) -i custom-branding-icon-mmt"
	build_rv youtube_args
	RV_PATCHES_JAR=$RV_PATCHES_JAR_BAK
}

build_music() {
	declare -A ytmusic_args
	ytmusic_args[app_name]="YouTube-Music"
	ytmusic_args[patcher_args]="-m ${RVE_INTEGRATIONS_APK} $(join_args "${MUSIC_EXCLUDED_PATCHES}" -e) $(join_args "${MUSIC_INCLUDED_PATCHES}" -i)"
	ytmusic_args[microg_patch]="music-microg-support"
	ytmusic_args[pkg_name]="com.google.android.apps.youtube.music"
	ytmusic_args[rip_all_libs]=false
	ytmusic_args[apkmirror_dlurl]="google-inc/youtube-music"

	for a in arm64-v8a arm-v7a; do
		if [ $a = arm64-v8a ]; then
			ytmusic_args[arch]=arm64-v8a
			ytmusic_args[regexp]='arm64-v8a</div>[^@]*@\([^"]*\)'
			ytmusic_args[mode]="$MUSIC_ARM64_V8A_MODE"
		elif [ $a = arm-v7a ]; then
			ytmusic_args[arch]=arm-v7a
			ytmusic_args[regexp]='armeabi-v7a</div>[^@]*@\([^"]*\)'
			ytmusic_args[mode]="$MUSIC_ARM_V7A_MODE"
		fi

		RV_PATCHES_JAR_BAK=$RV_PATCHES_JAR
		RV_PATCHES_JAR=$RVE_PATCHES_JAR
		build_rv ytmusic_args
		RV_PATCHES_JAR=$RV_PATCHES_JAR_BAK
	done

	ytmusic_args[app_name]="YouTube-Music-MMT-Icon"
	ytmusic_args[patcher_args]="-m ${RVE_INTEGRATIONS_APK} $(join_args "${MUSIC_EXCLUDED_PATCHES}" -e) $(join_args "${MUSIC_INCLUDED_PATCHES}" -i) -i custom-branding-music-mmt"

	for a in arm64-v8a arm-v7a; do
		if [ $a = arm64-v8a ]; then
			ytmusic_args[arch]=arm64-v8a
			ytmusic_args[regexp]='arm64-v8a</div>[^@]*@\([^"]*\)'
			ytmusic_args[mode]="$MUSIC_MMT_ARM64_V8A_MODE"
		elif [ $a = arm-v7a ]; then
			ytmusic_args[arch]=arm-v7a
			ytmusic_args[regexp]='armeabi-v7a</div>[^@]*@\([^"]*\)'
			ytmusic_args[mode]="$MUSIC_MMT_ARM_V7A_MODE"
		fi

		RV_PATCHES_JAR_BAK=$RV_PATCHES_JAR
		RV_PATCHES_JAR=$RVE_PATCHES_JAR
		build_rv ytmusic_args
		RV_PATCHES_JAR=$RV_PATCHES_JAR_BAK
	done
}

build_twitter() {
	declare -A tw_args
	tw_args[app_name]="Twitter"
	tw_args[mode]="$TWITTER_MODE"
	tw_args[patcher_args]="-m ${RV_INTEGRATIONS_APK} $(join_args "${TWITTER_EXCLUDED_PATCHES}" -e) $(join_args "${TWITTER_INCLUDED_PATCHES}" -i)"
	tw_args[pkg_name]="com.twitter.android"
	tw_args[apkmirror_dlurl]="twitter-inc/twitter"
	tw_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv tw_args
}

build_reddit() {
	declare -A reddit_args
	reddit_args[app_name]="Reddit"
	reddit_args[mode]="$REDDIT_MODE"
	reddit_args[patcher_args]="-m ${RV_INTEGRATIONS_APK} $(join_args "${REDDIT_EXCLUDED_PATCHES}" -e) $(join_args "${REDDIT_INCLUDED_PATCHES}" -i)"
	reddit_args[pkg_name]="com.reddit.frontpage"
	reddit_args[apkmirror_dlurl]="redditinc/reddit"
	reddit_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv reddit_args
}

build_twitch() {
	declare -A twitch_args
	twitch_args[app_name]="Twitch"
	twitch_args[patcher_args]="-m ${RV_INTEGRATIONS_APK} $(join_args "${TWITCH_EXCLUDED_PATCHES}" -e) $(join_args "${TWITCH_INCLUDED_PATCHES}" -i)"
	twitch_args[mode]="$TWITCH_MODE"
	twitch_args[pkg_name]="tv.twitch.android.app"
	twitch_args[apkmirror_dlurl]="twitch-interactive-inc/twitch"
	twitch_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv twitch_args
}

build_tiktok() {
	declare -A tiktok_args
	tiktok_args[app_name]="TikTok"
	tiktok_args[patcher_args]="-m ${RVE_INTEGRATIONS_APK}"
	tiktok_args[mode]="$TIKTOK_MODE"
	tiktok_args[pkg_name]="com.zhiliaoapp.musically"
	tiktok_args[apkmirror_dlurl]="tiktok-pte-ltd/tik-tok-including-musical-ly"
	tiktok_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv tiktok_args
}

build_spotify() {
	declare -A spotify_args
	spotify_args[app_name]="Spotify"
	spotify_args[mode]="$SPOTIFY_MODE"
	spotify_args[pkg_name]="com.spotify.music"

	build_rv spotify_args
}

build_ticktick() {
	declare -A ticktick_args
	ticktick_args[app_name]="TickTick"
	ticktick_args[mode]="$TICKTICK_MODE"
	ticktick_args[pkg_name]="com.ticktick.task"
	ticktick_args[apkmirror_dlurl]="appest-inc/ticktick-to-do-list-with-reminder-day-planner"
	ticktick_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv ticktick_args
}

build_warn_wetter() {
	declare -A warn_wetter_args
	warn_wetter_args[app_name]="WarnWetter"
	warn_wetter_args[mode]="$WARN_WETTER_MODE"
	warn_wetter_args[pkg_name]="de.dwd.warnapp"
	warn_wetter_args[apkmirror_dlurl]="deutscher-wetterdienst/warnwetter"
	warn_wetter_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv warn_wetter_args
}

build_backdrops() {
	declare -A backdrops_args
	backdrops_args[app_name]="Backdrops"
	backdrops_args[mode]="$BACKDROPS_MODE"
	backdrops_args[pkg_name]="com.backdrops.wallpapers"
	backdrops_args[apkmirror_dlurl]="backdrops/backdrops-wallpapers"
	backdrops_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv backdrops_args
}

build_windy() {
	declare -A windy_args
	windy_args[app_name]="Windy"
	windy_args[mode]="$WINDY_MODE"
	windy_args[pkg_name]="co.windyapp.android"
	windy_args[apkmirror_dlurl]="windy-weather-world-inc/windy-wind-weather-forecast"
	windy_args[regexp]='APK</span>[^@]*@\([^#]*\)'

	build_rv windy_args
}

build_tasker() {
	declare -A tasker_args
	tasker_args[app_name]="Tasker"
	tasker_args[mode]="$TASKER_MODE"
	tasker_args[pkg_name]="net.dinglisch.android.taskerm"
	tasker_args[apkmirror_dlurl]="joaomgcd/tasker"
	tasker_args[regexp]='APK</span>[^@]*@\([^#]*\)'
	
	build_rv tasker_args
}

build_citra() {
	declare -A citra_args
	citra_args[app_name]="Citra"
	citra_args[mode]="$CITRA_MODE"
	citra_args[pkg_name]="org.citra.citra_emu"
	citra_args[apkmirror_dlurl]="citra-emulator/citra-emulator"
	citra_args[regexp]='APK</span>[^@]*@\([^#]*\)'
	
	build_rv citra_args
}

build_instagram() {
	declare -A instagram_args
	instagram_args[app_name]="Instagram"
	instagram_args[mode]="$INSTAGRAM_MODE"
	instagram_args[pkg_name]="com.instagram.android"
	instagram_args[apkmirror_dlurl]="instagram/instagram-instagram"
	instagram_args[regexp]='APK</span>[^@]*@\([^#]*\)'
	
	build_rv instagram_args
}

build_nova() {
	declare -A nova_args
	nova_args[app_name]="Nova-Launcher"
	nova_args[mode]="$NOVA_MODE"
	nova_args[pkg_name]="com.teslacoilsw.launcher"
	nova_args[apkmirror_dlurl]="teslacoil-software/nova-launcher"
	nova_args[regexp]='APK</span>[^@]*@\([^#]*\)'
	
	build_rv nova_args
}

build_messenger() {
	declare -A messenger_args
	messenger_args[app_name]="Messenger"
	messenger_args[mode]="$MESSENGER_MODE"
	messenger_args[pkg_name]="com.facebook.orca"
	messenger_args[apkmirror_dlurl]="facebook-2/messenger"
	messenger_args[regexp]='APK</span>[^@]*@\([^#]*\)'
	
	build_rv messenger_args
}

hash_gen() {
	log "\n**App Hashes:**"
	log "\`\`\`"
	for FILE in build/*.apk; do
		log "$(echo $FILE | cut -d / -f 2): $(sha256sum $FILE | cut -d ' ' -f 1)"
	done
	log "\`\`\`"
}
