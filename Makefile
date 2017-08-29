#
# Copyright (C) 2014-2017 Jian Chang <aa65535@live.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-libev
PKG_VERSION:=3.0.8
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-libev.git
PKG_SOURCE_VERSION:=f1dd1354a9e0bf4a364773be3385e12de571d008
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.xz

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Jian Chang <aa65535@live.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocks-libev/Default
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lightweight Secured Socks5 Proxy
	URL:=https://github.com/shadowsocks/shadowsocks-libev
	DEPENDS:=+zlib +libev +libudns +libpcre +libpthread +libsodium +libmbedtls
endef

Package/shadowsocks-libev = $(Package/shadowsocks-libev/Default)
Package/shadowsocks-libev-server = $(Package/shadowsocks-libev/Default)

# gfwlist packages
define Package/shadowsocks-libev-gfwlist
  $(call Package/shadowsocks-libev/Default)
  DEPENDS:=+zlib +libev +libudns +libpcre +libpthread +libsodium +libmbedtls +dnsmasq-full +ipset +dns-forwarder
endef

define Package/shadowsocks-libev/description
Shadowsocks-libev is a lightweight secured socks5 proxy for embedded devices and low end boxes.
endef

Package/shadowsocks-libev-server/description = $(Package/shadowsocks-libev/description)

# gfwlist packages
Package/shadowsocks-libev-gfwlist/description = $(Package/shadowsocks-libev/description)

define Package/shadowsocks-libev-gfwlist/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/firewall restart
	/etc/init.d/shadowsocks restart
	/etc/init.d/dns-forwarder restart
	/etc/init.d/dnsmasq restart
fi
exit 0
endef

CONFIGURE_ARGS += --disable-ssp --disable-documentation --disable-assert

define Package/shadowsocks-libev/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-{local,redir,tunnel} $(1)/usr/bin
endef

define Package/shadowsocks-libev-server/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-server $(1)/usr/bin
endef

# gfwlist packages
define Package/shadowsocks-libev-gfwlist/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-{local,redir} $(1)/usr/bin
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks-gfwlist $(1)/etc/init.d/shadowsocks
	$(INSTALL_CONF) ./files/shadowsocks-gfwlist.json $(1)/etc/shadowsocks.json
	$(INSTALL_BIN) ./files/ss-watchdog $(1)/usr/bin/ss-watchdog
	
	#patch dnsmasq, add ipset gfwlist 
	$(INSTALL_CONF) ./files/dnsmasq.conf $(1)/etc/dnsmasq.conf
	$(INSTALL_DIR) $(1)/etc/dnsmasq.d
	$(INSTALL_CONF) ./files/gfw_list.conf $(1)/etc/dnsmasq.d/gfw_list.conf
	$(INSTALL_CONF) ./files/custom_list.conf $(1)/etc/dnsmasq.d/custom_list.conf
	
	#patch firewall rule, create ipset gfwlist & redirect traffic
	$(INSTALL_CONF) ./files/firewall.user $(1)/etc/firewall.user
	
	#patch dns-forwarder
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/dns-forwarder.config $(1)/etc/config/dns-forwarder
	
	#install luci for ssr
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_CONF) ./files/shadowsocks-libev.lua $(1)/usr/lib/lua/luci/controller/shadowsocks-libev.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/shadowsocks-libev
	$(INSTALL_CONF) ./files/shadowsocks-libev-general.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks-libev/shadowsocks-libev-general.lua
	$(INSTALL_CONF) ./files/shadowsocks-libev-custom.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks-libev/shadowsocks-libev-custom.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/shadowsocks-libev
	$(INSTALL_CONF) ./files/gfwlist.htm $(1)/usr/lib/lua/luci/view/shadowsocks-libev/gfwlist.htm
	$(INSTALL_CONF) ./files/watchdog.htm $(1)/usr/lib/lua/luci/view/shadowsocks-libev/watchdog.htm
endef

$(eval $(call BuildPackage,shadowsocks-libev))
$(eval $(call BuildPackage,shadowsocks-libev-server))

# gfwlist packages
$(eval $(call BuildPackage,shadowsocks-libev-gfwlist))
