#!/bin/bash
#
# Thanks for https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

function config_del(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"

    sed -i "/$yes/d" .config
    if ! grep -q "$no" .config; then
        echo "$no" >> .config
    fi
}

function config_add(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"

    sed -i "/$no/d" .config
    if ! grep -q "$yes" .config; then
        echo "$yes" >> .config
    fi
}

function config_package_del(){
    package="PACKAGE_$1"
    config_del $package
}

function config_package_add(){
    package="PACKAGE_$1"
    config_add $package
}

function drop_package(){
    if [ "$1" != "golang" ];then
        # feeds/base -> package
        find package/ -follow -name $1 -not -path "package/custom/*" | xargs -rt rm -rf
        find feeds/ -follow -name $1 -not -path "feeds/base/custom/*" | xargs -rt rm -rf
    fi
}

function clean_packages(){
    path=$1
    dir=$(ls -l ${path} | awk '/^d/ {print $NF}')
    for item in ${dir}
        do
            drop_package ${item}
        done
}

function config_device_del(){
    device="TARGET_DEVICE_$1"
    packages="TARGET_DEVICE_PACKAGES_$1"

    packages_list="CONFIG_TARGET_DEVICE_PACKAGES_$1="""    
    deleted_packages_list="# CONFIG_TARGET_DEVICE_PACKAGES_$1 is not set"

    config_del $device
    sed -i "s/$packages_list/$deleted_packages_list/" .config
}

function config_device_list(){
    grep -E 'CONFIG_TARGET_DEVICE_|CONFIG_TARGET_DEVICE_PACKAGES_' .config | while read -r line; do
        if [[ $line =~ CONFIG_TARGET_DEVICE_([^=]+)=y ]]; then
            chipset_device=${BASH_REMATCH[1]}
            chipset=${chipset_device%_DEVICE_*}
            device=${chipset_device#*_DEVICE_}
            echo "Chipset: $chipset, Model: $device"
        fi
    done | sort -u
}

function config_device_keep_only(){
    local keep_devices=("$@")
    grep -E 'CONFIG_TARGET_DEVICE_|CONFIG_TARGET_DEVICE_PACKAGES_' .config | while read -r line; do
        if [[ $line =~ CONFIG_TARGET_DEVICE_([^=]+)=y ]]; then
            chipset_device=${BASH_REMATCH[1]}
            device=${chipset_device#*_DEVICE_}
            if [[ ! " ${keep_devices[@]} " =~ " ${device} " ]]; then
                config_device_del $chipset_device
            fi
        fi
    done
}

config_device_list

config_device_keep_only "cmcc_xr30"

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Delete unwanted packages
config_package_del luci-app-ssr-plus_INCLUDE_NONE_V2RAY
config_package_del luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Client
config_package_del luci-app-ssr-plus_INCLUDE_ShadowsocksR_NONE_Server
config_package_del luci-theme-bootstrap-mod
config_package_del luci-app-ssr-plus_INCLUDE_ShadowsocksR_Rust_Client
config_package_del luci-app-ssr-plus_INCLUDE_ShadowsocksR_Rust_Server
# Add custom packages

## Web Terminal
config_package_add luci-app-ttyd
## IP-Mac Binding
config_package_add luci-app-arpbind
## Wake on Lan
config_package_add luci-app-wol
## QR Code Generator
config_package_add qrencode
## Fish
config_package_add fish
## Temporarily disable USB3.0
config_package_add luci-app-usb3disable
## USB
config_package_add kmod-usb-net-huawei-cdc-ncm
config_package_add kmod-usb-net-ipheth
config_package_add kmod-usb-net-aqc111
config_package_add kmod-usb-net-rtl8152-vendor
config_package_add kmod-usb-net-sierrawireless
config_package_add kmod-usb-storage
config_package_add kmod-usb-ohci
config_package_add kmod-usb-uhci
config_package_add usb-modeswitch
config_package_add sendat
## bbr
config_package_add kmod-tcp-bbr
## coremark cpu 跑分
config_package_add coremark
## autocore + lm-sensors-detect： cpu 频率、温度
config_package_add autocore
config_package_add lm-sensors-detect
## autoreboot
config_package_add luci-app-autoreboot
## 多拨
config_package_add kmod-macvlan
config_package_add mwan3
config_package_add luci-app-mwan3
# ## frpc
# config_package_add luci-app-frpc
## mosdns
# config_package_add luci-app-mosdns
## curl
config_package_add curl
## socat
config_package_add socat
## disk
config_package_add gdisk
config_package_add sgdisk
## Vim-Full
config_package_add vim-full
## iperf
config_package_add iperf

# MentoHust
git clone https://github.com/sbwml/luci-app-mentohust package/mentohust
config_package_add luci-app-mentohust

# Third-party packages
mkdir -p package/custom
git clone --depth 1  https://github.com/217heidai/OpenWrt-Packages.git package/custom
clean_packages package/custom

## golang
rm -rf feeds/packages/lang/golang
mv package/custom/golang feeds/packages/lang/

## Passwall
config_package_add luci-app-passwall2
config_package_add iptables-mod-socket
config_package_add luci-app-passwall2_Iptables_Transparent_Proxy
config_package_add luci-app-passwall2_INCLUDE_Hysteria
config_package_del luci-app-passwall2_Nftables_Transparent_Proxy
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Client
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Server
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Server
config_package_del luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Client
config_package_del luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Server
config_package_del luci-app-passwall2_INCLUDE_Trojan_Plus
config_package_del luci-app-passwall2_INCLUDE_Simple_Obfs
config_package_del luci-app-passwall2_INCLUDE_tuic_client
config_package_del shadowsocks-libev-config
config_package_del shadowsocks-libev-ss-local
config_package_del shadowsocks-libev-ss-redir
config_package_del shadowsocks-libev-ss-server
config_package_del shadowsocksr-libev-ssr-local
config_package_del shadowsocksr-libev-ssr-redir
config_package_del shadowsocks-libev-ssr-server
config_package_del shadowsocks-rust
config_package_del simple-obfs
rm -r package/custom/shadowsocks-rust
rm -r package/custom/simple-obfs

## 定时任务。重启、关机、重启网络、释放内存、系统清理、网络共享、关闭网络、自动检测断网重连、MWAN3负载均衡检测重连、自定义脚本等10多个功�
config_package_add luci-app-autotimeset
config_package_add luci-lib-ipkg

## byobu, tmux
config_package_add byobu
config_package_add tmux

## Try to enable ebpf

echo '

define KernelPackage/xdp-sockets-diag
  SUBMENU:=$(NETWORK_SUPPORT_MENU)
  TITLE:=PF_XDP sockets monitoring interface support for ss utility
  KCONFIG:= \
	CONFIG_XDP_SOCKETS=y \
	CONFIG_XDP_SOCKETS_DIAG
  FILES:=$(LINUX_DIR)/net/xdp/xsk_diag.ko
  AUTOLOAD:=$(call AutoLoad,31,xsk_diag)
endef

define KernelPackage/xdp-sockets-diag/description
 Support for PF_XDP sockets monitoring interface used by the ss tool
endef

$(eval $(call KernelPackage,xdp-sockets-diag))
' >> package/kernel/linux/modules/netsupport.mk

touch include/bpf.mk

echo '
BPF_DEPENDS := @HAS_BPF_TOOLCHAIN +@NEED_BPF_TOOLCHAIN
LLVM_VER:=

CLANG_MIN_VER:=12

ifneq ($(CONFIG_USE_LLVM_HOST),)
  BPF_TOOLCHAIN_HOST_PATH:=$(call qstrip,$(CONFIG_BPF_TOOLCHAIN_HOST_PATH))
  ifneq ($(BPF_TOOLCHAIN_HOST_PATH),)
    BPF_PATH:=$(BPF_TOOLCHAIN_HOST_PATH)/bin:$(PATH)
  else
    BPF_PATH:=$(PATH)
  endif
  CLANG:=$(firstword $(shell PATH='$(BPF_PATH)' command -v clang clang-13 clang-12 clang-11))
  LLVM_VER:=$(subst clang,,$(notdir $(CLANG)))
endif
ifneq ($(CONFIG_USE_LLVM_PREBUILT),)
  CLANG:=$(TOPDIR)/llvm-bpf/bin/clang
endif
ifneq ($(CONFIG_USE_LLVM_BUILD),)
  CLANG:=$(STAGING_DIR_HOST)/llvm-bpf/bin/clang
endif

LLVM_PATH:=$(dir $(CLANG))
LLVM_LLC:=$(LLVM_PATH)/llc$(LLVM_VER)
LLVM_DIS:=$(LLVM_PATH)/llvm-dis$(LLVM_VER)
LLVM_OPT:=$(LLVM_PATH)/opt$(LLVM_VER)
LLVM_STRIP:=$(LLVM_PATH)/llvm-strip$(LLVM_VER)

BPF_KARCH:=mips
BPF_ARCH:=mips$(if $(CONFIG_ARCH_64BIT),64)$(if $(CONFIG_BIG_ENDIAN),,el)
BPF_TARGET:=bpf$(if $(CONFIG_BIG_ENDIAN),eb,el)

BPF_HEADERS_DIR:=$(STAGING_DIR)/bpf-headers

BPF_KERNEL_INCLUDE := \
	-nostdinc -isystem $(TOOLCHAIN_ROOT_DIR)/lib/gcc/*/*/include \
	$(patsubst %,-isystem%,$(TOOLCHAIN_INC_DIRS)) \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/asm/mach-generic \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/generated \
	-I$(BPF_HEADERS_DIR)/include \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/uapi \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/generated/uapi \
	-I$(BPF_HEADERS_DIR)/include/uapi \
	-I$(BPF_HEADERS_DIR)/include/generated/uapi \
	-I$(BPF_HEADERS_DIR)/tools/lib \
	-I$(BPF_HEADERS_DIR)/tools/testing/selftests \
	-I$(BPF_HEADERS_DIR)/samples/bpf \
	-include linux/kconfig.h -include asm_goto_workaround.h

BPF_CFLAGS := \
	$(BPF_KERNEL_INCLUDE) -I$(PKG_BUILD_DIR) \
	-D__KERNEL__ -D__BPF_TRACING__ -DCONFIG_GENERIC_CSUM \
	-D__TARGET_ARCH_${BPF_KARCH} \
	-m$(if $(CONFIG_BIG_ENDIAN),big,little)-endian \
	-fno-stack-protector -Wall \
	-Wno-unused-value -Wno-pointer-sign \
	-Wno-compare-distinct-pointer-types \
	-Wno-gnu-variable-sized-type-not-at-end \
	-Wno-address-of-packed-member -Wno-tautological-compare \
	-Wno-unknown-warning-option \
	-fno-asynchronous-unwind-tables \
	-Wno-uninitialized -Wno-unused-variable \
	-Wno-unused-label \
	-O2 -emit-llvm -Xclang -disable-llvm-passes

ifneq ($(CONFIG_HAS_BPF_TOOLCHAIN),)
ifeq ($(DUMP)$(filter download refresh,$(MAKECMDGOALS)),)
  CLANG_VER:=$(shell $(CLANG) --target=$(BPF_TARGET) -dM -E - < /dev/null | grep __clang_major__ | cut -d' ' -f3)
  CLANG_VER_VALID:=$(shell [ "$(CLANG_VER)" -ge "$(CLANG_MIN_VER)" ] && echo 1 )
  ifeq ($(CLANG_VER_VALID),)
    $(error ERROR: LLVM/clang version too old. Minimum required: $(CLANG_MIN_VER), found: $(CLANG_VER))
  endif
endif
endif

define CompileBPF
	$(CLANG) -g -target $(BPF_ARCH)-linux-gnu $(BPF_CFLAGS) $(2) \
		-c $(1) -o $(patsubst %.c,%.bc,$(1))
	$(LLVM_OPT) -O2 -mtriple=$(BPF_TARGET) < $(patsubst %.c,%.bc,$(1)) > $(patsubst %.c,%.opt,$(1))
	$(LLVM_DIS) < $(patsubst %.c,%.opt,$(1)) > $(patsubst %.c,%.S,$(1))
	$(LLVM_LLC) -march=$(BPF_TARGET) -mcpu=v3 -filetype=obj -o $(patsubst %.c,%.o,$(1)) < $(patsubst %.c,%.S,$(1))
	$(CP) $(patsubst %.c,%.o,$(1)) $(patsubst %.c,%.debug.o,$(1))
	$(LLVM_STRIP) --strip-debug $(patsubst %.c,%.o,$(1))
endef
' >> include/bpf.mk

touch package/kernel/bpf-headers/Makefile
echo '
#
# Copyright (C) 2006-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

override QUILT:=
override HOST_QUILT:=

include $(INCLUDE_DIR)/kernel.mk


PKG_NAME:=linux
PKG_PATCHVER:=5.4
# Manually include kernel version and hash from kernel details file
include $(INCLUDE_DIR)/kernel-$(PKG_PATCHVER)

PKG_VERSION:=$(PKG_PATCHVER)$(strip $(LINUX_VERSION-$(PKG_PATCHVER)))
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=$(LINUX_SITE)
PKG_HASH:=$(LINUX_KERNEL_HASH-$(strip $(PKG_VERSION)))
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/bpf-headers/$(PKG_NAME)-$(PKG_VERSION)

GENERIC_PLATFORM_DIR := $(CURDIR)/../../../target/linux/generic
GENERIC_BACKPORT_DIR := $(GENERIC_PLATFORM_DIR)/backport$(if $(wildcard $(GENERIC_PLATFORM_DIR)/backport-$(PKG_PATCHVER)),-$(PKG_PATCHVER))
GENERIC_PATCH_DIR := $(GENERIC_PLATFORM_DIR)/pending$(if $(wildcard $(GENERIC_PLATFORM_DIR)/pending-$(PKG_PATCHVER)),-$(PKG_PATCHVER))
GENERIC_HACK_DIR := $(GENERIC_PLATFORM_DIR)/hack$(if $(wildcard $(GENERIC_PLATFORM_DIR)/hack-$(PKG_PATCHVER)),-$(PKG_PATCHVER))
GENERIC_FILES_DIR := $(foreach dir,$(wildcard $(GENERIC_PLATFORM_DIR)/files $(GENERIC_PLATFORM_DIR)/files-$(PKG_PATCHVER)),"$(dir)")
PATCH_DIR := $(CURDIR)/patches
FILES_DIR :=

REAL_LINUX_DIR := $(LINUX_DIR)
LINUX_DIR := $(PKG_BUILD_DIR)

include $(INCLUDE_DIR)/bpf.mk
include $(INCLUDE_DIR)/package.mk

define Package/bpf-headers
  SECTION:=kernel
  CATEGORY:=Kernel modules
  TITLE:=eBPF kernel headers
  BUILDONLY:=1
  HIDDEN:=1
endef

PKG_CONFIG_PATH:=

export HOST_EXTRACFLAGS=-I$(STAGING_DIR_HOST)/include

KERNEL_MAKE := \
	$(MAKE) -C $(PKG_BUILD_DIR) \
		ARCH=$(BPF_KARCH) \
		CROSS_COMPILE=$(BPF_ARCH)-linux- \
		LLVM=1 CC="$(CLANG)" LD="$(TARGET_CROSS)ld" \
		HOSTCC="$(HOSTCC)" \
		HOSTCXX="$(HOSTCXX)" \
		KBUILD_HOSTLDLIBS="-L$(STAGING_DIR_HOST)/lib" \
		CONFIG_SHELL="$(BASH)" \
		INSTALL_HDR_PATH="$(PKG_BUILD_DIR)/user_headers"

define Build/Patch
	$(Kernel/Patch/Default)
endef

BPF_DOC = $(PKG_BUILD_DIR)/scripts/bpf_doc.py

define Build/Configure/64
	echo 'CONFIG_CPU_MIPS64_R2=y' >> $(PKG_BUILD_DIR)/.config
	echo 'CONFIG_64BIT=y' >> $(PKG_BUILD_DIR)/.config
endef

define Build/Configure
	grep -vE 'CONFIG_(CPU_.*ENDIAN|HZ)' $(PKG_BUILD_DIR)/arch/mips/configs/generic_defconfig > $(PKG_BUILD_DIR)/.config
	echo 'CONFIG_CPU_$(if $(CONFIG_BIG_ENDIAN),BIG,LITTLE)_ENDIAN=y' >> $(PKG_BUILD_DIR)/.config
	$(if $(CONFIG_ARCH_64BIT),$(Build/Configure/64))
	grep CONFIG_HZ $(REAL_LINUX_DIR)/.config >> $(PKG_BUILD_DIR)/.config
	yes '' | $(KERNEL_MAKE) oldconfig
	grep 'CONFIG_HZ=' $(REAL_LINUX_DIR)/.config | \
		cut -d= -f2 | \
		bc -q $(LINUX_DIR)/kernel/time/timeconst.bc \
		> $(LINUX_DIR)/include/generated/timeconst.h
	$(BPF_DOC) --header \
		--file $(LINUX_DIR)/tools/include/uapi/linux/bpf.h \
		> $(PKG_BUILD_DIR)/tools/lib/bpf/bpf_helper_defs.h
endef

define Build/Compile
	$(KERNEL_MAKE) archprepare headers_install
endef

define Build/InstallDev
	mkdir -p $(1)/bpf-headers/arch $(1)/bpf-headers/tools
	$(CP) \
		$(PKG_BUILD_DIR)/arch/$(BPF_KARCH) \
		$(1)/bpf-headers/arch/
	$(CP) \
		$(PKG_BUILD_DIR)/tools/lib \
		$(PKG_BUILD_DIR)/tools/testing \
		$(1)/bpf-headers/tools/
	$(CP) \
		$(PKG_BUILD_DIR)/include \
		$(PKG_BUILD_DIR)/samples \
		$(PKG_BUILD_DIR)/scripts \
		$(PKG_BUILD_DIR)/user_headers \
		$(1)/bpf-headers
	$(CP) \
		$(CURDIR)/files/stdarg.h \
		$(1)/bpf-headers/include
endef

$(eval $(call BuildPackage,bpf-headers))
' >> package/kernel/bpf-headers/Makefile

touch package/kernel/bpf-headers/files/stdarg.h
echo '
#ifndef _STDARG_H
#define _STDARG_H

#ifdef __cplusplus
extern "C" {
#endif

typedef __builtin_va_list va_list;

#define va_start(v,l)   __builtin_va_start(v,l)
#define va_end(v)       __builtin_va_end(v)
#define va_arg(v,l)     __builtin_va_arg(v,l)
#define va_copy(d,s)    __builtin_va_copy(d,s)

#ifdef __cplusplus
}
#endif

#endif
' >> package/kernel/bpf-headers/files/stdarg.h

touch package/kernel/bpf-headers/patches/100-support_hz_300.patch
echo '
--- a/arch/mips/Kconfig
+++ b/arch/mips/Kconfig
@@ -1824,6 +1824,9 @@ choice
 	config HZ_256
 		bool "256 HZ" if SYS_SUPPORTS_256HZ || SYS_SUPPORTS_ARBIT_HZ
 
+	config HZ_300
+		bool "300 HZ" if SYS_SUPPORTS_ARBIT_HZ
+
 	config HZ_1000
 		bool "1000 HZ" if SYS_SUPPORTS_1000HZ || SYS_SUPPORTS_ARBIT_HZ
 
@@ -1831,6 +1834,7 @@ config HZ
 	default 128 if HZ_128
 	default 250 if HZ_250
 	default 256 if HZ_256
+	default 300 if HZ_300
 	default 1000 if HZ_1000
 	default 1024 if HZ_1024
' >> package/kernel/bpf-headers/patches/100-support_hz_300.patch

touch package/kernel/bpf-headers/src/include/generated/bounds.h
echo '
#ifndef __LINUX_BOUNDS_H__
#define __LINUX_BOUNDS_H__
/*
 * DO NOT MODIFY.
 *
 * This file was generated by Kbuild
 */

#define NR_PAGEFLAGS 23 /* __NR_PAGEFLAGS */
#define MAX_NR_ZONES 4 /* __MAX_NR_ZONES */
#define NR_CPUS_BITS 1 /* ilog2(CONFIG_NR_CPUS) */
#define SPINLOCK_SIZE 64 /* sizeof(spinlock_t) */

#endif
' >> package/kernel/bpf-headers/src/include/generated/bounds.h

config_add DEVEL
config_add KERNEL_DEBUG_INFO
config_del KERNEL_DEBUG_INFO_REDUCED
config_add KERNEL_DEBUG_INFO_BTF
config_add KERNEL_CGROUPS
config_add KERNEL_CGROUP_BPF
config_add KERNEL_BPF_EVENTS
config_add BPF_TOOLCHAIN_HOST
config_add KERNEL_XDP_SOCKETS
config_add KERNEL_MODULE_ALLOW_BTF_MISMATCH
config_package_add kmod-sched-core
config_package_add kmod-sched-bpf
config_package_add kmod-xdp-sockets-diag

## daed

git clone https://github.com/QiuSimons/luci-app-daed package/dae
mkdir -p Package/libcron && wget -O Package/libcron/Makefile https://raw.githubusercontent.com/immortalwrt/packages/refs/heads/master/libs/libcron/Makefile
config_package_add luci-app-daed

# ## Frp Latest version patch

# FRP_MAKEFILE_PATH="feeds/packages/net/frp/Makefile"

# FRP_LATEST_RELEASE=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

# if [ -z "$FRP_LATEST_RELEASE" ]; then
  # echo "无法获取最新的 Release 名称"
  # exit 1
# fi

# FRP_LATEST_VERSION=${FRP_LATEST_RELEASE#v}

# FRP_PKG_NAME="frp"
# FRP_PKG_SOURCE="${FRP_PKG_NAME}-${FRP_LATEST_VERSION}.tar.gz"
# FRP_PKG_SOURCE_URL="https://codeload.github.com/fatedier/frp/tar.gz/v${FRP_LATEST_VERSION}?"
# curl -L -o "$FRP_PKG_SOURCE" "$FRP_PKG_SOURCE_URL"

# FRP_PKG_HASH=$(sha256sum "$FRP_PKG_SOURCE" | awk '{print $1}')
# rm -r "$FRP_PKG_SOURCE"

# sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${FRP_LATEST_VERSION}/" "$FRP_MAKEFILE_PATH"
# sed -i "s/^PKG_HASH:=.*/PKG_HASH:=${FRP_PKG_HASH}/" "$FRP_MAKEFILE_PATH"

# echo "已更新 Makefile 中的 PKG_VERSION 和 PKG_HASH"
