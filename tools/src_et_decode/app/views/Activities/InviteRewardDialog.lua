local gt = cc.exports.gt

local InviteRewardDialog = class("InviteRewardDialog",function() 
	return gt.createMaskLayer()
 end)

function InviteRewardDialog:ctor()
	local csbfile = "InviteRewardDialog.csb"
	local csbNode = cc.CSLoader:createNode(csbfile)
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.csbNode = csbNode
	gt.m_IsShare = gt.m_IsShare or 1

    self.windowId = string.format("InviteRewardDialog-%d", os.time())
    gt.dadianDataAdd("fxlj", self.windowId, "share")

	self:loadControls()
	-- gt.socketClient:registerMsgListener(gt.GC_SHARE_SUCCESS, self, self.onRcvShareRoom)
end

function InviteRewardDialog:loadControls()
	self.textTip = gt.seekNodeByName(self.csbNode, "Text_Tip")
	self.closeBtn = gt.seekNodeByName(self.csbNode, "Btn_close")
	self.cancelBtn = gt.seekNodeByName(self.csbNode, "cancelBtn")
	self.okBtn = gt.seekNodeByName(self.csbNode, "okBtn")
	local alreadyShare = gt.seekNodeByName(self.csbNode, "Text_yes")
	local notShare = gt.seekNodeByName(self.csbNode, "Text_not")
	alreadyShare:setVisible(gt.m_IsShare == 2)
	notShare:setVisible(gt.m_IsShare == 1)

	if string.len(gt.ShareString)>0 then
		self.textTip:setString(gt.ShareString)
	end

    local windowId = self.windowId
	local function closeFunc(  )
		self:hide()

        gt.dadianDataAdd("fxlj", windowId, "cancel")
        gt.dadianDataSend()
	end

	gt.addBtnPressedListener(self.closeBtn, closeFunc)
	gt.addBtnPressedListener(self.cancelBtn, closeFunc)

	local function okFunc()
        gt.dadianDataAdd("fxlj", windowId, "confirm")

		gt.CopyText(" ")
		if gt.isIOSPlatform() then
			self.luaBridge = require("cocos/cocos2d/luaoc")
		elseif gt.isAndroidPlatform() then
			self.luaBridge = require("cocos/cocos2d/luaj")
		end
		-- local description = string.format("玩家:%s ID:%d 邀请您加入【熊猫麻将】。",gt.playerData.nickname,gt.playerData.uid)
		local description = "三缺一啦~就差你一个！每日免费房卡，登陆分享即可领取！"
		local title = "熊猫麻将"
		local shareUrl = {"http://t.cn/RoD0tWv"," http://t.cn/RoD0o8s"," http://t.cn/RoD0C94"," http://t.cn/RoD0Y24","http://t.cn/RoD0Qns",
						"http://t.cn/RoD0ElL","http://t.cn/RoD0ua0","http://t.cn/RoD0BSl","http://t.cn/RoD0ed6","http://t.cn/RoD0sxj"}
		self.url = shareUrl[tonumber(gt.playerData.uid)% #shareUrl + 1]
		self.androidParam = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		self.description = description
		self.title = title
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
	end
	gt.addBtnPressedListener(self.okBtn, okFunc)
end

function InviteRewardDialog:pushShareCodePYQ(authCode)	
	if (gt.isIOSPlatform() and authCode == 0) or (gt.isAndroidPlatform() and authCode == "success") then
        gt.dadianDataAdd("fxlj", self.windowId, "success")

		gt.log("分享朋友圈成功")
		if self.sendCallback then
			gt.log("请求赠送房卡消息")
			self.sendCallback()
		end
	else
        gt.dadianDataAdd("fxlj", self.windowId, "error")
		gt.log("分享朋友圈失败")
	end
    gt.dadianDataSend()
	self:hide()
end

function InviteRewardDialog:sendCallback()
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_SHARE_SUCCESS
	gt.socketClient:sendMessage(msgToSend)
	gt.dump(msgToSend)
end

function InviteRewardDialog:show( parent , zOrder )
	parent = parent or cc.Director:getInstance():getRunningScene()
	zOrder = zOrder or 60 -- notice tip 的 层级是 67 ，要比67 小
	parent:addChild(self,zOrder)
end

-- function InviteRewardDialog:onRcvShareRoom(msgTbl)
-- 	gt.log("function = onRcvShareRoom")
-- 	gt.dump(msgTbl)
-- 	if msgTbl.m_ErrorCode == 0 and msgTbl.m_GiftCount > 0 then
-- 		local GetRoomCard = cc.CSLoader:createNode("GetRoomCard.csb")
-- 		GetRoomCard:setPosition(gt.winCenter)
-- 		local scene = 
-- 		self:addChild(GetRoomCard,10086)
-- 		local Text_CardNum = gt.seekNodeByName(GetRoomCard,"Text_CardNum")
-- 		Text_CardNum:setString(msgTbl.m_GiftCount)

-- 		local btn_Close = gt.seekNodeByName(GetRoomCard,"Btn_close")
-- 		gt.addBtnPressedListener(btn_Close,function ()
-- 			if GetRoomCard then
-- 				GetRoomCard:removeFromParent()
-- 			end
-- 		end)
-- 		local Btn_Sure = gt.seekNodeByName(GetRoomCard,"Btn_Sure")
-- 		gt.addBtnPressedListener(Btn_Sure,function ()
-- 			if GetRoomCard then
-- 				GetRoomCard:removeFromParent()
-- 			end
-- 		end)
-- 		gt.m_IsShare = 2
-- 	elseif msgTbl.m_ErrorCode == 1 then
-- 		gt.log("未知错误")
-- 	else
-- 	end
-- end

function InviteRewardDialog:hide()
	self:removeFromParent()
end

return InviteRewardDialog
