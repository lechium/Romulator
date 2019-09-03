ARCHS = arm64
TARGET = appletv:clang:10.1:10.1
export GO_EASY_ON_ME=1
export SDKVERSION=10.2
THEOS_DEVICE_IP=4k.local
DEBUG=0
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Romulator
Romulator_FILES = Romulator.m
Romulator_INSTALL_PATH = /Library/PreferenceBundles
Romulator_FRAMEWORKS = UIKit Sharing
Romulator_PRIVATE_FRAMEWORKS = TVSettingKit
Romulator_LDFLAGS = -undefined dynamic_lookup
#Romulator_CFLAGS+= -I. -ITVSettings -ITVSettingsKit
Romulator_CFLAGS+= -F.
Romulator_CODESIGN_FLAGS=-Sent.plist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)
