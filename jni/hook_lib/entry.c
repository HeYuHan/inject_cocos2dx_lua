#define _GNU_SOURCE
#include <stdio.h>
#include <sys/types.h>
#include <string.h>
#include <jni.h>
#include "luaL_loadbuffer.h"
#include "tools.h"
// this file is going to be compiled into a thumb mode binary
void __attribute__((constructor)) hook_entry(void);

////cocos2d_LuaLog;
//DEFINE_HOOK_INFO(_ZN7cocos2d6LuaLogEPKc);
//void DEFINE_HOOK_FUNC_ARM(_ZN7cocos2d6LuaLogEPKc)(const char* log)
//{
//	return DEFINE_HOOK_FUNC(_ZN7cocos2d6LuaLogEPKc)(log);
//}
//void DEFINE_HOOK_FUNC(_ZN7cocos2d6LuaLogEPKc)(const char* log)
//{
//	LOGD("call hook cocos2d_LuaLog\nnconeten:%s\n", log);
//	void(*DEFINE_ORGIN_FUNC(_ZN7cocos2d6LuaLogEPKc))(const char* log);
//	DEFINE_ORGIN_FUNC(_ZN7cocos2d6LuaLogEPKc) = (void*)_ZN7cocos2d6LuaLogEPKc.orgin_func_info.orig;
//	hook_precall(&_ZN7cocos2d6LuaLogEPKc.orgin_func_info);
//	DEFINE_ORGIN_FUNC(_ZN7cocos2d6LuaLogEPKc)(log);
//	hook_postcall(&_ZN7cocos2d6LuaLogEPKc.orgin_func_info);
//}
void hook_entry()
{
	LOGD("%s", "begin hook");
	onhook_luaL_loadbuffer();
	LOGD("%s", "hook end");
	return;
}

