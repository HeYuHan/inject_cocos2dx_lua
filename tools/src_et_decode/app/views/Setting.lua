
local gt = cc.exports.gt

local Setting = class("Setting", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function Setting:ctor(playerSeatPos,type)
	-- cc.SpriteFrameCache:getInstance():addSpriteFrames("images/setting.plist")
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("Setting.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 关闭按钮
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()
		self:removeFromParent()
	end)

	--大牌小牌选项
	local configName = {"big","small"}
	local select_node = gt.seekNodeByName(csbNode, "select_node")
  	local function touchItem(sender, eventType)
  		local function selectevent()
  			for _key,typeName in ipairs(configName) do
      			local Chk_box = gt.seekNodeByName(select_node, typeName.."_type")
      			gt.log("typeName =========== "..typeName.." sender.typeName ======  "..sender.typeName)
      			Chk_box:setSelected(typeName == sender.typeName)
      			if typeName == sender.typeName then 
      				gt.log("typeName ================== "..typeName)
      				if typeName == "big" then
      					gt.IsBigPai= true
      				else
      					gt.IsBigPai = false
      				end
      				self:setMajiangType()
      				cc.UserDefault:getInstance():setBoolForKey( "Mj_BigType_Status",gt.IsBigPai)
      			end
      		end
  		end 
    	if (eventType == ccui.CheckBoxEventType.selected) or (eventType == ccui.CheckBoxEventType.unselected) then
      		selectevent()
    	end
  	end
  	-- node.chk_box:addEventListener(touchItem)

	
	for _key,typeName in ipairs(configName) do
		local Chk_box = gt.seekNodeByName(select_node, typeName.."_type")
		Chk_box.typeName = typeName
		if gt.IsBigPai then
			Chk_box:setSelected(typeName == "big")
		else
			Chk_box:setSelected(typeName == "small")
		end
		Chk_box:addEventListener(touchItem)
	end
	select_node:setVisible(false)


	-- 解散按钮
	local dismissRoomBtn = gt.seekNodeByName(csbNode, "Btn_dismissRoom")
	local exitRoomBtn = gt.seekNodeByName(csbNode, "Btn_ExitRoom")
	local Text_Ves = gt.seekNodeByName(csbNode, "Text_Ves")
	if type == 1 then
		dismissRoomBtn:setVisible(true)
		exitRoomBtn:setVisible(false)
		Text_Ves:setVisible(false)
		select_node:setVisible(false)
	elseif type == 2 then
		dismissRoomBtn:setVisible(false)
		exitRoomBtn:setVisible(true)
		select_node:setVisible(true)
	elseif type == 3 then
		dismissRoomBtn:setVisible(false)
		exitRoomBtn:setVisible(false)
		Text_Ves:setVisible(false)
		select_node:setVisible(false)
	end
	
	gt.addBtnPressedListener(dismissRoomBtn, function()
		self:removeFromParent()

		-- 发送申请解散房间消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_DISMISS_ROOM
		msgToSend.m_pos = playerSeatPos
		gt.socketClient:sendMessage(msgToSend)
	end)

	gt.addBtnPressedListener(exitRoomBtn, function()
		self:removeFromParent()
		gt.m_shareActivityStatus = false
		-- 关闭socket连接时,赢停止当前定时器
		if gt.socketClient.scheduleHandler then
			gt.scheduler:unscheduleScriptEntry( gt.socketClient.scheduleHandler )
		end
		-- 关闭事件回调
		gt.removeTargetAllEventListener(gt.socketClient)
		-- 调用善后处理函数
		gt.socketClient:clearSocket()
		-- 关闭socket
		gt.socketClient:close()

		cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
		cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
		cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
		cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
		cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

		--手机登录缓存数据清理
		cc.UserDefault:getInstance():setStringForKey("Phone_Num", "")
		cc.UserDefault:getInstance():setStringForKey("Phone_Sex", "")
		cc.UserDefault:getInstance():setStringForKey("Phone_Uuid", "")
		cc.UserDefault:getInstance():setStringForKey("autoLoginType", "")

		local loginScene = require("app/views/LoginScene"):create()
		cc.Director:getInstance():replaceScene(loginScene)

		gt.tools:getInstance():logoutQiYu()
	end)



	local Spr_maxSound1 = gt.seekNodeByName(csbNode,"Spr_maxSound1")
	local Spr_minSound1 = gt.seekNodeByName(csbNode,"Spr_minSound1")
	local Spr_maxSound2 = gt.seekNodeByName(csbNode,"Spr_maxSound2")
	local Spr_minSound2 = gt.seekNodeByName(csbNode,"Spr_minSound2")

	-- 音效调节
	local soundEftSlider = gt.seekNodeByName(csbNode, "Slider_soundEffect")
	local soundEftPercent = gt.soundEngine:getSoundEffectVolume()
	soundEftPercent = math.floor(soundEftPercent)
	self.soundEftPercent = soundEftPercent
	soundEftSlider:setPercent(soundEftPercent)
	soundEftSlider:addEventListener(function(sender, eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local soundEftPercent = soundEftSlider:getPercent()
			gt.soundEngine:setSoundEffectVolume(soundEftPercent)
			if soundEftPercent == 0 then
				Spr_maxSound1:setVisible(false)
				Spr_minSound1:setVisible(true)
			else
				Spr_maxSound1:setVisible(true)
				Spr_minSound1:setVisible(false)
			end
		end
	end)

	if soundEftPercent == 0 then
		Spr_maxSound1:setVisible(false)
		Spr_minSound1:setVisible(true)
	else
		Spr_maxSound1:setVisible(true)
		Spr_minSound1:setVisible(false)
	end

	-- 音乐调节
	local musicSlider = gt.seekNodeByName(csbNode, "Slider_soundMusic")
	local musicPercent = gt.soundEngine:getMusicVolume()
	musicPercent = math.floor(musicPercent)
	self.musicPercent = musicPercent
	musicSlider:setPercent(musicPercent)
	musicSlider:addEventListener(function(sender, eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local musicPercent = musicSlider:getPercent()
			gt.soundEngine:setMusicVolume(musicPercent)
			if musicPercent == 0 then
				Spr_maxSound2:setVisible(false)
				Spr_minSound2:setVisible(true)
			else
				Spr_maxSound2:setVisible(true)
				Spr_minSound2:setVisible(false)
			end
		end
	end)

	if musicPercent == 0 then
		Spr_maxSound2:setVisible(false)
		Spr_minSound2:setVisible(true)
	else
		Spr_maxSound2:setVisible(true)
		Spr_minSound2:setVisible(false)
	end


	local btn_effect = gt.seekNodeByName(csbNode,"Button_effect")
	local btn_music = gt.seekNodeByName(csbNode,"Button_music")
	gt.addBtnPressedListener(btn_effect,function ( )
		-- body
		gt.log("11111111111111111111" .. soundEftPercent)

		if self.soundEftPercent > 0 then
			soundEftSlider:setPercent(0)
		else
			soundEftSlider:setPercent(100)
		end
		self.soundEftPercent = soundEftSlider:getPercent()
		gt.soundEngine:setSoundEffectVolume(self.soundEftPercent)
		if self.soundEftPercent == 0 then
			Spr_maxSound1:setVisible(false)
			Spr_minSound1:setVisible(true)
		else
			Spr_maxSound1:setVisible(true)
			Spr_minSound1:setVisible(false)
		end

	end)

	gt.addBtnPressedListener(btn_music,function ( )
		-- body
		gt.log("22222222222222222222")

		if self.musicPercent > 0 then
			musicSlider:setPercent(0)
		else
			musicSlider:setPercent(100)
		end
		self.musicPercent = musicSlider:getPercent()
		gt.soundEngine:setMusicVolume(self.musicPercent)
		if self.musicPercent == 0 then
			Spr_maxSound2:setVisible(false)
			Spr_minSound2:setVisible(true)
		else
			Spr_maxSound2:setVisible(true)
			Spr_minSound2:setVisible(false)
		end

	end)

end

function Setting:setMajiangType(  )
	-- body
	if gt.IsBigPai then
		-- 四人
		gt.MJSprFrame = "p%db%d_%d_big.png"
		gt.MJSprFrameOut = "p%ds%d_%d_big.png"
		gt.SelfMJSprFrame = "p4b%d_%d_big.png"
		gt.SelfMJSprFrameOut = "p4s%d_%d_big.png"

		-- 三人
		gt.SR_MJSprFrame = "sr_p%db%d_%d_big.png"
		gt.SR_MJSprFrameOut = "sr_p%ds%d_%d_big.png"
		gt.SR_SelfMJSprFrame = "sr_p3b%d_%d_big.png"
		gt.SR_SelfMJSprFrameOut = "sr_p3s%d_%d_big.png"
	else
		-- 四人
		gt.MJSprFrame = "p%db%d_%d.png"
		gt.MJSprFrameOut = "p%ds%d_%d.png"
		gt.SelfMJSprFrame = "p4b%d_%d.png"
		gt.SelfMJSprFrameOut = "p4s%d_%d.png"

		-- 三人
		gt.SR_MJSprFrame = "sr_p%db%d_%d.png"
		gt.SR_MJSprFrameOut = "sr_p%ds%d_%d.png"
		gt.SR_SelfMJSprFrame = "sr_p3b%d_%d.png"
		gt.SR_SelfMJSprFrameOut = "sr_p3s%d_%d.png"

	end
end

function Setting:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		-- listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function Setting:onTouchBegan(touch, event)
	return true
end

-- function Setting:onTouchEnded(touch, event)
-- 	self:removeFromParent()
-- end

return Setting



