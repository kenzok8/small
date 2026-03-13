# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tcping
PKG_VERSION:=0.4
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/kenzok8/tcping/tar.gz/$(PKG_VERSION)?
PKG_HASH:=6512779e5a6b466e2be7c4daf02b5aad89aaeed7898314a6614d46f804bc1b54

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILE:=license.txt

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/tcping
  SECTION:=net
  CATEGORY:=Network
  TITLE:=tcping measures the latency of a tcp-connection (IPv4/IPv6 support)
  URL:=https://github.com/kenzok8/tcping
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS) -Wall" LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/tcping/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tcping $(1)/usr/sbin
endef

$(eval $(call BuildPackage,tcping))
