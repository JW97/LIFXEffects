include theos/makefiles/common.mk

TWEAK_NAME = LIFXEffects
LIFXEffects_FILES = Tweak.xm
LIFXEffects_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 LIFX"
