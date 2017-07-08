#include "luaL_loadbuffer.h"
#include "tools.h"
#define PACK_HACK_PATH "/data/data/com.mahjong.sichuang/hack_res/"
#define PACK_ORGIN_PATH "/data/data/com.mahjong.sichuang/origin/"
static DEFINE_HOOK_INFO(luaL_loadbuffer)
int DEFINE_HOOK_FUNC(luaL_loadbuffer)(void* lua_state, const char* content, size_t len, const char* file_name)
{
	char hack_file_path[256] = { 0 };
	char *hack_file_content = NULL;
	int hack_file_content_len = 0;
	sprintf(hack_file_path, "%s%s", PACK_HACK_PATH, file_name);
	hack_file_content_len = get_file_len(hack_file_path);
	
	if (hack_file_content_len > 0)
	{
		LOGD("load hack lua:%s", hack_file_path);
		hack_file_content = (char*)malloc(sizeof(char)*(hack_file_content_len + 1));
		if (read_file(hack_file_path, hack_file_content, hack_file_content_len + 1) < 0)
		{
			free(hack_file_content);
			hack_file_content = NULL;
		}
		else
		{
			content = hack_file_content;
			len = hack_file_content_len;
		}
	}
	//create_dir(save_dir, strlen(save_dir));
	//write_file(save_path, "w", content);
	//LOGD("call hook luaL_loadbuffer path:%s name:%s", save_path, save_dir);
	int(*DEFINE_ORGIN_FUNC(luaL_loadbuffer))(void* lua_state, const char* content, size_t len, const char* file_name);
	DEFINE_ORGIN_FUNC(luaL_loadbuffer) = (void*)luaL_loadbuffer.orgin_func_info.orig;
	hook_precall(&luaL_loadbuffer.orgin_func_info);
	int ret = DEFINE_ORGIN_FUNC(luaL_loadbuffer)(lua_state, content, len, file_name);
	hook_postcall(&luaL_loadbuffer.orgin_func_info);
	if (hack_file_content)
	{
		free(hack_file_content);
		hack_file_content = NULL;
	}
	return ret;
}
int DEFINE_HOOK_FUNC_ARM(luaL_loadbuffer)(void* lua_state, const char* content, size_t len, const char* file_name)
{
	return DEFINE_HOOK_FUNC(luaL_loadbuffer)(lua_state, content, len, file_name);
}
int onhook_luaL_loadbuffer()
{
	INIT_HOOK_INFO("libcocos2dlua.so", luaL_loadbuffer);
	return hook_by_info(&luaL_loadbuffer);
}