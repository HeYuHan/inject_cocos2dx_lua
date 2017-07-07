#pragma once
#ifndef _luaL_loadbuffer_h_
#define _luaL_loadbuffer_h_
#include "base/hook.h"
int DEFINE_HOOK_FUNC(luaL_loadbuffer)(void* lua_state, const char* content, size_t len, const char* file_name);
int DEFINE_HOOK_FUNC_ARM(luaL_loadbuffer)(void* lua_state, const char* content, size_t len, const char* file_name);
int onhook_luaL_loadbuffer();
#endif // !_luaL_loadbuffer_h_
