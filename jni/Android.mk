LOCAL_PATH := $(call my-dir)

#########################################################
#example
#include $(CLEAR_VARS)
#LOCAL_MODULE := base
#LOCAL_SRC_FILES := base/obj/local/armeabi/libbase.a
#LOCAL_EXPORT_C_INCLUDES := base
#include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE    := libexample
LOCAL_SRC_FILES := example/base.c example/hook.c example/util.c example/entry.c
LOCAL_CFLAGS := -g
LOCAL_LDLIBS += -llog  
include $(BUILD_SHARED_LIBRARY)

#########################################################
#Inject

include $(CLEAR_VARS)  
LOCAL_MODULE := Inject   
LOCAL_SRC_FILES := Inject/Inject.c
LOCAL_LDLIBS    := -lm -llog
#include $(BUILD_SHARED_LIBRARY)  
include $(BUILD_EXECUTABLE)
#PRODUCT_COPY_FILES += $(LOCAL_PATH)/../libs/$(TARGET_ARCH_ABI)/Inject:$(LOCAL_PATH)/../assets/Inject
