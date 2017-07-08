import os
import os.path
import sys
import shutil
hack_res_map = {
	"hack_mj":["LoginScene.lua","PlaySceneErRen.lua"]
}
hack_res_path = sys.path[0] +"\\..\\hack_res\\"
copy_res_path = sys.path[0] +"\\..\\assets\\hack_res\\"
hack_decode_path = sys.path[0] +"\\src_et_decode\\"
##############################################################################
#hack res
for root, sub_dirs, files in os.walk(hack_decode_path):
	for file in files:
		for project in hack_res_map:
			if file in hack_res_map[project]:
				orign_path = root + "\\" +file
				copy_to_path =hack_res_path + project + "\\"+ orign_path.replace(hack_decode_path,"")
				copy_dir = copy_to_path.replace(file,"")
				copy_to_path = copy_to_path.replace(".lua",".luac")
				if not os.path.exists(copy_dir):
					os.makedirs(copy_dir)
				shutil.copy(orign_path,copy_to_path)
				if os.path.exists(copy_to_path):
					print "copy decode file:" + copy_to_path
##############################################################################

if os.path.exists(hack_res_path):
	if os.path.exists(copy_res_path):
		shutil.rmtree(copy_res_path)
	os.makedirs(copy_res_path)
	for root, sub_dirs, files in os.walk(hack_res_path):
		for file in files:
			orign_path = root + "\\" +file
			copy_to_path =copy_res_path + orign_path.replace(hack_res_path,"")
			copy_dir = copy_to_path.replace(file,"")
			copy_to_path = copy_to_path
			if not os.path.exists(copy_dir):
				os.makedirs(copy_dir)
			shutil.copy(orign_path,copy_to_path)
			if os.path.exists(copy_to_path):
				print "copy hack res:" + copy_to_path
##############################################################################
exe_path = sys.path[0] + "\\..\\libs\\armeabi\\Inject"
copy_exe_path = sys.path[0] + "\\..\\assets\\hack_res\\Inject"
if os.path.exists(exe_path):
	shutil.copy(exe_path,copy_exe_path)
	if os.path.exists(copy_exe_path):
		print "copy hack res:" + copy_exe_path
