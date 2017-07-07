local ShareSelect = class("ShareSelect", function()
	return gt.createMaskLayer()
end)

local gt = cc.exports.gt

function ShareSelect:ctor(description, title,  url, sharetype, callback)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("ShareSelect.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 关闭按钮
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()
		self:removeFromParent()
	end)

	local NodeType_1 = gt.seekNodeByName(self.rootNode, "NodeType_1")
	local Text_not = gt.seekNodeByName(NodeType_1, "Text_not")
	local Text_yes = gt.seekNodeByName(NodeType_1, "Text_yes")
	local Spr_title_share  = gt.seekNodeByName(self.rootNode, "Spr_title_share")
	if not sharetype then sharetype = 0 end
	if sharetype == 0 then
		NodeType_1:setVisible(false)
	elseif sharetype ==1 then
		NodeType_1:setVisible(true)
		Spr_title_share:setVisible(false)
		Text_not:setVisible(true)
		Text_yes:setVisible(false)
	elseif sharetype == 2 then
		Spr_title_share:setVisible(false)
		
		NodeType_1:setVisible(true)
		Text_not:setVisible(false)
		Text_yes:setVisible(true)
	end
	--活动描述
	local Text_Tip = gt.seekNodeByName(self.rootNode, "Text_Tip")
	if string.len(gt.ShareString)>0 then
		Text_Tip:setString(gt.ShareString)
	end

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	self.description = description
	self.title = title
	self.url = url
	self.androidParam = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	self.callback = callback
	
	local btn_haoyou = gt.seekNodeByName(self.rootNode, "Button_haoyou")
	gt.addBtnPressedListener(btn_haoyou, function()
		gt.CopyText(" ")
		if gt.isIOSPlatform() then
			if gt.isUseNewMusic() then
				local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWX",
					{url = self.url, title = self.title, description = self.description, scriptHandler = handler(self, self.pushShareCodeHY)})
			else
				-- local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWX",
				-- 	{url = self.url, title = self.title, description = self.description})
				--提示更新
				local appUpdateLayer = require("app/views/UpdateVersion"):create("当前版本不支持此功能,是否前往下载新版本?", 1)
		 		self:addChild(appUpdateLayer, 100)
			end

		elseif gt.isAndroidPlatform() then
			if gt.isUseNewMusic() then
				self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushShareCodeHY)}, "(I)V")
			else
				--提示更新
				local appUpdateLayer = require("app/views/UpdateVersion"):create("当前版本不支持此功能,是否前往下载新版本?", 1)
		 		self:addChild(appUpdateLayer, 100)
			end
			local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
				{self.url, self.title, self.description},
				self.androidParam)
		end
	end)

	local btn_pengyou = gt.seekNodeByName(self.rootNode, "Button_pengyou")
	gt.addBtnPressedListener(btn_pengyou, function()
		gt.CopyText(" ")
		local ok, appVersion = nil
		if gt.isIOSPlatform() then
			ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
		elseif gt.isAndroidPlatform() then
			ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
		end
		local versionNumber = string.split(appVersion, '.')
		if gt.isUseNewMusic()==false then
			--提示更新
			local appUpdateLayer = require("app/views/UpdateVersion"):create("当前版本不支持此功能,是否前往下载新版本?", 1)
	 		self:addChild(appUpdateLayer, 100)
	 	else
			if gt.isIOSPlatform() then
				local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWXPYQ",
					{url = self.url, title = self.title .. self.description, description = "", scriptHandler = handler(self, self.pushShareCodePYQ)})

			elseif gt.isAndroidPlatform() then
				local luaj = require("cocos/cocos2d/luaj")
				luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushShareCodePYQ)}, "(I)V")			
				local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWXPYQ",
					{self.url, self.title .. self.description, ""},
					self.androidParam)
			end
		end
	end)
end

function ShareSelect:pushShareCodePYQ(authCode)
	if (gt.isIOSPlatform() and authCode == 0) or (gt.isAndroidPlatform() and authCode == "success") then
		gt.log("分享朋友圈成功")
		if self.callback then
			gt.log("请求赠送房卡消息")
			self.callback()
		end
	else
		gt.log("分享朋友圈失败")
	end
	self:removeFromParent()
end

function ShareSelect:pushShareCodeHY(authCode)
	gt.log("===================HY", authCode, type(authCode))
	if (gt.isIOSPlatform() and authCode == 0) or (gt.isAndroidPlatform() and authCode == "success") then
		gt.log("分享好友／群成功")
		if self.callback then
			gt.log("请求赠送房卡消息")
			self.callback()
		end
	else
		gt.log("分享好友／群失败")
	end
	self:removeFromParent()
end

return ShareSelect