
local gt = cc.exports.gt

local FriendEvaluation = class("FriendEvaluation", function()
	return cc.Layer:create()
end)

function FriendEvaluation:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("FriendEvaluation.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Sprite_bg"):setScaleY(1280/960)
		-- gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	self.historyListVw = gt.seekNodeByName(self.rootNode, "ListVw_content")

	-- 战绩标题
	local titleRoomNode = gt.seekNodeByName(csbNode, "Node_titleRoom")
	titleRoomNode:setVisible(true)

	local emptyLabel = gt.seekNodeByName(self.rootNode, "Text_xy")
	emptyLabel:setVisible(false)

	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		
		-- 移除消息回调
		gt.socketClient:unregisterMsgListener(gt.GC_CREHIS)
		gt.socketClient:unregisterMsgListener(gt.GC_GTU)

		-- 移除界面,返回主界面
		self:removeFromParent()
	end)

	-- 帮助按钮
	local Btn_help = gt.seekNodeByName(csbNode, "Btn_help")
	gt.addBtnPressedListener(Btn_help, function()
		require("app/views/zanHelpScene"):create()
	end)

	self.playerHeadMgr = require("app/PlayerHeadManager"):create()
	csbNode:addChild(self.playerHeadMgr)

	-- 发送请求战绩消息
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_CREHIS
	msgToSend.m_time = 0
	msgToSend.m_userId = tonumber(gt.m_id)
	gt.log("===" .. gt.m_id)
	gt.socketClient:sendMessage(msgToSend)
	self.tag = 1

	-- 注册消息回调
	gt.socketClient:registerMsgListener(gt.GC_CREHIS, self, self.onRcvFriendEvaluation)
	gt.socketClient:registerMsgListener(gt.GC_GTU, self, self.onRcvReplay)
end


function FriendEvaluation:onNodeEvent(eventName)
	if "enter" == eventName then
		-- 触摸事件
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		-- 移除触摸事件
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function FriendEvaluation:onTouchBegan(touch, event)
	return true
end

function FriendEvaluation:onRcvFriendEvaluation(msgTbl)
	gt.log("444'''===")
	dump(msgTbl)
	if msgTbl == nil then
		return
	end

	-- 显示战绩列表
	self.historyListVw:setTouchEnabled(true)

	if #msgTbl.m_record == 0 then
		local emptyLabel = gt.seekNodeByName(self.rootNode, "Text_xy")
		emptyLabel:setVisible(true)
	else
		self.m_record 	= msgTbl.m_record
		self.m_info		= msgTbl.m_info

		for i, cellData in ipairs(msgTbl.m_record) do
			local historyItem = self:createHistoryItem( i, cellData )
			self.historyListVw:pushBackCustomItem(historyItem)
		end
	end
	
end

function FriendEvaluation:onRcvReplay(msgTbl)
	gt.dump(msgTbl)
	table.remove(self.m_record, msgTbl.m_index)
	self.historyListVw:removeAllItems()
	self.playerHeadMgr:detachAll()
	for i, cellData in ipairs(self.m_record) do
		local historyItem = self:createHistoryItem( i, cellData )
		self.historyListVw:pushBackCustomItem(historyItem)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 创建战绩条目
-- @param cellData 条目数据
-- end --
function FriendEvaluation:createHistoryItem(index,cellData)
 	require("json")
	cellData = json.decode(cellData)
	local cellNode = cc.CSLoader:createNode("FriendEvaluationCell.csb")

	-- 序号
	local numLabel = gt.seekNodeByName(cellNode, "Label_num")
	numLabel:setString(tostring(index))
	gt.log("self.tag = "..index)
	-- 房间号
	local roomIDLabel = gt.seekNodeByName(cellNode, "Label_roomID")
	roomIDLabel:setString(gt.getLocationString("LTKey_0039", cellData.DeskId))
	-- 对战时间
	local timeLabel = gt.seekNodeByName(cellNode, "Label_time")
	local timeTbl = os.date("*t", cellData.Time)
	if tonumber(timeTbl.min) < 10 and tonumber(timeTbl.sec) < 10 then
		timeLabel:setString(gt.getLocationString("LTKey_0051", timeTbl.year, timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min, timeTbl.sec))
	elseif tonumber(timeTbl.min) < 10 and tonumber(timeTbl.sec) >= 10 then
		timeLabel:setString(gt.getLocationString("LTKey_0052", timeTbl.year, timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min, timeTbl.sec))
	elseif tonumber(timeTbl.min) >= 10 and tonumber(timeTbl.sec) < 10 then
		timeLabel:setString(gt.getLocationString("LTKey_0053", timeTbl.year, timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min, timeTbl.sec))
	else
		timeLabel:setString(gt.getLocationString("LTKey_0040", timeTbl.year, timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min, timeTbl.sec))
	end
	-- 玩家昵称+分数
	local num = #self.m_info
	for i=1,4 do
		local Node_playInfo = gt.seekNodeByName(cellNode, "Node_playInfo" .. i)
		Node_playInfo:setVisible(false)
	end

	local index1 = 1
	for i=1,4 do
		local Node_playInfo = gt.seekNodeByName(cellNode, "Node_playInfo" .. index1)
		if cellData.User[i] ~= gt.m_id and cellData.User[i] ~= 0 then
			Node_playInfo:setVisible(true)
			local ChkBox1 = gt.seekNodeByName(Node_playInfo, "ChkBox1")
			ChkBox1:setSelected(true)
			for j=1,num do
				if self.m_info[j][1] == cellData.User[i] then
					Node_playInfo.tag = cellData.User[i]
					local nicknameLabel = gt.seekNodeByName(Node_playInfo, "Label_Name")
					nicknameLabel:setString(gt.checkName(self.m_info[j][2]))
					local headSpr = gt.seekNodeByName(Node_playInfo, "Spr_head")
					local face = string.sub(self.m_info[j][3], 1, string.lastString(self.m_info[j][3], "/")) .. "96"
					self.playerHeadMgr:attach(headSpr, self.m_info[j][1], face,self.m_info[j][4])
					break
				end
			end
			index1 = index1 + 1
		end
	end

	local backBtn = gt.seekNodeByName(cellNode, "Btn_ok")
	gt.addBtnPressedListener(backBtn, function()
		local playInfo = {}
		for i=1,4 do
			local Node_playInfo = gt.seekNodeByName(cellNode, "Node_playInfo" .. i)

			local ChkBox1 = gt.seekNodeByName(Node_playInfo, "ChkBox1")
			if ChkBox1:isSelected()  then
				table.insert( playInfo, Node_playInfo.tag )
			end
		end
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_GTU
		msgToSend.m_userId = tonumber(gt.m_id)
		msgToSend.m_onelog = self.m_record[index]
		msgToSend.m_userList = playInfo
		msgToSend.m_index = index
		gt.log("===" .. gt.m_id)
		dump( msgToSend )
		gt.socketClient:sendMessage(msgToSend)

		backBtn:setEnabled(false)
	end)

	local cellSize = cellNode:getContentSize()
	local cellItem = ccui.Widget:create()
	cellItem:setTag(index)
	cellItem:setTouchEnabled(true)
	cellItem:setContentSize(cellSize)
	cellItem:addChild(cellNode)
	return cellItem
end

return FriendEvaluation

