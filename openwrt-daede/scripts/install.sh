#!/bin/sh

set -eu

B2_FEED_BASE_URL="https://kenzo111.s3.us-west-004.backblazeb2.com/openwrt-feed/daed"
GITHUB_API_URL="https://api.github.com/repos/kenzok8/luci-app-daed/releases/latest"
GITHUB_PROXY_PREFIX="${GITHUB_PROXY_PREFIX:-https://ghfast.top/}"
TMP_DIR="/tmp/daede-install"

fetch_text() {
  url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" 2>/dev/null
    return $?
  fi
  wget -qO- "$url" 2>/dev/null
}

download_file() {
  url="$1"
  out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$out"
    return $?
  fi
  wget -qO "$out" "$url"
}

download_url() {
  url="$1"
  case "$url" in
    https://github.com/*)
      printf '%s%s\n' "$GITHUB_PROXY_PREFIX" "$url"
      ;;
    *)
      printf '%s\n' "$url"
      ;;
  esac
}

detect_manager() {
  if command -v opkg >/dev/null 2>&1; then echo opkg; return; fi
  if command -v apk >/dev/null 2>&1; then echo apk; return; fi
  echo "unsupported"
}

detect_arch() {
  pm="$1"
  if [ "$pm" = "opkg" ]; then
    opkg print-architecture | awk '/^arch / {print $2}' | tail -n 1
    return
  fi
  apk --print-arch
}

detect_sdk() {
  if [ ! -r /etc/openwrt_release ]; then return 1; fi
  release="$(sed -n "s/^DISTRIB_RELEASE=['\"]\\([^'\"]*\\)['\"]$/\\1/p" /etc/openwrt_release | head -n 1)"
  [ -n "$release" ] || return 1
  sdk="$(printf '%s\n' "$release" | grep -Eo '[0-9]+\.[0-9]+' | head -n 1)"
  [ -n "$sdk" ] || return 1
  printf '%s\n' "$sdk"
}

feed_base_for() {
  printf '%s/%s/%s' "$B2_FEED_BASE_URL" "$1" "$2"
}

# 从 B2 manifest 获取包名
load_manifest_url() {
  sdk="$1"
  arch="$2"
  base="$(feed_base_for "$sdk" "$arch")"
  manifest_text="$(fetch_text "${base}/manifest-daede.txt" || true)"
  [ -n "$manifest_text" ] || return 1
  luci_file="$(printf '%s\n' "$manifest_text" | sed -n 's/^luci=//p' | head -n 1)"
  [ -n "$luci_file" ] || return 1
  LUCI_URL="${base}/${luci_file}"
  return 0
}

# 从 GitHub release 获取
load_github_url() {
  arch="$1"
  ext="$2"
  payload="$(fetch_text "$GITHUB_API_URL" || true)"
  [ -n "$payload" ] || return 1
  urls="$(printf '%s\n' "$payload" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p')"
  [ -n "$urls" ] || return 1

  if [ "$ext" = "apk" ]; then
    LUCI_URL="$(printf '%s\n' "$urls" | grep -E "/luci-app-daede-[^-]+.*-r[0-9]+-${arch}\.apk$" | head -n 1)"
  else
    LUCI_URL="$(printf '%s\n' "$urls" | grep -E '/luci-app-daede_.*_all\.ipk$' | head -n 1)"
  fi
  [ -n "$LUCI_URL" ]
}

PM="$(detect_manager)"
if [ "$PM" = "unsupported" ]; then
  echo "No supported package manager (opkg/apk)."
  exit 1
fi

ARCH="$(detect_arch "$PM")"
[ -n "$ARCH" ] || { echo "Cannot detect architecture"; exit 1; }

EXT="ipk"
[ "$PM" = "apk" ] && EXT="apk"

SDK="$(detect_sdk || true)"
LUCI_URL=""

if [ -n "$SDK" ]; then
  if load_manifest_url "$SDK" "$ARCH"; then
    echo "Using B2 manifest: ${SDK}/${ARCH}"
  fi
fi

if [ -z "$LUCI_URL" ]; then
  if load_github_url "$ARCH" "$EXT"; then
    echo "Using GitHub latest release"
  else
    echo "Cannot find luci-app-daede for arch: $ARCH"
    exit 1
  fi
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "Downloading luci-app-daede..."
download_file "$(download_url "$LUCI_URL")" "$TMP_DIR/luci.${EXT}"

echo "Installing..."
if [ "$PM" = "opkg" ]; then
  opkg install "$TMP_DIR/luci.${EXT}"
else
  echo "[WARN] 签名校验失败，临时使用 --allow-untrusted；构建完成稳定 key 上线后再跑一次本脚本即可。"
  apk add --allow-untrusted "$TMP_DIR/luci.${EXT}"
fi

echo "Install complete."
