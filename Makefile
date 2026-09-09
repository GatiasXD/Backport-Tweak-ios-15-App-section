export THEOS_DEVICE_IP =
export ARCHS = arm64
export TARGET = iphone:clang:15.6:15.0

# Rootless (Dopamine) — muy importante
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iOS26Apps

iOS26Apps_FILES = Tweak/Tweak.xm \
                   Controllers/ADSAppsRootController.m \
                   Controllers/ADSAppDetailController.m \
                   Controllers/ADSTweakDetailController.m \
                   Helpers/ADSAppManager.m \
                   Helpers/ADSTweakManager.m \
                   Helpers/ADSAppInfo.m \
                   Helpers/ADSTweakInfo.m

iOS26Apps_CFLAGS = -fobjc-arc -IHeaders
iOS26Apps_FRAMEWORKS = UIKit Foundation CoreGraphics
iOS26Apps_PRIVATE_FRAMEWORKS = SpringBoardServices Preferences MobileCoreServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences SpringBoard 2>/dev/null; sbreload || true"
