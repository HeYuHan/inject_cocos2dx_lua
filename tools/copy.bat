@echo off
set path=%~sdp0
set exe_path=%path%..\libs\armeabi\Inject
set copy_exe_path=%path%..\assets\Inject
copy %exe_path% %copy_exe_path%
set cop_res_dir=%path%..\hack_res
start python copy.py
