-- create by sunhaozhi

local gt = cc.exports.gt
local Tools = class("Tools")
function Tools:ctor()
	gt.log("================>init tools")
end

function Tools:getInstance( )
	if not self.instance then
		self.instance = Tools.new()
	end
	return self.instance
end

function Tools:initQiYuLabel()
	if self.qiyuLabel == nil then
		local jsonArr = {}
		jsonArr[#jsonArr+1] = {key="uid",label="uid"}
		jsonArr[#jsonArr+1] = {key="unionid",label="unionid"}
		jsonArr[#jsonArr+1] = {key="ip",label="ip"}
		jsonArr[#jsonArr+1] = {key="source",label="咨询入口"}
		jsonArr[#jsonArr+1] = {key="resVersion",label="资源版本"}
		jsonArr[#jsonArr+1] = {key="totalPlayNum",label="游戏局数"}
		jsonArr[#jsonArr+1] = {key="isOldPlayer",label="是否老玩家"}
		jsonArr[#jsonArr+1] = {key="histroyLog",label="登录流程"}
		jsonArr[#jsonArr+1] = {key="LoginServerIP",label="服务器IP"}
		jsonArr[#jsonArr+1] = {key="LoginServerIPName",label="登录策略"}
		jsonArr[#jsonArr+1] = {key="remoteVersionUrl",label="主versionUrl"}
		jsonArr[#jsonArr+1] = {key="secondVersionUrl",label="副versionUrl"}
		jsonArr[#jsonArr+1] = {key="backupRemoteVersionUrl",label="Ftp versionUrl"}
		jsonArr[#jsonArr+1] = {key="isUseBackup",label="尝试过副地址"}
		jsonArr[#jsonArr+1] = {key="isUseBackupCDN",label="尝试过ftp地址"}
		jsonArr[#jsonArr+1] = {key="updateLog",label="更新日志"}

		require "json"
		self.qiyuLabel = json.encode(jsonArr)
	end 

	return self.qiyuLabel
end

function Tools:hasQiYu()
	--检查版本 1.0.14才有客服系统
	-- return self:checkVersion('1.0.14','1.0.14')
	return gt.checkVersion(1, 0, 9)
	
end

function Tools:hasQiYuNoti()
	--检查版本 1.0.16才有客服系统推送
	-- return self:checkVersion('1.0.16','1.0.16')
	return gt.checkVersion(1, 0, 9)
end

function Tools:registerQiyuMessageHandler(handler)
	gt.log("registerQiyuMessageHandler--------------")
	if self:hasQiYuNoti() == false then 
		return 
	end 

	local ok = false
	if(gt.isAndroidPlatform()) then
		local luaj = require("cocos/cocos2d/luaj")
		ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerQiyuMessageHandler", {handler}, "(I)V")
	else
		local luaoc = require("cocos/cocos2d/luaoc")
		ok= luaoc.callStaticMethod("AppController", "registerQiYuUnreadHandler",{scriptHandler = handler})
	end 
end

function Tools:removeQiyuMessageHandler()
	if self:hasQiYuNoti() == false then 
		return 
	end 

	local ok = false
	if(gt.isAndroidPlatform()) then
		local luaj = require("cocos/cocos2d/luaj")
		ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "removeQiyuMessageHandler", nil, "()V")
	else
		local luaoc = require("cocos/cocos2d/luaoc")
		ok= luaoc.callStaticMethod("AppController", "unregisterQiYuUnreadHandler",nil)
	end 
end

function Tools:getQiyuUnreadMessage()
	gt.log("function is getQiyuUnreadMessage")
	if self:hasQiYuNoti() == false then 
		return 0
	end 

	local ok = false
	local count = 0
	if(gt.isAndroidPlatform()) then
		local luaj = require("cocos/cocos2d/luaj")
		ok,count = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "getQiyuUnreadCount", nil, "()I")
	else
		local luaoc = require("cocos/cocos2d/luaoc")
		ok,count = luaoc.callStaticMethod("AppController", "getQiyuUnreadCount",nil)
	end

	if ok == false then 
		count = 0
	end  
	gt.log("未读数为"..count)
	return count
end



--打开客服系统
function Tools:openQiYu(param) 

	if self:hasQiYu() == false then 
		return false
	end 
	
	local paramObj = {}

	if param then 
		for k,v in pairs(param) do
			paramObj[k] = v
		end
	end 

	paramObj.labelsArr = self:initQiYuLabel()

	local ok = false
	if(gt.isAndroidPlatform()) then
		local luaj = require("cocos/cocos2d/luaj")
		require "json"

		local nickname = ""
		if paramObj.nickname ~= nil then 
			nickname = paramObj.nickname
			paramObj.nickname = nil
		end 
		local jsonParam = json.encode(paramObj)
		ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "openQiYu", {jsonParam,nickname}, "(Ljava/lang/String;Ljava/lang/String;)V")
	elseif(gt.isIOSPlatform()) then
		--ios版本暂停音乐
		if gt.soundEngine then
			gt.soundEngine:pauseAllSound()
		end

		--添加退出七鱼的监听

		if self.backHandler == nil then 
			self.backHandler  = function ()
				if gt.soundEngine then
					gt.soundEngine:resumeAllSound()
				end
			end

			local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
			local customListenerBg = cc.EventListenerCustom:create("BACK_FROM_QIYU_EVENT",
									self.backHandler)
			eventDispatcher:addEventListenerWithFixedPriority(customListenerBg, 1)
		end 


		local luaoc = require("cocos/cocos2d/luaoc")
		ok = luaoc.callStaticMethod("AppController", "openQiYu",paramObj)
	end
	return ok
end

function Tools:logoutQiYu() 
	gt.log("function is logoutQiYu")
	if self:hasQiYu() == false then 
		return false
	end 

	local ok = false
	if(gt.isAndroidPlatform()) then
		local luaj = require("cocos/cocos2d/luaj")
		ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "logoutQiYu", nil, "()V")
	elseif(gt.isIOSPlatform()) then
		local luaoc = require("cocos/cocos2d/luaoc")
		ok = luaoc.callStaticMethod("AppController", "logoutQiYu",nil)
	end
	return ok
end

return Tools
