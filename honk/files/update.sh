#!/bin/sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
umask 077
. /usr/share/libubox/jshn.sh

UPDATE_ROOT=/tmp/honk-update
TRUST_ROOT=/etc/honk/update-trust
FEED_FILE=$TRUST_ROOT/feed.url
MANIFEST_KEY=$TRUST_ROOT/manifest.pub
MANIFEST=$UPDATE_ROOT/manifest.json
SIGNATURE=$UPDATE_ROOT/manifest.json.sig
RECORDS=$UPDATE_ROOT/packages.tsv
UPDATE_LOCK_OWNED=0
CHECK_DIR=

update_lock_acquire() {
	. /usr/share/honk/lock.sh || return 1
	honk_lock_acquire || return 1
	UPDATE_LOCK_OWNED=1
}

update_lock_release() {
	[ "$UPDATE_LOCK_OWNED" = 1 ] || return 0
	honk_lock_release >/dev/null 2>&1 || return 1
	UPDATE_LOCK_OWNED=0
}

discard_check_dir() {
	case "$CHECK_DIR" in
		"$UPDATE_ROOT"/.check.*)
			[ -d "$CHECK_DIR" ] && [ ! -L "$CHECK_DIR" ] && rm -rf "$CHECK_DIR"
			;;
	esac
	CHECK_DIR=
}

cleanup_update() {
	discard_check_dir
	update_lock_release || :
}

emit_update() {
	json_init
	json_add_boolean ok "$1"
	json_add_boolean available "$2"
	json_add_boolean apply_enabled "$3"
	json_add_string message "$4"
	json_add_string reason "$5"
	[ -z "$6" ] || json_add_string version "$6"
	json_dump
}

safe_file() {
	[ -f "$1" ] && [ ! -L "$1" ] && [ "$(stat -c '%u:%a' "$1" 2>/dev/null)" = "0:$2" ]
}

prepare_update_root() {
	if [ -e "$UPDATE_ROOT" ] || [ -L "$UPDATE_ROOT" ]; then
		[ -d "$UPDATE_ROOT" ] && [ ! -L "$UPDATE_ROOT" ] && [ "$(stat -c '%u:%a' "$UPDATE_ROOT" 2>/dev/null)" = 0:700 ] || return 1
	else
		mkdir "$UPDATE_ROOT" && chmod 0700 "$UPDATE_ROOT" || return 1
	fi
}

read_trust() {
	[ -d "$TRUST_ROOT" ] && [ ! -L "$TRUST_ROOT" ] && [ "$(stat -c '%u:%a' "$TRUST_ROOT" 2>/dev/null)" = 0:700 ] || return 1
	safe_file "$FEED_FILE" 600 && safe_file "$MANIFEST_KEY" 600 || return 1
	[ "$(wc -c < "$FEED_FILE" | tr -d ' ')" -le 512 ] || return 1
	feed_url=$(cat "$FEED_FILE") || return 1
	[ -n "$feed_url" ] || return 1
	case "$feed_url" in *'?'*|*'#'*|*'@'*|*' '*|*'\'*|*'"'*|*"'"*) return 1 ;; esac
	echo "$feed_url" | grep -Eq '^https://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._~/%+-]*)?$' || return 1
	return 0
}

manifest_field() {
	jsonfilter -i "$MANIFEST" -e "$1" 2>/dev/null
}

installed_version() {
	awk -v wanted="$1" '
		$0 == "P:" wanted { found=1; next }
		found && /^V:/ { print substr($0, 3); exit }
		found && /^P:/ { exit }
	' /lib/apk/db/installed 2>/dev/null
}

validate_manifest() {
	validate_url=$1
	validate_json=$(cat "$MANIFEST") || return 1
	json_load "$validate_json" 2>/dev/null || return 1
	json_get_type validate_packages_type packages
	[ "$validate_packages_type" = array ] || return 1
	json_select packages || return 1
	json_get_keys validate_package_keys
	[ "$(printf '%s\n' "$validate_package_keys" | wc -w | tr -d ' ')" = 2 ] || return 1
	json_select .. || return 1
	[ "$(manifest_field '@.schema')" = 1 ] || return 1
	[ "$(manifest_field '@.product')" = openwrt-honk ] || return 1
	# Target must match this device: map uname -m to manifest arch names.
	case "$(uname -m)" in
		x86_64) _local_arch=x86_64 ;;
		aarch64) _local_arch=aarch64 ;;
		armv7l) _local_arch=armv7 ;;
		*) return 1 ;;
	esac
	[ "$(manifest_field '@.target.architecture')" = "$_local_arch" ] || return 1
	# OpenWrt version must match: 24.10 (opkg/ipk) or 25.12 (apk).
	_local_owrt=$(sed -n 's/^DISTRIB_RELEASE="\([0-9]*\.[0-9]*\).*/\1/p' /etc/openwrt_release 2>/dev/null | head -n 1)
	case "$_local_owrt" in 24.10|25.12) ;; *) return 1 ;; esac
	[ "$(manifest_field '@.target.openwrt')" = "$_local_owrt" ] || return 1
	case "$_local_owrt" in
		24.10) [ "$(manifest_field '@.target.package_format')" = ipk ] || return 1 ;;
		25.12) [ "$(manifest_field '@.target.package_format')" = apk ] || return 1 ;;
	esac
	[ "$(manifest_field '@.target.kernel_min')" = 6.12 ] || return 1
	[ "$(manifest_field '@.target.requires_btf')" = true ] || return 1
	[ "$(manifest_field '@.min_updater_api')" = 1 ] || return 1
	[ "$(manifest_field '@.state_schema')" = 2 ] || return 1
	# (arch and OpenWrt version already validated against local system above)
	[ -r /sys/kernel/btf/vmlinux ] || return 1
	kernel_version=$(uname -r | sed 's/-.*//')
	kernel_major=${kernel_version%%.*}
	kernel_minor=${kernel_version#*.}
	kernel_minor=${kernel_minor%%.*}
	case "$kernel_major:$kernel_minor" in *[!0-9:]*|:*) return 1 ;; esac
	[ "$kernel_major" -gt 6 ] || { [ "$kernel_major" = 6 ] && [ "$kernel_minor" -ge 12 ]; } || return 1
	validate_commit=$(manifest_field '@.core.commit')
	case "$validate_commit" in *[!0-9a-f]*|'') return 1 ;; esac
	[ "${#validate_commit}" -eq 40 ] || return 1
	validate_commit=$(manifest_field '@.doona.commit')
	case "$validate_commit" in *[!0-9a-f]*|'') return 1 ;; esac
	[ "${#validate_commit}" -eq 40 ] || return 1
	for validate_sha in \
		"$(manifest_field '@.core.artifact_sha256')" \
		"$(manifest_field '@.doona.patch_sha256')" \
		"$(manifest_field '@.doona.artifact_sha256')" \
		"$(manifest_field '@.sdk_sha256')"; do
		case "$validate_sha" in *[!0-9a-f]*|'') return 1 ;; esac
		[ "${#validate_sha}" -eq 64 ] || return 1
	done
	validate_version=$(manifest_field '@.packages[0].version')
	case "$validate_version" in ''|*[!A-Za-z0-9.+~-]*) return 1 ;; esac
	: > "$RECORDS" || return 1
	validate_seen=' '
	validate_available=0
	for validate_index in 0 1; do
		validate_name=$(manifest_field "@.packages[$validate_index].name")
		validate_version=$(manifest_field "@.packages[$validate_index].version")
		validate_arch=$(manifest_field "@.packages[$validate_index].arch")
		validate_filename=$(manifest_field "@.packages[$validate_index].filename")
		validate_size=$(manifest_field "@.packages[$validate_index].size")
		validate_sha=$(manifest_field "@.packages[$validate_index].sha256")
		validate_package_url=$(manifest_field "@.packages[$validate_index].url")
		case "$validate_name" in honk|luci-app-honk) ;; *) return 1 ;; esac
		case "$validate_seen" in *" $validate_name "*) return 1 ;; esac
		validate_seen="$validate_seen$validate_name "
		case "$validate_version" in ''|*[!A-Za-z0-9.+~-]*) return 1 ;; esac
		case "$validate_arch" in x86_64|aarch64|armv7|noarch) ;; *) return 1 ;; esac
		case "$validate_name:$validate_arch" in honk:x86_64|honk:aarch64|honk:armv7|luci-app-honk:x86_64|luci-app-honk:aarch64|luci-app-honk:armv7|luci-app-honk:noarch) ;; *) return 1 ;; esac
		[ "$validate_filename" = "$validate_name-$validate_version.apk" ] || [ "$validate_filename" = "${validate_name}_${validate_version}_${validate_arch}.ipk" ] || return 1
		case "$validate_filename" in *'/'*|*'..'*|*[!A-Za-z0-9.+_-]*) return 1 ;; esac
		case "$validate_size" in ''|*[!0-9]*) return 1 ;; esac
		[ "$validate_size" -gt 0 ] && [ "$validate_size" -le 134217728 ] || return 1
		case "$validate_sha" in *[!0-9a-f]*|'') return 1 ;; esac
		[ "${#validate_sha}" -eq 64 ] || return 1
		[ "$validate_package_url" = "${validate_url%/}/packages/$validate_filename" ] || return 1
		printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$validate_name" "$validate_version" "$validate_arch" "$validate_filename" "$validate_size" "$validate_sha" "$validate_package_url" >> "$RECORDS" || return 1
		[ "$(installed_version "$validate_name")" = "$validate_version" ] || validate_available=1
	done
	[ "$(wc -l < "$RECORDS" | tr -d ' ')" = 2 ] || return 1
	for validate_required in honk luci-app-honk; do
		case "$validate_seen" in *" $validate_required "*) ;; *) return 1 ;; esac
	done
	update_version=$(awk -F '\t' '$1 == "honk" { print $2; exit }' "$RECORDS")
	return 0
}

verify_signed_manifest() {
	read_trust || return 2
	prepare_update_root || return 3
	CHECK_DIR=$(mktemp -d "$UPDATE_ROOT/.check.XXXXXX") || return 3
	check_dir=$CHECK_DIR
	chmod 0700 "$check_dir" || { discard_check_dir; return 3; }
	check_manifest=$check_dir/manifest.json
	check_signature=$check_dir/manifest.json.sig
	if ! curl -fLsS --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 4 --max-time 12 --max-filesize 65536 \
		"${feed_url%/}/manifest.json" -o "$check_manifest" 2>/dev/null ||
		! curl -fLsS --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 4 --max-time 8 --max-filesize 4096 \
		"${feed_url%/}/manifest.json.sig" -o "$check_signature" 2>/dev/null ||
		! usign -V -m "$check_manifest" -p "$MANIFEST_KEY" -x "$check_signature" >/dev/null 2>&1; then
		discard_check_dir
		return 4
	fi
	MANIFEST=$check_manifest
	RECORDS=$check_dir/packages.tsv
	if ! validate_manifest "$feed_url"; then
		discard_check_dir
		return 5
	fi
	cp "$check_manifest" "$UPDATE_ROOT/manifest.json.new" && cp "$check_signature" "$UPDATE_ROOT/manifest.json.sig.new" || { discard_check_dir; return 3; }
	cp "$RECORDS" "$UPDATE_ROOT/packages.tsv.new" || { discard_check_dir; return 3; }
	printf '%s\n' "$(date +%s)" > "$UPDATE_ROOT/checked-at.new" || { discard_check_dir; return 3; }
	chmod 0600 "$UPDATE_ROOT/manifest.json.new" "$UPDATE_ROOT/manifest.json.sig.new" "$UPDATE_ROOT/packages.tsv.new" "$UPDATE_ROOT/checked-at.new" || { discard_check_dir; return 3; }
	mv -f "$UPDATE_ROOT/manifest.json.new" "$UPDATE_ROOT/manifest.json" &&
	mv -f "$UPDATE_ROOT/manifest.json.sig.new" "$UPDATE_ROOT/manifest.json.sig" &&
	mv -f "$UPDATE_ROOT/packages.tsv.new" "$UPDATE_ROOT/packages.tsv" &&
	mv -f "$UPDATE_ROOT/checked-at.new" "$UPDATE_ROOT/checked-at" || { discard_check_dir; return 3; }
	discard_check_dir
	return 0
}

update_check() {
	read_trust || { emit_update true false false no_release trusted_feed_unavailable; return 0; }
	update_lock_acquire || { emit_update false false false update_check_failed operation_in_progress; return 1; }
	verify_signed_manifest
	check_rc=$?
	update_lock_release
	case "$check_rc" in
		2) emit_update true false false no_release trusted_feed_unavailable; return 0 ;;
		4) emit_update false false false update_check_failed signed_manifest_unavailable; return 1 ;;
		3) emit_update false false false update_check_failed update_storage_unavailable; return 1 ;;
		5) emit_update false false false update_check_failed manifest_incompatible; return 1 ;;
		0) ;;
		*) emit_update false false false update_check_failed manifest_invalid; return 1 ;;
	esac
	if [ "$validate_available" = 1 ]; then
		emit_update true true false update_available rollback_tuple_unavailable "$update_version"
	else
		emit_update true false false no_update already_current "$update_version"
	fi
}

update_gate() {
	read_trust || { emit_update true false false no_release trusted_feed_unavailable; return 0; }
	update_lock_acquire || { emit_update false false false update_check_failed operation_in_progress; return 1; }
	gate_ok=1
	gate_available=0
	gate_reason=
	prepare_update_root || { gate_ok=0; gate_reason=update_storage_unavailable; }
	if [ "$gate_ok" = 1 ]; then
		for gate_file in "$UPDATE_ROOT/manifest.json" "$UPDATE_ROOT/manifest.json.sig" "$UPDATE_ROOT/packages.tsv" "$UPDATE_ROOT/checked-at"; do
			safe_file "$gate_file" 600 || { gate_reason=signed_manifest_missing; break; }
		done
	fi
	if [ "$gate_ok" = 1 ] && [ -z "$gate_reason" ]; then
		checked_at=$(cat "$UPDATE_ROOT/checked-at")
		case "$checked_at" in ''|*[!0-9]*) gate_reason=signed_manifest_expired ;; esac
		if [ -z "$gate_reason" ] && [ $(( $(date +%s) - checked_at )) -gt 600 ]; then gate_reason=signed_manifest_expired; fi
	fi
	if [ "$gate_ok" = 1 ] && [ -z "$gate_reason" ]; then
		usign -V -m "$UPDATE_ROOT/manifest.json" -p "$MANIFEST_KEY" -x "$UPDATE_ROOT/manifest.json.sig" >/dev/null 2>&1 || { gate_ok=0; gate_reason=manifest_signature_invalid; }
	fi
	if [ "$gate_ok" = 1 ] && [ -z "$gate_reason" ]; then
		MANIFEST=$UPDATE_ROOT/manifest.json
		RECORDS=$UPDATE_ROOT/packages.tsv
		validate_manifest "$feed_url" || { gate_ok=0; gate_reason=manifest_incompatible; }
	fi
	gate_available=${validate_available:-0}
	gate_version=${update_version:-}
	update_lock_release
	if [ "$gate_ok" != 1 ]; then emit_update false false false update_check_failed "$gate_reason"; return 1; fi
	if [ -n "$gate_reason" ]; then emit_update true false false no_release "$gate_reason"; return 0; fi
	if [ "$gate_available" = 1 ]; then
		emit_update true true false update_available rollback_tuple_unavailable "$gate_version"
	else
		emit_update true false false no_update already_current "$gate_version"
	fi
}

update_apply() {
	update_gate >/dev/null || { emit_update false false false update_apply_failed trusted_manifest_invalid; return 1; }
	[ "$validate_available" = 1 ] || { emit_update false false false update_apply_failed no_update; return 1; }
	# No previous signed package tuple or exercised downgrade path is available yet.
	# Keep the backend gate closed even when the update manifest itself is compatible.
	emit_update false false false update_apply_failed rollback_tuple_unavailable
	return 1
}

trap cleanup_update EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

case "$1" in
	check) update_check ;;
	gate) update_gate ;;
	apply) update_apply ;;
	*) emit_update false false false update_check_failed invalid_action; exit 2 ;;
esac
