#!/bin/sh
# Publish converter snapshots without exposing a partially written final file.

set -eu

DIR=/etc/daed
PREFIX=daede-sub
STAGE_PREFIX=.daede-sub-stage

fail() {
	echo "$*" >&2
	exit 1
}

valid_token() {
	[ "$#" -eq 1 ] || return 1
	case "$1" in
		''|*[!A-Za-z0-9]*) return 1 ;;
	esac
	[ "${#1}" -le 64 ]
}

stage_path() { printf '%s/%s-%s\n' "$DIR" "$STAGE_PREFIX" "$1"; }
final_path() { printf '%s/%s-%s\n' "$DIR" "$PREFIX" "$1"; }

regular_file() {
	[ -f "$1" ] && [ ! -L "$1" ]
}

safe_dir() {
	[ -d "$DIR" ] && [ ! -L "$DIR" ] || fail "invalid snapshot directory"
}

publish() {
	[ "$#" -eq 1 ] || fail 'publish expects one token'
	valid_token "$1" || fail 'invalid snapshot token'
	safe_dir
	stage=$(stage_path "$1")
	final=$(final_path "$1")
	regular_file "$stage" || fail 'snapshot stage is not a regular file'
	[ ! -e "$final" ] && [ ! -L "$final" ] || fail 'snapshot already exists'
	chmod 600 "$stage" || fail 'cannot secure snapshot stage'
	mv -f "$stage" "$final" || fail 'cannot publish snapshot'
}

replace() {
	[ "$#" -eq 2 ] || fail 'replace expects existing and stage tokens'
	valid_token "$1" || fail 'invalid existing snapshot token'
	valid_token "$2" || fail 'invalid stage snapshot token'
	safe_dir
	[ "$1" != "$2" ] || fail 'existing and stage tokens must differ'
	stage=$(stage_path "$2")
	final=$(final_path "$1")
	regular_file "$stage" || fail 'snapshot stage is not a regular file'
	if [ -e "$final" ] || [ -L "$final" ]; then
		regular_file "$final" || fail 'existing snapshot is not a regular file'
	fi
	chmod 600 "$stage" || fail 'cannot secure snapshot stage'
	mv -f "$stage" "$final" || fail 'cannot replace snapshot'
}

discard() {
	[ "$#" -eq 1 ] || fail 'discard expects one token'
	valid_token "$1" || fail 'invalid snapshot token'
	safe_dir
	stage=$(stage_path "$1")
	if [ -L "$stage" ]; then
		fail 'refusing symlink snapshot stage'
	fi
	if [ -e "$stage" ]; then
		[ -f "$stage" ] || fail 'snapshot stage is not a regular file'
		rm -f "$stage" || fail 'cannot discard snapshot stage'
	fi
}

case "${1:-}" in
	publish) shift; publish "$@" ;;
	replace) shift; replace "$@" ;;
	discard) shift; discard "$@" ;;
	*) fail 'unknown snapshot action' ;;
esac
