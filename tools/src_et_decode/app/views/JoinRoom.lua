
local gt = cc.exports.gt

local JoinRoom = class("JoinRoom", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function JoinRoom:ctor(callback)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("JoinRoom.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end
	self:addChild(csbNode)
	self.csbNode = csbNode

	-- 最大输入6个数字
	self.inputMaxCount = 6
	-- 数字文本
	self.inputNumLabels = {}
	self.curInputIdx = 1
	for i = 1, self.inputMaxCount do
		local numLabel = gt.seekNodeByName(csbNode, "Label_num_" .. i)
		numLabel:setString("")
		self.inputNumLabels[i] = numLabel
	end

	-- 数字按键
	for i = 0, 9 do
		local numBtn = gt.seekNodeByName(csbNode, "Btn_num_" .. i)  --遍历数字按键
		numBtn:setTag(i)  --设置标记为0-9
		numBtn:addClickEventListener(handler(self, self.numBtnPressed))  --添加点击事件
	end

	-- 重置按键
	local resetBtn = gt.seekNodeByName(csbNode, "Btn_reset")
	resetBtn:addClickEventListener(handler(self, self.resetPressed))

   -- 删除按键
	local delBtn = gt.seekNodeByName(csbNode, "Btn_del")
	delBtn:addClickEventListener(handler(self, self.delPressed))

	-- -- 关闭按键
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(closeBtn, function()
		callback()
		self:removeFromParent()
	end)

	gt.socketClient:registerMsgListener(gt.GC_JOIN_ROOM, self, self.onRcvJoinRoom)
end

function JoinRoom:resetPressed( senderBtn )
	-- body
	for i = self.inputMaxCount, 1 , -1 do
		local numLabel = gt.seekNodeByName(self.csbNode, "Label_num_" .. i)
		numLabel:setString("")
	end
	self.curInputIdx = 1  --光标设置在第一位
end

function JoinRoom:delPressed( senderBtn )
	-- body
	for i = self.curInputIdx - 1, 1 , -1 do	
		if self.curInputIdx - 1  >= 1 then
			local numLabel = gt.seekNodeByName(self.csbNode, "Label_num_" .. i)
			numLabel:setString("")
			self.curInputIdx = self.curInputIdx - 1
		end
		break
	end
end

function JoinRoom:numBtnPressed(senderBtn)
	local btnTag = senderBtn:getTag()
	local numLabel = self.inputNumLabels[self.curInputIdx]
	numLabel:setString(tostring(btnTag))
	if self.curInputIdx >= #self.inputNumLabels then
		local roomID = 0
		local tmpAry = {100000, 10000, 1000, 100, 10, 1}
		for i = 1, self.inputMaxCount do
			local inputNum = tonumber(self.inputNumLabels[i]:getString())
			roomID = roomID + inputNum * tmpAry[i]
		end
		-- 发送进入房间消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_JOIN_ROOM
		msgToSend.m_deskId = roomID
		gt.socketClient:sendMessage(msgToSend)

		gt.showLoadingTips(gt.getLocationString("LTKey_0006"))
	end
	self.curInputIdx = self.curInputIdx + 1
end

function JoinRoom:onRcvJoinRoom(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		-- 进入房间失败
		gt.removeLoadingTips()
		if msgTbl.m_errorCode == 1 then
			-- 房间人已满
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0018"), nil, nil, true)
		elseif msgTbl.m_errorCode == 6 then
			-- 房间不存在
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "点赞数不够", nil, nil, true)
		else
			-- 房间不存在
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0015"), nil, nil, true)
		end

		self.curInputIdx = 1
		for i = 1, self.inputMaxCount do
			local numLabel = self.inputNumLabels[i]
			numLabel:setString("")
		end
	end
end

function JoinRoom:onNodeEvent(eventName)
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

function JoinRoom:onTouchBegan(touch, event)
	return true
end

function JoinRoom:onTouchEnded(touch, event)
	self:removeFromParent()
end

return JoinRoom

