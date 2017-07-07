#########################################################
#base
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := base
LOCAL_SRC_FILES :=  ../base.c ../hook.c ../util.c 
include $(BUILD_STATIC_LIBRARY)