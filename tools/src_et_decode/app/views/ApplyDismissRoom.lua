
local ApplyDismissRoom = class("ApplyDismissRoom", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function ApplyDismissRoom:ctor(roomPlayers, playerSeatIdx)
	-- 注册节点事件
	gt.log("注册节点事件ApplyDismissRoom")
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	self.roomPlayers = roomPlayers
	self.playerSeatIdx = playerSeatIdx

	self:setVisible(false)

    -- 注册解散房间事件
    gt.registerEventListener(gt.EventType.APPLY_DIMISS_ROOM, self, self.dismissRoomEvt)
end

function ApplyDismissRoom:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)

	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)

		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)

		-- 事件回调
		gt.removeTargetAllEventListener(self)
	end
end

function ApplyDismissRoom:onTouchBegan(touch, event)
	if not self:isVisible() then
		return false
	end

	return true
end

-- start --
--------------------------------
-- @class function
-- @description 更新解散房间倒计时
-- end --
function ApplyDismissRoom:update(delta)
	if not self.rootNode or not self.dimissTimeCD then
		return
	end

	self.dimissTimeCD = self.dimissTimeCD - delta
	if self.dimissTimeCD < 0 then
		self.dimissTimeCD = 0
	end
	local timeCD = math.ceil(self.dimissTimeCD)
	local dismissTimeCDLabel = gt.seekNodeByName(self.rootNode, "Label_dismissCD")
	dismissTimeCDLabel:setString(tostring(timeCD))
end

-- start --
--------------------------------
-- @class function
-- @description 接收解散房间消息事件ReadyPlay接收消息以事件方式发送过来
-- @param eventType
-- @param msgTbl
-- end --
function ApplyDismissRoom:dismissRoomEvt(eventType, msgTbl)

	gt.log("dismissRoomEvt ...... ")
	dump(msgTbl)

	if msgTbl.m_errorCode == 0 then
		-- 等待操作中
		if not self.rootNode then
			local csbNode = cc.CSLoader:createNode("ApplyDismissRoom.csb")
			csbNode:setPosition(gt.winCenter)
			self:addChild(csbNode)
			self.rootNode = csbNode

			local agreeBtn = gt.seekNodeByName(self.rootNode, "Btn_agree")
			-- 同意
			agreeBtn:setTag(1)
			gt.addBtnPressedListener(agreeBtn, handler(self, self.buttonClickEvt))

			local refuseBtn = gt.seekNodeByName(self.rootNode, "Btn_refuse")
			-- 拒绝
			refuseBtn:setTag(2)
			gt.addBtnPressedListener(refuseBtn, handler(self, self.buttonClickEvt))

			-- 倒计时初始化
			self.dimissTimeCD = msgTbl.m_time
			local dismissTimeCDLabel = gt.seekNodeByName(self.rootNode, "Label_dismissCD")
			dismissTimeCDLabel:setString(tostring(self.dimissTimeCD))
		end
		gt.seekNodeByName(self.rootNode, "Btn_agree"):setVisible(true)
		gt.seekNodeByName(self.rootNode, "Btn_refuse"):setVisible(true)
		local contentLabel = gt.seekNodeByName(self.rootNode, "Label_content")
		local contentString = ""
		if msgTbl.m_flag == 0 then
			-- 等待同意或者拒绝
			contentString = gt.getLocationString("LTKey_0022", msgTbl.m_apply)
		else
			-- 已经同意或者拒绝
			contentString = gt.getLocationString("LTKey_0023", msgTbl.m_apply)

			-- 隐藏操作按钮
			local agreeBtn = gt.seekNodeByName(self.rootNode, "Btn_agree")
			local refuseBtn = gt.seekNodeByName(self.rootNode, "Btn_refuse")
			agreeBtn:setVisible(false)
			refuseBtn:setVisible(false)
		end
		for _, v in ipairs(msgTbl.m_agree) do
			if v ~= msgTbl.m_apply then
				contentString = contentString .. gt.getLocationString("LTKey_0025", v)
			end
		end
		for _, v in ipairs(msgTbl.m_wait) do
			contentString = contentString .. gt.getLocationString("LTKey_0024", v)
		end
		contentLabel:setString(contentString)
	elseif msgTbl.m_errorCode == 2 then
		if not gt.isInReview then

            if table.contains({103, 107, 115, 118, 120}, gt.roomState) then
				-- 二个人同意，解散成功
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
					gt.getLocationString("LTKey_0027_1", unpack(msgTbl.m_agree)),
					function()
						self:setVisible(false)
					end, nil, true)

			else
				-- 三个人同意，解散成功
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
					gt.getLocationString("LTKey_0027", unpack(msgTbl.m_agree)),
					function()
						self:setVisible(false)
					end, nil, true)
			end

			
		end
		
	elseif msgTbl.m_errorCode == 3 then
		if not gt.isInReview then
			-- 时间到，解散成功
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
				gt.getLocationString("LTKey_0044"),
				function()
					self:setVisible(false)
				end, nil, true)
		end
		
	elseif msgTbl.m_errorCode == 4 then
		-- if self:isVisible() == true then
		-- 	gt.log("m_errorCode == 4 and return...")
		-- 	return
		-- end
		if not gt.isInReview then
			-- 有一个人拒绝，解散失败
			gt.log("有一个人拒绝，解散失败...")
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
				gt.getLocationString("LTKey_0026", msgTbl.m_refuse),
				function()
					if not self.rootNode then
						self:setVisible(false)
					else
						local agreeBtn = gt.seekNodeByName(self.rootNode, "Btn_agree")
						if not agreeBtn:isVisible() then
							self:setVisible(false)
						end
					end
				end, nil, true)
		end
		
	end

	self:setVisible(true)
	
	if gt.isIOSPlatform() and gt.isInReview then
		self:setVisible(false)
	end

	if msgTbl.m_errorCode ~= 0 then
		if self.rootNode then
			self.rootNode:removeFromParent()
			self.rootNode = nil
		end
	end
end

function ApplyDismissRoom:buttonClickEvt(sender)
	local agreeBtn = gt.seekNodeByName(self.rootNode, "Btn_agree")
	local refuseBtn = gt.seekNodeByName(self.rootNode, "Btn_refuse")
	agreeBtn:setVisible(false)
	refuseBtn:setVisible(false)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_APPLY_DISMISS
	msgToSend.m_pos = self.playerSeatIdx - 1
	msgToSend.m_flag = sender:getTag()
	gt.socketClient:sendMessage(msgToSend)
end

return ApplyDismissRoom

