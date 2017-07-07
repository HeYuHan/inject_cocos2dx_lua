LOCAL_PATH := $(call my-dir)

#########################################################
#
include $(CLEAR_VARS)
LOCAL_MODULE    := libexample
LOCAL_CFLAGS := -g
LOCAL_LDLIBS += -llog  
#LOCAL_C_INCLUDES := $(NDK_ROOT)/sources/cxx-stl/stlport/stlport
LOCAL_SRC_FILES :=  hook_lib/base/base.c \
					hook_lib/base/hook.c \
					hook_lib/base/util.c \
					hook_lib/tools.c \
					hook_lib/entry.c \
					hook_lib/luaL_loadbuffer.c \
					

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
