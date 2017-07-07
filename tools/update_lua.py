import urllib
import urllib2
import json
import os
import os.path
import sys
sign = "SQLLiteData"
decode_key = "mXjv7U5dUl1aMTVV_xianlai"

url = "http://update.xlpdk.cn/client/mahjongsichuan/project.manifest";
req = urllib2.Request(url)
res_data = urllib2.urlopen(req)
json_str = res_data.read()
json_map = json.loads(json_str)
assets_map = json_map["newassets"]
res_update_url_root = json_map["packageUrl"]
res_update_url_root += "/"
print "packageUrl:" + res_update_url_root

for key in assets_map:
	if ".luac" in key and "cocos" not in key:
		dir_path = os.path.dirname(key)
		decode_path = dir_path.replace("src_et","src_et_decode")
		if not os.path.exists(dir_path):
			os.makedirs(dir_path);
		if not os.path.exists(decode_path):
			os.makedirs(decode_path);
		res_url = res_update_url_root + key
		data_req = urllib2.Request(res_url)
		data_res = urllib2.urlopen(data_req)
		data = data_res.read()
		file = open(key,"wb")
		file.write(data)
		file.close()
		full_orgin_path = sys.path[0] + "\\" + key.replace("/","\\")
		full_decode_path = sys.path[0] + "\\" + key.replace("/","\\").replace("src_et","src_et_decode").replace(".luac",".lua")
		os.system('xxtea.exe ' + full_orgin_path + ' ' + full_decode_path + ' '+ sign + ' ' + decode_key)
print "==============================================="
			