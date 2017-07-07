
local gt = cc.exports.gt

local HistoryRecord = class("HistoryRecord", function()
	return cc.Layer:create()
end)

function HistoryRecord:ctor(uid)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("HistoryRecord.csb")
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

	-- 无战绩提示
	local emptyLabel = gt.seekNodeByName(csbNode, "Label_empty")
	emptyLabel:setVisible(false)
	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		
		if self.historyListVw:isVisible() then
			-- 移除消息回调
			gt.socketClient:unregisterMsgListener(gt.GC_HISTORY_RECORD)
			gt.socketClient:unregisterMsgListener(gt.GC_REPLAY)

			-- 移除界面,返回主界面
			self:removeFromParent()
            gt.GM_simulate_uid = nil -- 移除GM模拟id
		else
			-- 隐藏详细信息
			local titleRoomNode = gt.seekNodeByName(csbNode, "Node_titleRoom")
			titleRoomNode:setVisible(true)
			self.historyListVw:setVisible(true)
			local historyDetailNode = gt.seekNodeByName(self.rootNode, "Node_historyDetail")
			historyDetailNode:removeAllChildren()
		end
	end)

	-- 发送请求战绩消息
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_HISTORY_RECORD
	msgToSend.m_time = 0
	if gt.isGM == 1 then
		msgToSend.m_userId = tonumber(uid)
        gt.GM_simulate_uid = tonumber(uid) -- gm模拟的用户id
	end
	self.uid  = uid
	--gt.log("===" .. uid)
	gt.socketClient:sendMessage(msgToSend)
	self.tag = 1
	self.historyMsgTbl = {}

	-- 注册消息回调
	gt.socketClient:registerMsgListener(gt.GC_HISTORY_RECORD, self, self.onRcvHistoryRecord)
	gt.socketClient:registerMsgListener(gt.GC_REPLAY, self, self.onRcvReplay)
	gt.socketClient:registerMsgListener(gt.GC_S_ROOM_LOG , self, self.onRoomInfo)
end


function HistoryRecord:onNodeEvent(eventName)
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


function HistoryRecord:onTouchBegan(touch, event)
	return true
end

function HistoryRecord:onRcvHistoryRecord(msgTbl)
	gt.log("444'''===")
	dump(msgTbl)
	if msgTbl == nil then
		return
	end
	if #self.historyMsgTbl == 0 and #msgTbl.m_data == 0 then
		-- 没有战绩
		local emptyLabel = gt.seekNodeByName(self.rootNode, "Label_empty")
		emptyLabel:setVisible(true)
	else
		-- 显示战绩列表
		self.historyListVw:setTouchEnabled(true)
		self.historyListVw:addEventListener(function ( sender, eventType )
			gt.log("进入listview回调"..sender:getInnerContainerPosition().y)
			if sender:getInnerContainerPosition().y > -5 then
				gt.log("滑至最底部")
				if #msgTbl.m_data == 10 then
					-- 发送请求战绩消息
					self.listPos = sender:getInnerContainerPosition().y
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_HISTORY_RECORD
					msgToSend.m_time = msgTbl.m_data[10].m_time
					if gt.isGM == 1 then
						msgToSend.m_userId = tonumber(self.uid)
					end
					gt.socketClient:sendMessage(msgToSend)
					dump(msgToSend)
					sender:setTouchEnabled(false)
				end
			end
		end)
		for i, cellData in ipairs(msgTbl.m_data) do
			local historyItem = self:createHistoryItem(cellData)
			self.historyListVw:pushBackCustomItem(historyItem)
			table.insert(self.historyMsgTbl,cellData)
		end

		if self.listPos then
			self.historyListVw:jumpToPercentVertical((self.tag-#msgTbl.m_data)/self.tag*100)
		end
		
		dump(self.historyMsgTbl)
	end
end

function HistoryRecord:onRcvReplay(msgTbl)
	gt.dump(msgTbl)
	gt.log("self.data_num = "..self.data_num)
	if self.data_num ~= 0 then
		local contentListVw = gt.seekNodeByName(self.detailPanel, "ListVw_content")
		contentListVw:getChildByTag(self.data_num):getChildByTag(self.data_num):getChildByTag(self.data_num):setTouchEnabled(true)
	end
	local replayLayer = require("app/views/ReplayLayer"):create(msgTbl)
	self:addChild(replayLayer, 6)
end

-- start --
--------------------------------
-- @class function
-- @description 创建战绩条目
-- @param cellData 条目数据
-- end --
function HistoryRecord:createHistoryItem(cellData)
	local cellNode = cc.CSLoader:createNode("HistoryCell.csb")

	-- 序号
	local numLabel = gt.seekNodeByName(cellNode, "Label_num")
	numLabel:setString(tostring(self.tag))
	gt.log("self.tag = "..self.tag)
	-- 房间号
	local roomIDLabel = gt.seekNodeByName(cellNode, "Label_roomID")
	roomIDLabel:setString(gt.getLocationString("LTKey_0039", cellData.m_deskId))
	-- 对战时间
	local timeLabel = gt.seekNodeByName(cellNode, "Label_time")
	local timeTbl = os.date("*t", cellData.m_time)
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
	for i, v in ipairs(cellData.m_nike) do
		local nicknameLabel = gt.seekNodeByName(cellNode, "Label_nickname_" .. i)
		if v then
			v = gt.checkName(v)
			nicknameLabel:setString(v)
		end
		local scoreLabel = gt.seekNodeByName(cellNode, "Label_score_" .. i)
		if tostring(cellData.m_score[i]) then
			scoreLabel:setString(tostring(cellData.m_score[i]))
		end
		if cellData.m_flag == 103 or cellData.m_flag == 107 or cellData.m_flag == 115 or cellData.m_flag == 118 then
			local Label_score_4 = gt.seekNodeByName(cellNode, "Label_score_4")
			local Label_nickname_4 = gt.seekNodeByName(cellNode, "Label_nickname_4")
			Label_nickname_4:setVisible(false)
			Label_score_4:setVisible(false)
        elseif cellData.m_flag == 120 then
            gt.findNodeArray(cellNode, "Label_score_#3#4", "Label_nickname_#3#4"):setVisible(false)
		end
	end

	local cellSize = cellNode:getContentSize()
	local cellItem = ccui.Widget:create()
	cellItem:setTag(self.tag)
	cellItem:setTouchEnabled(true)
	cellItem:setContentSize(cellSize)
	cellItem:addChild(cellNode)

	cellItem:addClickEventListener(handler(self, self.historyItemClick))
	self.tag = self.tag + 1
	return cellItem
end

--单局录像返回
function HistoryRecord:onRoomInfo(msgTbl)
	-- body
	dump(msgTbl)
	self:historyItemClickEvent(msgTbl)
	gt.log("888888===")
end

function HistoryRecord:historyItemClick(sender, eventType)
	print("----------------------")
	print("sender:",sender:getTag())
	print("eventType:",eventType)
	self.itemTag = sender:getTag()
	self.cellData = self.historyMsgTbl[self.itemTag]

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_S_ROOM_LOG
	msgToSend.m_deskId = self.cellData.m_deskId
	msgToSend.m_pos = self.cellData.m_userid[1]
	msgToSend.m_time = self.cellData.m_time
	msgToSend.m_userId = 1
	dump(msgToSend)
	gt.socketClient:sendMessage(msgToSend)

end
function HistoryRecord:historyItemClickEvent(msgTbl)
	-- 隐藏历史记录
	self.historyListVw:setVisible(false)
	-- 切换标题
	local titleRoomNode = gt.seekNodeByName(self.rootNode, "Node_titleRoom")
	titleRoomNode:setVisible(true)
	
	local historyDetailNode = gt.seekNodeByName(self.rootNode, "Node_historyDetail")
	local detailPanel = cc.CSLoader:createNode("HistoryDetail.csb")
	detailPanel:setAnchorPoint(0.5, 0.5)
	historyDetailNode:addChild(detailPanel)
	self.detailPanel = detailPanel


	-- 玩家昵称
	for i, v in ipairs(self.cellData.m_nike) do
		local nicknameLabel = gt.seekNodeByName(detailPanel, "Label_nickname_" .. i)
		nicknameLabel:setString(v)
	end
	dump(msgTbl)
	gt.log("kkkkk==")
	-- 对应详细记录信息
	local contentListVw = gt.seekNodeByName(detailPanel, "ListVw_content")
	
	for i, v in pairs(msgTbl.m_data) do
		dump(v)
		gt.log("888--")
		local detailCellNode = cc.CSLoader:createNode("HistoryDetailCell.csb")
		detailCellNode:setTag(i)
		local bg1 = gt.seekNodeByName(detailCellNode,"Image_bg1")
		local bg2 = gt.seekNodeByName(detailCellNode,"Image_bg2")
		
		if i%2 == 0 then
			bg1:setVisible(false)
			bg2:setVisible(true)
		else
			bg1:setVisible(true)
			bg2:setVisible(false)
		end

		-- 序号
		local numLabel = gt.seekNodeByName(detailCellNode, "Label_num")
		numLabel:setString(tostring(i))
		-- 对战时间
		local timeLabel = gt.seekNodeByName(detailCellNode, "Label_time")
		local timeTbl = os.date("*t", v.m_time)
		if tonumber(timeTbl.min) < 10 then
			timeLabel:setString(string.format("%d-%d %d:0%d", timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min))
		else
			timeLabel:setString(string.format("%d-%d %d:%d", timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min))
		end
		-- 对战分数
		
		for j, score in ipairs(v.m_score) do
			local scoreLabel = gt.seekNodeByName(detailCellNode, "Label_score_" .. j)
			if score then
				scoreLabel:setString(tostring(score))
			end
		end

		-- 查牌按钮
		local replayBtn = gt.seekNodeByName(detailCellNode, "Btn_replay")
		replayBtn:setTouchEnabled(true)

		replayBtn.videoId = v.m_videoId
		replayBtn:setTag(i)
		self.data_num = 0
		
		gt.addBtnPressedListener(replayBtn, function(sender)
			sender:setTouchEnabled(false)
			self.data_num = sender:getTag()
			gt.log("sender:getTouchEnabled()")
			local btnTag = sender.videoId
			-- 请求打牌回放数据
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_REPLAY
			msgToSend.m_videoId = btnTag
			gt.socketClient:sendMessage(msgToSend)
		end)

		local cellSize = detailCellNode:getContentSize()
		local detailItem = ccui.Widget:create()
		detailItem:setContentSize(cellSize)
		detailItem:addChild(detailCellNode)
		detailItem:setTag(i)
		contentListVw:pushBackCustomItem(detailItem)

		if msgTbl.m_flag == 103 or msgTbl.m_flag == 107 or msgTbl.m_flag == 115 or msgTbl.m_flag == 118 then
			local Label_score_4 = gt.seekNodeByName(detailCellNode, "Label_score_4")
			Label_score_4:setVisible(false)
        elseif msgTbl.m_flag == 120 then
            gt.findNodeArray(detailCellNode, "Label_score_#3#4"):setVisible(false)
		end

	end

end

return HistoryRecord

