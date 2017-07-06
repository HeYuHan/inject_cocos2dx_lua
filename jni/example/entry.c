/*
 *  Collin's Binary Instrumentation Tool/Framework for Android
 *  Collin Mulliner <collin[at]mulliner.org>
 *  http://www.mulliner.org/android/
 *
 *  (c) 2012,2013
 *
 *  License: LGPL v2.1
 *
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dlfcn.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <string.h>
#include <termios.h>
#include <pthread.h>
#include <sys/epoll.h>

#include <jni.h>
#include <stdlib.h>

#include "hook.h"
#include "base.h"
 // this file is going to be compiled into a thumb mode binary

void __attribute__((constructor)) hook_entry(void);
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
	hookFunction(&__func__); \
}
#define DEFINE_HOOK_INFO(__func__) static struct HookInfo __func__;
#define DEFINE_HOOK_FUNC(__func__) hook_##__func__ 
#define DEFINE_HOOK_FUNC_ARM(__func__) hook_##__func__##_arm
#define DEFINE_ORGIN_FUNC(__func__) orgin_##__func__

DEFINE_HOOK_INFO(luaL_loadbuffer)
int DEFINE_HOOK_FUNC(luaL_loadbuffer)(void* lua_state,const char* content,size_t len,const char* file_name)
{
	LOGD("call hook luaL_loadbuffer\nfile:%s\nconeten:%s\n",file_name,content);
	int(*DEFINE_ORGIN_FUNC(luaL_loadbuffer))(void* lua_state,const char* content,size_t len,const char* file_name);
	DEFINE_ORGIN_FUNC(luaL_loadbuffer) =(void*)luaL_loadbuffer.orgin_func_info.orig;
	hook_precall(&luaL_loadbuffer.orgin_func_info);
	int ret= DEFINE_ORGIN_FUNC(luaL_loadbuffer)(lua_state,content,len,file_name);
	hook_postcall(&luaL_loadbuffer.orgin_func_info);
	return ret;
}
int DEFINE_HOOK_FUNC_ARM(luaL_loadbuffer)(void* lua_state, const char* content, size_t len, const char* file_name)
{
	return DEFINE_HOOK_FUNC(luaL_loadbuffer)(lua_state, content, len, file_name);
}
//cocos2d_LuaLog;
DEFINE_HOOK_INFO(_ZN7cocos2d6LuaLogEPKc);
void DEFINE_HOOK_FUNC_ARM(_ZN7cocos2d6LuaLogEPKc)(const char* log)
{
	return DEFINE_HOOK_FUNC(_ZN7cocos2d6LuaLogEPKc)(log);
}
void DEFINE_HOOK_FUNC(_ZN7cocos2d6LuaLogEPKc)(const char* log)
{
	LOGD("call hook cocos2d_LuaLog\nnconeten:%s\n", log);
	void(*DEFINE_ORGIN_FUNC(_ZN7cocos2d6LuaLogEPKc))(const char* log);
	DEFINE_ORGIN_FUNC(_ZN7cocos2d6LuaLogEPKc) = (void*)_ZN7cocos2d6LuaLogEPKc.orgin_func_info.orig;
	hook_precall(&_ZN7cocos2d6LuaLogEPKc.orgin_func_info);
	DEFINE_ORGIN_FUNC(_ZN7cocos2d6LuaLogEPKc)(log);
	hook_postcall(&_ZN7cocos2d6LuaLogEPKc.orgin_func_info);
}
int hookFunction(struct HookInfo *info)
{
	if (info->hook_func&&info->hook_func_arm&&info->lib_name&&info->orgin_func_name)
	{
		return hook(&info->orgin_func_info, getpid(), info->lib_name, info->orgin_func_name, info->hook_func_arm, info->hook_func);
	}
	return -1;
}

void hook_entry()
{
	LOGD("%s", "begin hook");
	INIT_HOOK_INFO("libcocos2dlua.so", luaL_loadbuffer);
	INIT_HOOK_INFO("libcocos2dlua.so", _ZN7cocos2d6LuaLogEPKc);
	LOGD("%s", "hook end");
	return;
}

