#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=v2dat
PKG_SOURCE_DATE:=2026-03-13
PKG_SOURCE_VERSION:=1862a66a5da8278ddc9206be69fd987538d1f3ff
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/kenzok8/v2dat/tar.gz/$(PKG_SOURCE_VERSION)?
PKG_HASH:=e2979c879a5692fbfed51b2ec019223a9da79ce8bce0cd0f9091fe20fc31c943
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILE:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/kenzok8/v2dat

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/v2dat
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=V2ray geo/ip data unpack tools
  URL:=https://github.com/kenzok8/v2dat
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/v2dat/install
	$(call GoPackage/Package/Install/Bin,$(1))
endef

$(eval $(call GoBinPackage,v2dat))
$(eval $(call BuildPackage,v2dat))
