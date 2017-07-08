#include "tools.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <sys/types.h>
#include "base/hook.h"
int create_dir(char* path,int len)
{
	if (access(path, 0)==0)
	{
		return 0;
	}
	else
	{
		char copy_path[256] = { 0 };
		memcpy(copy_path, path, len);
		int i;
		for (i = 1;i < len;i++)
		{
			if (copy_path[i] == '/')
			{
				copy_path[i] = 0;
				if (access(copy_path, 0)==-1)
				{
					
					if (mkdir(copy_path, 0755) != 0)
					{
						LOGD("create path error:%s", copy_path);
						return -1;
					}
				}
				copy_path[i] = '/';
			}
		}
	}
	return 0;
}
int get_path_file_name(char* path, char* out_put)
{
	int len = strlen(path);
	char* file_name = NULL;
	int i;
	for (i = len-1;i >= 0;i--)
	{
		if (path[i] == '/')
		{
			file_name = &path[i + 1];
			break;
		}
	}
	if (file_name)
	{
		len = strlen(file_name);
		memcpy(out_put, file_name, len);
		out_put[len] = 0;
		return len;
	}
	return -1;
}
int get_path_dir_name(char* path, char* out_put)
{
	int len = strlen(path);
	int dir_end = 0;
	int i;
	for (i = len - 1;i >= 0;i--)
	{
		if (path[i] == '/')
		{
			dir_end = i+1;
			break;
		}
	}
	if (dir_end>0)
	{
		memcpy(out_put, path, dir_end);
		out_put[dir_end] = 0;
		return dir_end;
	}
	return -1;
}
int write_file(char* path, char* mode, const char* content)
{
	FILE* file;
	int ret = -1;
	file = fopen(path, mode);
	if (file)
	{
		ret = fputs(content, file);
		fclose(file);
	}
	return ret;
}
int read_file(char* path, char* out_put, int len)
{
	if (access(path, 0) != 0)return -1;
	FILE* file;
	int ret = -1;
	file = fopen(path, "r");
	if (file)
	{
		fseek(file, 0, SEEK_END);
		int file_len = ftell(file);
		if (len > file_len)
		{
			rewind(file);
			fread(out_put, 1, file_len, file);
			out_put[file_len] = 0;
			ret = file_len;
			
		}
		fclose(file);
	}
	return ret;
}
int get_file_len(char* path)
{
	if (access(path, 0) != 0)
	{
		return -1;
	}
	FILE* file;
	int ret = -1;
	file = fopen(path, "r");
	if (file)
	{
		fseek(file, 0, SEEK_END);
		ret = ftell(file);
		fclose(file);
	}
	return ret;
}