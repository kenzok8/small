#!/bin/sh

set -eu

detect_manager() {
  if command -v opkg >/dev/null 2>&1; then echo opkg; return; fi
  if command -v apk >/dev/null 2>&1; then echo apk; return; fi
  echo "unsupported"
}

PM="$(detect_manager)"

case "$PM" in
  opkg)
    opkg remove luci-app-daede --autoremove
    ;;
  apk)
    apk del luci-app-daede
    ;;
  *)
    echo "No supported package manager (opkg/apk)."
    exit 1
    ;;
esac

echo "Uninstall complete."
