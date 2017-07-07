local gt = cc.exports.gt
local GIFT_ID = {
	{label = "ipad",name = "ipad"},
	{label = "小米手机",name = "phone"},
	{label = "华为智能手表",name = "shoubiao"},
	{label = "便携迷你影响",name = "gbl"},
	{label = "运动书包",name = "back"},
	{label = "小米充电宝",name = "other"},
	{label = "小米运动手环",name = "shouhuan"},
	{label = "10000金币"},
	{label = "2张房卡"},
	{label = "1张房卡"},
	{label = "再接再厉"},
}

local numConfig = {50,80,150,250,400,600,800}
-- local numConfig = {2,4,6,8,10,12,14}
local texturePicConf = {1,2,3,4,3,2,1} -- activitydb_4_1_btnpic.png


local ActivityDragonBoat = class("ActivityDragonBoat",function() 
	local maskLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 180), gt.winSize.width, gt.winSize.height)
	local function onTouchBegan(touch, event)
		return true
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	local eventDispatcher = maskLayer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, maskLayer)
	return maskLayer
 end)

function ActivityDragonBoat.isOpen()
	if cc.FileUtils:getInstance():isFileExist("ActivityDragonBoat.csb") and 
		cc.FileUtils:getInstance():isFileExist("images/ActivityDragonBoat.png") 
		then
		return true
	end

	return false
end

function ActivityDragonBoat:ctor( data )
	self.data = data
	-- gt.log("self.data ========= "..self.data.m_nHaveTel)
	local csbfile = "ActivityDragonBoat.csb"
	local csbNode = cc.CSLoader:createNode(csbfile)
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end

	self.csbNode = csbNode

	self:loadControls()

	--注册抽奖结果返回消息
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_REPLY_DRAW, self, self.onRecvRetGetLottery)
	--提交手机号返回结果
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_WRITE_PHONE, self, self.onRecvSavePhoneNum)

	self:registerScriptHandler(handler(self, self.onNodeEvent))
end

function ActivityDragonBoat:loadControls()
	local finishRoundNum = self.data.m_nGameOverCount or 0
	gt.log("m_nGameOverCount ====================== "..self.data.m_nGameOverCount)
	self.data.m_vecMyOpenGiftRecordList =  self.data.m_vecMyOpenGiftRecordList or {}
	self.data.m_vecUserGiftRecordList = self.data.m_winUsers or {}
	self.data.m_btnsState = self.data.m_btnsState or {}


	local giftdata = self.data.m_vecMyOpenGiftRecordList
	-- self.data.user_open_gift_record = self.data.user_open_gift_record or {}
	self.root = gt.seekNodeByName(self.csbNode, "root")
	local closeBtn = gt.seekNodeByName(self.root, "Btn_close")
	local function closeFunc()
		self:hide()
	end
	gt.addBtnPressedListener(closeBtn, closeFunc)

	self.phoneNumPage = gt.seekNodeByName(self.root, "Panel_1")
	-- self.phoneNumPage:setVisible(true)
	local closePageBtn = gt.seekNodeByName(self.root, "Btn_close_Num")
	local sendNumBtn = gt.seekNodeByName(self.root, "Btn_sendNum")
	local phoneNumEditBox =  gt.seekNodeByName(self.phoneNumPage,"inputBox")
	local function sendPhoneNumFunc()
		local phoneNumStr = phoneNumEditBox:getString()
		local phoneNum = tonumber(phoneNumStr)
		gt.log("phoneNum ================ ",phoneNum)
		if phoneNum and #phoneNumStr == 11 then
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_ACTIVITY_WRITE_PHONE
			msgToSend.m_AutoId = self.giftAutoId
			msgToSend.m_PhoneNum = phoneNumStr
			gt.socketClient:sendMessage(msgToSend)
			gt.showLoadingTips("正在提交手机号...")
		else
			require("app/views/NoticeTips"):create("提示", "请输入正确的手机号！", nil, nil, true)
		end
	end
	gt.addBtnPressedListener(sendNumBtn, sendPhoneNumFunc)

	local function closePhonePage()
		self.phoneNumPage:setVisible(false)
	end
	gt.addBtnPressedListener(closePageBtn, closePhonePage)

	local finishNumLabel = gt.seekNodeByName(self.root, "finishText")
	local showNum = finishRoundNum
	if showNum > 800 then
		showNum = 800
	end
	 
	finishNumLabel:setString("("..showNum.."/800)")

	local shouldShowPro = 0
	local procentPro = 0
	for i=7,1,-1 do
		if finishRoundNum >= numConfig[i] then
			shouldShowPro = i
			if i == 7 then
				break
			end
			procentPro = finishRoundNum - numConfig[i]
			procentPro = procentPro/(numConfig[i+1] - numConfig[i])*100
			break
		end
	end

	-- init gift info list 
	local infoList = gt.seekNodeByName(self.root, "infoList")
	infoList:setScrollBarEnabled(false)
	infoList:setItemsMargin(10)
	local scrollVwSize = infoList:getContentSize()
	local user_gift_list = self.data.m_vecUserGiftRecordList
	-- gt.log("user_gift_list ==================== "..user_gift_list[1][1].."    "..GIFT_ID[user_gift_list[1][2]].label)
	local haveGiftUserInfo = #user_gift_list
	for i=1,haveGiftUserInfo do
		--text = "玩家:" .. gt.lotteryInfoTab.m_winUsers[i][1] .. "		" .. gt.lotteryInfoTab.m_winUsers[i][2]
		-- gt.log("================= ","玩家:" .. ".."..user_gift_list[i][1] .. " " .. "获得"..GIFT_ID[user_gift_list[i][2]].label)
		local text = "玩家:" ..user_gift_list[i][1] .. " " .. "获得"..user_gift_list[i][2]
		
		local agreementLabel = gt.createTTFLabel(text, 24)
		agreementLabel:setAnchorPoint(0,0)
		agreementLabel:setColor(cc.c3b(255,255,255))
		-- agreementLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
		--agreementLabel:setWidth(scrollVwSize.width)

		local cellSize = agreementLabel:getContentSize()
		local cellItem = ccui.Widget:create()
		cellItem:setTouchEnabled(true)
		cellItem:setContentSize(cellSize)
		cellItem:addChild(agreementLabel)

		infoList:pushBackCustomItem(cellItem)
	end
	infoList:jumpToTop()
	-- infoList:setTouchEnabled(false)
	infoList:scrollToBottom(haveGiftUserInfo,false)

	self.dumplingsVector = {}
	self.targetNumNodeVector = {}
	self.loadingbarVector = {}
	self.giftVector = {}
	for i=1,7 do
		-- 解析粽子按钮
		local button = gt.seekNodeByName(self.root, "Button_"..i)
		button.tagNum = i
		self.dumplingsVector[i] = button
		gt.addBtnPressedListener(button, function() 
			self:btnEventCallBack(i)
		end)
		-- :loadTex
		gt.log("self.data.m_vecMyOpenGiftRecordList[i][2] =========== ",self.data.m_btnsState[i][2])
    -- Btn_Type:loadTextures("creatroom1.png", "creatroom2.png", "creatroom2.png",ccui.TextureResType.plistType)
		-- local texturePicConf = {1,2,3,4,3,2,1} -- activitydb_4_1_btnpic.png
		local nameConfig = "activitydb_"..texturePicConf[i].."_1_btnpic.png"
		if not (self.data.m_btnsState[i][2] ~= 0 and self.data.m_btnsState[i][2] ~= 2)  then
			button:loadTextures(nameConfig, nameConfig, nameConfig,ccui.TextureResType.plistType)
		end
		-- true 可点击 false 不可点击
		-- button:setTouchEnabled(self.data.m_btnsState[i][2] ~= 0 and self.data.m_btnsState[i][2] ~= 2 )
		-- button:setBright(self.data.m_btnsState[i][2] ~= 0 and self.data.m_btnsState[i][2] ~= 2)
		-- 解析数字节点
		local numNode = gt.seekNodeByName(self.root, "pro"..i)
		self.targetNumNodeVector[i] = numNode
		local lightNum = gt.seekNodeByName(numNode, "onNum")

		lightNum:setVisible(shouldShowPro >= i)

		-- 解析进度条
		local aPro = gt.seekNodeByName(self.root, "LoadingBar_"..i)
		if aPro then
			self.loadingbarVector[i] = aPro
			if i < shouldShowPro then
				aPro:setVisible(true)
				aPro:setPercent(100)
			elseif i == shouldShowPro then
				aPro:setVisible(true)
				aPro:setPercent(procentPro)
			else
				aPro:setVisible(false)
			end
		end

		-- 解析礼物列表
		local aGift = gt.seekNodeByName(self.root, "Sprite_"..i)
		self.giftVector[i] = aGift
		local giftBtn = gt.seekNodeByName(aGift, "giftButton")
		gt.addBtnPressedListener(giftBtn, function(  )
			-- body
			if self.data and self.data.m_vecMyOpenGiftRecordList[i][9] ~= "" then
				require("app/views/NoticeTips"):create("提示", "您已经填写过手机号！", nil, nil, true)
			else
				gt.log("请输入手机号！")
				-- require("app/views/NoticeTips"):create("提示", "请输入手机号！", nil, nil, true)
				local giftindex = self.data.m_vecMyOpenGiftRecordList[i][6]
				self.giftAutoId = self.data.m_vecMyOpenGiftRecordList[i][1]
				self.clickRealThingIndex = i
				self:showGiftInfo( giftindex ,self.data.m_vecMyOpenGiftRecordList[i][5])
			end
		end)
		local giftCount = #giftdata
		if giftCount >= i then
			aGift:setVisible(true)
			local giftThing = gt.seekNodeByName(aGift,"thing")
			giftThing:setSpriteFrame("activitydb_ipadpic.png")
		else
			aGift:setVisible(false)
		end
	end 
end

function ActivityDragonBoat:onRecvSavePhoneNum(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_errorCode == 0 then
		require("app/views/NoticeTips"):create("提示", "手机号提交成功!活动结束后实物奖励将统一发放！", nil, nil, true)
		-- self.data.m_nHaveTel = 1
		self.data.m_vecMyOpenGiftRecordList[self.clickRealThingIndex][9] = "111"
	else
		require("app/views/NoticeTips"):create("提示", "手机号提交失败！\n请输入正确的手机号确保奖品能准确发放！", nil, nil, true)
	end
	gt.removeLoadingTips()
	-- gt.seekNodeByName(self, "Image_lbt"):setVisible(true)
	-- gt.seekNodeByName(self, "ScrollVw_agreement"):setVisible(true)
	-- self:setAllVisible()
	gt.lotteryInfoTab.m_NeedPhoneNum = 0
end

function ActivityDragonBoat:onRecvRetGetLottery(msgTbl)
	
	-- gt.log("errorCode = " .. msgTbl.m_errorCode
	-- 	.. ", data = " .. msgTbl.m_date
	-- 	.. ", rewardId = " .. msgTbl.m_RewardID
	-- 	.. ", m_NeedPhoneNum = " .. msgTbl.m_NeedPhoneNum)
	gt.dump(msgTbl)
	if msgTbl.m_errorCode == 0 then
		gt.lotteryInfoTab	=  gt.lotteryInfoTab or {}
		-- require("app/views/NoticeTips"):create("提示", "抽奖成功", nil, nil, true)
		-- gt.NoticeTips:onShow("提示", "抽奖成功", nil, nil, true)
		gt.lotteryInfoTab.m_LastJoinDate = msgTbl.m_AutoId
		gt.lotteryInfoTab.m_NeedPhoneNum = msgTbl.m_NeedPhoneNum
		gt.lotteryInfoTab.m_GiftName = msgTbl.m_GiftName
		gt.lotteryInfoTab.m_GiftType = msgTbl.m_GiftType
		gt.lotteryInfoTab.m_LastGiftState = 1
		-- self:start(gt.lotteryInfoTab.m_RewardID)
		self:showGiftInfo(gt.lotteryInfoTab.m_GiftType , gt.lotteryInfoTab.m_GiftName)
		gt.removeLoadingTips()


		self.clickIndex = self.clickIndex or 1
		local button = gt.seekNodeByName(self.root, "Button_"..self.clickIndex)
		-- button:setTouchEnabled(false)
		-- button:setBright(false)
		local nameConfig = "activitydb_"..texturePicConf[self.clickIndex].."_1_btnpic.png"
		
		button:loadTextures(nameConfig, nameConfig, nameConfig,ccui.TextureResType.plistType)
		self.data.m_btnsState[self.clickIndex][2] = 2
		local totalNum = 0
		for _key,aBtnStatus in ipairs(self.data.m_btnsState) do
			if aBtnStatus[2] == 1 then
				totalNum = totalNum + 1
			end
		end
		gt.log("totalNum ================== ",totalNum)
		gt.m_dragonBoatActivityPointNum = totalNum
		if totalNum == 0 and gt.dragonActRedPoint then
			gt.dragonActRedPoint:setVisible(false)
		end

		if gt.lotteryInfoTab.m_GiftType == 4 then
			local agiftInfo = {}
			agiftInfo[1] = self.clickTarget
			agiftInfo[2] = self.clickIndex
			table.insert(self.data.m_vecMyOpenGiftRecordList,agiftInfo)
		end

		self:showGiftOnGiftList()
	else
		require("app/views/NoticeTips"):create("提示", "抽奖失败", nil, nil, true)
		gt.removeLoadingTips()
	end
end

function ActivityDragonBoat:showGiftOnGiftList()
	local giftdata = self.data.m_vecMyOpenGiftRecordList
	local giftCount = #giftdata
	for i=1,7 do
		local aGift = gt.seekNodeByName(self.root, "Sprite_"..i)
		if giftCount >= i then
			aGift:setVisible(true)
			local giftThing = gt.seekNodeByName(aGift,"thing")
			giftThing:setSpriteFrame("activitydb_".. "ipad".."pic.png")
		else
			aGift:setVisible(false)
		end
	end
end

function ActivityDragonBoat:showGiftInfo( giftindex ,giftName)
	-- local giftInfoConf = GIFT_ID[giftindex]
	-- local giftInfoConf = GIFT_ID[giftindex]

	if giftindex == 4 then
		local giftText = gt.seekNodeByName(self.phoneNumPage,"giftText")
		local giftSprite = gt.seekNodeByName(self.phoneNumPage,"giftSprite")
		self.phoneNumPage:setVisible(true)
		giftText:setString("("..giftName..")")
		giftSprite:setSpriteFrame("activitydb_ipadpic.png")
	elseif giftindex == -1 then
		self.phoneNumPage:setVisible(false)
		require("app/views/NoticeTips"):create("提示", "再接再厉哦！", nil, nil, true)
	else
		self.phoneNumPage:setVisible(false)
		require("app/views/NoticeTips"):create("恭喜您获得", giftName, nil, nil, true)
	end
end

function ActivityDragonBoat:floatTip( parent , content )
	gt.golbalZOrder = 10000
	if string.len(gt.fontNormal) == 0 then
		gt.fontNormal = "res/fonts/DFYuanW7-GB2312.ttf"
	end
	if not content or content == "" then
		return
	end

	local offsetY = 20
	local rootNode = cc.Node:create()
	rootNode:setPosition(cc.p(75, 100))

	local bg = cc.Scale9Sprite:create("res/sd/images/otherImages/float_text_bg.png")
	local capInsets = cc.size(200, 5)
	local textWidth = bg:getContentSize().width - capInsets.width * 2
	bg:setScale9Enabled(true)
	bg:setCapInsets(cc.rect(capInsets.width, capInsets.height, bg:getContentSize().width - capInsets.width, bg:getContentSize().height - capInsets.height))
	bg:setAnchorPoint(cc.p(0.5, 0.5))
	bg:setGlobalZOrder(gt.golbalZOrder)
	gt.golbalZOrder = gt.golbalZOrder + 1
	rootNode:addChild(bg)
	bg:setOpacity(0)

	local ttfConfig = {}
	ttfConfig.fontFilePath = gt.fontNormal
	ttfConfig.fontSize = 38
	local ttfLabel = cc.Label:createWithSystemFont( content, gt.fontNormal, 38)
	ttfLabel:setGlobalZOrder(gt.golbalZOrder)
	gt.golbalZOrder = gt.golbalZOrder + 1
	ttfLabel:setTextColor(cc.RED)
	ttfLabel:setAnchorPoint(cc.p(0.5, 0.5))
	rootNode:addChild(ttfLabel)

	if ttfLabel:getContentSize().width > textWidth then
		bg:setContentSize(cc.size(bg:getContentSize().width + (ttfLabel:getContentSize().width - textWidth), bg:getContentSize().height))
	end
	
	local action = cc.Sequence:create(
		cc.MoveBy:create(1.5, cc.p(0, 120)),
		cc.CallFunc:create(function()
			rootNode:removeFromParent(true)
			parent.floatNode = nil
		end)
	)
	parent:addChild(rootNode,100000)
	parent.floatNode = rootNode
	rootNode:setScale(0.7)
	rootNode:runAction(action)
	return rootNode
end

function ActivityDragonBoat:btnEventCallBack( index )
	if self.data.m_btnsState[index][2] == 0 then
		local parent = gt.seekNodeByName(self.root, "Button_"..index)
		if parent.floatNode then
			return
		end
		local floatNode = self:floatTip( parent , "完成"..numConfig[index] .. "局才能抽奖！" )
		-- parent.floatNode = floatNode
	elseif self.data.m_btnsState[index][2] == 2 then
		local parent = gt.seekNodeByName(self.root, "Button_"..index)
		if parent.floatNode then
			return
		end
		local floatNode = self:floatTip( parent , "此次机会已经使用！" )
		parent.floatNode = floatNode
	else
		self.clickIndex = index
		local target = numConfig[index] or 50
		self.clickTarget = target
		local msgToSend = {}
		msgToSend.m_fd = target
		msgToSend.m_msgId = gt.CG_ACTIVITY_REQUEST_DRAGON_DRAW
		gt.socketClient:sendMessage(msgToSend)
		gt.showLoadingTips("正在获取抽奖结果...")
	end
end

function ActivityDragonBoat:onNodeEvent(eventName)
	if "enter" == eventName then
		
	elseif "exit" == eventName then
		gt.isSendDragonActivities  = false
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function ActivityDragonBoat:show( parent , zOrder )
	parent = parent or cc.Director:getInstance():getRunningScene()
	zOrder = zOrder or 60 -- notice tip 的 层级是 67 ，要比67 小
	parent:addChild(self,zOrder)
end

function ActivityDragonBoat:hide()
	self:removeFromParent()
end

return ActivityDragonBoat