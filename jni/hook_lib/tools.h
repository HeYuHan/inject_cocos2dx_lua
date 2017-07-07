#pragma once
#ifndef _tools_h_
#define _tools_h_
int create_dir(char* path,int len);
int get_path_file_name(char* path, char* out_put);
int get_path_dir_name(char* path, char* out_put);
int write_file(char* path, char* mode, const char* content);
int read_file(char* path, char* out_put, int len);
int get_file_len(char* path);
#endif