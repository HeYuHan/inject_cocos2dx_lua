import os
import os.path
import sys
sign = "SQLLiteData"
key = "mXjv7U5dUl1aMTVV_xianlai"
def get_filter_files(dir_path,filter_map,file_list):
	for parent,dirs,files in os.walk(dir_path):
		for file in files:
			file_ext = os.path.splitext(file)[1];
			if file_ext in filter_map:
				file_list.append(os.path.join(parent,file));

if __name__ == "__main__":
	argv = sys.argv;
	if len(argv) < 3:
		print 'arg need inputdir outdir sgin key';
	else:
		inputdir = argv[1];
		outputdir = argv[2];
		if inputdir == outputdir:
			print 'arg error';
		else:
			file_list=[];
			get_filter_files(inputdir,['.luac'],file_list);
			for file in file_list:
				new_dir = outputdir + os.path.dirname(file).replace(inputdir,'') ;
				new_path= new_dir +'\\'+ (os.path.split(file)[1]).replace('.luac','.lua');
				if not os.path.exists(new_dir):
					os.makedirs(new_dir);
				os.system('xxtea.exe ' + file + ' ' + new_path + ' '+ sgin + ' ' +key)
				print new_path;
