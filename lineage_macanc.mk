#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from macanc device
$(call inherit-product, device/oneplus/macanc/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_macanc
PRODUCT_DEVICE := macanc
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := PLR110

PRODUCT_GMS_CLIENTID_BASE := android-oneplus

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi-user 16 BP2A.250605.015 1782990090751 release-keys" \
    BuildFingerprint=OnePlus/PLR110/OP6117L1:16/BP2A.250605.015/B.2b5b5cd-6c66aa-6bea3a:user/release-keys \
    DeviceName=OP6117L1 \
    DeviceProduct=PLR110 \
    SystemDevice=OP6117L1 \
    SystemName=PLR110

# AviumUI
AVIUM_MAINTAINER ?= kingzcheung
AVIUM_SETTINGS_SOC_MODEL_NAME ?= Snapdragon 8 Elite Gen 5
AVIUM_SETTINGS_DEVICE_CODENAME ?= macanc
# 选择是否开启 GMS (Vanilla: false)
WITH_GMS ?= false
# 版本号附加时分秒
AVIUM_VERSION_APPEND_TIME_OF_DAY ?= false
# 隐藏 bootloader 解锁状态的欺骗 prop
AVIUM_FORCE_SET_FAKE_PROP ?= false
# 强制开启模糊
TARGET_FORCE_ENABLE_BLUR ?= false
