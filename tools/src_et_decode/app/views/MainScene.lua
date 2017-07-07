
local gt = cc.exports.gt
local loginStrategy = require("app/LoginIpStrategy")
local MainScene = class("MainScene", function()
	return cc.Scene:create()
end)

MainScene.ZOrder = {
	PANDA_ANIMATION			= 4,
	HISTORY_RECORD			= 5,
	CREATE_ROOM				= 6,
	JOIN_ROOM				= 7,
	PLAYER_INFO_TIPS		= 9,
}

local OtherGameRecruitConfigs = {
	-- { 
	-- 	picPath = "images/otherImages/yunnanbutton.png",
	-- 	url = "http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.yunnanmahjong",
	-- 	scaleNum = 0.9
	-- },
	{ 	
		picPath = "images/otherImages/tubao_xianlaibuyu.png",
		url = "http://3g.tuyoo.com/landing/ldy1_2/2017-04-17/220.html",
		scaleNum = 0.7,
		posAdd = cc.p(0,0)
	}
	-- {
	-- 	picPath = "images/otherImages/paohuzi.png",
	-- 	url = "http://www.ixianlai.com/download_url/paohuzi/paohuzi.html",
	-- 	scaleNum = 0.9,
	-- 	posAdd = cc.p(0,0)
	-- },
	-- {
	-- 	picPath = "images/otherImages/jiangsu.png",
	-- 	url = "http://a.app.qq.com/o/simple.jsp?pkgname=com.mahjong.jiangsu&fromcase=20000&ckey=CK1359549401032&g_f=1002725",
	-- 	scaleNum = 0.8,
	-- 	posAdd = cc.p(0,0)
	-- }
}

function MainScene:ctor(isNewPlayer, isRoomCreater, roomID,showCardInfo)
	self.isNewPlayer = isNewPlayer
	self.isRoomCreater = isRoomCreater
	self.showCardInfo = showCardInfo

	--首页pageview的资源和链接配置表
	self.addFlowUrl = {}
	--{"MainScene_new6.png",""}--健康公告
	-- {"MainScene_new11.png","http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.yunnanmahjong"},--云南
	-- {"MainScene_new10.png","http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.ddz"},--斗地主
	-- {"MainScene_new12.png","http://a.app.qq.com/o/simple.jsp?pkgname=com.ixianlai.mahjonghefei"},--安徽
	-- {"MainScene_new15.png","http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.mahjongguiyang"}--贵州
	--{webURL = "http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.mahjongguangxi"}--广西
	--{webURL = "http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.mahjongjx"}--江西
	--{webURL = "http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.guandan"}--惯蛋
	
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("MainScene_new.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Spr_bg"):setScaleY(1280/960)
		gt.seekNodeByName(csbNode, "Node_top"):setPositionY(840)
		gt.seekNodeByName(csbNode, "Node_bottom"):setPositionY(-120)
		gt.seekNodeByName(csbNode, "Spr_Tip"):setPositionY(250)
		gt.seekNodeByName(csbNode, "Sprite_Panda"):setPositionY(-120)
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	self.bottomBtnTabel = {}
	--pageview公告栏
	-- self.PageView_Tips = gt.seekNodeByName(csbNode, "PageView_Tips")
	-- self.PageView_Tips:setTouchEnabled(true)
	-- self.PageView_Tips:setScrollBarEnabled(false)

	-- local function PageEventCallBack(sender)
	-- 	local url = self.addFlowUrl[sender:getTag()][2]
	-- 	if gt.isIOSPlatform() then
	-- 		local luaoc = require("cocos/cocos2d/luaoc")
	-- 		local ok = luaoc.callStaticMethod("AppController", "openWebURL", {webURL = url})				
	-- 	elseif gt.isAndroidPlatform() then
	-- 		local luaoj = require("cocos/cocos2d/luaj")
	-- 		local ok = luaoj.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL", {url}, "(Ljava/lang/String;)V")
	-- 	end
	-- end
	-- for i=1,#self.addFlowUrl do
 --    	---创建layout，内容添加到layout
 --        local layout=ccui.Layout:create()
 --        layout:setContentSize(self.PageView_Tips:getContentSize())
 --        local frameName = ""
 --    	frameName = self.addFlowUrl[i][1]
 --    	if self.addFlowUrl[i][2] then
 --    		layout:addClickEventListener(PageEventCallBack)
	-- 	end
 --        local Tips = cc.Sprite:createWithSpriteFrameName(frameName)
 --        Tips:setContentSize(layout:getContentSize())
 --        Tips:setPosition(cc.p(layout:getContentSize().width*0.5,layout:getContentSize().height*0.5))
 --        layout:addChild(Tips)
 --        layout:setTag(i)
 --        layout:setTouchEnabled(true)
 --        self.PageView_Tips:insertPage(layout,i-1)
 --    end

	local Btn_Node = gt.seekNodeByName(csbNode, "Node_bottom")

	-- 战绩
	local historyBtn = gt.seekNodeByName(Btn_Node, "Btn_history")
	self.bottomBtnTabel[1] = historyBtn
	gt.addBtnPressedListener(historyBtn, function()
		if gt.isGM == 1 then
			local checkHistory = require("app/views/GMCheckHistory"):create()
			self:addChild(checkHistory, MainScene.ZOrder.HISTORY_RECORD)
		else
			local historyRecord = require("app/views/HistoryRecord"):create()
			self:addChild(historyRecord, MainScene.ZOrder.HISTORY_RECORD)
		end 
	end)

	-- 推广员活动
	local recruitBtn = gt.seekNodeByName(Btn_Node, "Btn_recruit")
	-- gt.log("recruitBtn =================== "..recruitBtn)x
	if recruitBtn then
	gt.log("recruitBtn =================== 3333333333333")

		local function openFunc( ... )
			local ActivityRecruitDialog = require("app/views/Activities/ActivityRecruitDialog")
			if ActivityRecruitDialog.isOpen() then
				ActivityRecruitDialog:create():show()
			end		
		end
		gt.addBtnPressedListener(recruitBtn, openFunc)
	end
	
	-- 分享按钮
	local shareBtn = gt.seekNodeByName(Btn_Node,"Btn_share")
	self.bottomBtnTabel[2] = shareBtn
	self.Sprite_jiang = gt.seekNodeByName(shareBtn, "Sprite_jiang")
	self.Sprite_jiang:setVisible(false)
	
	gt.addBtnPressedListener(shareBtn,function()
		gt.IsShowSprjiang = 1
		self.Sprite_jiang:setVisible(false)
		local description = string.format("玩家:%s ID:%d 邀请您加入【熊猫麻将】。",gt.playerData.nickname,gt.playerData.uid)
		local title = "熊猫麻将"
		local url = gt.shareWeb
		if gt.isIOSPlatform() then
			url = gt.shareiosWeb
		end
		local shareSelect = nil
		-- local function callback()
		-- 	local msgToSend = {}
		-- 	msgToSend.m_msgId = gt.CG_SHARE_SUCCESS
		-- 	gt.socketClient:sendMessage(msgToSend)
		-- 	gt.dump(msgToSend)
		-- end
		-- if gt.m_IsShare == 0 then
		-- 	shareSelect = require("app/views/ShareSelect"):create(description, title, url)
		-- elseif gt.m_IsShare == 1 then
		-- 	shareSelect = require("app/views/ShareSelect"):create(description, title, url, gt.m_IsShare, callback)
		-- elseif gt.m_IsShare == 2 then
		-- 	shareSelect = require("app/views/ShareSelect"):create(description, title, url, gt.m_IsShare)
		-- end
		shareSelect = require("app/views/ShareSelect"):create(description, title, url)
		local runningScene = cc.Director:getInstance():getRunningScene()
		runningScene:addChild(shareSelect, 68)
	end)

	-- 反馈按钮
	local Btn_feedback = gt.seekNodeByName(Btn_Node,"Btn_feedback")
	self.bottomBtnTabel[5] = Btn_feedback
	Btn_feedback:setVisible(false)
	self.feedbackSprite_1 = gt.seekNodeByName(Btn_feedback, "Sprite_1")
	gt.addBtnPressedListener(Btn_feedback, function ()
                                 -- if gt.checkVersion(1, 0, 8) then
                                 --     gt.bridge.setAppInfo("current_user_id",   gt.playerData.uid)
                                 --     gt.bridge.setAppInfo("current_user_name", gt.playerData.nickname)
                                 --     gt.bridge.setAppInfo("lua_file_version",  gt.resVersion)
                                 --     -- gt.bridge.setAppInfo("other_info", "其他信息")

                                 --     gt.bridge.openFeedback()
                                 -- else
                                 --     require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "使用反馈功能请更新安装最新版本", function ()
                                 --                                                gt.bridge.openWebURL(gt.shareWeb)
                                 --                                                                                                                  end, nil, true)
                                 -- end
                                 -- 接口调用例子
        -- gt.tools:removeQiyuMessageHandler()
        self.feedbackSprite_1:setVisible(false)
		local isCanOpenQiYu = false
		if gt.tools.openQiYu then
			local param = {}

			if gt.playerData then 
				param.nickname = gt.playerData.nickname
				param.uid = gt.playerData.uid
				param.unionid = gt.playerData.unionid 
				param.ip = gt.playerData.ip 
				-- param.headURL = gt.playerData.headURL   
				-- print('headURL:' .. param.headURL)
			end 
			--param.staffId = "120951"
			param.source = "主界面"
			param.resVersion = gt.resVersion
			param.isOldPlayer = tostring(gt.IsOldUser) 
			param.totalPlayNum = tostring(gt.totalPlayNum)
			isCanOpenQiYu = gt.tools:getInstance():openQiYu(param)
			-- print('调用客服系统成功了么:' .. tostring(isCanOpenQiYu))
		end
	end)

	local Node_top = gt.seekNodeByName(csbNode, "Node_top")
	-- 玩家信息
	local playerInfoNode = gt.seekNodeByName(Node_top, "Node_playerInfo")
	local playerData = gt.playerData
	-- 头像
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	playerHeadMgr:attach(headSpr, playerData.uid, playerData.headURL,playerData.sex)
	self:addChild(playerHeadMgr)
	-- 昵称
	local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Label_nickname")
	nicknameLabel:setString(playerData.nickname)
	-- 点击头像显示信息
	local headFrameBtn = gt.seekNodeByName(playerInfoNode, "Btn_headFrame")
	headFrameBtn:addClickEventListener(function()
		local playerInfoTips = require("app/views/PlayerInfoTips"):create(gt.playerData)
		self:addChild(playerInfoTips, MainScene.ZOrder.PLAYER_INFO_TIPS)
	end)
	--房卡张数
    local ttf_eight = gt.seekNodeByName(playerInfoNode, "Txt_numbereight")
	ttf_eight:setString(playerData.roomCardsCount[2])
	--信用
    local Txt_numXY = gt.seekNodeByName(playerInfoNode, "Txt_numXY")
	Txt_numXY:setString(playerData.m_credit)
	--金币信息
	local Gold_Num = gt.seekNodeByName(playerInfoNode, "Gold_Num")
	Gold_Num:setString(gt.formatCoinNumber(playerData.roomCardsCount[4]))
	gt.log("playerData = ")
	gt.dump(playerData)

	-- id信息
	local useridLabel = gt.seekNodeByName(playerInfoNode,"Text_id")
	useridLabel:setString(playerData.uid)

	-- 弹出房卡购
	local nodeBuyCard = gt.seekNodeByName(playerInfoNode,"Node_buy_card")
	-- if gt.isIOSPlatform() and gt.isInReview then
	-- 	nodeBuyCard:setVisible(true)
	-- end
	gt.addBtnPressedListener(nodeBuyCard, function()
		if gt.isIOSPlatform() then
			if gt.checkIAPState() == true then
				local luaBridge = require("cocos/cocos2d/luaoc")
				local ok, ret = luaBridge.callStaticMethod("AppController", "getBundleID")
				if ret == "com.game.xiongmao" or ret == "com.sichuan.majiangxmjh" then
					local agreementPanel = require("app/views/Purchase/RechargeLayer"):create()
					self:addChild(agreementPanel, 66)
				elseif ret == "com.game.sichuan" then
					local agreementPanel = require("app/views/Purchase/RechargeLayer"):create()
					self:addChild(agreementPanel, 66)
				else
					require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
				end
			else
				require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
			end
			
		elseif gt.isAndroidPlatform() then
			require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
		end
	end)
	local buyCardBtn = gt.seekNodeByName(playerInfoNode, "Btn_buyCard")
	
	--商城
	local btnShop = gt.seekNodeByName(Node_top, "Btn_Shop")
	btnShop:setVisible(false)
	 -- btnShop:setVisible(gt.isIOSPlatform())
	gt.addBtnPressedListener(btnShop, function()
		if gt.checkIAPState() == true then
			local luaBridge = require("cocos/cocos2d/luaoc")
			local ok, ret = luaBridge.callStaticMethod("AppController", "getBundleID")
			if ret == "com.game.xiongmao" then
				local agreementPanel = require("app/views/Purchase/RechargeLayer"):create()
				self:addChild(agreementPanel, 66)
			else
				require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
			end
		else
			if gt.isIOSPlatform() == true then
				require("app/views/NoticeTips"):create("提示", "请升级到最新版本", nil, nil, true)
			end
		end
	end)

	--实名认证
	local BtnRealName = gt.seekNodeByName(Node_top, "BtnRealName")
	if not BtnRealName then
		BtnRealName = gt.seekNodeByName(Btn_Node, "BtnRealName")
		self.bottomBtnTabel[4] = BtnRealName
	end
	if gt.isIOSPlatform() and gt.isInReview then
		BtnRealName:setVisible(false)
	else
		BtnRealName:setVisible(true)
	end
	local Spr_Real = gt.seekNodeByName(playerInfoNode, "Spr_Real")--头像标志
	Spr_Real:setVisible(false)
	gt.IsShowRealName = 0
	gt.IsShowRealName = cc.UserDefault:getInstance():getIntegerForKey("IsShowRealName")
	if gt.IsShowRealName == 1 then
		BtnRealName:setVisible(true)
		Spr_Real:setVisible(true)
	end
	gt.addBtnPressedListener(BtnRealName, function()
		if gt.IsShowRealName == 1 then
			require("app/views/NoticeTips"):create("提示", "您已经实名认证过了哦！", nil, nil, true)
			return
		end
		local RealName = require("app/views/RealName"):create(
			function ()
				-- BtnRealName:setVisible(false)
				gt.IsShowRealName = 1
				Spr_Real:setVisible(true)
			end)
		self:addChild(RealName, 66)
	end)

	--购卡说明
	local BtnBuyCardTips = gt.seekNodeByName(Node_top, "BtnBuyCardTips")
	BtnBuyCardTips:setVisible(false)
	gt.addBtnPressedListener(BtnBuyCardTips, function()
		require("app/views/wxTipsLayer"):create(gt.roomCardBuyInfo)
	end)
	local BtnZan = gt.seekNodeByName(Btn_Node, "BtnZan")
	self.bottomBtnTabel[3] = BtnZan
	local zanSprite_1 = gt.seekNodeByName(BtnZan, "Sprite_1")
	zanSprite_1:setVisible(false)
	if gt.isZan == true then
		zanSprite_1:setVisible(true)
	end
	gt.addBtnPressedListener(BtnZan, function()
		gt.isZan = false
		zanSprite_1:setVisible(false)
		local historyRecord = require("app/views/FriendEvaluation"):create()
		self:addChild(historyRecord, MainScene.ZOrder.HISTORY_RECORD)
	end)

	-- 消息
	local messageBtn = gt.seekNodeByName(Node_top, "Btn_message")
	gt.addBtnPressedListener(messageBtn, function()
		local checkHistory = require("app/views/MessageScene"):create()
		self:addChild(checkHistory, MainScene.ZOrder.HISTORY_RECORD)
	end)
	-- 帮助
	local helpBtn = gt.seekNodeByName(Node_top, "Btn_help")
	gt.addBtnPressedListener(helpBtn, function()
		if self.checkHistory then
			self.checkHistory:setVisible(true)
			gt._webView:setVisible(true)
			self.checkHistory:setZOrder(MainScene.ZOrder.HISTORY_RECORD)
		else
			self.checkHistory = require("app/views/HelpScene"):create()
			self:addChild(self.checkHistory, MainScene.ZOrder.HISTORY_RECORD)
		end
	end)
	-- 退出
	local exitBtn = gt.seekNodeByName(Node_top, "Btn_set")
	gt.addBtnPressedListener(exitBtn, function()
		local settingPanel = require("app/views/Setting"):create(nil,2)
		self:addChild(settingPanel, 100)
	end)

	-- 跑马灯
	local marqueeNode = gt.seekNodeByName(csbNode, "Node_marquee")
	local marqueeMsg = require("app/MarqueeMsg"):create()
	marqueeNode:addChild(marqueeMsg)
	self.marqueeMsg = marqueeMsg
	-- self.marqueeMsg:showMsg("欢迎来到熊猫麻将,请玩家文明娱乐,严禁赌博,如发现有赌博行为,将封停帐号,并向公安机关举报,对游戏的意见和建议可联系客服QQ:3399801288")
	if gt.marqueeMsgTemp then
		self.marqueeMsg:showMsg(gt.marqueeMsgTemp)
		gt.log("_________ is .. " .. gt.marqueeMsgTemp)
	end

	if not (gt.isIOSPlatform() and gt.isInReview) then -- 不是iOS审核模式则请求分IP新的跑马灯
        self:requestMarquee()
    end

	local Node_center = gt.seekNodeByName(csbNode, "Node_center")
	self.Node_center = Node_center
	-- 其他游戏推广入口icon
	local __node = gt.seekNodeByName(Node_center, "GameEnterNode")
	__node:setVisible(false)
	self.__node = __node
	self.recruitGameBtnNode = gt.seekNodeByName(__node, "root")
	local btnSprite = gt.seekNodeByName(self.recruitGameBtnNode, "btnSprite")

	local showListBtn =  gt.seekNodeByName(self.recruitGameBtnNode,"btn_show")
	self.isShowStatus = true
	local posY = self.recruitGameBtnNode:getPositionY()
	self.recruitGameBtnNode.btnSprite = btnSprite
	gt.addBtnPressedListener(showListBtn, function()
		gt.log("==========================btn ")
		if self.isShowStatus then
			self.isShowStatus = false
			self.recruitGameBtnNode:stopAllActions()
			self.recruitGameBtnNode:runAction(cc.MoveTo:create(0.5,cc.p(-230,posY)))
			btnSprite:setSpriteFrame("sc_lobby_button010.png")
		else
			self.isShowStatus = true
			self.recruitGameBtnNode:stopAllActions()
			self.recruitGameBtnNode:runAction(cc.MoveTo:create(0.5,cc.p(0,posY)))
			btnSprite:setSpriteFrame("sc_lobby_button009 2.png")
		end
	end)
	-- 创建/返回房间
	-- self.createRoomLayer = require("app/views/CreateRoom"):create()
	-- self:addChild(self.createRoomLayer, self:getZOrder()-1)
	-- self.createRoomLayer:setVisible(false)
	local createRoomPanel = gt.seekNodeByName(Node_center, "Panel_createRoom")
	createRoomPanel:addClickEventListener(function()
		if self.isRoomCreater then
			-- 房主返回房间
			-- 发送进入房间消息
			gt.showLoadingTips(gt.getLocationString("LTKey_0006"))
			gt.log("isRoomCreater = true")

			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_JOIN_ROOM
			msgToSend.m_deskId = roomID
			gt.socketClient:sendMessage(msgToSend)
		else
			if self.createRoomLayer then
				self.createRoomLayer:setVisible(true)
				self.createRoomLayer:setZOrder(MainScene.ZOrder.CREATE_ROOM)
			else
				self.createRoomLayer = require("app/views/CreateRoomNew"):create()
				self:addChild(self.createRoomLayer, MainScene.ZOrder.CREATE_ROOM)
			end
		end
	end)
	-- 创建房间
	self.createRoomSpr = gt.seekNodeByName(createRoomPanel, "Spr_createRoom")
	-- 返回房间
	self.backRoomSpr = gt.seekNodeByName(createRoomPanel, "Spr_backRoom")
	if self.isRoomCreater then
		self.createRoomSpr:setVisible(false)
		self.backRoomSpr:setVisible(true)
	else
		self.createRoomSpr:setVisible(true)
		self.backRoomSpr:setVisible(false)
	end

	-- 进入房间
	local joinRoomPanel = gt.seekNodeByName(Node_center, "Panel_joinRoom")
	joinRoomPanel:addClickEventListener(function()
		gt.socketClient:unregisterMsgListener(gt.GC_JOIN_ROOM)
		local function callback()
			gt.socketClient:unregisterMsgListener(gt.GC_JOIN_ROOM)
			gt.socketClient:registerMsgListener(gt.GC_JOIN_ROOM, self, self.onRcvJoinRoom)
		end
		
		local joinRoomLayer = require("app/views/JoinRoom"):create(callback)
		self:addChild(joinRoomLayer, MainScene.ZOrder.JOIN_ROOM)
	end)

	-- 进入金币场
	local goldRoomPanel = gt.seekNodeByName(Node_center, "Panel_goldRoom")
	goldRoomPanel:addClickEventListener(function()
		if not gt.GoldControl then
			-- 发送创建房间消息
			local msgToSend = {}
			-- 局数偏移矫正加一与服务器同步
			msgToSend.m_msgId = gt.CG_ENTER_GOLD_ROOM
			msgToSend.m_state = 1102
			msgToSend.m_playType = {46,23,30,20,27,34}
			-- msgToSend.m_state = 1101
			-- msgToSend.m_playType = {22,25,30}
			-- msgToSend.m_flag = 2
			
			msgToSend.m_robotNum = gt.robotNum
			if self.glodNum then
				msgToSend.m_coins = self.glodNum
			end
			msgToSend.m_cardValue = gt.senTab
			gt.socketClient:sendMessage(msgToSend)
			gt.dump(msgToSend)
			-- 等待提示
			gt.showLoadingTips("正在进入金币场...")
		else
			require("app/views/NoticeTips"):create("提示", "暂未开放", nil, nil, true)
		end
	end)
	local Spr_Tip = gt.seekNodeByName(Node_center, "Spr_Tip")
	if tonumber(loginStrategy:getPlayCount())>30 then
		gt.seekNodeByName(Spr_Tip, "Text_2"):setString("官方微信公众号\n  xmscmj666")
	end
	

	-- 进入房间
	gt.socketClient:registerMsgListener(gt.GC_ENTER_ROOM, self, self.onRcvEnterRoom)

	--金币兑换功能
	local Button_ExchangeGold = gt.seekNodeByName(csbNode, "Button_ExchangeGold")
	self.Button_ExchangeGold = Button_ExchangeGold
	if gt.IsExchangeGoldActShow then
		Button_ExchangeGold:setVisible(true)
	else
		Button_ExchangeGold:setVisible(false)
	end
	gt.addBtnPressedListener(Button_ExchangeGold, function()
		if self.ExchangeGold then
			self.ExchangeGold:setVisible(true)
			self.ExchangeGold:setZOrder(MainScene.ZOrder.HISTORY_RECORD)
		else
			self.ExchangeGold = require("app/views/ExchangeGold"):create()
			self:addChild(self.ExchangeGold, MainScene.ZOrder.HISTORY_RECORD)
		end
	end)
	--弹窗活动按钮
	local Actbtn = gt.seekNodeByName(csbNode, "Btn_act")
	Actbtn:setVisible(false)
	self.Actbtn = Actbtn
	gt.addBtnPressedListener(Actbtn, function()
		local date = os.date("%m%d")
		if tonumber(date) >= 118 and tonumber(date) <= 212 then
			gt.pushLayer(gt.createMaskLayer(0),false,self.rootNode,111)
			local ExtActivityNode = cc.CSLoader:createNode("ExActivitylayer.csb")
			if display.autoscale == "FIXED_HEIGHT" then
				ExtActivityNode:setScale(0.75)
			end
			ExtActivityNode:setAnchorPoint(0.5, 0.5)
			ExtActivityNode:setPosition(gt.winCenter)
			self:addChild(ExtActivityNode,10086)
			self.ExtActivityNode = ExtActivityNode

			local btn_Close = gt.seekNodeByName(ExtActivityNode,"Btn_Close")
			gt.addBtnPressedListener(btn_Close,function ()
				gt.popLayer()
				if self.ExtActivityNode then
					self.ExtActivityNode:removeFromParent()
				end
				gt.activityControl = false
			end)
		-- else
		-- 	self.Actbtn:setVisible(false)
		end
	end)
	--邀请好友活动
	local RoomCardBtn = gt.seekNodeByName(csbNode, "Button_RoomCard")
	RoomCardBtn:setVisible(false)
	
	if gt.isInReview == false then
		self:addOtherGameDownLoad(__node)
	end
	self:addRecruitIcon( recruitBtn )
	-- -- -- 转盘活动
	gt.isSendActivities = false
	-- 活动按钮
	local Btn_monthactivity = gt.seekNodeByName(csbNode, "Btn_monthactivity")
	-- Btn_monthactivity:setVisible(false)
	gt.addBtnPressedListener(Btn_monthactivity, function()
		if not gt.isSendActivities then
			gt.isSendActivities = true
			self:sendGetActivities()
		end
	end)
	self.Btn_monthactivity = Btn_monthactivity

	--配牌
	local okBtn = gt.seekNodeByName(csbNode,"Button_paixing")
	okBtn:setVisible(false)
	local textfield = gt.seekNodeByName(csbNode, "TextField_paixing")
	textfield:setVisible(false)

	local Image_4 = gt.seekNodeByName(csbNode,"Image_4")
	Image_4:setVisible(false)

	--配金币
	local TextField_gold = gt.seekNodeByName(csbNode, "TextField_gold")
	TextField_gold:setVisible(false)
	--机器人
	local TextField_robot = gt.seekNodeByName(csbNode, "TextField_robot")
	TextField_robot:setVisible(false)

    if gt.debugMode then
        okBtn:setVisible(true)
        textfield:setVisible(true)
        Image_4:setVisible(true)
        TextField_gold:setVisible(true)
        TextField_robot:setVisible(true)

        local function parsePeipai(str)
            str = str:gsub("\n", "")
            str = str:gsub(",", "")
            str = str:gsub(" ", "")
            local strArray = {}

            for i=1, #str, 2 do
                table.insert(strArray, str:sub(i, i+1))
            end

            -- dump(strArray)

            return table.concat(strArray, ",")
        end

        local paixing = [[
            11,11,11   12,12,12,  13,13,13  14,14,14 15
            0000 0000 0000 0000 0000 0000 00
            1515 0000 0000 0000 0000 0000 00
            15
            ]]

        paixing = parsePeipai(paixing)
        -- textfield:setString(paixing)
        -- TextField_robot:setString("3")
    end

	gt.addBtnPressedListener(okBtn, function ( )
			local senTab = {}
			local textfield = gt.seekNodeByName(csbNode, "TextField_paixing")
			local cardNum = textfield:getStringValue()
			if string.len(cardNum) ~= 0 then
				local subStrs = string.split(cardNum, ",")

				for i,v in ipairs(subStrs) do
					local carTab = {}
					carTab[1] = math.floor(tonumber(v)/10)
					carTab[2] = tonumber(v)%10
					senTab[#senTab+1] = carTab
				end
			end
			gt.senTab = senTab	
			
			local glodNum = TextField_gold:getStringValue()
			if string.len(glodNum) ~= 0 then
				self.glodNum = tonumber(glodNum)
			end

			local robotNum = TextField_robot:getStringValue()
			if string.len(robotNum) ~= 0 then
				gt.robotNum = tonumber(robotNum)
			end

			gt.dump(gt.senTab)
		
	end)

	if gt.isUpdate == true and gt.isShowUpdateView == true then
		local updateInfoTipsLayer = require("app/views/updateInfoTipsLayer"):create()
		self:addChild(updateInfoTipsLayer, MainScene.ZOrder.HISTORY_RECORD)
		gt.isUpdate = false
	end

	-- local horIndex = 0
	-- local function pageviewAct()
	-- 	if self.PageView_Tips:getCurrentPageIndex() <= 0 then
	-- 		self.PageView_Tips:scrollToPage(self.PageView_Tips:getCurrentPageIndex()+1)	
	-- 		horIndex = 1
	-- 	elseif self.PageView_Tips:getCurrentPageIndex() == #self.addFlowUrl-1 then
	-- 		--向前滑动
	-- 		self.PageView_Tips:scrollToPage(self.PageView_Tips:getCurrentPageIndex()-1)
	-- 		horIndex = -1
	-- 	else
	-- 		if horIndex == 1 then
	-- 			--向后滑动
	-- 			self.PageView_Tips:scrollToPage(self.PageView_Tips:getCurrentPageIndex()+1)
	-- 			horIndex = 1
	-- 		elseif horIndex == -1 then
	-- 			--向前滑动
	-- 			self.PageView_Tips:scrollToPage(self.PageView_Tips:getCurrentPageIndex()-1)
	-- 			horIndex = -1
	-- 		end
	-- 	end
	-- end

	-- local callFunc1 = cc.CallFunc:create(function(sender)
	-- 	-- pageviewAct()
	-- end)
	-- local callFunc2 = cc.CallFunc:create(function(sender)
	-- 	-- pageviewAct()
	-- end)
	-- local callFunc3 = cc.CallFunc:create(function(sender)
	-- 	-- pageviewAct()
	-- end)
	-- local delayTime = cc.DelayTime:create(5)
	-- local seqAction = cc.Sequence:create(callFunc1,delayTime,callFunc2,delayTime,callFunc3,delayTime)
	-- self:runAction(cc.RepeatForever:create(seqAction))

	--审核屏蔽
	if (gt.isInReview) then
		gt.robotNum = 3
		-- buyCardBtn:setVisible(true)
		-- nodeBuyCard:setVisible(true)
		--FangkaAnimateNode:setVisible(false)
		--BtnBuyCardTips:setVisible(false)
		goldRoomPanel:setVisible(false)

		okBtn:setVisible(false)
		textfield:setVisible(false)
		Image_4:setVisible(false)
		TextField_gold:setVisible(false)
		TextField_robot:setVisible(false)

		messageBtn:setVisible(false)
		helpBtn:setVisible(false)
		exitBtn:setVisible(false)
		Spr_Tip:setVisible(false)
		
		-- createRoomPanel:setPositionX(-200)
		-- joinRoomPanel:setPositionX(200)

		btnShop:setPosition(cc.p(-570,-190))

		gt.seekNodeByName(csbNode,"Sprite_Gold"):setVisible(false)
		gt.seekNodeByName(csbNode,"Gold_Num"):setVisible(false)
		gt.seekNodeByName(csbNode,"Sprite_xyd"):setVisible(false)
		gt.seekNodeByName(csbNode,"Sprite_xy"):setVisible(false)
		gt.seekNodeByName(csbNode,"Txt_numXY"):setVisible(false)
		--gt.seekNodeByName(csbNode,"Image_under3"):setVisible(false)
		
		-- gt.seekNodeByName(csbNode,"Spr_Tips"):setVisible(false)
		-- gt.seekNodeByName(csbNode,"PageView_Tips"):setVisible(false)

		gt.seekNodeByName(csbNode,"Node_bottom"):setVisible(false)
		-- gt.seekNodeByName(csbNode,"Spr_cardBg"):setVisible(false)
		-- gt.seekNodeByName(csbNode,"Spr_CardLab"):setVisible(false)
		gt.seekNodeByName(csbNode,"Txt_numbereight"):setVisible(true)
	else
		buyCardBtn:setVisible(true)
		nodeBuyCard:setVisible(true)
	end
	
	-- 注册消息回调
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER, self, self.onRcvLoginServer)
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
	gt.socketClient:registerMsgListener(gt.GC_MARQUEE, self, self.onRcvMarquee)
	gt.registerEventListener(gt.EventType.GM_CHECK_HISTORY, self, self.gmCheckHistoryEvt)
	-- 金币场相关
	gt.socketClient:registerMsgListener(gt.GC_GIVE_GLOLD, self, self.onRcvGiveGold)
	gt.socketClient:registerMsgListener(gt.GC_ENTER_GOLD_ROOM, self, self.onRcvDeskError)
	gt.socketClient:registerMsgListener(gt.GC_GET_GOLDS, self, self.onRcvGetGold)--点击领取金币后服务器返回的消息

	-- 服务器推送活动信息
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_REPLY_DRAW_OPEN, self, self.onRecvLotteryInfo)
	-- 服务器推送邀请活动信息
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_REPLY_INVITE_OPEN, self, self.onRecvActivityInviteInfo)
	-- 服务器推送端午节活动信息
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_REPLY_DRAGON_OPEN, self, self.onRecvActivityDragonInfo)

	-- 断线重连
	gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)

	gt.socketClient:registerMsgListener(gt.GC_LOGIN_GATE, self, self.onRcvLoginGate)
	gt.socketClient:registerMsgListener(gt.GC_JOIN_ROOM, self, self.onRcvJoinRoom)
	--分享游戏赠送房卡
	gt.socketClient:registerMsgListener(gt.GC_SHARE_SUCCESS, self, self.onRcvShareRoom)
	--活动信息
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_INFO, self, self.onRecvActivityInfo)
end

function MainScene:UpdateFeedbackMessage(unreadCount)
	gt.log("gt.checkVersion(1, 0, 9) xxxxxxxxxxxxxxxxx"..unreadCount)
	if gt.checkVersion(1, 0, 9) then
		if unreadCount > 0 then
			self.feedbackSprite_1:setVisible(true)
		else
			self.feedbackSprite_1:setVisible(false)
		end
	end
end

function MainScene:addDragonBoatActivityIcon( otherGamesBtnNode )
	gt.log("================== addDragonBoatActivityIcon ")

   	if not gt.m_dragonBoatActivityStatus or self.Btn_DragonAct then
		return
	end
	cc.SpriteFrameCache:getInstance():addSpriteFrames("images/ActivityDragonBoat.plist")
	local Btn_DragonAct = ccui.Button:create()
	local picName = "activitydb_icon.png"
	
    Btn_DragonAct:loadTextures(picName, picName, picName,ccui.TextureResType.plistType)
    Btn_DragonAct:setPosition(cc.p(-500,-130))
    Btn_DragonAct:setAnchorPoint(cc.p(0.5,0.5))
   	self.Node_center:addChild(Btn_DragonAct,20)
   	otherGamesBtnNode:setLocalZOrder(30)
   	self.Btn_DragonAct = Btn_DragonAct


   	local redPoint = cc.Sprite:createWithSpriteFrameName("activitydb_iconpoint.png")
   	redPoint:setPosition(cc.p(150,170))
   	self.Btn_DragonAct.redPoint = redPoint
   	gt.dragonActRedPoint = redPoint
   	Btn_DragonAct:addChild(redPoint)
   	gt.log("gt.m_dragonBoatActivityPointNum ============= "..gt.m_dragonBoatActivityPointNum)
   	if tonumber( gt.m_dragonBoatActivityPointNum)  <= 0 then
		redPoint:setVisible(false)
   	end

   	gt.addBtnPressedListener(Btn_DragonAct, function()
		-- if not gt.isSendActivities then
		-- 	gt.isSendActivities = true
		-- 	self:sendGetActivities()
		-- end
		if gt.isSendDragonActivities then
			return
		end
		gt.log("========================== sender")
		gt.isSendDragonActivities = true
		local msgTbl = {}
		msgTbl.m_msgId = gt.CG_ACTIVITY_REQUEST_DRAGON_OPEN
		-- msgTbl.m_userId = tonumber(gt.m_id)
 	--   	msgTbl.m_strUserUUID = gt.socketClient:getPlayerUUID()
		gt.socketClient:sendMessage( msgTbl )
	end)

	self.isShowStatus = false
	local posY = self.recruitGameBtnNode:getPositionY()
	self.recruitGameBtnNode:setPosition(cc.p(-230,posY))
	self.recruitGameBtnNode.btnSprite:setSpriteFrame("sc_lobby_button010.png")
end

function MainScene:addInviteActivityIcon( otherGamesBtnNode )
	gt.log("function is addInviteActivityIcon")
	local Btn_inviteAct = gt.seekNodeByName(self.Node_center, "activity_invite")
	if gt.m_inviteActivityStatus then
		gt.log("gt.m_inviteActivityStatus = true")
	else
		gt.log("gt.m_inviteActivityStatus = false")
	end
	if not gt.m_inviteActivityStatus then
		Btn_inviteAct:setVisible(false)
		return
	end

	Btn_inviteAct:setVisible(true)
	self.isShowStatus = false
	local posY = self.recruitGameBtnNode:getPositionY()
	self.recruitGameBtnNode:setPosition(cc.p(-230,posY))
	self.recruitGameBtnNode.btnSprite:setSpriteFrame("sc_lobby_button010.png")

	otherGamesBtnNode:setLocalZOrder(30)
	gt.isSendInviteActivities = false
	gt.log("=====================addInviteActivityIcon ")
	local Btn_inviteAct = ccui.Button:create()
	local picName = "Activity_invite_icon.png"
	cc.SpriteFrameCache:getInstance():addSpriteFrames("images/ActivityInvite.plist")
	
    Btn_inviteAct:loadTextures(picName, picName, picName,ccui.TextureResType.plistType)
    Btn_inviteAct:setPosition(cc.p(-500,-130))
    Btn_inviteAct:setAnchorPoint(cc.p(0.5,0.5))
   	self.Node_center:addChild(Btn_inviteAct,20)
   	local _csbFile = "ActivityInviteBtnAct_2.csb"
	local actcsbNode = cc.CSLoader:createNode(_csbFile)
	local actionLine = cc.CSLoader:createTimeline(_csbFile)
   	actionLine:gotoFrameAndPlay(0, 80,true)
   	actcsbNode:runAction(actionLine)
   	actcsbNode:setPosition(cc.p(113,118))
   	Btn_inviteAct:addChild(actcsbNode)

	gt.addBtnPressedListener(Btn_inviteAct, function() 

		-- local tabllll = {
		-- 	m_drawChance = 8,
		-- 	m_invitedUsers = {
		-- 		{m_userId = "🙃🙃🙃🙃🙃🙃🙃🙃🙃",m_headImageUrl = "sdadadadas"},
		-- 		{m_userId = "찾은단어가없습니다",m_headImageUrl = "sdadadadas"},
		-- 		{m_userId = "好治ufhwihf",m_headImageUrl = "sdadadadas"},
		-- 		{m_userId = "❁҉҉҉҉҉҉҉sdadahaozhi",m_headImageUrl = "sdadadadas"},
		-- 		{m_userId = "好治❁҉҉҉҉҉҉҉ahaozhi",m_headImageUrl = "sdadadadas"},
		-- 	}
		-- }
		-- require("app/views/Activities/ActivityInviteDialog"):create(tabllll):show(self,7)
		if gt.isSendInviteActivities then
			return
		end
		gt.log("========================== sender")
		gt.isSendInviteActivities = true
		local msgTbl = {}
		msgTbl.m_msgId = gt.CG_ACTIVITY_REQUEST_INVITE_OPEN
		-- msgTbl.m_userId = tonumber(gt.m_id)
 	--   	msgTbl.m_strUserUUID = gt.socketClient:getPlayerUUID()
		gt.socketClient:sendMessage( msgTbl )
	end)
end

function MainScene:addShareActivityIcon(otherGamesBtnNode)
	gt.log("-------------------------0")
	if not gt.m_shareActivityStatus then
		return 
	end
	gt.log("-------------------------1")
	if self.shareActBtn then
		return
	end

	gt.log("-------------------------2")
	local btncsbfile = "InviteRewardBtn.csb"
	local btncsbNode = cc.CSLoader:createNode(btncsbfile)
	btncsbNode:setAnchorPoint(0.5, 0.5)
	btncsbNode:setPosition(cc.p(-340,110))
	if display.autoscale == "FIXED_HEIGHT" then
		btncsbNode:setPosition(cc.p(-330,220))
	end
	self.Node_center:addChild(btncsbNode,59)

	local actionLine = cc.CSLoader:createTimeline(btncsbfile)
   	actionLine:gotoFrameAndPlay(0, 160,true)
   	btncsbNode:runAction(actionLine)

	local eventBtn = gt.seekNodeByName(btncsbNode,"eventBtn")

   	self.shareActBtn = eventBtn
	gt.addBtnPressedListener(eventBtn,function()
		require("app/views/Activities/InviteRewardDialog"):create():show()
	end)
end

-- start --
--------------------------------
-- @class function
-- @description 接收通用的活动内容
-- @param msgTbl 消息体
-- end --
function MainScene:onRecvActivityInfo( msgTbl )
	gt.log("通用活动内容")
	dump(msgTbl)

	if gt.isInReview then
		return
	end
	require("json")
	for i=1,#msgTbl.m_activities do
		if msgTbl.m_activities[i][1] == 1003 then
			gt.log("msgTbl.m_activities[i][3][1][2] = "..msgTbl.m_activities[i][3][1][2])
			local respJson = json.decode(msgTbl.m_activities[i][2])
			gt.ShareString = respJson.Desc
			gt.log("gt.ShareString = "..gt.ShareString)
			--分享送房卡
			if msgTbl.m_activities[i][3][1][2] == "1" then
				gt.m_IsShare = 1
				gt.log("gt.m_IsShare = "..gt.m_IsShare)
			elseif msgTbl.m_activities[i][3][1][2] == "0" then
				gt.m_IsShare = 2
			end
			gt.m_shareActivityStatus = true
			self:addShareActivityIcon(self.__node)
		elseif msgTbl.m_activities[i][1] == 1002 then
			--转盘活动
			gt.m_activeID = 1002
			local beginTime = os.date("*t", msgTbl.m_activities[i][3][1][2])
			beginTime = beginTime.year .. "年" .. beginTime.month .. "月" .. beginTime.day .. "日 " .. beginTime.hour .. ":" .. beginTime.min
			local EndTime = os.date("*t", msgTbl.m_activities[i][3][2][2])
			EndTime = EndTime.year .. "年" .. EndTime.month .. "月" .. EndTime.day .. "日 " .. EndTime.hour .. ":" .. EndTime.min
			gt.GoldTime = "活动时间：" .. beginTime  .. "至" .. EndTime
			gt.log(gt.GoldTime)
		elseif msgTbl.m_activities[i][1] == 1004 then
			-- 邀请好友活动
			gt.m_activeID = 1004
			gt.m_inviteActivityStatus = true
			self:addInviteActivityIcon(self.__node)
		elseif msgTbl.m_activities[i][1] == 1005 then
			gt.m_activeID = 1005
			gt.m_dragonBoatActivityStatus = true
			local attriVector = msgTbl.m_activities[i][3] or {}
			gt.m_dragonBoatActivityPointNum = 0
			for _key,_value in ipairs(attriVector) do
				local attriName = _value[1]
				if attriName == "FD" then
					gt.m_dragonBoatActivityPointNum = _value[2]
				end
			end
			gt.log("_value[1]==================== ",gt.m_dragonBoatActivityPointNum)
			gt.m_dragonBoatActivityPointNum = gt.m_dragonBoatActivityPointNum or 0
			self:addDragonBoatActivityIcon(self.__node)
		end
	end
	-- gt.m_inviteActivityStatus = true
end
function MainScene:addOtherGameDownLoad( recruitNode )
	-- self.gameBtnCounter = self.gameBtnCounter or 0
	-- self.gameBtnCounter = self.gameBtnCounter + 1
	
	local recruitIconCount = #OtherGameRecruitConfigs
	if recruitIconCount > 0 then
		recruitNode:setVisible(true)
	else
		return
	end
	local contentSz = cc.size(253,257) -- 图片尺寸
	local aCellSize = cc.size(104,104) -- 测量计算的cell 大小
	local leftDownCornerSize = cc.size(22.5,24.5)
	local row = 2

	local backG = gt.seekNodeByName(self.recruitGameBtnNode,"back")

	if recruitIconCount/2 > 2 then
		row = math.ceil(recruitIconCount/2)
		contentSz = cc.size(contentSz.width,contentSz.height+(row - 2)*aCellSize.height)
		backG:setContentSize(contentSz)
	end

	local function checkPos( index )
		-- 第几行
		local _row = math.ceil(index/2)
		-- 第几列
		local _col = (index - 1)%2
		local posX = leftDownCornerSize.width + aCellSize.width/2 + _col*aCellSize.width
		local posY = leftDownCornerSize.height + aCellSize.height/2 + (row - _row)*aCellSize.height
		gt.log("posX =================== _row === ".._row.." _col= ".. _col.."   "..posX .."   -------------    ".. posY)
		return cc.p(posX,posY)
	end

	for i=1,recruitIconCount do
		local Btn_Recruit = ccui.Button:create()
		local picName = OtherGameRecruitConfigs[i].picPath
		local url = OtherGameRecruitConfigs[i].url
		local scaleNum = OtherGameRecruitConfigs[i].scaleNum or 0.9
		local posAdd = OtherGameRecruitConfigs[i].posAdd or cc.p(0,0)
	    Btn_Recruit:loadTextures(picName, picName, picName)--云南
	    local pos = checkPos( i )
	    Btn_Recruit:setPosition(cc.pAdd(pos,posAdd))
	    Btn_Recruit:setScale(scaleNum)
	    Btn_Recruit:setAnchorPoint(cc.p(0.5,0.5))
	   	backG:addChild(Btn_Recruit)
		gt.addBtnPressedListener(Btn_Recruit, function()
			if gt.isIOSPlatform() then
				local luaoc = require("cocos/cocos2d/luaoc")
				local ok = luaoc.callStaticMethod("AppController", "openWebURL", {webURL = url})				
			elseif gt.isAndroidPlatform() then
				local luaoj = require("cocos/cocos2d/luaj")
				local ok = luaoj.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL", {url}, "(Ljava/lang/String;)V")
			end
		end)
	end
	
end


function MainScene:addRecruitIcon( recruitBtn )

	-- body
	-- 招募推广员活动入口

	-- 如果UI 界面已经有的话 不创建
	local limitedCount = 100 --次数前段配置，可修改
	if gt.debugMode then
		limitedCount = 5
	end
	local playCount = tonumber(loginStrategy:getPlayCount()) --用户玩游戏次数
	gt.log("playCount ============= "..playCount)
	local beginposX
	local nextposx
	if tonumber(playCount) < limitedCount then
		recruitBtn:setVisible(false)
		beginposX = -520
	else
		beginposX = -365
	end

	local index = 4
	if gt.checkVersion(1, 0, 9) then
		index = 5
		nextposx = 250
		self.bottomBtnTabel[5]:setVisible(true)
	else
		index = 4
		nextposx = 295
	end

	for i=1,index do
		local aBtn = self.bottomBtnTabel[i]
		if aBtn then
			local posX = aBtn:getPositionX()
			aBtn:setPositionX(beginposX+((1280-(640+beginposX)-110)/(index-1))*(i-1))
		end
	end

end

function MainScene:CopyRoomId()
	gt.log("function is CopyRoomId")
	local RoomID = ""
	local RoomIDUrl = gt.getCopyStr()
	if string.len(RoomIDUrl) == 6 and type(tonumber(RoomIDUrl)) == "number" then
		RoomID = RoomIDUrl
	elseif string.len(RoomIDUrl) > 6 then
		if string.find(RoomIDUrl,"%[") and string.find(RoomIDUrl,"]") then
			local a = string.find(RoomIDUrl,"%[")+1
			local b = string.find(RoomIDUrl,"]")-1
			RoomID = string.sub(RoomIDUrl,a,b)
		elseif string.find(RoomIDUrl,"roomId=") then
			local a = string.find(RoomIDUrl,"roomId=")+7
			local b = a+6
			RoomID = string.sub(RoomIDUrl,a,b)
		end
	end
	
	if string.len(RoomID) == 6 and type(tonumber(RoomID)) == "number" then
		gt.log("RoomID = "..RoomID)
		local JoinRoomTipText = string.format("您确定要进入房间 %d 吗？", RoomID)
		require("app/views/NoticeTips"):create("提示", JoinRoomTipText, function ()
				-- 发送进入房间消息
				local msgToSend = {}
				msgToSend.m_msgId = gt.CG_JOIN_ROOM
				msgToSend.m_deskId = tonumber(RoomID)
				gt.socketClient:sendMessage(msgToSend)
				gt.dump(msgToSend)
				gt.showLoadingTips(gt.getLocationString("LTKey_0006"))
				gt.CopyText(" ")
			end,function ()
				gt.CopyText(" ")
			end, false)
	end
end

function MainScene:onRcvShareRoom(msgTbl)
	gt.log("function = onRcvShareRoom")
	gt.dump(msgTbl)
	if msgTbl.m_ErrorCode == 0 and msgTbl.m_GiftCount > 0 then
		local GetRoomCard = cc.CSLoader:createNode("GetRoomCard.csb")
		GetRoomCard:setPosition(gt.winCenter)
		self:addChild(GetRoomCard,10086)
		local Text_CardNum = gt.seekNodeByName(GetRoomCard,"Text_CardNum")
		Text_CardNum:setString(msgTbl.m_GiftCount)

		local btn_Close = gt.seekNodeByName(GetRoomCard,"Btn_close")
		gt.addBtnPressedListener(btn_Close,function ()
			if GetRoomCard then
				GetRoomCard:removeFromParent()
			end
		end)
		local Btn_Sure = gt.seekNodeByName(GetRoomCard,"Btn_Sure")
		gt.addBtnPressedListener(Btn_Sure,function ()
			if GetRoomCard then
				GetRoomCard:removeFromParent()
			end
		end)
		gt.m_IsShare = 2
	elseif msgTbl.m_ErrorCode == 1 then
		gt.log("未知错误")
	else
	end
end

function MainScene:onRcvJoinRoom(msgTbl)
	gt.log("function = onRcvJoinRoom")
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
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0015"), function ()
				gt.CopyText(" ")
			end, nil, true)
		end
		self.createRoomSpr:setVisible(true)
		self.backRoomSpr:setVisible(false)
		self.isRoomCreater = false
	end
end

-- 断线重连,走一次登录流程
function MainScene:reLogin()
	-- print("========重连登录1")
	local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

	local unionid 		= cc.UserDefault:getInstance():getStringForKey( "WX_Uuid" )
	local sex 			= cc.UserDefault:getInstance():getStringForKey( "WX_Sex" )
	local nickname 		= gt.wxNickName--cc.UserDefault:getInstance():getStringForKey( "WX_Nickname" )
	local headimgurl 	= cc.UserDefault:getInstance():getStringForKey( "WX_ImageUrl" )

	gt.resume_time = 30

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN
	msgToSend.m_plate = "wechat"
	msgToSend.m_accessToken = accessToken
	msgToSend.m_refreshToken = refreshToken
	msgToSend.m_openId = openid
	msgToSend.m_severID = 15001
	msgToSend.m_uuid = unionid
	msgToSend.m_sex = tonumber(sex)
	msgToSend.m_nikename = nickname
	msgToSend.m_imageUrl = headimgurl

	local catStr = string.format("%s%s%s%s", openid, accessToken, refreshToken, unionid)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
	-- print("========重连登录2")
end

function MainScene:onRcvLogin(msgTbl)
	-- print("========重连登录4")
	-- 去掉转圈
	-- gt.removeLoadingTips()

	-- 发送登录gate消息
	gt.loginSeed 		= msgTbl.m_seed
	-- gt.GateServer.ip 	= gt.socketClient.serverIp
	gt.GateServer.port 	= tostring(msgTbl.m_gatePort)

	gt.socketClient:close()
	
	gt.socketClient:connect(loginStrategy.ip, gt.GateServer.port, true)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_GATE
	msgToSend.m_strUserUUID = gt.socketClient:getPlayerUUID()
	gt.socketClient:sendMessage(msgToSend)


	-- local msgToSend = {}
	-- msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	-- msgToSend.m_seed = msgTbl.m_seed
	-- msgToSend.m_id = msgTbl.m_id
	-- local catStr = tostring(gt.loginSeed)
	-- msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	-- gt.socketClient:sendMessage(msgToSend)
	-- print("========重连登录5")
end

--服务器返回gate登录
function MainScene:onRcvLoginGate( msgTbl )
	
	dump( msgTbl )

	gt.socketClient:setPlayerKeyAndOrder(msgTbl.m_strKey, msgTbl.m_uMsgOrder)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	msgToSend.m_seed = gt.loginSeed
	msgToSend.m_id = gt.m_id
	local catStr = tostring(gt.loginSeed)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
end

--企业签名包跳转更新
function MainScene:updateVersion()
	local appID;
	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
		appID = ret
	end
	if appID == "wx848c15b329e26e8d" then 	--企业签名包
	
		local NoticeTips_Update = cc.CSLoader:createNode("NoticeTips_Update.csb")
		NoticeTips_Update:setAnchorPoint(0.5, 0.5)
		NoticeTips_Update:setPosition(gt.winCenter)
		self:addChild(NoticeTips_Update,gt.CommonZOrder.NOTICE_TIPS)
		self.NoticeTips_Update = NoticeTips_Update
		local Btn_back = gt.seekNodeByName(NoticeTips_Update, "Btn_back")
		gt.addBtnPressedListener(Btn_back, function()
			self.NoticeTips_Update:removeFromParent()
		end)
		local Btn_ok = gt.seekNodeByName(NoticeTips_Update, "Btn_ok")
		gt.addBtnPressedListener(Btn_ok, function()
			if gt.isIOSPlatform() then
				local ok = self.luaBridge.callStaticMethod("AppController", "openWebURL", {webURL = gt.shareWeb})
			end
		end)
	end
end

function MainScene:onNodeEvent(eventName)
	if "enter" == eventName then
		gt.log(" enter == eventName")
		self:JoinUrlRoom()
		self.createRoomLayer = require("app/views/CreateRoomNew"):create()
		self:addChild(self.createRoomLayer, self:getZOrder()-1)
		self.createRoomLayer:setVisible(false)
		-- if gt.m_IsShare == 1 or gt.m_IsShare == 2 then
		-- 	if gt.IsShowSprjiang == 0 then
		-- 		self.Sprite_jiang:setVisible(true)
		-- 	else
		-- 		self.Sprite_jiang:setVisible(false)
		-- 	end
		-- end

		self:addShareActivityIcon(self.__node)
		--转盘活动
		if gt.m_activeID and gt.m_activeID == 1002 then
			gt.log("gt.m_activeID = 1002")
			self.Btn_monthactivity:setVisible(true)
		else
			self.Btn_monthactivity:setVisible(false)
		end
		self:addInviteActivityIcon(self.__node)
		self:addDragonBoatActivityIcon(self.__node)

		-- self:updateVersion()
		if gt.activityControl then
			-- local ExtActivityNode = cc.CSLoader:createNode("ExActivitylayer.csb")
			-- ExtActivityNode:setAnchorPoint(0.5, 0.5)
			-- ExtActivityNode:setPosition(gt.winCenter)
			-- self:addChild(ExtActivityNode,10086)
			-- self.ExtActivityNode = ExtActivityNode


			-- local btn_Close = gt.seekNodeByName(ExtActivityNode,"Btn_Close")
			-- gt.addBtnPressedListener(btn_Close,function ()
			-- 	self.ExtActivityNode:removeFromParent()
			-- 	gt.activityControl = false
			-- end)
			-- 
			local date = os.date("%m%d")
			gt.log("date = "..date)
			-- if tonumber(date) >= 207 and tonumber(date) <= 214 then
				gt.pushLayer(gt.createMaskLayer(0),false,self.rootNode,111)
				local ExtActivityNode = cc.CSLoader:createNode("ExActivitylayer.csb")
				if display.autoscale == "FIXED_HEIGHT" then
					ExtActivityNode:setScale(0.75)
				end
				ExtActivityNode:setAnchorPoint(0.5, 0.5)
				ExtActivityNode:setPosition(gt.winCenter)
				self:addChild(ExtActivityNode,10086)
				self.ExtActivityNode = ExtActivityNode

				local btn_Close = gt.seekNodeByName(ExtActivityNode,"Btn_Close")
				gt.addBtnPressedListener(btn_Close,function ()
					gt.popLayer()
					if self.ExtActivityNode then
						self.ExtActivityNode:removeFromParent()
					end
					gt.activityControl = false
				end)
			-- end
		end

		if self.showCardInfo then
			if self.showCardInfo.loginInterval and tonumber(self.showCardInfo.loginInterval) > 0 then
				local str_des = string.format("老朋友，欢迎回来！赠你%d房卡",self.showCardInfo.m_card1)
				if gt.isIOSPlatform() and gt.isInReview then
					str_des = gt.getLocationString("LTKey_0029_1")
				end
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
				str_des, nil, nil, true)
			end
		end

		if self.isNewPlayer then
			-- 显示新玩家奖励牌提示
			-- local str_des = gt.getLocationString("LTKey_0029")

			local str_des = string.format("第一次登陆送房卡%d张",gt.playerData.roomCardsCount[2])

			if gt.isIOSPlatform() and gt.isInReview then
				str_des = gt.getLocationString("LTKey_0029_1")
			end
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
				str_des, nil, nil, true)
		end


		local function onEvent1(event)
			if gt.NYwebView then
				gt.NYwebView:removeFromParent()
			end
	    end
	    -- 切到后台
	    self._listener1 = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND_EVENT", onEvent1)
	    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	    eventDispatcher:addEventListenerWithFixedPriority(self._listener1, 1)
	 	local function onEvent2(event)
	 		gt.resume_time = 1
	 		if gt.NYwebView then
				gt.NYwebView:removeFromParent()
			end
			
			local delayTime = cc.DelayTime:create(0.3)
			local callFunc = cc.CallFunc:create(function(sender)
				gt.roomState = 0
				self:JoinUrlRoom()
			end)

			local seqAction = cc.Sequence:create(delayTime, callFunc)
			self:runAction(seqAction)
	    end
	    --返回前台
	    self.foregroundEvent = cc.EventListenerCustom:create("APP_ENTER_FOREGROUND_EVENT", onEvent2)
	    eventDispatcher:addEventListenerWithFixedPriority(self.foregroundEvent, 1)
	    
		gt.tools:registerQiyuMessageHandler(handler(self, self.UpdateFeedbackMessage))
	elseif "exit" == eventName then
		gt.dragonActRedPoint = nil
		cc.Director:getInstance():getEventDispatcher():removeEventListener(self._listener1)
		cc.Director:getInstance():getEventDispatcher():removeEventListener(self.foregroundEvent)
		gt.tools:removeQiyuMessageHandler()
		gt.removeTargetEventListenerByType(self, gt.EventType.GM_CHECK_HISTORY)
	end
end


-- 服务器推送活动信息
function MainScene:onRecvLotteryInfo( msgTbl )
	dump(msgTbl)
	-- gt.log("........ onRecvLotteryInfo"..msgTbl.m_SpendType)
	if self.Btn_monthactivity then
		self.Btn_monthactivity:setTouchEnabled(true)
	end
	if msgTbl.m_errorCode == 0 then
		gt.lotteryInfoTab	= {}
		gt.lotteryInfoTab.m_winUsers = msgTbl.m_winUsers
		gt.lotteryInfoTab.m_SpendType = msgTbl.m_SpendType;
		gt.lotteryInfoTab.m_SpendCount = msgTbl.m_SpendCount;
		gt.lotteryInfoTab.m_nGameOverCount = msgTbl.m_playCount
		gt.lotteryInfoTab.m_btnsState = msgTbl.m_fd
		gt.lotteryInfoTab.m_vecMyOpenGiftRecordList = msgTbl.m_logs
		if msgTbl.m_SpendType == 2 then
			gt.log("邀请好友活动")
			local activityMotherDayLayer = require("app/views/Activities/TurntableActivity"):create()
			self:addChild(activityMotherDayLayer, 8)
		elseif msgTbl.m_SpendType == 1 then
			gt.log("old转盘活动")
			local activityMotherDayLayer = require("app/views/Activities/ActivityMotherDay"):create()
			self:addChild(activityMotherDayLayer, 8)
		end
	else
		gt.isSendActivities = false
		require("app/views/NoticeTips"):create("提示", "活动未开启", nil, nil, true)
	end
	-- gt.isSendActivities = false
end

-- 服务器推送邀请好友界面信息
function MainScene:onRecvActivityInviteInfo( msgTbl )
	gt.dump(msgTbl)
	if msgTbl.m_errorCode == 0 then
		local infoTbl = {}
		infoTbl.m_drawChance = msgTbl.m_drawChance
		infoTbl.m_invitedUsers = msgTbl.m_invitedUsers
		require("app/views/Activities/ActivityInviteDialog"):create(infoTbl):show(self,7)
	else
		require("app/views/NoticeTips"):create("提示", "无活动信息", nil, nil, true)
		gt.isSendInviteActivities = false
	end
end

function MainScene:onRecvActivityDragonInfo( msgTbl ) 
	gt.dump(msgTbl)
	gt.log("==================== onRecvActivityDragonInfo")
	if msgTbl.m_errorCode == 0 then
		local infoTbl = {}
		-- infoTbl.m_nHaveTel = msgTbl.m_nHaveTel
		-- infoTbl.m_nGameOverCount = msgTbl.m_nGameOverCount
		-- infoTbl.m_vecMyOpenGiftRecordList = msgTbl.m_vecMyOpenGiftRecordList
		-- infoTbl.m_vecUserGiftRecordList = msgTbl.m_vecUserGiftRecordList
		infoTbl.m_winUsers = msgTbl.m_winUsers

		infoTbl.m_nGameOverCount = msgTbl.m_playCount
		infoTbl.m_btnsState = msgTbl.m_fd
		infoTbl.m_vecMyOpenGiftRecordList = msgTbl.m_logs
		require("app/views/Activities/ActivityDragonBoat"):create(infoTbl):show(self,7)
	else
		require("app/views/NoticeTips"):create("提示", "无活动信息", nil, nil, true)
		gt.isSendInviteActivities = false
	end
end

-- 当有活动时,向服务器请求活动信息
function MainScene:sendGetActivities()
	if gt.m_activeID and gt.m_activeID ~= -1 then
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_ACTIVITY_REQUEST_DRAW_OPEN
		if gt.m_activeID == 1005 then
			msgToSend.m_msgId = gt.CG_ACTIVITY_REQUEST_DRAGON_OPEN
		end
		gt.socketClient:sendMessage(msgToSend)
		gt.log("#######请求微信的活动信息##########")
	else
		require("app/views/NoticeTips"):create("提示", "无活动信息", nil, nil, true)
	end
end

function MainScene:onRcvLoginServer(msgTbl)
	gt.dump(msgTbl)
	-- 去除正在返回游戏提示
	gt.removeLoadingTips()
	gt.socketClient:setIsStartGame(true)
	gt.socketClient:setIsCloseHeartBeat(false)
end

-- start --
--------------------------------
-- @class function
-- @description 进入房间消息
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvEnterRoom(msgTbl)
	gt.dump(msgTbl)
	gt.removeLoadingTips()

	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)
	gt.socketClient:unregisterMsgListener(gt.GC_ENTER_ROOM)
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
	gt.socketClient:unregisterMsgListener(gt.GC_MARQUEE)
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN)
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_GATE)
	gt.socketClient:unregisterMsgListener(gt.GC_JOIN_ROOM)
	gt.socketClient:unregisterMsgListener(gt.GC_GIVE_GLOLD)
	gt.socketClient:unregisterMsgListener(gt.GC_ENTER_GOLD_ROOM)
	gt.socketClient:unregisterMsgListener(gt.GC_GET_GOLDS)

	gt.socketClient:unregisterMsgListener(gt.GC_SHARE_SUCCESS)

	gt.socketClient:unregisterMsgListener(gt.GC_ACTIVITY_INFO)

	gt.removeTargetAllEventListener(self)

	gt.roomState = tonumber(msgTbl.m_state)
	gt.report_desk_id = tonumber(msgTbl.m_deskId)
	if tonumber(msgTbl.m_state) == 102 then--血流
		local playScene = require("app/views/PlaySceneXL"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 101 then--血战
		local playScene = require("app/views/PlaySceneXZ"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 103 then--三人
		local playScene = require("app/views/PlaySceneTX"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 104 then--倒倒胡
		local playScene = require("app/views/PlaySceneDDH"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 105 then--四人
		local playScene = require("app/views/PlaySceneNJ"):create(msgTbl)--
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 106 then--德阳
		local playScene = require("app/views/PlaySceneDY"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 107 then--三人三房
		local playScene = require("app/views/PlaySceneTXS"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 108 then--绵阳麻将
		local playScene = require("app/views/PlaySceneMY"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 109 then--宜宾麻将
		local playScene = require("app/views/PlaySceneYB"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 110 then--万州麻将
		local playScene = require("app/views/PlaySceneWZ"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 111 then--泸州麻将
		local playScene = require("app/views/PlaySceneLZ"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 112 then--乐山麻将
		local playScene = require("app/views/PlaySceneLS"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 113 then--南充麻将
		local playScene = require("app/views/PlaySceneNC"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 116 then--雅安麻将
		local playScene = require("app/views/PlaySceneYA"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 114 then--广安麻将
		local playScene = require("app/views/PlaySceneGA"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 115 then--自贡
		local playScene = require("app/views/PlaySceneZG"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 117 then--自贡四人
		local playScene = require("app/views/PlaySceneZGSR"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
    elseif tonumber(msgTbl.m_state) == 118 then -- 内江三人
		local playScene = require("app/views/PlaySceneNeiJiang"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
    elseif tonumber(msgTbl.m_state) == 119 then -- 内江四人
		local playScene = require("app/views/PlaySceneNeiJiang"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
    elseif tonumber(msgTbl.m_state) == 120 then -- 两人麻将
		local playScene = require("app/views/PlaySceneErRen"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 1102 then--金币场
		local playScene = require("app/views/PlaySceneGold"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	elseif tonumber(msgTbl.m_state) == 1101 then--比赛场
		local playScene = require("app/views/PlaySceneMatch"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	end
	gt.WaitTime = msgTbl.m_opOutTime
end

-- start --
--------------------------------
-- @class function
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvRoomCard(msgTbl)
	gt.dump(msgTbl)
	local playerData = gt.playerData
	playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3,msgTbl.m_coins}
	-- 玩家信息
	local Node_top = gt.seekNodeByName(self.rootNode, "Node_top")
	local Node_playerInfo = gt.seekNodeByName(Node_top, "Node_playerInfo")
	-- 房卡信息
	local Txt_numbereight = gt.seekNodeByName(Node_playerInfo, "Txt_numbereight")
	Txt_numbereight:setString(playerData.roomCardsCount[2])
	--金币信息
	local Gold_Num = gt.seekNodeByName(Node_playerInfo, "Gold_Num")
	Gold_Num:setString(gt.formatCoinNumber(playerData.roomCardsCount[4]))
end

-- start --
--------------------------------
-- @class function
-- @description 赠送金币
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvGiveGold(msgTbl)
	gt.log("赠送金币－－－－－－－－－－－")
	gt.dump(msgTbl)
	local playerData = gt.playerData
	playerData.roomCardsCount[4] = playerData.roomCardsCount[4] + msgTbl.m_coins
	--金币信息
	local Gold_Num = gt.seekNodeByName(self.rootNode, "Gold_Num")
	if Gold_Num then
		Gold_Num:setString(gt.formatCoinNumber(playerData.roomCardsCount[4]))
	end

	local str_des = string.format("系统赠送您%d金币,今日免费领取剩余%d次！",msgTbl.m_coins,msgTbl.m_remainCount)
	require("app/views/NoticeTips"):create("提示", str_des, nil, nil, true)
end

-- start --
--------------------------------
-- @class function
-- @description 接收跑马灯消息
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvMarquee(msgTbl)
	gt.log("限时活动balabala")
	dump(msgTbl)
	if gt.isIOSPlatform() and gt.isInReview then
		gt.marqueeMsgTemp = gt.getLocationString("LTKey_0048")
		self.marqueeMsg:showMsg(gt.marqueeMsgTemp)
	else
		if msgTbl.m_type == 0 then
            -- 已经改用分IP新的跑马灯
		elseif msgTbl.m_type == 1 then

			gt.FreeGameType = {}
			require("json")
			gt.log("string.len(msgTbl.m_str) = "..string.len(msgTbl.m_str))
			if string.len(msgTbl.m_str)>0 then
				local respJson = json.decode(msgTbl.m_str)
				gt.dump(respJson)
				if respJson ~= nil and #respJson >0 then
					for i,v in ipairs(respJson) do
						gt.dump(v)
						if v.GameType == "All" then
							gt.FreeGameType = gt.AllGameType
						else
							table.insert(gt.FreeGameType,tonumber(v.GameType))
						end
					end
				else
					gt.FreeGameType = {}
				end
			end
			table.sort(gt.FreeGameType)
			if #gt.FreeGameType > 2 then
				for i=2,#gt.FreeGameType do
					if gt.FreeGameType[i] == gt.FreeGameType[i-1] then
						table.remove(gt.FreeGameType,i-1)
					end
				end
			end
			gt.dump(gt.FreeGameType)

		elseif msgTbl.m_type == 2 then
			if string.len(msgTbl.m_str) > 1 then
				gt.IsExchangeGoldActShow = true
				require("json")
   				local respJson = json.decode(msgTbl.m_str)
   				local beginTime = os.date("*t", respJson.StartTime)
   				beginTime = beginTime.year .. "年" .. beginTime.month .. "月" .. beginTime.day .. "日 " .. beginTime.hour .. ":" .. beginTime.min
   				local EndTime = os.date("*t", respJson.EndTime)
   				EndTime = EndTime.year .. "年" .. EndTime.month .. "月" .. EndTime.day .. "日 " .. EndTime.hour .. ":" .. EndTime.min
				gt.GoldTime = "活动时间：" .. beginTime  .. "至" .. EndTime
				gt.Exchange = respJson.Exchange
				gt.log(gt.GoldTime)
				self.Button_ExchangeGold:setVisible(true)
			else
				gt.IsExchangeGoldActShow = false
				self.Button_ExchangeGold:setVisible(false)
			end
		end
	end
end

--创建房间消息
function MainScene:onRcvDeskError(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		-- 创建失败
		gt.removeLoadingTips()
		if msgTbl.m_errorCode == 1 then
			if msgTbl.m_remainCount == 0 then
				require("app/views/NoticeTips"):create("提示", "您的金币不够！！！", nil, nil, true)
			else
				require("app/views/NoticeTips"):create("提示", "金币不足,请点击确定领取！！！", function ()
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_GET_GOLDS
					msgToSend.m_userid = gt.m_id
					gt.socketClient:sendMessage(msgToSend)
					gt.dump(msgToSend)
				end,nil, false)
			end
		elseif msgTbl.m_errorCode == 3 then
			require("app/views/NoticeTips"):create("提示", "未知错误！！！", nil, nil, true)
		elseif msgTbl.m_errorCode == 4 then
			require("app/views/NoticeTips"):create("提示", "进入金币场桌子失败！！！", nil, nil, true)
		elseif msgTbl.m_errorCode == 6 then
			require("app/views/NoticeTips"):create("提示", "金币场人数太多，请稍后！！！", nil, nil, true)
		elseif msgTbl.m_errorCode == 2 then
			require("app/views/NoticeTips"):create("提示", "已有房间，暂时无法进入！！！", nil, nil, true)
		else
			require("app/views/NoticeTips"):create("提示", "无法进入！！！", nil, nil, true)
		end
	end
end

--玩家领取金币成功
function MainScene:onRcvGetGold(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_result == 0 then
		local str_des = string.format("系统赠送您%d金币,今日免费领取剩余%d次！",msgTbl.m_coins,msgTbl.m_remainCount)
		require("app/views/NoticeTips"):create("提示", str_des, nil, nil, true)
	else
		require("app/views/NoticeTips"):create("提示", "领取失败，已无免费领取次数！！！", nil, nil, true)
	end
end

function MainScene:gmCheckHistoryEvt(eventType, uid)
	gt.log("---------0000997666--" .. uid)
	local historyRecord = require("app/views/HistoryRecord"):create(uid)
	self:addChild(historyRecord, MainScene.ZOrder.HISTORY_RECORD)
end

--玩家通过点击url打开游戏直接进入房间
function MainScene:JoinUrlRoom()
	gt.log("function is getRoomIDUrl")
	if gt.roomState and gt.roomState ~= 0 then
		gt.log("gt.roomState = "..gt.roomState)
		return
	end
	local RoomID = ""
	local RoomIDUrl = gt.getRoomIDUrl()
	if string.find(RoomIDUrl,"roomId=") then
		local a = string.find(RoomIDUrl,"roomId=")+7
		local b = a+6
		gt.log("a = "..a.."b = "..b)
		RoomID = string.sub(RoomIDUrl,a,b)
	end
	if string.len(RoomID) == 6 and type(tonumber(RoomID)) == "number" then
		gt.log("RoomID = "..RoomID)
		-- 发送进入房间消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_JOIN_ROOM
		msgToSend.m_deskId = tonumber(RoomID)
		gt.socketClient:sendMessage(msgToSend)
		gt.dump(msgToSend)
		gt.showLoadingTips(gt.getLocationString("LTKey_0006"))
		gt.CopyText(" ")
	else
		if not self.isRoomCreater then
			self:CopyRoomId()--直接进入粘贴板的房间
		end
	end
	if self.isRoomCreater then
		gt.log("isRoomCreater = true")
	else
		gt.log("isRoomCreater = false")
	end
end

MainScene.requestMarqueeCurTime = 0
MainScene.lastMsg = nil
function MainScene:requestMarquee()
    local curTime = os.time()
    if MainScene.requestMarqueeCurTime ~= 0 and curTime - MainScene.requestMarqueeCurTime < 3600 then
        if MainScene.lastMsg then
            self.marqueeMsg:showMsg(MainScene.lastMsg)
        end
        return
    end
    MainScene.requestMarqueeCurTime = curTime

    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    local userInfoURL = string.format("https://active.xianlaigame.com/xlhy-activity/hallMarquee/getContent?serverCode=%s&gameId=%s&userIp=%s", "sichuan_db", "15001", gt.playerData.ip)
    dump(userInfoURL)
    xhr:open("GET", userInfoURL)

    local function onResp()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local response = xhr.response
            require("json")
            local respJson = json.decode(response)
            if respJson then
                local str_des = respJson.hallMarqueeContent
                self.marqueeMsg:showMsg(str_des)
                MainScene.lastMsg = str_des
            end
        elseif xhr.readyState == 1 and xhr.status == 0 then
            local str_des = gt.getLocationString("LTKey_0048")
            self.marqueeMsg:showMsg(str_des)
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onResp)
    xhr:send()
end

return MainScene
