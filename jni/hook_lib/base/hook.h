/*
 *  Collin's Binary Instrumentation Tool/Framework for Android
 *  Collin Mulliner <collin[at]mulliner.org>
 *
 *  (c) 2012,2013
 *
 *  License: LGPL v2.1
 *
 */
#include <sys/types.h>
#include <string.h>
#include <android/log.h>
#define LOG_TAG "INJECT"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__);


struct hook_t {
	unsigned int jump[3];
	unsigned int store[3];
	unsigned char jumpt[20];
	unsigned char storet[20];
	unsigned int orig;
	unsigned int patch;
	unsigned char thumb;
	unsigned char name[128];
	void *data;
};

struct HookInfo
{
	char *lib_name;
	char *orgin_func_name;
	void* hook_func;
	void* hook_func_arm;
	struct hook_t orgin_func_info;
};
#define INIT_HOOK_INFO(__lib__,__func__) \
{ \
	__func__.lib_name = __lib__; \
	__func__.orgin_func_name = #__func__; \
	__func__.hook_func = hook_##__func__; \
	__func__.hook_func_arm = hook_##__func__##_arm; \
}
#define DEFINE_HOOK_INFO(__func__) struct HookInfo __func__;
#define DEFINE_HOOK_FUNC(__func__) hook_##__func__ 
#define DEFINE_HOOK_FUNC_ARM(__func__) hook_##__func__##_arm
#define DEFINE_ORGIN_FUNC(__func__) orgin_##__func__

int start_coms(int *coms, char *ptsn);

void hook_cacheflush(unsigned int begin, unsigned int end);	
void hook_precall(struct hook_t *h);
void hook_postcall(struct hook_t *h);
int hook(struct hook_t *h, int pid, char *libname, char *funcname, void *hook_arm, void *hook_thumb);
int hook_by_info(struct HookInfo *info);
void unhook(struct hook_t *h);
