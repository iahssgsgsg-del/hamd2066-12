# المعالجات المدعومة (لأجهزة الآيفون الحديثة)
ARCHS = arm64 arm64e

# إصدار النظام المستهدف
TARGET := iphone:clang:latest:14.0

# اسم العملية التي سيتم التعديل عليها
INSTALL_TARGET_PROCESSES = Snapchat

include $(THEOS)/makefiles/common.mk

# --- إعدادات النسخة الذهبية ---
TWEAK_NAME = GoldSnapV10

# الملفات البرمجية التي سيتم استخدامها
GoldSnapV10_FILES = Tweak.x

# استخدام لغة برمجة حديثة (ARC)
GoldSnapV10_CFLAGS = -fobjc-arc

# المكتبات الأساسية لتشغيل الواجهة والموقع
GoldSnapV10_FRAMEWORKS = UIKit CoreLocation

include $(THEOS_MAKE_PATH)/tweak.mk

after-package::
	rm -rf ./packages/*
