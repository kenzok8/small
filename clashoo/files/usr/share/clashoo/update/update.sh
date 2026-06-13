#!/bin/sh

config_name="${1:-$(uci -q get clashoo.config.config_update_name 2>/dev/null)}"
[ -n "$config_name" ] || exit 1
exec sh /usr/share/clashoo/update/subscription_update.sh --mihomo "$config_name"
