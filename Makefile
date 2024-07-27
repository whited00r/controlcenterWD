THEOS_DEVICE_IP = 192.168.1.18
GO_EASY_ON_ME = 1
include theos/makefiles/common.mk

TWEAK_NAME = ControlCenter
ControlCenter_FILES = Tweak.xm UIImage+StackBlur.m
ControlCenter_FRAMEWORKS = UIKit CoreGraphics Foundation QuartzCore MediaPlayer
ControlCenter_PRIVATE_FRAMEWORKS = GraphicsServices Accelerate
include $(THEOS_MAKE_PATH)/tweak.mk
