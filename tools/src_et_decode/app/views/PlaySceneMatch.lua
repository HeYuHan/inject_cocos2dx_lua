
-- this is Match with playScene
-- code by zhaozeguang
-- 2017-6-21 17:00

local gt = cc.exports.gt
local loginStrategy = require("app/LoginIpStrategy")
local PlaySceneMatch = class("PlaySceneMatch", function()
	return cc.Scene:create()
end)

PlaySceneMatch.DecisionType = {
	-- 接炮胡
	TAKE_CANNON_WIN				= 1,
	-- 自摸胡
	SELF_DRAWN_WIN				= 2,
	-- 明杠
	BRIGHT_BAR					= 3,
	-- 暗杠
	DARK_BAR					= 4,
	-- 碰
	PUNG						= 5,
	-- 吃
	EAT					        = 6,
	--眀补
	BRIGHT_BU                   = 7,
	--暗补
	DARK_BU                     = 8,
	--抢杠
	QIANG_GANG                  = 9
}

PlaySceneMatch.ZOrder = {
	MJTABLE						= 1,
	PLAYER_INFO					= 2,
	MJTILES						= 6,
	OUTMJTILE_SIGN				= 7,
	DECISION_BTN				= 8,
	DECISION_SHOW				= 9,
	PLAYER_INFO_TIPS			= 10,
	REPORT						= 16,
	DISMISS_ROOM				= 17,
	SETTING						= 18,
	CHAT						= 20,
	MJBAR_ANIMATION				= 21,
	FLIMLAYER           	    = 16,
	HAIDILAOYUE					= 23,

	ROUND_REPORT				= 66 -- 单局结算界面显示在总结算界面之上
}

PlaySceneMatch.FLIMTYPE = {
	FLIMLAYER_BAR				= 1,
	FLIMLAYER_BU				= 2,
}

PlaySceneMatch.TAG = {
	FLIMLAYER_BAR				= 50,
	FLIMLAYER_BU				= 51,
}

function PlaySceneMatch:ctor(enterRoomMsgTbl)
	gt.log("__________this is PlaySceneMatch____________")
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	-- 加载界面资源
	local csbNode, animation = gt.createCSAnimation("PlaySceneMatch.csb")

	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "mahjong_table"):setScale(1280/960)
		gt.seekNodeByName(csbNode, "Label_time"):setPositionY(802)
        gt.seekNodeByName(csbNode, "Text_TableType_BG"):setPositionY(808)
		gt.seekNodeByName(csbNode, "Btn_outRoom"):setPositionY(740)
		gt.seekNodeByName(csbNode, "Btn_dimissRoom"):setPositionY(-70)
		gt.seekNodeByName(csbNode, "Btn_setting"):setPositionY(740)
		gt.seekNodeByName(csbNode, "Btn_message"):setPositionY(660)

		gt.seekNodeByName(csbNode, "Node_WIFI"):setPositionY(100)

		gt.seekNodeByName(csbNode, "Sprite_IPsame"):setPositionY(875)
		gt.seekNodeByName(csbNode, "Node_playerInfo_2"):setPositionY(670)
		gt.seekNodeByName(csbNode, "Node_playerInfo_4"):setPositionY(154)

		local Node_playerMjTiles_2 = gt.seekNodeByName(csbNode, "Node_playerMjTiles_2")
		gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileHold_1"):setPositionY(730)
		gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileHold_2"):setPositionY(730)
		gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileOut_1"):setPositionY(658)
		gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileOut_2"):setPositionY(658)
		gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileOut_3"):setPositionY(617)
		gt.seekNodeByName(Node_playerMjTiles_2, "Panel_mjTileGroup"):setPositionY(702)
		gt.seekNodeByName(Node_playerMjTiles_2, "Node_showMjTile"):setPositionY(616)

		local Node_playerMjTiles_4 = gt.seekNodeByName(csbNode, "Node_playerMjTiles_4")
		gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileHold_1"):setPositionY(-20)
		gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileHold_2"):setPositionY(-20)
		gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileOut_1"):setPositionY(78)
		gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileOut_2"):setPositionY(78)
		gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileOut_3"):setPositionY(119)
		gt.seekNodeByName(Node_playerMjTiles_4, "Panel_mjTileGroup"):setPositionY(-77)
		gt.seekNodeByName(Node_playerMjTiles_4, "Node_showMjTile"):setPositionY(106)
	end

	-- 胡牌之后,单据结算界面延迟显示时间
	self.reportDelayTime = 1.2
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 刚进入房间,隐藏玩家信息节点
	for i = 1, 4 do
		local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		playerNode:setVisible(false)
	end
	self:hidePlayersReadySign()
	-- 隐藏玩家麻将参考位置（麻将参考位置父节点，pos(0，0）)
	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	playNode:setVisible(false)
	-- 隐藏轮换位置标识（东南西北信息）
	self.turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	self.turnPosBgSpr:setVisible(false)
	for i=1,4 do
		local turnPosSpr = gt.seekNodeByName(self.turnPosBgSpr, "Spr_turnPos_" .. i)
		local fadeOut = cc.FadeOut:create(0.4)
		local fadeIn = cc.FadeIn:create(0.4)
		local seqAction = cc.Sequence:create(fadeOut, fadeIn)
		turnPosSpr:runAction(cc.RepeatForever:create(seqAction))
	end
	-- 倒计时
	self.playTimeCDLabel = gt.seekNodeByName(self.rootNode, "Label_playTimeCD")
	gt.WaitTime = 8
	gt.ChangeTime = 15
	if enterRoomMsgTbl.m_opOutTime then
		gt.WaitTime = enterRoomMsgTbl.m_opOutTime
	end
	if enterRoomMsgTbl.m_changeOutTime then
		gt.ChangeTime = enterRoomMsgTbl.m_changeOutTime
	end
	
	self.playTimeCDLabel:setString("0")

	-- 隐藏牌局状态（倒计时，剩余牌局，剩余牌数）
	self.roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	self.roundStateNode:setVisible(false)
	-- 隐藏玩家决策按钮（碰，杠，胡，过的父节点）
	self.decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
	self.rootNode:reorderChild(self.decisionBtnNode, PlaySceneMatch.ZOrder.DECISION_BTN)
	self.decisionBtnNode:setVisible(false)
	-- 隐藏自摸决策暗杠，碰转明杠，自摸胡
	self.selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
	self.rootNode:reorderChild(self.selfDrawnDcsNode, PlaySceneMatch.ZOrder.DECISION_BTN)
	self.selfDrawnDcsNode:setVisible(false)
	-- 隐藏游戏中设置按钮
	self.playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
	self.playBtnsNode:setVisible(false)
	-- 隐藏准备按钮
	self.readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	self.readyBtn:setVisible(true)
	gt.addBtnPressedListener(self.readyBtn, handler(self, self.readyBtnClickEvt))

	-- 隐藏所有玩家对话框
	local chatBgNode = gt.seekNodeByName(self.rootNode, "Node_chatBg")
	self.rootNode:reorderChild(chatBgNode, PlaySceneMatch.ZOrder.CHAT)
	chatBgNode:setVisible(false)

	local settingBtn = gt.seekNodeByName(self.playBtnsNode, "Btn_setting")
	gt.addBtnPressedListener(settingBtn, function()
		if gt.debugMode then
			local settingPanel = require("app/views/Setting"):create(enterRoomMsgTbl.m_pos,1)
			self:addChild(settingPanel, PlaySceneMatch.ZOrder.SETTING,102)
		else
			local settingPanel = require("app/views/Setting"):create(enterRoomMsgTbl.m_pos,3)
			self:addChild(settingPanel, PlaySceneMatch.ZOrder.SETTING,102)
		end
	end)
	local messageBtn = gt.seekNodeByName(self.playBtnsNode, "Btn_message")
	gt.addBtnPressedListener(messageBtn, function()
		local chatPanel = require("app/views/ChatPanel"):create()
		self:addChild(chatPanel, PlaySceneMatch.ZOrder.CHAT , 101)
	end)

	-- 麻将层
	local playMjLayer = cc.Layer:create()
	self.rootNode:addChild(playMjLayer, PlaySceneMatch.ZOrder.MJTILES)
	self.playMjLayer = playMjLayer

	-- 出的牌标识动画
	local outMjtileSignNode, outMjtileSignAnime = gt.createCSAnimation("animation/OutMjtileSign.csb")
	outMjtileSignAnime:play("run", true)
	outMjtileSignNode:setVisible(false)
	self.rootNode:addChild(outMjtileSignNode, PlaySceneMatch.ZOrder.OUTMJTILE_SIGN)
	self.outMjtileSignNode = outMjtileSignNode

	-- 头像下载管理器
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	self.rootNode:addChild(playerHeadMgr)
	self.playerHeadMgr = playerHeadMgr

	self.readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
	self.readyPlayNode:setVisible(true)
	-- 获取luabridge
	self:getLuaBridge()
	-- 玩家进入房间
	self:playerEnterRoom(enterRoomMsgTbl)

	-- 最大局数
	self.roundMaxCount = enterRoomMsgTbl.m_maxCircle
	-- 准备界面逻辑
	local paramTbl = {}
	paramTbl.roomID = enterRoomMsgTbl.m_deskId
	paramTbl.playerSeatPos = enterRoomMsgTbl.m_pos
	paramTbl.m_state = enterRoomMsgTbl.m_state
	paramTbl.roundMaxCount = enterRoomMsgTbl.m_maxCircle
	paramTbl.playtypebranch = enterRoomMsgTbl.m_playtype
	self.readyPlay = require("app/views/ReadyPlay"):create(csbNode, paramTbl)

	-- 解散房间
	self.applyDimissRoom = require("app/views/ApplyDismissRoom"):create(self.roomPlayers, self.playerSeatIdx)
	self:addChild(self.applyDimissRoom, PlaySceneMatch.ZOrder.DISMISS_ROOM)

	--语音提示
	local yuyinNode =  gt.seekNodeByName(self.rootNode, "Node_yuyin")
	if yuyinNode then
		yuyinNode:setVisible(false)
		self.yuyinNode = yuyinNode
	end

	local yuyinChatNode = gt.seekNodeByName(self.rootNode, "Node_Yuyin_Dlg")
	if yuyinChatNode then
		yuyinChatNode:setVisible(false)
		self.yuyinChatNode = yuyinChatNode
	end

	--定缺
	local dingque = gt.seekNodeByName(self.rootNode,"Node_ding")
	dingque:setVisible(false)
	self.dingque = dingque

	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	hutypeNode:setVisible(false)
	for i=1,4 do
		local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
		hutypeSubNode:setVisible(false)
	end
	
	
	-- 正式包点击语音按钮回调函数
	self.starAudioTime = 0
	local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.began then
            self.sendVocie = false
            self:playYuYinAnimation()
	        gt.soundEngine:pauseAllSound()
	        self.sendVocie = true
	        self.yuyinNode:setVisible(true)
	        self.rootNode:reorderChild(self.yuyinNode, 100)
	        self:startAudio()
	        self.starAudioTime = os.time()
        elseif eventType == ccui.TouchEventType.moved then

        elseif eventType == ccui.TouchEventType.ended then
		    self.yuyinNode:setVisible(false)
		    self:cancelYuYinAnimation()
	    	gt.soundEngine:resumeAllSound()
	    	local time = os.time()
	    	if time - self.starAudioTime > gt.audioTime then
	    		self:stopAudio()
	    	else
	    		self:cancelAudio()
	    		require("app/views/NoticeTips"):create("提示", "语音时间小于".. gt.audioTime .."秒，不能发送。", nil, nil, true)
	    	end
        elseif eventType == ccui.TouchEventType.canceled then
        	self.yuyinNode:setVisible(false)
        	self:cancelYuYinAnimation()
            gt.soundEngine:resumeAllSound()
		    self:cancelAudio()
        end
    end
    self.yuyinBtn = gt.seekNodeByName(self.rootNode,"Btn_Voice")
    self.yuyinBtn:addTouchEventListener(touchEvent)

    if gt.isIOSPlatform() or gt.isAndroidPlatform() then
    	self:initWifi()
    end

	-- 是否是最后一局
	self.lastRound = false

	-- 是否是胡牌状态 false表示没有胡牌
	self.ownerWin = false

	-- 定缺的标志
	local dingqueTypeTable = {}
	self.dingqueTypeTable = dingqueTypeTable

	-- 定缺的状态 false 没有定缺
	self.dingqueColorState = false

	local dingqueColorTable = {}
	self.dingqueColorTable = dingqueColorTable

	-- 隐藏定缺的标志
	for i=1,4 do
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local Image_que = gt.seekNodeByName(playerInfoNode,"Image_que")
		Image_que:setVisible(false)
	end

	local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
	node_ReplaceThreeCard:setVisible(false)

	-- 当前换三张的状态 false表示没换过  
	self.replaceThreeCardType = false

	-- 用户选择的三张牌
	local replaceThreeCardTable = {}
	self.replaceThreeCardTable = replaceThreeCardTable

	-- 用户新换的三张牌
	local replaceNewThreeCardTable = {}
	self.replaceNewThreeCardTable = replaceNewThreeCardTable

	-- 纪录谁换过了牌
	local replaceThreeOkType = {}
	self.replaceThreeOkType = replaceThreeOkType

	-- 自己换三张后锁定状态
	self.ownerReplaceCardType = false

	-- 自己发送了换三张消息
	self.ownerSendReplaceCardMsg = false

	-- 限制发牌之前  手速过快点击 闪退bug
	self.fastTouchBugType = false

	-- 是否支持换三张
	self.isPlayThreeCardState = false
	self:onTablePlayState(enterRoomMsgTbl)

	self.startGame = true

	-- 隐藏新版本出牌
	local OutPaiBgNode = gt.seekNodeByName(csbNode,"OutPaiBgNode")
	OutPaiBgNode:setVisible(false)

	-- 胡牌索引
	self.huIndex = 0

	-- 接收消息分发函数
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
	gt.socketClient:registerMsgListener(gt.GC_ENTER_ROOM, self, self.onRcvEnterRoom)
	gt.socketClient:registerMsgListener(gt.GC_ADD_PLAYER, self, self.onRcvAddPlayer)
	gt.socketClient:registerMsgListener(gt.GC_REMOVE_PLAYER, self, self.onRcvRemovePlayer)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_ROOM_STATE, self, self.onRcvSyncRoomState)
	gt.socketClient:registerMsgListener(gt.GC_READY, self, self.onRcvReady)
	gt.socketClient:registerMsgListener(gt.GC_OFF_LINE_STATE, self, self.onRcvOffLineState)
	gt.socketClient:registerMsgListener(gt.GC_ROUND_STATE, self, self.onRcvRoundState)
	gt.socketClient:registerMsgListener(gt.GC_START_GAME, self, self.onRcvStartGame)
	gt.socketClient:registerMsgListener(gt.GC_TURN_SHOW_MJTILE, self, self.onRcvTurnShowMjTile)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_SHOW_MJTILE, self, self.onRcvSyncShowMjTile)
	gt.socketClient:registerMsgListener(gt.GC_MAKE_DECISION, self, self.onRcvMakeDecision)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_MAKE_DECISION, self, self.onRcvSyncMakeDecision)
	gt.socketClient:registerMsgListener(gt.GC_CHAT_MSG, self, self.onRcvChatMsg)
	gt.socketClient:registerMsgListener(gt.GC_XUELIU_ROUND, self, self.onRcvRoundXueliu)
	gt.socketClient:registerMsgListener(gt.GC_ROUND_REPORT, self, self.onRcvRoundReport)
	gt.socketClient:registerMsgListener(gt.GC_FINAL_REPORT, self, self.onRcvFinalReport)
	-- gt.socketClient:registerMsgListener(gt.GC_START_DECISION, self, self.onRcvStartDecision)
	-- gt.socketClient:registerMsgListener(gt.GC_SYNC_BAR_TWOCARD, self, self.onRcvSyncBarTwoCard)
	-- gt.socketClient:registerMsgListener(gt.GC_SYNC_START_PLAYER_DECISION, self, self.onRcvSyncStartDecision)--起手胡消息废弃
	gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)-- 断线重连
	gt.socketClient:registerMsgListener(gt.GC_MARQUEE, self, self.onRcvMarquee)-- 跑马灯
	gt.socketClient:registerMsgListener(gt.CG_USER_DING_QUE, self, self.onRecUserDingQue)-- 新命令 用户定缺
	gt.socketClient:registerMsgListener(gt.CG_REPLACE_CARD, self, self.onRecUserReplaceCard)	-- 新命令 换三张
	gt.socketClient:registerMsgListener(gt.CG_REPLACE_CARD_CHOOSE, self, self.onRecUserReplaceCardComplate)-- 换牌结果
	gt.socketClient:registerMsgListener(gt.CG_REMOVE_BAR_CARD,self,self.onRecUserRemoveBarCard)
	gt.socketClient:registerMsgListener(gt.CG_USER_DING_QUE_COMPLATE,self,self.onRecUserDingQueComplate)-- 用户定缺完成
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER,self,self.onRcvLoginServer)--解散房间后回调
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_GATE, self, self.onRcvLoginGate)

	--金币场相关
	gt.socketClient:registerMsgListener(gt.GC_OUT_GOLD_ROONM, self, self.onRcvReturnMainScene)
	gt.socketClient:registerMsgListener(gt.GC_USER_AI_GIVE, self, self.onRcvUserPlayWork)
	gt.socketClient:registerMsgListener(gt.GC_GIVE_GLOLD, self, self.onRcvGiveGold)
	gt.socketClient:registerMsgListener(gt.GC_GET_GOLDS, self, self.onRcvGetGold)--点击领取金币后服务器返回的消息	
	gt.socketClient:registerMsgListener(gt.GC_PLAYER_GOLDS, self, self.onRcvplayerGold)--广播玩家金币消息
	
	gt.socketClient:registerMsgListener(gt.GC_GOON_NEXTGAME, self, self.onRcvGoonNext)
	gt.registerEventListener(gt.EventType.BACK_MAIN_SCENE, self, self.backMainSceneEvt)
end

function PlaySceneMatch:onRcvGoonNext(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_errorCode == 0 then
		if self:getChildByTag(103) then
			self:getChildByTag(103):removeFromParent()
		end
	else
		if msgTbl.m_errorCode == 1 then
			if msgTbl.m_remainCount == 0 then
				require("app/views/NoticeTips"):create("提示", "金币不足,今日已无免费领取次数！！！",function ()
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_QUIT_ROOM
					msgToSend.m_pos = self.playerSeatIdx - 1
					gt.socketClient:sendMessage(msgToSend)
					self:backMainSceneEvt()
				end,nil, true)
			else
				require("app/views/NoticeTips"):create("提示", "金币不足，请点确定领取！！！", function ()
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_GET_GOLDS
					msgToSend.m_userid = gt.m_id
					gt.socketClient:sendMessage(msgToSend)
					gt.dump(msgToSend)
				end,function ()
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_QUIT_ROOM
					msgToSend.m_pos = self.playerSeatIdx - 1
					gt.socketClient:sendMessage(msgToSend)
					self:backMainSceneEvt()
				end, false)
			end
		elseif msgTbl.m_errorCode == 2 then
			require("app/views/NoticeTips"):create("提示", "系统错误，请重新进入游戏！！！", handler(self, self.onRcvReturnMainScene),nil,  true)
		elseif msgTbl.m_errorCode == 3 then
			require("app/views/NoticeTips"):create("提示", "未知错误！！！", handler(self, self.onRcvReturnMainScene), nil, true)
		elseif msgTbl.m_errorCode == 4 then
			require("app/views/NoticeTips"):create("提示", "创建桌子失败！！！",  handler(self, self.onRcvReturnMainScene),nil, true)
		elseif msgTbl.m_errorCode == 5 then
			require("app/views/NoticeTips"):create("提示", "系统参数错误！！！",  handler(self, self.onRcvReturnMainScene),nil, true)
		end
	end
end

--玩家领取金币成功
function PlaySceneMatch:onRcvGetGold(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_result == 0 then
		local str_des = string.format("系统赠送您%d金币,今日免费领取剩余%d次！",msgTbl.m_coins,msgTbl.m_remainCount)
		require("app/views/NoticeTips"):create("提示", str_des, nil, nil, true)
	else
		require("app/views/NoticeTips"):create("提示", "领取失败，已无免费领取次数！！！", nil, nil, true)
	end
end

--广播玩家金币信息
function PlaySceneMatch:onRcvplayerGold(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_pos then
		local seatIdx = msgTbl.m_pos + 1
		local roomPlayer = self.roomPlayers[seatIdx]
		roomPlayer.scoreLabel:setString(tostring(gt.formatCoinNumber(msgTbl.m_coins)))
	end
end

function PlaySceneMatch:playYuYinAnimation()
	local action = nil
	local yuyinNode, action = gt.createCSAnimation("huatong.csb")
	action:play("huatong", true)
	yuyinNode:setPosition(cc.p(self.yuyinNode:getContentSize().width/2,
							   self.yuyinNode:getContentSize().height/2))
	self.yuyinNode:addChild(yuyinNode, 1000)
	self.m_yuyinNode = yuyinNode
end

function PlaySceneMatch:cancelYuYinAnimation()
	if self.m_yuyinNode then
		self.m_yuyinNode:removeFromParent()
		self.m_yuyinNode = nil
	end
end

function PlaySceneMatch:getLuaBridge()
	if self.luaBridge then
		return
	end

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end
end

function PlaySceneMatch:unregisterAllMsgListener()
	gt.log("remove all msgListener!!!")
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
	gt.socketClient:unregisterMsgListener(gt.GC_ENTER_ROOM)
	gt.socketClient:unregisterMsgListener(gt.GC_ADD_PLAYER)
	gt.socketClient:unregisterMsgListener(gt.GC_REMOVE_PLAYER)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_ROOM_STATE)
	gt.socketClient:unregisterMsgListener(gt.GC_READY)
	gt.socketClient:unregisterMsgListener(gt.GC_OFF_LINE_STATE)
	gt.socketClient:unregisterMsgListener(gt.GC_ROUND_STATE)
	gt.socketClient:unregisterMsgListener(gt.GC_START_GAME)
	gt.socketClient:unregisterMsgListener(gt.GC_TURN_SHOW_MJTILE)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_SHOW_MJTILE)
	gt.socketClient:unregisterMsgListener(gt.GC_MAKE_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_MAKE_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_CHAT_MSG)
	gt.socketClient:unregisterMsgListener(gt.GC_XUELIU_ROUND)--血流结算
	gt.socketClient:unregisterMsgListener(gt.GC_ROUND_REPORT)
	gt.socketClient:unregisterMsgListener(gt.GC_FINAL_REPORT)
	gt.socketClient:unregisterMsgListener(gt.GC_START_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_START_PLAYER_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_BAR_TWOCARD)


	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN)

	gt.socketClient:unregisterMsgListener(gt.CG_USER_DING_QUE)

	gt.socketClient:unregisterMsgListener(gt.CG_REPLACE_CARD)
	gt.socketClient:unregisterMsgListener(gt.CG_REPLACE_CARD_CHOOSE)

	gt.socketClient:unregisterMsgListener(gt.CG_REMOVE_BAR_CARD)
	gt.socketClient:unregisterMsgListener(gt.CG_USER_DING_QUE_COMPLATE)

	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)

	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_GATE)

	gt.socketClient:unregisterMsgListener(gt.GC_MARQUEE)
	--金币场相关
	gt.socketClient:unregisterMsgListener(gt.GC_OUT_GOLD_ROONM)
	gt.socketClient:unregisterMsgListener(gt.GC_GIVE_GLOLD)
	gt.socketClient:unregisterMsgListener(gt.GC_GOON_NEXTGAME)
	gt.socketClient:unregisterMsgListener(gt.GC_USER_AI_GIVE)
	gt.socketClient:unregisterMsgListener(gt.GC_GET_GOLDS)
	gt.socketClient:unregisterMsgListener(gt.GC_PLAYER_GOLDS)
end

-- start --
--------------------------------
-- @class function
-- @description 服务器返回登录大厅结果
-- end --
function PlaySceneMatch:onRcvLoginServer(msgTbl)
	gt.removeLoadingTips()
	gt.socketClient:setIsStartGame(true)
	gt.socketClient:setIsCloseHeartBeat(false)

	-- 判断进入大厅还是房间
	if self.finalReport == nil then
		if msgTbl.m_state == 0 then
			gt.removeTargetAllEventListener(self)
			self:unregisterAllMsgListener()

			-- 进入大厅主场景
			-- 判断是否是新玩家
			local isNewPlayer = msgTbl.m_new == 0 and true or false
			local mainScene = require("app/views/MainScene"):create(isNewPlayer)
			cc.Director:getInstance():replaceScene(mainScene)
		end
	end
end

function PlaySceneMatch:onRecUserRemoveBarCard( msgTbl )
	self.isPlayerShow = false
	dump(msgTbl)

	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]
	if seatIdx == self.playerSeatIdx then
		-- 玩家持有牌中去除牌
		for k,v in pairs(roomPlayer.holdMjTiles) do

			if msgTbl.m_color == v.mjColor and msgTbl.m_number == v.mjNumber then
				local mjTile = roomPlayer.holdMjTiles[k]
				if mjTile then
					mjTile.mjTileSpr:removeFromParent()
					table.remove(roomPlayer.holdMjTiles, k)
				end
				self:sortPlayerMjTiles()
				break
			end
		end

	else
		roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
		roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1
	end

end

-- 断线重连,走一次登录流程
function PlaySceneMatch:reLogin()
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
end

function PlaySceneMatch:onRcvLogin(msgTbl)
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
end


--服务器返回gate登录
function PlaySceneMatch:onRcvLoginGate( msgTbl )
	gt.dump( msgTbl )

	gt.socketClient:setPlayerKeyAndOrder(msgTbl.m_strKey, msgTbl.m_uMsgOrder)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	msgToSend.m_seed = gt.loginSeed
	msgToSend.m_id = gt.m_id
	local catStr = tostring(gt.loginSeed)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)


end

function PlaySceneMatch:onNodeEvent(eventName)
	if "enter" == eventName then
		-- 计算更新当前时间倒计时
		local curTimeStr = os.date("%X", os.time())
		local timeSections = string.split(curTimeStr, ":")
		local secondTime = tonumber(timeSections[3])
		self.updateTimeCD = 60 - secondTime
		self:updateCurrentTime()

		-- 触摸事件
		self.isTouchBegan = false
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		listener:registerScriptHandler(handler(self, self.onTouchCancelled), cc.Handler.EVENT_TOUCH_CANCELLED)
		local eventDispatcher = self.playMjLayer:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.playMjLayer)

		-- 逻辑更新定时器
		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)

		gt.soundEngine:playMusic("bgm2", true)

	    self._listener1 = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND_EVENT", handler(self, self.onEnterBackground))
	    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	    eventDispatcher:addEventListenerWithFixedPriority(self._listener1, 1)
	 	local function onEvent2(event)
	 		if gt.isIOSPlatform() or gt.isAndroidPlatform then
	 			gt.socketClient:reloginServer()
	 		end
	 		gt.resume_time = 1
	    end
	    self.foregroundEvent = cc.EventListenerCustom:create("APP_ENTER_FOREGROUND_EVENT", onEvent2)
	    eventDispatcher:addEventListenerWithFixedPriority(self.foregroundEvent, 1)

	elseif "exit" == eventName then
		local eventDispatcher = self.playMjLayer:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self.playMjLayer)

		cc.Director:getInstance():getEventDispatcher():removeEventListener(self._listener1)
		cc.Director:getInstance():getEventDispatcher():removeEventListener(self.foregroundEvent)
		
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		-- 屏蔽掉音效的update
		if self.voiceUrlScheduleHandler then
			gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
			self.voiceUrlScheduleHandler = nil
		end

		gt.soundEngine:playMusic("bgm1", true)
	end
end

--金币场踢人
function PlaySceneMatch:onRcvReturnMainScene(msgTbl)
	-- gt.dump(msgTbl)
	-- 事件回调
	gt.removeTargetAllEventListener(self)
	-- 消息回调
	self:unregisterAllMsgListener()

	local mainScene = require("app/views/MainScene"):create(false, false, nil)
	cc.Director:getInstance():replaceScene(mainScene)
end

--玩家自动出牌
function PlaySceneMatch:onRcvUserPlayWork(msgTbl)
	gt.log("客户端摸牌后的操作")
	gt.dump(msgTbl)
	if not msgTbl.m_card then return end
	self.AIoutcard = true
	if  msgTbl.m_type == 1 then
		self.isPlayerShow = false
		-- 停止倒计时音效
		if self.playCDAudioID then
			gt.soundEngine:stopEffect(self.playCDAudioID)
			self.playCDAudioID = nil
		end

		-- 把牌先打出去
		self:addAlreadyOutMjTiles(self.playerSeatIdx, msgTbl.m_card[1][1], msgTbl.m_card[1][2])
		-- 显示出的牌箭头标识
		self:showOutMjtileSign(self.playerSeatIdx)

		self:outPaiBigAnimate(self.playerSeatIdx,msgTbl.m_card[1][1], msgTbl.m_card[1][2],1)

		-- 玩家持有牌中去除打出去的牌
		local mj_color = msgTbl.m_card[1][1]
		local mj_number = msgTbl.m_card[1][2]
		local roomPlayer = self.roomPlayers[self.playerSeatIdx]
		for i = #roomPlayer.holdMjTiles, 1, -1 do
			local mjTile = roomPlayer.holdMjTiles[i]
			if mjTile.mjColor == mj_color and mjTile.mjNumber == mj_number then
				mjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles, i)
				break
			end
		end
		gt.soundManager:PlayCardSound(gt.playerData.sex, mj_color, mj_number)
		self:sortPlayerMjTiles()
		if self:checkRightCradNum() == false then
			self.isTouchBegan = false
			gt.socketClient:reloginServer()
			return
		end
		self:checkOutMjTile(0,0)

		if self.selfDrawnDcsNode:isVisible() or self.decisionBtnNode:isVisible() then
			self.selfDrawnDcsNode:setVisible(false)
			self.decisionBtnNode:setVisible(false)
			gt.log("msgTbl.m_type == 1")
		end
	elseif  msgTbl.m_type == 0 then
		if self.selfDrawnDcsNode:isVisible() or self.decisionBtnNode:isVisible() then
			self.selfDrawnDcsNode:setVisible(false)
			self.decisionBtnNode:setVisible(false)
			gt.log("msgTbl.m_type == 0")
		end
	elseif  msgTbl.m_type == -2 then
		--换三张
	else
		gt.log("msgTbl.m_type ~= 1"..msgTbl.m_type)
	end
	self.isPlayerDecision = false
end

-- start --
--------------------------------
-- @class function
-- @description 出牌倒计时
-- @param
-- @param
-- @param
-- @return
-- end --
function PlaySceneMatch:playTimeCDStart(timeDuration)
	if timeDuration then
		self.playTimeCD = timeDuration
	else
		self.playTimeCD = 10
	end

	self.isVibrateAlarm = false
	self.playTimeCDLabel:setVisible(true)
	self.playTimeCDLabel:setString(tostring(timeDuration))
end

-- start --
--------------------------------
-- @class function
-- @description 更新出牌倒计时
-- @param delta 定时器周期
-- end --
function PlaySceneMatch:playTimeCDUpdate(delta)
	if not self.playTimeCD then
		return
	end

	self.playTimeCD = self.playTimeCD - delta
	if self.playTimeCD < 0 then
		self.playTimeCD = 0
	end
	if (self.isPlayerShow or self.isPlayerDecision) and self.playTimeCD <= 3 and not self.isVibrateAlarm then
		-- 剩余3s开始播放警报声音+震动一下手机
		self.isVibrateAlarm = true

		-- 播放声音
		self.playCDAudioID = gt.soundEngine:playEffect("common/timeup_alarm")

		-- 震动提醒
		cc.Device:vibrate(1)
	end
	local timeCD = math.ceil(self.playTimeCD)
	self.playTimeCDLabel:setVisible(true)
	self.playTimeCDLabel:setString(tostring(timeCD))

	if timeCD == 0 and self.TimeCDControl then
		gt.log("timeCD = 0 回调")
		self.TimeCDControl = false
		self:TimeCDCallback()
	end
end
-- start --
--------------------------------
-- @class function
-- @description 发送玩家准备请求消息
-- end --
function PlaySceneMatch:readyBtnClickEvt()
	self.readyBtn:setVisible(false)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_READY
	msgToSend.m_pos = self.playerSeatIdx - 1
	gt.socketClient:sendMessage(msgToSend)
	self.TimeCDControl = false
end

function PlaySceneMatch:TimeCDCallback()
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_USER_OUT_CARD
	gt.socketClient:sendMessage(msgToSend)
	gt.dump(msgToSend)
	self.TimeCDControl = false
	self.selfDrawnDcsNode:setVisible(false)
	self.decisionBtnNode:setVisible(false)
	gt.log("self.isPlayerDecision = true is function TimeCDCallback")
	self.isPlayerDecision = true
	--换三张按钮不能点击
	local Btn_Replace_ThreeCard = gt.seekNodeByName(self.rootNode,"Btn_Replace_ThreeCard")
	Btn_Replace_ThreeCard:setTouchEnabled(false)
end

-- 当前房间的玩法   支持换三张吗
function PlaySceneMatch:onTablePlayState( msgTbl )
	if msgTbl.m_playtype then
		if table.contains(msgTbl.m_playtype, 20) then
			self.isPlayThreeCardState = true
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 赠送金币
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvGiveGold(msgTbl)
	gt.log("赠送金币")
	gt.dump(msgTbl)
	
	local delayTime = cc.DelayTime:create(0.5)
	local callFunc = cc.CallFunc:create(function()
		local str_des = string.format("系统赠送您%d金币,今日免费领取剩余%d次！",msgTbl.m_coins,msgTbl.m_remainCount)
		require("app/views/NoticeTips"):create("提示", str_des, nil, nil, true)
	end)
	local seqAction = cc.Sequence:create(delayTime,callFunc)
	self:runAction(seqAction)
end

-- start --
--------------------------------
-- @class function
-- @description 接收跑游戏桌面马灯消息
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvPlaySeceneCSMarquee(msgTbl)
	if gt.isIOSPlatform() and gt.isInReview then
		local str_des = gt.getLocationString("LTKey_0048")
		self.marqueeMsg:showMsg(str_des, 3)
	else
		self.marqueeMsg:showMsg(msgTbl.m_str, 3)
	end
end

--切到后台 恢复鼠标事件
function PlaySceneMatch:onEnterBackground()
	if gt.isIOSPlatform() or gt.isAndroidPlatform then
		gt.socketClient:close()--切到后台直接断线
	end

	if self.isTouchBegan then
		self.isTouchBegan = false
	end

	--如果鼠标正在拖动，将牌放回原来的位置 不出牌
	if self.isTouchMoved then
		self.chooseMjTile.mjTileSpr:setPosition(self.mjTileOriginPos)
		self.playMjLayer:reorderChild(self.chooseMjTile.mjTileSpr, self.mjTileOriginPos.y)

		self.isTouchMoved = false
	end
end

function PlaySceneMatch:onTouchCancelled(touch, event)
	self.isTouchBegan = false
end

function PlaySceneMatch:onTouchBegan(touch, event)
	gt.log("onTouchBegan11111111111111")
	if self.startGame then
		return false
	end
	gt.log("onTouchBegan77777777777777777")
	if self.isTouchBegan then
		return false
	end
	gt.log("onTouchBegan2222222222222222")
	-- self.isPlayThreeCardState = true
	if self.isPlayThreeCardState == false then
		gt.log("onTouchBegan33333333333333333")
		-- 不需要换三张 
		-- 胡牌后不可以出牌了

		if self.dingqueColorState == false then
			-- 没定缺完成限制点击
			gt.log("self.dingqueColorState == false")
			return false
		end

		local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
		local roomPlayer = self.roomPlayers[self.playerSeatIdx]

		gt.log("onTouchBegan6666666666666666666666666")
		if self.selfWin and mjTileIdx ~= #roomPlayer.holdMjTiles then
			return false
		end

		gt.log("onTouchBegan777777777777777")
		if not self.isPlayerShow or self.isPlayerDecision then
			return false
		end

		if not touchMjTile then
			return false
		end

		-- 判断选中麻将牌的花色 如果是定缺的花色 
		local roomPlayer = self.roomPlayers[self.playerSeatIdx]
		if touchMjTile.mjColor ~= roomPlayer.dingQueColor and #roomPlayer.dingQueTable>0 then
			return false
		end


		-- 记录原始位置
		self.playMjLayer:reorderChild(touchMjTile.mjTileSpr, gt.winSize.height)
		self.chooseMjTile = touchMjTile
		self.chooseMjTileIdx = mjTileIdx
		self.mjTileOriginPos = cc.p(touchMjTile.mjTileSpr:getPosition())
		self.preTouchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
		self.isTouchMoved = false
		self:checkOutMjTile( self.chooseMjTile.mjColor, self.chooseMjTile.mjNumber )

	else
		gt.log("onTouchBegan44444444444444")
		if self.replaceThreeCardType then
			gt.log("onTouchBegan5555555555555555555")
			-- 表示都换完了  按照正常流程走
			if self.dingqueColorState == false then
				-- 没定缺完成限制点击
				return false
			end

			if not self.isPlayerShow or self.isPlayerDecision then
				return false
			end

			local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
			if not touchMjTile then
				return false
			end

			local roomPlayer = self.roomPlayers[self.playerSeatIdx]
			if self.selfWin and mjTileIdx ~= #roomPlayer.holdMjTiles then
				return false
			end

			-- 判断选中麻将牌的花色 如果是定缺的花色 
			local roomPlayer = self.roomPlayers[self.playerSeatIdx]
			if touchMjTile.mjColor ~= roomPlayer.dingQueColor and #roomPlayer.dingQueTable>0 then
				return false
			end

			-- 记录原始位置
			self.playMjLayer:reorderChild(touchMjTile.mjTileSpr, gt.winSize.height)
			self.chooseMjTile = touchMjTile
			self.chooseMjTileIdx = mjTileIdx
			self.mjTileOriginPos = cc.p(touchMjTile.mjTileSpr:getPosition())
			self.preTouchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
			self.isTouchMoved = false
			self:checkOutMjTile( self.chooseMjTile.mjColor, self.chooseMjTile.mjNumber )

		else
			-- 表示自己发送了换三张消息
			if self.ownerSendReplaceCardMsg then
				return false
			end
			---表示别人没换完  但自己换完了   
			if self.ownerReplaceCardType then
				return false
			end
			-- 表示没换完
			local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
			if not touchMjTile then
				return false
			end
			gt.dump(touchMjTile)
			gt.log("touchMjTile.mjColor = "..touchMjTile.mjColor.."touchMjTile.mjNumber = "..touchMjTile.mjNumber)

			-- 记录原始位置
			self.playMjLayer:reorderChild(touchMjTile.mjTileSpr, gt.winSize.height)
			self.chooseMjTile = touchMjTile
			self.chooseMjTileIdx = mjTileIdx
			self.mjTileOriginPos = cc.p(touchMjTile.mjTileSpr:getPosition())
			self.preTouchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
			self.isTouchMoved = false
		end
	end
	self.isTouchBegan = true
	return true
end

function PlaySceneMatch:onTouchMoved(touch, event)
	gt.log("function is onTouchMoved")
	if self.AIoutcard then 
		self.chooseMjTile = nil
		return 
	end
	gt.log("function is onTouchMoved1111111111")
	local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
	if cc.pGetDistance(self.preTouchPoint, touchPoint) < 10 then
		return
	end
	gt.log("function is onTouchMoved2222222222222")
	if self.isPlayThreeCardState then
		if self.replaceThreeCardType then
			local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
			if self.chooseMjTile then
				self.chooseMjTile.mjTileSpr:setPosition(touchPoint)
			end
			self.isTouchMoved = true
		end
	else
		local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
		if self.chooseMjTile then
			self.chooseMjTile.mjTileSpr:setPosition(touchPoint)
		end
		self.isTouchMoved = true
	end
end

function PlaySceneMatch:onTouchEnded(touch, event)
	if self.AIoutcard then 
		self.chooseMjTile = nil
		self.isTouchBegan = false
		self.isTouchMoved = false
		return 
	end
	if self.isPlayThreeCardState == false then
		-- 不需要换三张 

		local isShowMjTile = false
		-- 拖拽出牌
		local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
		if cc.pDistanceSQ(self.preTouchPoint, touchPoint) > 400 then
			-- 拖拽距离大于20判断为拖动
			local roomPlayer = self.roomPlayers[self.playerSeatIdx]
			local limitPosY = roomPlayer.mjTilesReferPos.outStart.y
			if touchPoint.y > limitPosY then
				-- 拖动位置大于上限认为出牌
				isShowMjTile = true
			end
		else
			-- 点击麻将牌
			-- 点中弹出
			if self.chooseMjTile ~= self.preClickMjTile then
				local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
				local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
				self.chooseMjTile.mjTileSpr:runAction(moveAction)

				-- 上一次点中的复位
				if self.preClickMjTile then
					mjTilePos = cc.p(self.preClickMjTile.mjTileSpr:getPosition())
					local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
					self.preClickMjTile.mjTileSpr:runAction(moveAction)
				end
			end

			-- 判断双击
			if self.preClickMjTile and self.preClickMjTile == self.chooseMjTile then
				isShowMjTile = true
			end
			self.preClickMjTile = self.chooseMjTile
		end

		if self.isTouchMoved and not isShowMjTile then
			-- 放回原来的位置,不出牌
			self.chooseMjTile.mjTileSpr:setPosition(self.mjTileOriginPos)
			self.playMjLayer:reorderChild(self.chooseMjTile.mjTileSpr, self.mjTileOriginPos.y)
		end

		if isShowMjTile then
			-- 发送出牌消息
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_SHOW_MJTILE
			-- 出牌标识
			msgToSend.m_type = 1
			msgToSend.m_think = {}
			local think_temp = {self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber}
			table.insert(msgToSend.m_think,think_temp)
			gt.socketClient:sendMessage(msgToSend)

			self.isPlayerShow = false
			self.preClickMjTile = nil
			self.TimeCDControl = false--不进入倒计时回调
			-- 停止倒计时音效
			if self.playCDAudioID then
				gt.soundEngine:stopEffect(self.playCDAudioID)
				self.playCDAudioID = nil
			end

			-- 把牌先打出去
			self:addAlreadyOutMjTiles(self.playerSeatIdx, self.chooseMjTile.mjColor, self.chooseMjTile.mjNumber)
			-- 显示出的牌箭头标识
			self:showOutMjtileSign(self.playerSeatIdx)

			self:outPaiBigAnimate(self.playerSeatIdx,self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber,1)

			-- 玩家持有牌中去除打出去的牌
			local mj_color = self.chooseMjTile.mjColor
			local mj_number = self.chooseMjTile.mjNumber
			local roomPlayer = self.roomPlayers[self.playerSeatIdx]
			for i = #roomPlayer.holdMjTiles, 1, -1 do
				local mjTile = roomPlayer.holdMjTiles[i]
				if mjTile.mjColor == mj_color and mjTile.mjNumber == mj_number then
					mjTile.mjTileSpr:removeFromParent()
					table.remove(roomPlayer.holdMjTiles, i)
					break
				end
			end
			gt.soundManager:PlayCardSound(gt.playerData.sex, mj_color, mj_number)
			self:sortPlayerMjTiles()
			if self:checkRightCradNum() == false then
				self.isTouchBegan = false
				gt.socketClient:reloginServer()
				return
			end
			self:checkOutMjTile( 9, 10 )
		end
	else
		if self.replaceThreeCardType then

			local isShowMjTile = false
			-- 拖拽出牌
			local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
			if cc.pDistanceSQ(self.preTouchPoint, touchPoint) > 400 then
				-- 拖拽距离大于20判断为拖动
				local roomPlayer = self.roomPlayers[self.playerSeatIdx]
				local limitPosY = roomPlayer.mjTilesReferPos.outStart.y
				if touchPoint.y > limitPosY then
					-- 拖动位置大于上限认为出牌
					isShowMjTile = true
				end
			else
				-- 点击麻将牌
				-- 点中弹出
				if self.chooseMjTile ~= self.preClickMjTile then
					local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
					local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
					self.chooseMjTile.mjTileSpr:runAction(moveAction)

					-- 上一次点中的复位
					if self.preClickMjTile then
						mjTilePos = cc.p(self.preClickMjTile.mjTileSpr:getPosition())
						local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
						self.preClickMjTile.mjTileSpr:runAction(moveAction)
					end
				end

				-- 判断双击
				if self.preClickMjTile and self.preClickMjTile == self.chooseMjTile then
					isShowMjTile = true
				end
				self.preClickMjTile = self.chooseMjTile
			end

			if self.isTouchMoved and not isShowMjTile then
				-- 放回原来的位置,不出牌
				self.chooseMjTile.mjTileSpr:setPosition(self.mjTileOriginPos)
				self.playMjLayer:reorderChild(self.chooseMjTile.mjTileSpr, self.mjTileOriginPos.y)
			end

			if isShowMjTile then
				-- 发送出牌消息
				local msgToSend = {}
				msgToSend.m_msgId = gt.CG_SHOW_MJTILE
				-- 出牌标识
				msgToSend.m_type = 1
				msgToSend.m_think = {}
				local think_temp = {self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber}
				table.insert(msgToSend.m_think,think_temp)
				gt.socketClient:sendMessage(msgToSend)

				self.isPlayerShow = false
				self.preClickMjTile = nil
				self.TimeCDControl = false--不进入倒计时回调
				-- 停止倒计时音效
				if self.playCDAudioID then
					gt.soundEngine:stopEffect(self.playCDAudioID)
					self.playCDAudioID = nil
				end

				-- 把牌先打出去
				self:addAlreadyOutMjTiles(self.playerSeatIdx, self.chooseMjTile.mjColor, self.chooseMjTile.mjNumber)
				-- 显示出的牌箭头标识
				self:showOutMjtileSign(self.playerSeatIdx)

				self:outPaiBigAnimate(self.playerSeatIdx,self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber,1)

				-- 玩家持有牌中去除打出去的牌
				local mj_color = self.chooseMjTile.mjColor
				local mj_number = self.chooseMjTile.mjNumber
				local roomPlayer = self.roomPlayers[self.playerSeatIdx]
				for i = #roomPlayer.holdMjTiles, 1, -1 do
					local mjTile = roomPlayer.holdMjTiles[i]
					if mjTile.mjColor == mj_color and mjTile.mjNumber == mj_number then
						mjTile.mjTileSpr:removeFromParent()
						table.remove(roomPlayer.holdMjTiles, i)
						break
					end
				end
				gt.soundManager:PlayCardSound(gt.playerData.sex, mj_color, mj_number)
				self:sortPlayerMjTiles()
				if self:checkRightCradNum() == false then
					self.isTouchBegan = false
					gt.socketClient:reloginServer()
					return
				end
				self:checkOutMjTile( 9, 10 )
			end

		else

			dump(self.chooseMjTile)
			-- 换三张
			if self.chooseMjTile.mjChooseType == true then

				gt.log(" touch bengan 复原 ............. ")

				-- 复原
				local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
				local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
				self.chooseMjTile.mjTileSpr:runAction(moveAction)

				self:ThreeCardRemoveMjType(self.chooseMjTile)

			else

				gt.log(" touch bengan 弹起 ............. ")

				-- 弹起
				local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
				local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
				self.chooseMjTile.mjTileSpr:runAction(moveAction)

				self:ThreeCardInsertMjType(self.chooseMjTile)

			end

		end

	end
	-- self:sortPlayerMjTiles()
	-- self.AIoutcard = false
	self.isTouchBegan = false
	self.isTouchMoved = false
end

function PlaySceneMatch:outPaiBigAnimate(seatIdx, color, number ,isShow)
	--播放出牌音效
	gt.soundEngine:playEffect("common/audio_outpai")

	local roomPlayer = self.roomPlayers[seatIdx]
	local OutPaiBgNode = gt.seekNodeByName(self.rootNode,"OutPaiBgNode")
	OutPaiBgNode:setVisible(true)
	self:reorderChild(OutPaiBgNode, gt.winSize.height)
	for i=1,4 do
		local outPaiBg = gt.seekNodeByName(OutPaiBgNode,"outPaiBg"..i)
		outPaiBg:setVisible(false)
	end
	if isShow == 1 then
		local outPaiBg = gt.seekNodeByName(OutPaiBgNode,"outPaiBg"..roomPlayer.displaySeatIdx)
		outPaiBg:setVisible(true)
		outPaiBg:setZOrder(11111)
		local SpritePai = gt.seekNodeByName(outPaiBg,"SpritePai")
		SpritePai:setSpriteFrame(string.format(gt.SelfMJSprFrameOut, color, number))
		local fadeInAction = cc.FadeIn:create(0.3)
		local delayTime = cc.DelayTime:create(0.8)
		local fadeOutAction = cc.FadeOut:create(0.3)
		local callFunc = cc.CallFunc:create(function(sender)
			sender:setVisible(false)
		end)
		outPaiBg:runAction(cc.Sequence:create(fadeInAction, delayTime, fadeOutAction, callFunc))
	end
end

function PlaySceneMatch:update(delta)
	self.updateTimeCD = self.updateTimeCD - delta
	if self.updateTimeCD <= 0 then
		self.updateTimeCD = 60
		self:updateCurrentTime()
	end
	if gt.IsSendheartbeat == true then
		gt.IsSendheartbeat = false
		local timenow = gt.socket.gettime()
		self.currtime = math.floor(timenow*1000)-gt.m_sec*1000-gt.m_usec
		self.currtimeLabel:setString(self.currtime.."ms")
		gt.InitCurrtimeColor(self.currtimeLabel,self.currtime)
		gt.log("timenow = "..timenow.."currtime = "..self.currtime)
	end
	-- 更新倒计时
	self:playTimeCDUpdate(delta)

	if gt.isIOSPlatform() or gt.isAndroidPlatform() then
		self.updateWifiTime = self.updateWifiTime + 1
		if self.updateWifiTime > 60 then
			self:updateWifi()
			self.updateWifiTime = 0
		end
		
	end
end

function PlaySceneMatch:initPaoMaDeng()
	-- 跑马灯
	local marqueeNode = gt.seekNodeByName(self.rootNode, "Node_marquee")
	local marqueeMsg = require("app/MarqueeMsg"):create()
	marqueeNode:addChild(marqueeMsg)
	self.marqueeMsg = marqueeMsg
	if gt.marqueeMsgTemp then
		self.marqueeMsg:showMsg(gt.marqueeMsgTemp)
		self.marqueeMsg:setVisible(true)
		marqueeNode:setVisible(true)
	end
end

function PlaySceneMatch:onRcvMarquee(msgTbl)
	if gt.isIOSPlatform() and gt.isInReview then
		-- local str_des = gt.getLocationString("LTKey_0048")
		-- self.marqueeMsg:showMsg(str_des)
	else
		if msgTbl.m_type == 0 then
			-- gt.marqueeMsgTemp = msgTbl.m_str
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
		end
	end
end

function PlaySceneMatch:initWifi()
	local Node_Wifi = gt.seekNodeByName(self.rootNode, "Node_WIFI")
	-- 电量
	self.LoadingBar_Battery = gt.seekNodeByName(Node_Wifi, "LoadingBar_Battery")
	local battery = self:getStaticMethod("getDeviceBattery")
	self.LoadingBar_Battery:setPercent(tonumber(battery))
	
	-- wifi信号
	local FileNode_wifi = gt.seekNodeByName(Node_Wifi, "FileNode_wifi")
	local wifiNode, wifiAction = gt.createCSAnimation("Wifi.csb")
	wifiNode:setScale(0.7)
	self.wifiAction = wifiAction
	self.wifiNode = wifiNode
	FileNode_wifi:addChild(wifiNode)
	self.updateWifiTime = 0

	--网络延迟
	self.currtimeLabel = gt.seekNodeByName(Node_Wifi, "lbl_currtime")
	self.currtimeLabel:setString("0ms")
end

function PlaySceneMatch:updateWifi()
	local signalStatus = self:getStaticMethod("getDeviceSignalStatus")

	if signalStatus == "WIFI" then
		local signalLevel = tonumber(self:getStaticMethod("getDeviceSignalLevel"))
		if signalLevel >= 0 and signalLevel <= 3 then
			self.wifiAction:play("wifi" .. signalLevel, true)
			self.wifiNode:setScale(0.7)
		end
	else
		local signalLevel = 4
		if gt.isAndroidPlatform() then
			signalLevel = tonumber(self:getStaticMethod("getDeviceNoWifiLevel"))
		elseif gt.isIOSPlatform() then
			signalLevel = tonumber(self:getStaticMethod("getDeviceSignalLevel"))
		end
		if signalLevel >= 0 and signalLevel <= 4 then
			self.wifiAction:play("mobile" .. (tonumber(signalLevel) + 1), true)
			self.wifiNode:setScale(1.0)
		end
	end

	local battery = self:getStaticMethod("getDeviceBattery")
	--self.LoadingBar_Battery:setPercent(tonumber(battery))
end

function PlaySceneMatch:getStaticMethod(methodName)
	local ok = ""
	local result = ""
	if gt.isIOSPlatform() then
		ok, result = self.luaBridge.callStaticMethod("AppController", methodName)
	elseif gt.isAndroidPlatform() then
		ok, result = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", methodName, nil, "()Ljava/lang/String;")
	end
	return result
end

-- 检查手牌是否低于13张牌
function PlaySceneMatch:checkRightCradNum()
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	if not roomPlayer then -- 还未开始
		return false
	end
	if not roomPlayer.holdMjTiles then
		return false
	end

	-- 玩家持有牌
	local holdNum = #roomPlayer.holdMjTiles

	local totalNum = holdNum % 3

	gt.log("the checkRightCradNum ... count is ... " .. totalNum)

	if totalNum ~= 1 then
		return false
	else
		return true
	end
end

-- start --
--------------------------------
-- @class function
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvRoomCard(msgTbl)
	if msgTbl.m_coins then
		gt.playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3,msgTbl.m_coins}

		local roomPlayer = self.roomPlayers[self.playerSeatIdx]
		roomPlayer.scoreLabel:setString(tostring(gt.formatCoinNumber(msgTbl.m_coins)))
		roomPlayer.gold = msgTbl.m_coins
	else
		gt.playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3}
	end
end

-- start --
--------------------------------
-- @class function
-- @description 进入房间
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvEnterRoom(msgTbl)
	gt.removeLoadingTips()

	self.playMjLayer:removeAllChildren()
	self:playerEnterRoom(msgTbl)

	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	if hutypeNode:isVisible() then
		hutypeNode:setVisible(false)
	end
	if self.outMjtileSignNode:isVisible() then
		self.outMjtileSignNode:setVisible(false)
	end

	if msgTbl.m_opOutTime then
		gt.WaitTime = msgTbl.m_opOutTime
	end
	if msgTbl.m_changeOutTime then
		gt.ChangeTime = msgTbl.m_changeOutTime
	end
	self.readyPlayNode:setVisible(true)
	self.roundStateNode:setVisible(false)
end

-- start --
--------------------------------
-- @class function
-- @description 接收房间添加玩家消息
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvAddPlayer(msgTbl)
	-- 封装消息数据放入到房间玩家表中
	local roomPlayer = {}
	roomPlayer.uid = msgTbl.m_userId
	roomPlayer.nickname = msgTbl.m_nike
	roomPlayer.headURL = string.sub(msgTbl.m_face, 1, string.lastString(msgTbl.m_face, "/")) .. "96"
	roomPlayer.sex = msgTbl.m_sex
	roomPlayer.ip = msgTbl.m_ip
	-- 服务器位置从0开始
	-- 客户端位置从1开始
	roomPlayer.seatIdx = msgTbl.m_pos + 1
	-- 显示座位编号
	roomPlayer.displaySeatIdx = (msgTbl.m_pos + self.seatOffset) % 4 + 1
	roomPlayer.readyState = msgTbl.m_ready
	roomPlayer.score = msgTbl.m_score
	roomPlayer.gold = msgTbl.m_coins

	--是否在线
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	-- 离线标示
	local offLineSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_offLineSign")
	if msgTbl.m_online == true then
		-- 在线
		offLineSignSpr:setVisible(false)
	elseif msgTbl.m_online == false then
		-- 离线
		offLineSignSpr:setVisible(true)
	end

	-- 房间添加玩家
	self:roomAddPlayer(roomPlayer)
end

-- start --
--------------------------------
-- @class function
-- @description 从房间移除一个玩家
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvRemovePlayer(msgTbl)
	gt.dump(msgTbl)
	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 隐藏玩家信息
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	playerInfoNode:setVisible(false)

	-- 隐藏玩家准备手势
	local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
	local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. roomPlayer.displaySeatIdx)
	readySignSpr:setVisible(false)

	-- 取消头像下载监听
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	self.playerHeadMgr:detach(headSpr)

	-- 去除数据
	self.roomPlayers[seatIdx] = nil
end

-- start --
--------------------------------
-- @class function
-- @description 断线重连
-- end --
function PlaySceneMatch:onRcvSyncRoomState(msgTbl)

	dump(msgTbl)
	-- 停止所有事件   删除牌桌所有牌
	self:stopAllActions()
	self.playMjLayer:removeAllChildren()
	if self.selfDrawnDcsNode:isVisible() or self.decisionBtnNode:isVisible() then
		self.selfDrawnDcsNode:setVisible(false)
		self.decisionBtnNode:setVisible(false)
	end

	if msgTbl.m_state == 1 then
		-- 等待状态
		return
	end
	self.pung = true

	if msgTbl.m_opOutTime then
		gt.WaitTime = msgTbl.m_opOutTime
	end
	if msgTbl.m_changeOutTime then
		gt.ChangeTime = msgTbl.m_changeOutTime
	end
	
	-- 断线重连后,当前所选牌,索引等需要清理掉
	self.chooseMjTile 		= nil
	self.chooseMjTileIdx 	= nil
	self.preClickMjTile = nil

	self.huIndex = 0

	-- 定缺的标志
	self.dingqueTypeTable = {}

	-- 定缺的状态 false 没有定缺
	self.dingqueColorState = false

	self.dingqueColorTable = {}

	-- 用户选择的三张牌
	self.replaceThreeCardTable = {}

	-- 用户新换的三张牌
	self.replaceNewThreeCardTable = {}

	-- 纪录谁换过了牌
	self.replaceThreeOkType = {}

	self.startGame = false

	self.AIoutcard = false--重新开始默认为false

	if self.applyDimissRoom and self.applyDimissRoom:isVisible() == true then
		self.applyDimissRoom:setVisible(false)
	end

	-- 隐藏等待界面元素
	self.readyPlayNode:setVisible(false)
	-- 游戏开始后隐藏准备标识
	self:hidePlayersReadySign()
	self.readyBtn:setVisible(false)

	-- 显示轮转座位标识
	self.turnPosBgSpr:setVisible(true)
	-- 显示游戏中按钮
	self.playBtnsNode:setVisible(true)

	-- 隐藏胡牌标记
	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	hutypeNode:setVisible(false)
	for i=1,4 do
		local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
		hutypeSubNode:setVisible(false)
	end

	if msgTbl.m_pos then
		-- 显示当前出牌座位标示

		local seatIdx = msgTbl.m_pos + 1
		self:setTurnSeatSign(seatIdx)
		-- if seatIdx == self.playerSeatIdx then
		-- 	-- 玩家选择出牌
		-- 	self.isPlayerShow = false
		-- end
	end

	-- 牌局状态,剩余牌
	local remainTilesLabel = gt.seekNodeByName(self.roundStateNode, "Label_remainTiles")
	remainTilesLabel:setString(tostring(msgTbl.m_dCount))
	-- 判断最后四张牌提示
	if msgTbl.m_dCount == 4 then
		self:showLastFourCard()
	end

	-- 庄家座位号
	local bankerSeatIdx = msgTbl.m_zhuang + 1

	-- 其他玩家牌
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
		-- 庄家标识
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
		local bankerSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_bankerSign")
		roomPlayer.isBanker = false
		bankerSignSpr:setVisible(false)
		if bankerSeatIdx == seatIdx then
			roomPlayer.isBanker = true
			bankerSignSpr:setVisible(true)
		end

		-- 玩家持有牌
		roomPlayer.holdMjTiles = {}
		-- 玩家已出牌
		roomPlayer.outMjTiles = {}
		-- 玩家已胡牌
		roomPlayer.huMjTiles = {}
		-- 碰
		roomPlayer.mjTilePungs = {}
		-- 明杠
		roomPlayer.mjTileBrightBars = {}
		-- 暗杠
		roomPlayer.mjTileDarkBars = {}
		--吃
		roomPlayer.mjTileEat = {}
		-- 明补
		roomPlayer.mjTileBrightBu = {}
		-- 暗补
		roomPlayer.mjTileDarkBu = {}

		-- 麻将放置参考点
		roomPlayer.mjTilesReferPos = self:setPlayerMjTilesReferPos(roomPlayer.displaySeatIdx)
		-- 剩余持有牌数量
		roomPlayer.mjTilesRemainCount = msgTbl.m_CardCount[seatIdx]
		-- 定缺牌型
		roomPlayer.dingQueColor = 0

		roomPlayer.dingQueTable = {}

		-- 换三张 1是换过的 0是没换的
		if msgTbl.m_bchange then
			roomPlayer.replaceCardType = msgTbl.m_bchange[seatIdx]
		else
			roomPlayer.replaceCardType = 0
		end

		if roomPlayer.seatIdx == self.playerSeatIdx then
			gt.log("自己的手牌")
			-- 定缺纪录服务器的位置
			self.dingque_pos = roomPlayer.seatIdx - 1

			-- 玩家持有牌
			if msgTbl.m_myCard then
				for _, v in ipairs(msgTbl.m_myCard) do
					self:addMjTileToPlayer(v[1], v[2])
				end
				-- 根据花色大小排序并重新放置位置
				self:sortPlayerMjTiles()

				local mjMarkTable = {}
				for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
					if mjTile.mjColor ~= roomPlayer.dingQueColor and #roomPlayer.dingQueTable>0 then
						mjTile.mjTileSpr:setColor(cc.c3b(100,100,100))
						table.insert(mjMarkTable,mjTile)
					end
				end
				self.mjMarkTable = mjMarkTable

			end
		else
			gt.log("别人的手牌"..roomPlayer.mjTilesRemainCount)
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			local maxCount = roomPlayer.mjTilesRemainCount + 1
			for i = 1, maxCount do
				local mjTileName = string.format("tbgs_%d.png", roomPlayer.displaySeatIdx)
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setPosition(mjTilePos)
				self.playMjLayer:addChild(mjTileSpr, (gt.winSize.height - mjTilePos.y))
				mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)

				local mjTile = {}
				mjTile.mjTileSpr = mjTileSpr
				table.insert(roomPlayer.holdMjTiles, mjTile)

				-- 隐藏多产生的牌
				if i > roomPlayer.mjTilesRemainCount then
					mjTileSpr:setVisible(false)
				end
			end
		end

		-- 服务器座次编号
		local turnPos = seatIdx - 1
		-- 已出牌
		local outMjTilesAry = msgTbl["m_oCard" .. turnPos]
		if outMjTilesAry then
			for _, v in ipairs(outMjTilesAry) do
				self:addAlreadyOutMjTiles(seatIdx, v[1], v[2])
			end
		end

		-- 暗杠
		local darkBarArray = msgTbl["m_aCard" .. turnPos]
		if darkBarArray then
			for _, v in ipairs(darkBarArray) do
				self:addMjTileBar(seatIdx, v[1], v[2], false)
			end
		end

		-- 明杠
		local brightBarArray = msgTbl["m_mCard" .. turnPos]
		if brightBarArray then
			for _, v in ipairs(brightBarArray) do
				self:addMjTileBar(seatIdx, v[1], v[2], true)
			end
		end

		-- 碰
		local pungArray = msgTbl["m_pCard" .. turnPos]
		if pungArray then
			for _, v in ipairs(pungArray) do
				self:addMjTilePung(seatIdx, v[1], v[2])
			end
		end

		--吃
		local eatArray = msgTbl["m_eCard" .. turnPos]
		if eatArray then
			local eatTable = {}
			local group1 = {}
			local group2 = {}
			local group3 = {}
			local group4 = {}
			for i, v in ipairs(eatArray) do
				local endTag = nil
				if i <= 3 then
					table.insert(group1,{v[2],1,v[1]}) --牌号，手中牌标识，颜色
					if i == 3 then
						table.insert(eatTable,group1)
						table.insert(roomPlayer.mjTileEat,group1)
					end
				elseif i > 3 and i <= 6 then
					table.insert(group2,{v[2],1,v[1]})
					if i == 6 then
						table.insert(eatTable,group2)
						table.insert(roomPlayer.mjTileEat,group2)
					end
				elseif i > 6 and i <= 9  then
					table.insert(group3,{v[2],1,v[1]})
					if i == 9 then
						table.insert(eatTable,group3)
						table.insert(roomPlayer.mjTileEat,group3)
					end
				elseif i > 9 and i <= 12  then
					table.insert(group4,{v[2],1,v[1]})
					if i == 9 then
						table.insert(eatTable,group4)
						table.insert(roomPlayer.mjTileEat,group4)
					end
				end
			end

			for j, eatTile in pairs(eatTable) do
				self:pungBarReorderMjTiles(seatIdx, eatTile[j][3], eatTile)
			end
		end
	end
	self.pung = false

	-- 房间玩法  
	self:onTablePlayState(msgTbl)

	self.yuyinBtn:setVisible(true)

	-- 校验胡牌
	self:onRcvWinCard(msgTbl)

	if self.isPlayThreeCardState then
		-- 支持换三张玩法 校验换三张
		self:onRcvSyncReplaceCardType()
	else
		-- 不支持
		for i = 1, 4 do
			local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
			local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
			if img_replacecard then
				img_replacecard:setVisible(false)
			end
		end
	end

	if self.startMjTileAnimation ~= nil then
		self.startMjTileAnimation:stopAllActions()
		self.startMjTileAnimation:removeFromParent()
		self.startMjTileAnimation = nil
	end

	if self.outMjtileSignNode then
		self.outMjtileSignNode:setVisible(false)
	end
end

function PlaySceneMatch:onRcvWinCard(msgTbl)
	gt.log("onRcvWinCard:================")
	dump(msgTbl)
	-- 同步断线后胡牌的状态
	self.ownerWin = false
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
		if msgTbl.m_hType[seatIdx] == 1 then
			self:showHuPaiType(seatIdx,roomPlayer.hasHuCard[1],roomPlayer.hasHuCard[2],true,true,msgTbl.m_winList[seatIdx])
		elseif msgTbl.m_hType[seatIdx] == 2 then
			self:showHuPaiType(seatIdx,roomPlayer.hasHuCard[1],roomPlayer.hasHuCard[2],false,true,msgTbl.m_winList[seatIdx])
		end
	end
end

-- 校验换三张
function PlaySceneMatch:onRcvSyncReplaceCardType( )
	
	-- 先隐藏掉所有
	for i = 1, 4 do
		local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
		if img_replacecard then
			img_replacecard:setVisible(false)
		end
		local img_dingque = gt.seekNodeByName(playerNode,"Image_dingque")
		if img_dingque then
			img_dingque:setVisible(false)
		end
	end


	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do

		if roomPlayer.seatIdx == self.playerSeatIdx then
			if roomPlayer.replaceCardType ~= 0 then
				--我自己换过了

				self.ownerReplaceCardType = true

				local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
				node_ReplaceThreeCard:setVisible(false)
				table.insert(self.replaceThreeOkType, string.format("%d",roomPlayer.displaySeatIdx))
			end
		else

			-- 别人换
			if roomPlayer.replaceCardType ~= 0 then

				table.insert(self.replaceThreeOkType, string.format("%d",roomPlayer.displaySeatIdx))

				local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
				local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
				if img_replacecard then
					img_replacecard:setVisible(false)
				end

			else

				local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
				local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
				if img_replacecard then
					img_replacecard:setVisible(true)
				end

			end

		end

	end


	if #self.replaceThreeOkType == 4 then

		self.replaceThreeCardType = true

		-- 表示4个人都换牌完成 隐藏换牌标志
		for i = 1, 4 do
			local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
			local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
			if img_replacecard then
				img_replacecard:setVisible(false)
			end
		end

	end

end

-- start --
--------------------------------
-- @class function
-- @description 玩家准备手势
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvReady(msgTbl)
	gt.dump(msgTbl)
	local seatIdx = msgTbl.m_pos + 1
	self:playerGetReady(seatIdx)
end



-- start --
--------------------------------
-- @class function
-- @description 玩家在线标识
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvOffLineState(msgTbl)
	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	-- 离线标示
	local offLineSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_offLineSign")
	if msgTbl.m_flag == 0 then
		-- 掉线了
		offLineSignSpr:setVisible(true)
	elseif msgTbl.m_flag == 1 then
		-- 回来了
		offLineSignSpr:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 当前局数/最大局数量
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvRoundState(msgTbl)
	-- 牌局状态,剩余牌
	self.roundStateNode:setVisible(true)
	self:onTablePlayState(msgTbl)

end

-- start --
--------------------------------
-- @class function
-- @description 游戏开始
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvStartGame(msgTbl)
	gt.dump(msgTbl)
	self.startGame = true

	self.playMjLayer:removeAllChildren()
	--扫光光效
	local KaijuAnimateNode, KaijuAnimate = gt.createCSAnimation("animation/kaiju_P.csb")
	KaijuAnimateNode:setAnchorPoint(0.5, 0.5)
	KaijuAnimateNode:setPosition(gt.winCenter)
	self:addChild(KaijuAnimateNode)
	
	local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
	local ReplaceNodeZorder = node_ReplaceThreeCard:getZOrder()
	node_ReplaceThreeCard:setZOrder(gt.seekNodeByName(self.rootNode, "mahjong_table"):getZOrder()-1)
	self.playMjLayer:setVisible(false)

	self:IsSameIp()
	self:onRcvSyncRoomState(msgTbl)

	local callFunc1 = cc.CallFunc:create(function(sender)
		KaijuAnimate:play("run", false)
	end)
	local callFunc2 = cc.CallFunc:create(function(sender)
		self.playMjLayer:setVisible(true)
		local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
		node_ReplaceThreeCard:setZOrder(ReplaceNodeZorder)
		sender:removeFromParent()
	end)
	local delayTime = cc.DelayTime:create(1)
	local seqAction = cc.Sequence:create(callFunc1,delayTime,callFunc2)
	KaijuAnimateNode:runAction(seqAction)
	
	self.fastTouchBugType = true
	--开始游戏  放开语音按钮
	-- self.yuyinBtn:setVisible(true)
	--隐藏等待界面元素
	self.readyPlayNode:setVisible(false)
	-- 显示游戏中按钮（消息，设置）
	self.playBtnsNode:setVisible(true)
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家出牌
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:onRcvTurnShowMjTile(msgTbl)
	dump(msgTbl)
	gt.log("通知玩家出牌")
	-- 牌局状态,剩余牌
	self.roundStateNode:setVisible(true)
	local remainTilesLabel = gt.seekNodeByName(self.roundStateNode, "Label_remainTiles")
	remainTilesLabel:setString(tostring(msgTbl.m_dCount))

	-- 判断最后四张牌提示
	if msgTbl.m_dCount == 4 then
		self:showLastFourCard()
	end

	local seatIdx = msgTbl.m_pos + 1
	-- 当前出牌座位
	self:setTurnSeatSign(seatIdx)

	-- 出牌倒计时
	gt.log("出牌倒计时")
	self:playTimeCDStart(gt.WaitTime)
	local roomPlayer = self.roomPlayers[seatIdx]

	if seatIdx == self.playerSeatIdx then
		-- 轮到玩家出牌
		self.isPlayerShow = true
		self.AIoutcard = false
		self.isPlayerDecision = false
		self.TimeCDControl = true
		
		-- 摸牌
		if msgTbl.m_flag == 0 then
			-- 添加牌放在末尾
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
			mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))

			local mjTile = self:addMjTileToPlayer(msgTbl.m_color, msgTbl.m_number)
			mjTile.mjTileSpr:setPosition(cc.p(mjTilePos.x, 150 ))
			if display.autoscale == "FIXED_HEIGHT" then
				mjTile.mjTileSpr:runAction(cc.EaseSineOut:create(cc.MoveTo:create(0.1, cc.p( mjTilePos.x, -20 ) )))
			else
				mjTile.mjTileSpr:runAction(cc.EaseSineOut:create(cc.MoveTo:create(0.1, cc.p( mjTilePos.x, 80 ) )))
			end
			
			self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
		end

		local mjMarkTable = {}
		-- 摸牌后遍历玩家的持有牌 判断定缺的牌 不是定缺都加遮罩  表示不可出
		for _, mjTile in ipairs(roomPlayer.holdMjTiles) do 
			if mjTile.mjColor ~= roomPlayer.dingQueColor and #roomPlayer.dingQueTable>0 then
				mjTile.mjTileSpr:setColor(cc.c3b(100,100,100))
				table.insert(mjMarkTable,mjTile)
			end
		end
		self.mjMarkTable = mjMarkTable

		-- local b_isHu = false
		-- change by yang 2016.4,7
		local decisionTypes = {}
		if msgTbl.m_think then
			for _,value in ipairs(msgTbl.m_think) do
				local think_m_type = value[1]
				local think_m_cardList = {}
				think_m_cardList = value[2]
				gt.log("m_type = ")
				gt.log(think_m_type)


				if think_m_type == 2 then
					-- 胡
					--haidiWinType = true
					-- b_isHu = true
					local decisionData = {}
					decisionData.flag = 2
					decisionData.mjColor = 0
					decisionData.mjNumber = 0
					for _,v in ipairs(think_m_cardList) do
						decisionData.mjColor = v[1]
						decisionData.mjNumber = v[2]
						break
					end
					table.insert(decisionTypes,decisionData)
					gt.log("胡")
				end
				if think_m_type == 3 then
					-- 暗杠
					local decisionData = {}
					decisionData.flag = 3
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("暗杠")
				end
				if think_m_type == 4 then
					-- 明杠
					local decisionData = {}
					decisionData.flag = 4
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("明杠")
				end
				if think_m_type == 7 then
					-- 暗补
					local decisionData = {}
					decisionData.flag = 7
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("暗补")
				end
				if think_m_type == 8 then
					-- 明补
					local decisionData = {}
					decisionData.flag = 8
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("明补")
				end
			end
		end

		-- 按钮排列
		if #decisionTypes > 0 then
			-- 自摸类型决策
			gt.log("self.isPlayerDecision = true is function onRcvTurnShowMjTile")
			self.isPlayerDecision = true

			self.selfDrawnDcsNode:setVisible(true)

			for _, decisionBtn in ipairs(self.selfDrawnDcsNode:getChildren()) do
				local nodeName = decisionBtn:getName()
				if nodeName == "Btn_decisionPass" then
					-- 设置不存在的索引值
					decisionBtn:setTag(0)
					gt.addBtnPressedListener(decisionBtn, function()
						local function passDecision()
							self.isPlayerDecision = false

							self.selfDrawnDcsNode:setVisible(false)
							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)

							local msgToSend = {}
							msgToSend.m_msgId = gt.CG_SHOW_MJTILE
							msgToSend.m_type = 0
							msgToSend.m_think = {{1,1}}

							gt.socketClient:sendMessage(msgToSend)
							
						end
							passDecision()
					end)
				else
					decisionBtn:setVisible(false)
				end
			end

			local decisionBtn_pass = gt.seekNodeByName(self.selfDrawnDcsNode, "Btn_decisionPass")
			local beginPos = cc.p(decisionBtn_pass:getPosition())
			local btnSpace = decisionBtn_pass:getContentSize().width * 3

			-- 有胡必胡
			if msgTbl.m_bOnlyHu == true then
				decisionBtn_pass:setVisible(false)
			else
				decisionBtn_pass:setVisible(true)
			end

			-- 获取可以杠的数据和可补的数据
			local cardList_bar = {}
			local cardList_bu = {}
			for idx, decisionData in ipairs(decisionTypes) do
				if decisionData.flag == 3 or decisionData.flag == 4 then
					-- 明暗杠
					for _,v in ipairs(decisionData.cardList) do
						local card_bar = {}
						card_bar.flag = decisionData.flag
						card_bar.mjColor = v.mjColor
						card_bar.mjNumber = v.mjNumber
						table.insert(cardList_bar,card_bar)
					end
				elseif decisionData.flag == 7 or decisionData.flag == 8 then
					-- 明暗补
					for _,v in ipairs(decisionData.cardList) do
						local card_bu = {}
						card_bu.flag = decisionData.flag
						card_bu.mjColor = v.mjColor
						card_bu.mjNumber = v.mjNumber
						table.insert(cardList_bu,card_bu)
					end
				end
			end
			gt.log("杠的次数")
			gt.log(#cardList_bar)
			gt.log("补的次数")
			gt.log(#cardList_bu)

			local btn_presentList = {}
			for idx, decisionData in ipairs(decisionTypes) do
				local decisionBtn = nil
				if decisionData.flag == 2 then
					-- 胡
					decisionBtn = gt.seekNodeByName(self.selfDrawnDcsNode, "Btn_decisionWin")
					-- 杠的显示优先级为1
					table.insert(btn_presentList,{1,decisionBtn})
				elseif decisionData.flag == 3 or decisionData.flag == 4 then
					-- 明暗杠
					local btn_bar_name = "Btn_decisionBar"
					decisionBtn = gt.seekNodeByName(self.selfDrawnDcsNode, btn_bar_name)
					local isExistBarBtn = false
					for _,v in ipairs(btn_presentList) do
						-- 杠的显示优先级为2
						if v[1] == 2 then
							isExistBarBtn = true
							break
						end
					end
					if not isExistBarBtn then
						table.insert(btn_presentList,{2,decisionBtn})
					end
					-- 显示杠胡牌
					local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
					if mjTileSpr then
						if #cardList_bar == 1 then
							mjTileSpr:setSpriteFrame(string.format(gt.SelfMJSprFrameOut, cardList_bar[1].mjColor, cardList_bar[1].mjNumber))
							mjTileSpr:setVisible(true)
						else
							mjTileSpr:setVisible(false)
						end
					end
				elseif decisionData.flag == 7 or decisionData.flag == 8 then
					-- 明暗杠
					local btn_bar_name = "Btn_decisionBar"
					decisionBtn = gt.seekNodeByName(self.selfDrawnDcsNode, btn_bar_name)
					local isExistBarBtn = false
					for _,v in ipairs(btn_presentList) do
						-- 杠的显示优先级为2
						if v[1] == 2 then
							isExistBarBtn = true
							break
						end
					end
					if not isExistBarBtn then
						table.insert(btn_presentList,{2,decisionBtn})
					end
					-- 显示杠胡牌
					local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
					if mjTileSpr then
						if #cardList_bar == 1 then
							mjTileSpr:setSpriteFrame(string.format(gt.SelfMJSprFrameOut, cardList_bar[1].mjColor, cardList_bar[1].mjNumber))
							mjTileSpr:setVisible(true)
						else
							mjTileSpr:setVisible(false)
						end
					end
				else
					--
				end

				decisionBtn:setVisible(true)
				decisionBtn:setTag(idx)
				-- decisionBtn:setPosition(beginPos)

				-- 可杠
				if decisionData.flag == 3 or decisionData.flag == 4 then
					if #cardList_bar == 1 then
						gt.addBtnPressedListener(decisionBtn, function(sender)
							self.isPlayerDecision = false

							self.selfDrawnDcsNode:setVisible(false)

							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)
							-- 发送消息
							local btnTag = sender:getTag()
							local decisionData = decisionTypes[sender:getTag()]
							local msgToSend = {}
							msgToSend.m_msgId = gt.CG_SHOW_MJTILE
							msgToSend.m_type = decisionData.flag
							msgToSend.m_think = {}
							local think_temp = {decisionData.cardList[1].mjColor,decisionData.cardList[1].mjNumber}
							table.insert(msgToSend.m_think,think_temp)
							gt.socketClient:sendMessage(msgToSend)
							self.isPlayerShow = false

							dump(msgToSend)
							dump(decisionData)

						end)
					else
						gt.addBtnPressedListener(decisionBtn, function(sender)
							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)
							-- add new
							local flimLayer = self:createFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR,cardList_bar)
							self:addChild(flimLayer,PlaySceneMatch.ZOrder.FLIMLAYER,PlaySceneMatch.TAG.FLIMLAYER_BAR)
							flimLayer:ignoreAnchorPointForPosition(false)
							flimLayer:setAnchorPoint(0.5,0)
							local pos_x = 0
							if decisionBtn:getPositionX()+flimLayer:getContentSize().width/2 > gt.winSize.width then
								flimLayer:setPositionX(gt.winSize.width-flimLayer:getContentSize().width/2)
							elseif decisionBtn:getPositionX()-flimLayer:getContentSize().width/2 < 0 then
								flimLayer:setPositionX(flimLayer:getContentSize().width/2)
							else
							flimLayer:setPositionX(decisionBtn:getPositionX())
							end
							flimLayer:setPositionY(decisionBtn:getPositionY()+flimLayer:getContentSize().height/2)
						end)
					end
				elseif decisionData.flag == 7 or decisionData.flag == 8 then   -- 补张
					if #cardList_bu == 1 then
						gt.addBtnPressedListener(decisionBtn, function(sender)
						self.isPlayerDecision = false

						self.selfDrawnDcsNode:setVisible(false)

						-- 删除弹出框（杠）
						self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
						-- 删除弹出框（补）
						self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)

						-- 发送消息
						local btnTag = sender:getTag()
						local decisionData = decisionTypes[sender:getTag()]
						local msgToSend = {}
						msgToSend.m_msgId = gt.CG_SHOW_MJTILE
						msgToSend.m_type = decisionData.flag
						msgToSend.m_think = {}
						gt.log("send flag is ... " .. decisionData.flag)
						local think_temp = {decisionData.cardList[1].mjColor,decisionData.cardList[1].mjNumber}
						table.insert(msgToSend.m_think,think_temp)
						gt.socketClient:sendMessage(msgToSend)
						end)
					else
						gt.addBtnPressedListener(decisionBtn, function(sender)
							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)
							-- add new
							local flimLayer = self:createFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU,cardList_bu)
							self:addChild(flimLayer,PlaySceneMatch.ZOrder.FLIMLAYER,PlaySceneMatch.TAG.FLIMLAYER_BU)
							flimLayer:ignoreAnchorPointForPosition(false)
							flimLayer:setAnchorPoint(0.5,0)
							local pos_x = 0
							if decisionBtn:getPositionX()+flimLayer:getContentSize().width/2 > gt.winSize.width then
								flimLayer:setPositionX(gt.winSize.width-flimLayer:getContentSize().width/2)
							elseif decisionBtn:getPositionX()-flimLayer:getContentSize().width/2 < 0 then
								flimLayer:setPositionX(flimLayer:getContentSize().width/2)
							else
								flimLayer:setPositionX(decisionBtn:getPositionX())
							end
							flimLayer:setPositionY(decisionBtn:getPositionY()+flimLayer:getContentSize().height/2)
						end)
					end
				else
					gt.addBtnPressedListener(decisionBtn, function(sender)
						self.isPlayerDecision = false

						self.selfDrawnDcsNode:setVisible(false)

						-- 删除弹出框（杠）
						self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
						-- 删除弹出框（补）
						self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)

						-- 发送消息
						local btnTag = sender:getTag()
						local decisionData = decisionTypes[sender:getTag()]
						local msgToSend = {}
						msgToSend.m_msgId = gt.CG_SHOW_MJTILE
						msgToSend.m_type = decisionData.flag
						msgToSend.m_think = {}
						local think_temp = {decisionData.mjColor,decisionData.mjNumber}
						if decisionData.mjColor~=0 or decisionData.mjNumber~=0 then
							table.insert(msgToSend.m_think,think_temp)
						end
						gt.socketClient:sendMessage(msgToSend)
					end)
				end
			end

			-- 根据显示优先级进行排序
			table.sort(btn_presentList, function(a, b)
				return a[1] < b[1]
			end)
			-- 根据排序好的优先级进行显示按钮
			for _,v in ipairs(btn_presentList) do
				beginPos = cc.p(beginPos.x - btnSpace , beginPos.y)
				v[2]:setPosition(beginPos)
			end

		end


	else
		self.TimeCDControl = false--不让回调

		self.isPlayerShow = false

		-- 摸牌
		if msgTbl.m_flag == 0 then
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
			roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount + 1
			local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
			vv:setVisible(true)
			local dn = self.playerSeatIdx-seatIdx
			if dn == 2 or dn == -2 then
				vv:setPosition( cc.pAdd(mjTilePos,cc.p(-15,0)) )
			elseif dn == -1 or dn == 3 then
				vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,30)) )
			elseif dn == 1 or dn == -3 then
				vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,-40)) )
			end
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 广播玩家出牌
-- end --
function PlaySceneMatch:onRcvSyncShowMjTile(msgTbl)
	dump(msgTbl)

	gt.log("广播玩家出牌")

	if msgTbl.m_errorCode ~= 0 then
		gt.socketClient:reloginServer()
		return
	end

	-- 座位号（1，2，3，4）
	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]


	if  seatIdx == self.playerSeatIdx then
		if self.selfWin then
			for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
				mjTile.mjTileSpr:setColor(cc.c3b(100,100,100))
			end
		else
			if self.mjMarkTable and #self.mjMarkTable ~= 0 then
				for _, mjTile in ipairs(self.mjMarkTable) do
					mjTile.mjTileSpr:setColor(cc.c3b(255,255,255))
				end
			end
		end
	end


	if msgTbl.m_type == 2 then
		-- 自摸胡

		self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.SELF_DRAWN_WIN, msgTbl.m_hu)

		self:showHuPaiType(seatIdx,msgTbl.m_color, msgTbl.m_number,true,false)

	elseif msgTbl.m_type == 9 then
		-- 胡
		self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.TAKE_CANNON_WIN, msgTbl.m_hu)

		self:showHuPaiType(seatIdx,msgTbl.m_color, msgTbl.m_number,false,false)

	elseif msgTbl.m_type == 1 then
		
		if seatIdx ~= self.playerSeatIdx then

			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			-- 显示出的牌
			self:addAlreadyOutMjTiles(seatIdx, mj_color, mj_number)
			-- 显示出的牌箭头标识
			self:showOutMjtileSign(seatIdx)

			self:outPaiBigAnimate(seatIdx,mj_color,mj_number,1)

			roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
			roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1

			gt.soundManager:PlayCardSound(roomPlayer.sex, mj_color, mj_number)

		end

		-- 记录出牌的上家
		self.preShowSeatIdx = seatIdx
	elseif msgTbl.m_type == -1 then
		local  mj_color = msgTbl.m_think[1][1]
		local  mj_number = msgTbl.m_think[1][2]
		if msgTbl.m_qianggangflag == 1 then
			gt.log("断线重连抢杠牌添加到手牌中")
			self.isPlayerShow = false
		else
			-- 显示出的牌
			self:addAlreadyOutMjTiles(seatIdx, mj_color, mj_number)
			-- 显示出的牌箭头标识
			self:showOutMjtileSign(seatIdx)
			self:outPaiBigAnimate(seatIdx,mj_color,mj_number,1)

			gt.soundManager:PlayCardSound(roomPlayer.sex, mj_color, mj_number)
		end

		-- 记录出牌的上家
		self.preShowSeatIdx = seatIdx

	elseif msgTbl.m_type == 3 then
		-- 暗杠
		gt.log("     暗杠     ")
		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			self:addMjTileBar(seatIdx, mj_color, mj_number, false)
			self:hideOtherPlayerMjTiles(seatIdx, true, false)
			self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.DARK_BAR)
		end
	elseif msgTbl.m_type == 7 then
		-- 暗补
		gt.log("     暗补     ")
		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			self:addMjTileBar(seatIdx, mj_color, mj_number, false)
			self:hideOtherPlayerMjTiles(seatIdx, true, false)
			self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.DARK_BU)
		end
	elseif msgTbl.m_type == 4 then
		-- 碰转明杠
		gt.log("     碰转明杠     ")
		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			self:changePungToBrightBar(seatIdx, mj_color, mj_number)
			self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.BRIGHT_BAR)
		end
	elseif msgTbl.m_type == 8 then
		-- 明补
		gt.log("     明补     ")
		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			self:changePungToBrightBar(seatIdx, mj_color, mj_number)
			self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.BRIGHT_BU)
		end
	end

end

function PlaySceneMatch:discardsOneCard(seatIdx,mjColor,mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	local realpos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
	-- 显示出的牌
	self:addAlreadyOutMjTiles(seatIdx, mjColor, mjNumber)
	-- 显示出的牌箭头标识
	self:showOutMjtileSign(seatIdx)

	-- 记录出牌的上家
	self.preShowSeatIdx = seatIdx

	-- dj revise
	gt.soundManager:PlayCardSound(roomPlayer.sex, mjColor, mjNumber)
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家决策
-- end --
function PlaySceneMatch:onRcvMakeDecision(msgTbl)
	gt.log("通知玩家决策")
	gt.dump(msgTbl)
	self.isShowEat = false

	if msgTbl.m_flag == 1 then
		-- 玩家决策
		gt.log("self.isPlayerDecision = true is function onRcvMakeDecision")
		self.isPlayerDecision = true

		-- 决策倒计时
		self:playTimeCDStart(gt.WaitTime)
		self.TimeCDControl = true

		-- 玩家决策
		local decisionTypes = msgTbl.m_think --玩家决策类型
		-- 最后加入决策"过"选项

		-- 必须胡  不加过而且只有胡
		if msgTbl.m_bOnlyHu == true then
			decisionTypes = {2}
		else
			local pass = {0,{}}
			table.insert(decisionTypes, pass)
		end


		-- 显示对应的决策按键
		self.decisionBtnNode:setVisible(true)

		for _, decisionBtn in ipairs(self.decisionBtnNode:getChildren()) do
			decisionBtn:setVisible(false)
		end
		local Btn_decision_0 = gt.seekNodeByName(self.decisionBtnNode, "Btn_decision_0")
		local startPosX = Btn_decision_0:getPositionX()
		local posY = Btn_decision_0:getPositionY()


		local noSame = {}
		for i, v in ipairs(decisionTypes) do
			local isExist = false
			table.foreach(noSame, function(k, m)
				if m[1] == v[1] then
					isExist = true
					return false
				end
			end)
			if not isExist then
				table.insert(noSame, v)
			end
		end
		local posTag = #noSame
		dump(noSame)
		for i, v in ipairs(noSame) do
			local m_type = nil
			if v[1] == 0 then
				m_type = 0
			elseif v[1] == 2 then
				m_type = 1
			elseif v[1] == 3 or v[1] == 4 then
				m_type = 2
			elseif v[1] == 5 then
				m_type = 3
			elseif v[1] == 6 then
				m_type = 4
			elseif v[1] == 7 or v[1] == 8 then
				m_type = 2
			elseif v[1] == 10 then
				m_type = 6
			end
			
			gt.log("Btn_decision_" .. m_type .. " is show")
			local decisionBtn = gt.seekNodeByName(self.decisionBtnNode, "Btn_decision_" .. m_type)
			if decisionBtn:getChildByTag(5) then
				decisionBtn:getChildByTag(5):removeFromParent()
			end
			decisionBtn:setTag(v[1])
			decisionBtn:setVisible(true)

			
			local x = startPosX - (posTag - i) * Btn_decision_0:getContentSize().width * 3
			decisionBtn:setPosition(cc.p(x, posY))

			-- 显示要碰，杠，胡的牌
			local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
			if mjTileSpr then
				mjTileSpr:setSpriteFrame(string.format(gt.SelfMJSprFrameOut, msgTbl.m_color, msgTbl.m_number))
			end
			if m_type == 1 or m_type == 6 then
				mjTileSpr:setVisible(false)
			end

			-- 响应决策按键事件
			gt.addBtnPressedListener(decisionBtn, function(sender)
				local function makeDecision(decisionType, m_type)
					self.isPlayerDecision = false
					self.isShowEat = false

					-- 隐藏决策按键
					self.decisionBtnNode:setVisible(false)
					-- 发送决策消息
					local msgToSend = {}

					msgToSend.m_msgId = gt.CG_PLAYER_DECISION
					msgToSend.m_type = decisionType
					msgToSend.m_think = {{msgTbl.m_color,msgTbl.m_number}}
					gt.socketClient:sendMessage(msgToSend)
				end

				local decisionType = sender:getTag()
				if decisionType == 6 then  --吃牌
					if self.isShowEat then
						return
					end
					local showMjEatTable = {} --要显示的吃的牌
					for _, m in pairs(decisionTypes) do
						if m[1] == 6 then
							table.insert(showMjEatTable, {m[2][1][2], msgTbl.m_number, m[2][2][2]})
						end
					end
					local function sendEatMssage(result1, result2)
						self.isPlayerDecision = false --决策标识为false
						self.isShowEat = false
						-- 隐藏决策按键
						self.decisionBtnNode:setVisible(false)

						-- 发送决策消息
						local msgToSend = {}
						msgToSend.m_msgId = gt.CG_PLAYER_DECISION
						msgToSend.m_type = 6
						msgToSend.m_think = {{msgTbl.m_color,result1},{msgTbl.m_color,result2}} -- wxg msgTbl.m_color又是哪里来的?
						gt.socketClient:sendMessage(msgToSend)
					end

					local eatBg = cc.Scale9Sprite:create("images/otherImages/tipsbg.png")
					eatBg:setContentSize(cc.size(#showMjEatTable * 3 * mjTileSpr:getContentSize().width + #showMjEatTable * 25, decisionBtn:getContentSize().height))
					local menu = cc.Menu:create()

					local pos = 0
					local mjWidth = 0

					for i, mjNumber in pairs(showMjEatTable) do
						pos = pos + 1
						for j = 1, 3 do
							local mjTileName = string.format(gt.SelfMJSprFrameOut, msgTbl.m_color, mjNumber[j]) --获取图片
							local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)  --创建精灵
							if tonumber(mjNumber[j]) == tonumber(msgTbl.m_number) then
								mjTileSpr:setColor(cc.c3b(255,255,0))
							end

							local menuItem = cc.MenuItemSprite:create(mjTileSpr,mjTileSpr) --创建菜单项
							menuItem:setTag(i)


							local function menuCallBack(i, sender)
								local result = {}
								for m, eat in pairs(showMjEatTable) do
									if m == i then
										for n = 1, 3 do
											if msgTbl.m_number ~= showMjEatTable[m][n] then
												table.insert(result,showMjEatTable[m][n])
											end
										end
									end
								end
								sendEatMssage(result[1], result[2])
							end
							menuItem:registerScriptTapHandler(menuCallBack)

							menuItem:setPosition(cc.p(mjWidth  + (pos - 1) * 10, eatBg:getContentSize().height / 2))
							menu:addChild(menuItem)

							mjWidth = mjWidth + mjTileSpr:getContentSize().width

						end
					end
					eatBg:addChild(menu)
					if pos == 1 then
						menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + mjTileSpr:getContentSize().width * 0.5 ,0)
					elseif pos == 2 then
						menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + mjTileSpr:getContentSize().width * 0.4 ,0)
					else
						menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + mjTileSpr:getContentSize().width * 0.3 ,0)
					end
					sender:addChild(eatBg , -10, 5)
					eatBg:setPosition(0,eatBg:getContentSize().height * 1.5)
					self.isShowEat = true
				elseif decisionType == 2 or decisionType == 10 then

					for _, m in pairs(decisionTypes) do
						if (m[1] == 2 and decisionType == 2) or (m[1] == 10 and decisionType == 10)then
							self.isPlayerDecision = false
							-- 隐藏决策按键
							self.decisionBtnNode:setVisible(false)
							-- 发送决策消息
							local msgToSend = {}
							msgToSend.m_msgId = gt.CG_PLAYER_DECISION
							msgToSend.m_type = decisionType
							msgToSend.m_think = m[2]
							gt.socketClient:sendMessage(msgToSend)
						end
					end
				else
					makeDecision(decisionType, 0)
				end

			end)
		end
	elseif msgTbl.m_flag == 0 then
		self.isPlayerShow = false
	end
end

-- start --
--------------------------------
-- @class function
-- @description 广播决策结果
-- end --
function PlaySceneMatch:onRcvSyncMakeDecision(msgTbl)
	gt.log("广播决策结果")
	dump(msgTbl)

	if msgTbl.m_errorCode ~= 0 then
		return
	end

	-- 隐藏决策按键
	local decision_str = ""
	if self.decisionBtnNode:isVisible() == true then
		local isCanHuFlag = false
		for _, decisionBtn in ipairs(self.decisionBtnNode:getChildren()) do
			if  decisionBtn:getName() == "Btn_decision_1" or decisionBtn:getName() == "Btn_decision_6" then
				if decisionBtn:isVisible() == true then
					decision_str = tostring(decisionBtn:getName())
					isCanHuFlag = true
					break
				end

			end
		end

		if isCanHuFlag == true then -- 有胡
			for _, decisionBtn in ipairs(self.decisionBtnNode:getChildren()) do
				 if decisionBtn:getName() == "Btn_decision_0" or tostring(decisionBtn:getName()) == decision_str then
					decisionBtn:setVisible(true)
				else
					decisionBtn:setVisible(false)
				end
			end
		end

		if isCanHuFlag == false then
			self.isPlayerDecision = false

			self.decisionBtnNode:setVisible( false )
		end
	end

	if msgTbl.m_think ~= 0 then -- 吃,碰,杠,胡
		if self.startMjTileAnimation ~= nil then
			self.startMjTileAnimation:stopAllActions()
			self.startMjTileAnimation:removeFromParent()
			self.startMjTileAnimation = nil
			self:addAlreadyOutMjTiles(self.preShowSeatIdx, self.startMjTileColor, self.startMjTileNumber, true)
		end
	end

	local seatIdx = msgTbl.m_pos + 1

	dump(msgTbl.m_think[1])
	if msgTbl.m_think[1] == 2 or msgTbl.m_think[1] == 10 then
		-- 接炮胡m_hu
		if msgTbl.m_think[1] == 2 then
			self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.TAKE_CANNON_WIN, msgTbl.m_hu)
		else
			self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.QIANG_GANG, msgTbl.m_hu)
			if #self.mjMarkTable ~= 0 then
				for _, mjTile in ipairs(self.mjMarkTable) do
					if mjTile.mjTileSpr then
						mjTile.mjTileSpr:setColor(cc.c3b(255,255,255))
					end
				end
				self.mjMarkTable = {}
			end
		end

		self:showHuPaiType(seatIdx, msgTbl.m_color, msgTbl.m_number,false,true)

		if msgTbl.m_hType ~= 1 then
			-- 移除上家打出的牌
			self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
		end

	elseif msgTbl.m_think[1] == 3 or  msgTbl.m_think[1] == 4 then
		-- 明杠
		self:addMjTileBar(seatIdx, msgTbl.m_color, msgTbl.m_number, true)
		-- 杠牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.BRIGHT_BAR)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, true, true)

		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
		
	elseif msgTbl.m_think[1] == 5 then
		-- 碰牌
		self:addMjTilePung(seatIdx, msgTbl.m_color, msgTbl.m_number)
		-- 碰牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.PUNG)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, false)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
		
	elseif msgTbl.m_think[1] == 6 then
		local eatGroup = {}
		table.insert(eatGroup,{msgTbl.m_think[2][1][2], 0, msgTbl.m_color})
		table.insert(eatGroup,{msgTbl.m_number, 1, msgTbl.m_color})
		table.insert(eatGroup,{msgTbl.m_think[2][2][2], 0, msgTbl.m_color})

		-- 吃牌
		local roomPlayer = self.roomPlayers[seatIdx]
		table.insert(roomPlayer.mjTileEat, eatGroup)

		self:pungBarReorderMjTiles(seatIdx, msgTbl.m_color, eatGroup)
		-- 碰牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.EAT)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, false)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile()
	elseif msgTbl.m_think[1] == 7 or msgTbl.m_think[1] == 8 then

		self:addMjTileBu(seatIdx, msgTbl.m_color, msgTbl.m_number, true)
		-- 杠牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneMatch.DecisionType.BRIGHT_BAR)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, true, true)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
	end

	self:checkMjTile()
end

function PlaySceneMatch:onRcvChatMsg(msgTbl)
	if msgTbl.m_type == 4 then
		--语音
		local s1,s2 = string.find(msgTbl.m_musicUrl, "isok")
		if s1 ~= nil then
			return
		end
		gt.soundEngine:pauseAllSound()
		-- require("json")

		local num1,num2 = string.find(msgTbl.m_musicUrl, "\\")
		local curUrl = string.sub(msgTbl.m_musicUrl,1,num2-1)
		local videoTime = string.sub(msgTbl.m_musicUrl,num2+1)
		gt.log("the play voide url is .." .. curUrl)
		gt.log("the play voide videoTime is .." .. videoTime)
		
		self:getLuaBridge()
		if gt.isIOSPlatform() then
			local ok = self.luaBridge.callStaticMethod("AppController", "playVoice", {voiceUrl = curUrl})
		elseif gt.isAndroidPlatform() then
			local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "playVoice", {curUrl}, "(Ljava/lang/String;)V")
		end

		self.yuyinChatNode:setVisible(true)
		self.rootNode:reorderChild(self.yuyinChatNode, 110)

		local seatIdx = msgTbl.m_pos + 1
		for i = 1, 4 do
			local chatBgImg = gt.seekNodeByName(self.yuyinChatNode, "Image_" .. i)
			chatBgImg:setVisible(false)
		end
		local roomPlayer = self.roomPlayers[seatIdx]
		local chatBgImg = gt.seekNodeByName(self.yuyinChatNode, "Image_" .. roomPlayer.displaySeatIdx)
		chatBgImg:setVisible(true)
		self.yuyinChatNode:stopAllActions()
		local fadeInAction = cc.FadeIn:create(0.5)
		local delayTime = cc.DelayTime:create(videoTime)
		local fadeOutAction = cc.FadeOut:create(0.5)
		local callFunc = cc.CallFunc:create(function(sender)
			sender:setVisible(false)
			gt.soundEngine:resumeAllSound()
		end)
		self.yuyinChatNode:runAction(cc.Sequence:create(fadeInAction, delayTime, fadeOutAction, callFunc))
	else
		local chatBgNode = gt.seekNodeByName(self.rootNode, "Node_chatBg")
		chatBgNode:setVisible(true)
		local seatIdx = msgTbl.m_pos + 1
		for i = 1, 4 do
			local chatBgImg = gt.seekNodeByName(chatBgNode, "Img_playerChatBg_" .. i)
			chatBgImg:setVisible(false)
		end
		local roomPlayer = self.roomPlayers[seatIdx]
		local chatBgImg = gt.seekNodeByName(chatBgNode, "Img_playerChatBg_" .. roomPlayer.displaySeatIdx)
		chatBgImg:setVisible(true)
		local msgLabel = gt.seekNodeByName(chatBgImg, "Label_msg")
		local emojiSpr = gt.seekNodeByName(chatBgImg, "Spr_emoji")
		local isTextMsg = false
		if msgTbl.m_type == gt.ChatType.FIX_MSG then
			msgLabel:setString(gt.getLocationString("LTKey_0028_" .. msgTbl.m_id))
			isTextMsg = true
			gt.soundManager:PlayFixSound(roomPlayer.sex, msgTbl.m_id)
		elseif msgTbl.m_type == gt.ChatType.INPUT_MSG then
			msgLabel:setString(msgTbl.m_msg)
			isTextMsg = true
		elseif msgTbl.m_type == gt.ChatType.EMOJI then
			emojiSpr:setSpriteFrame(msgTbl.m_msg)
			isTextMsg = false
		elseif msgTbl.m_type == gt.ChatType.VOICE_MSG then
		end

		msgLabel:setVisible(isTextMsg)
		emojiSpr:setVisible(not isTextMsg)
		local chatBgSize = chatBgImg:getContentSize()
		local bgWidth = chatBgSize.width
		if isTextMsg then
			local labelSize = msgLabel:getContentSize()
			bgWidth = labelSize.width + 30
			msgLabel:setPositionX(bgWidth * 0.5)
		else
			local emojiSize = emojiSpr:getContentSize()
			bgWidth = emojiSize.width + 50
			emojiSpr:setPositionX(bgWidth * 0.5)
		end
		chatBgImg:setContentSize(cc.size(bgWidth, chatBgSize.height))

		chatBgNode:stopAllActions()
		local fadeInAction = cc.FadeIn:create(0.5)
		local delayTime = cc.DelayTime:create(2)
		local fadeOutAction = cc.FadeOut:create(0.5)
		local callFunc = cc.CallFunc:create(function(sender)
			sender:setVisible(false)
		end)
		chatBgNode:runAction(cc.Sequence:create(fadeInAction, delayTime, fadeOutAction, callFunc))
	end
end

function PlaySceneMatch:onRcvRoundXueliu(msgTbl)
	gt.dump(self.roomPlayers)
	gt.log("self.playerScore = ")
	gt.dump(msgTbl)
	if msgTbl~=nil then
		--处理血流结算
		local playerScore = {}
		for i=1,4 do
			playerScore[i] = {}
			for seatIdx,userRound in ipairs(msgTbl.m_result) do
				if tonumber(userRound[1])+1 == i or tonumber(userRound[2])+1 == i then
					table.insert(playerScore[i], userRound)
				end
			end
		end
		self.playerScore = playerScore
	end
end


function PlaySceneMatch:onRcvRoundReport(msgTbl)
	--删除聊天框
	if self:getChildByTag(101) then
		self:getChildByTag(101):removeFromParent()
	end
	--删除设置
	if self:getChildByTag(102) then
		self:getChildByTag(102):removeFromParent()
	end
	self.TimeCDControl = false

	gt.log("onRcvRoundReport ........... ")

	local curRoomPlayers = {}
	curRoomPlayers = self:copyTab(self.roomPlayers)
	local allDelayTimy = self.reportDelayTime -- 需要延迟的时间,如果存在海底牌,需要将海底牌展示结束方可
	local delayTime = cc.DelayTime:create(allDelayTimy)
	local callFunc = cc.CallFunc:create(function(sender)
		-- 显示准备按钮
		self.readyBtn:setVisible(true)

		-- 停止未完成动作
		if self.startMjTileAnimation ~= nil then
			self.startMjTileAnimation:stopAllActions()
			self.startMjTileAnimation:removeFromParent()
			self.startMjTileAnimation = nil
		end

		-- 停止倒计时音效
		self.playTimeCD = nil

		--清除胡牌状态
		self.selfWin = false

		-- 移除所有麻将
		self.playMjLayer:removeAllChildren()

		-- 定缺的标志
		self.dingqueTypeTable = {}

		-- 定缺的状态 false 没有定缺
		self.dingqueColorState = false

		self.dingqueColorTable = {}

		-- 隐藏定缺的标志
		for i=1,4 do
			local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
			local Image_que = gt.seekNodeByName(playerInfoNode,"Image_que")
			Image_que:setVisible(false)
			local img_replacecard = gt.seekNodeByName(playerInfoNode,"Image_threecard")
			if img_replacecard then
				img_replacecard:setVisible(false)
			end
		end
	
		local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
		node_ReplaceThreeCard:setVisible(false)

		-- 当前换三张的状态 false表示没换过  
		self.replaceThreeCardType = false

		-- 用户选择的三张牌
		self.replaceThreeCardTable = {}

		-- 用户新换的三张牌
		self.replaceNewThreeCardTable = {}

		-- 纪录谁换过了牌
		self.replaceThreeOkType = {}

		-- 自己换三张后锁定状态
		self.ownerReplaceCardType = false
		self.ownerSendReplaceCardMsg = false

		-- 限制发牌之前  手速过快点击 闪退bug
		self.fastTouchBugType = false

		-- 是否支持换三张
		self.isPlayThreeCardState = false

		self.startGame = true

		-- 玩家准备手势隐藏
		self:hidePlayersReadySign()

		-- 隐藏座次标识
		self.turnPosBgSpr:setVisible(false)

		-- 隐藏牌局状态
		self.roundStateNode:setVisible(false)

		-- 隐藏倒计时
		-- self.playTimeCDLabel:setVisible(false)

		-- 隐藏出牌标识
		self.outMjtileSignNode:setVisible(false)

		-- 隐藏决策
		self.decisionBtnNode:setVisible(false)

		self.selfDrawnDcsNode:setVisible(false)

		-- 隐藏胡牌标记
		local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
		hutypeNode:setVisible(false)
		for i=1,4 do
			local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
			hutypeSubNode:setVisible(false)
		end

		--初始化控件
		self.playBtnsNode:setVisible(false)
		self.playTimeCDLabel:setVisible(false)

		--定缺中
		for i=1,4 do
			local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
			local Image_que = gt.seekNodeByName(playerInfoNode,"Image_dingque")
			if Image_que then
				Image_que:setVisible(false)
			end
		end
		self.dingque:setVisible(false)--定缺隐藏

		-- 弹出局结算界面
		if msgTbl.m_end == 0 then -- 不是最后一局
			local roundReport = require("app/views/RoundReport"):create(self.roomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
			self:addChild(roundReport, PlaySceneMatch.ZOrder.ROUND_REPORT)
		else
			gt.isZan = true
			local roundReport = require("app/views/RoundReport"):create(self.curRoomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
			self:addChild(roundReport, PlaySceneMatch.ZOrder.ROUND_REPORT)
		end

		self.lastRound = false
	end)

	local seqAction = cc.Sequence:create(delayTime, callFunc)
	self:runAction(seqAction)
end

function PlaySceneMatch:copyTab(st)
    local tab = {}
    for k, v in pairs(st or {}) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = self:copyTab(v)
        end
    end
    return tab
end

function PlaySceneMatch:onRcvFinalReport(msgTbl)
	gt.log("进入总结算")
	self.lastRound = true
	local curRoomPlayers = {}
	curRoomPlayers = self:copyTab(self.roomPlayers)

	self.finalReport = require("app/views/FinalReport"):create(curRoomPlayers, msgTbl)
	self.finalReport:setVisible(false)
	self:addChild(self.finalReport, PlaySceneMatch.ZOrder.REPORT)
	local allDelayTimy = self.reportDelayTime+0.5
	local delayTime = cc.DelayTime:create( allDelayTimy )
	local callFunc = cc.CallFunc:create(function(sender)
		-- -- 弹出总结算界面
		self.finalReport:setVisible(true)
	end)

	local seqAction = cc.Sequence:create(delayTime, callFunc)
	self:runAction(seqAction)
end

-- start --
--------------------------------
-- @class function
-- @description 更新当前时间
-- end --
function PlaySceneMatch:updateCurrentTime()
	local timeLabel = gt.seekNodeByName(self, "Label_time")
	local curTimeStr = os.date("%X", os.time())
	local timeSections = string.split(curTimeStr, ":")
	-- 时:分
	timeLabel:setString(string.format("%s:%s", timeSections[1], timeSections[2]))
end

-- start --
--------------------------------
-- @class function
-- @description 房间添加玩家
-- @param roomPlayer 玩家信息
-- end --
function PlaySceneMatch:roomAddPlayer(roomPlayer)
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	playerInfoNode:setVisible(true)
	-- 头像
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	self.playerHeadMgr:attach(headSpr, roomPlayer.uid, roomPlayer.headURL,roomPlayer.sex)
	-- 昵称
	local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Label_nickname")
	-- 名字只取四个字,并且清理掉其中的空格
	local nickname = string.gsub(roomPlayer.nickname," ","")
	nickname = string.gsub(nickname,"　","")
	nicknameLabel:setString(gt.checkName(nickname))
	-- 积分修改为金币
	local scoreLabel = gt.seekNodeByName(playerInfoNode, "Label_score")
	scoreLabel:setString(tostring(gt.formatCoinNumber(roomPlayer.gold)))
	roomPlayer.scoreLabel = scoreLabel
	-- 离线标示
	local offLineSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_offLineSign")
	offLineSignSpr:setVisible(false)
	-- 庄家
	local bankerSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_bankerSign")
	bankerSignSpr:setVisible(false)

	-- 点击头像显示信息
	local headFrameBtn = gt.seekNodeByName(playerInfoNode, "Btn_headFrame")
	headFrameBtn:setTag(roomPlayer.seatIdx)
	headFrameBtn:addClickEventListener(handler(self, self.showPlayerInfo))

	-- 添加入缓冲
	self.roomPlayers[roomPlayer.seatIdx] = roomPlayer

	-- 准备标示
	if roomPlayer.readyState == 1 then
		self:playerGetReady(roomPlayer.seatIdx)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 玩家自己进入房间
-- @param msgTbl 消息体
-- end --
function PlaySceneMatch:playerEnterRoom(msgTbl)
	gt.log("玩家自己进入房间")
	gt.dump(msgTbl)
	-- 房间中的玩家
	self.roomPlayers = {}
	-- 玩家自己放入到房间玩家中
	local roomPlayer = {}
	roomPlayer.uid = gt.playerData.uid
	roomPlayer.nickname = gt.playerData.nickname
	roomPlayer.headURL = gt.playerData.headURL
	roomPlayer.sex = gt.playerData.sex
	roomPlayer.ip = gt.playerData.ip
	roomPlayer.seatIdx = msgTbl.m_pos + 1
	-- 玩家座位显示位置
	roomPlayer.displaySeatIdx = 4
	roomPlayer.readyState = msgTbl.m_ready
	roomPlayer.score = msgTbl.m_score
	roomPlayer.gold = msgTbl.m_coins
	-- 添加玩家自己
	self:roomAddPlayer(roomPlayer)

	-- 房间编号
	self.roomID = msgTbl.m_deskId
	-- 玩家座位编号
	self.playerSeatIdx = roomPlayer.seatIdx
	-- 玩家显示固定座位号
	self.playerFixDispSeat = 4
	-- 逻辑座位和显示座位偏移量(从0编号开始)
	local seatOffset = (self.playerFixDispSeat - 1) - msgTbl.m_pos
	self.seatOffset = seatOffset
	-- 旋转座次标识
	self.turnPosBgSpr:setRotation(-seatOffset * 90)
	for _, turnPosSpr in ipairs(self.turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end
	-- 玩家出牌类型
	self.isPlayerShow = false
	self.isPlayerDecision = false

	-- 牌桌类型
	local tableType = gt.seekNodeByName(self.rootNode,"Text_TableType")
	local TypeStr,tableStr = gt.PalyTypeText(msgTbl.m_state,msgTbl.m_playtype)
	tableType:setString(tableStr)
	if string.len(tableStr)>85 then
        tableType:setFontSize(18)
    end
	
	if roomPlayer.readyState == 0 then
		-- 未准备显示准备按钮
		-- local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
		self.readyBtn:setVisible(true)
	else
		self.readyBtn:setVisible(false)
		-- 隐藏胡牌标记
		local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
		hutypeNode:setVisible(false)
		for i=1,4 do
			local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
			hutypeSubNode:setVisible(false)
		end
	end

end

-- start --
--------------------------------
-- @class function
-- @description 玩家进入准备状态
-- @param seatIdx 座次
-- end --
function PlaySceneMatch:playerGetReady(seatIdx)
	self.playTimeCDLabel:setString("0")
	--初始化控件
	self.readyPlayNode:setVisible(true)
	self.roundStateNode:setVisible(false)
	self.playBtnsNode:setVisible(false)
	self.playTimeCDLabel:setVisible(false)
	-- self.turnPosBgSpr:setVisible(true)

	local roomPlayer = self.roomPlayers[seatIdx]
	-- 显示玩家准备手势
	local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
	local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. roomPlayer.displaySeatIdx)
	readySignSpr:setVisible(true)

	-- 玩家本身
	if seatIdx == self.playerSeatIdx then
		-- 隐藏准备按钮
		self.readyBtn:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 隐藏所有玩家准备手势标识
-- end --
function PlaySceneMatch:hidePlayersReadySign()
	for i = 1, 4 do
		local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
		local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. i)
		readySignSpr:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家具体信息面板
-- @param sender
-- end --
function PlaySceneMatch:showPlayerInfo(sender)
	local senderTag = sender:getTag()
	local roomPlayer = self.roomPlayers[senderTag]
	if not roomPlayer then
		return
	end

	local playerInfoTips = require("app/views/PlayerInfoTips"):create(roomPlayer)
	self:addChild(playerInfoTips, PlaySceneMatch.ZOrder.PLAYER_INFO_TIPS)
end

-- start --
--------------------------------
-- @class function
-- @description 设置玩家麻将基础参考位置
-- @param displaySeatIdx 显示座位编号
-- @return 玩家麻将基础参考位置
-- end --
function PlaySceneMatch:setPlayerMjTilesReferPos(displaySeatIdx)
	local mjTilesReferPos = {}

	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	local mjTilesReferNode = gt.seekNodeByName(playNode, "Node_playerMjTiles_" .. displaySeatIdx)

	-- 持有牌数据
	local mjTileHoldSprF = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_1")
	local mjTileHoldSprS = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_2")
	mjTilesReferPos.holdStart = cc.p(mjTileHoldSprF:getPosition())
	mjTilesReferPos.holdSpace = cc.pSub(cc.p(mjTileHoldSprS:getPosition()), cc.p(mjTileHoldSprF:getPosition()))

	-- 打出牌数据
	local mjTileOutSprF = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileOut_1")
	local mjTileOutSprS = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileOut_2")
	local mjTileOutSprT = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileOut_3")
	mjTilesReferPos.outStart = cc.p(mjTileOutSprF:getPosition())
	mjTilesReferPos.outSpaceH = cc.pSub(cc.p(mjTileOutSprS:getPosition()), cc.p(mjTileOutSprF:getPosition()))
	mjTilesReferPos.outSpaceV = cc.pSub(cc.p(mjTileOutSprT:getPosition()), cc.p(mjTileOutSprF:getPosition()))


	-- 碰，杠牌数据
	local mjTileGroupPanel = gt.seekNodeByName(mjTilesReferNode, "Panel_mjTileGroup")
	local groupMjTilesPos = {}
	for _, groupTileSpr in ipairs(mjTileGroupPanel:getChildren()) do
		table.insert(groupMjTilesPos, cc.p(groupTileSpr:getPosition()))
	end
	mjTilesReferPos.groupMjTilesPos = groupMjTilesPos
	mjTilesReferPos.groupStartPos = cc.p(mjTileGroupPanel:getPosition())
	local groupSize = mjTileGroupPanel:getContentSize()
	if displaySeatIdx == 1 or displaySeatIdx == 3 then
		mjTilesReferPos.groupSpace = cc.p(0, groupSize.height + 4)
		if displaySeatIdx == 3 then
			mjTilesReferPos.groupSpace.y = -mjTilesReferPos.groupSpace.y
		end
	else
		mjTilesReferPos.groupSpace = cc.p(groupSize.width + 4, 0)
		if displaySeatIdx == 2 then
			mjTilesReferPos.groupSpace.x = -mjTilesReferPos.groupSpace.x
		end
	end

	-- 胡牌显示坐标
	if displaySeatIdx == 1 then
		mjTilesReferPos.m_huSpace = cc.p( groupMjTilesPos[2].x-groupMjTilesPos[3].x, groupMjTilesPos[2].y-groupMjTilesPos[3].y)
	else
		mjTilesReferPos.m_huSpace = cc.p( groupMjTilesPos[2].x-groupMjTilesPos[1].x, groupMjTilesPos[2].y-groupMjTilesPos[1].y)
	end

	-- 当前出牌展示位置
	local showMjTileNode = gt.seekNodeByName(mjTilesReferNode, "Node_showMjTile")
	mjTilesReferPos.showMjTilePos = cc.p(showMjTileNode:getPosition())

	return mjTilesReferPos
end

-- start --
--------------------------------
-- @class function
-- @description 设置座位编号标识
-- @param seatIdx 座位编号
-- end --
function PlaySceneMatch:setTurnSeatSign(seatIdx)
	-- 显示轮到的玩家座位标识
	if self.preTurnSeatIdx and self.preTurnSeatIdx ~= seatIdx then
		-- 隐藏上次座位标识
		local turnPosSpr = gt.seekNodeByName(self.turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
		turnPosSpr:setVisible(false)
	end
	
	-- 显示当先座位标识
	local turnPosSpr = gt.seekNodeByName(self.turnPosBgSpr, "Spr_turnPos_" .. seatIdx)
	turnPosSpr:setVisible(true)
	
	self.preTurnSeatIdx = seatIdx
end

-- start --
--------------------------------
-- @class function
-- @description 给玩家发牌
-- @param mjColor
-- @param mjNumber
-- @param replaceType
-- end --
function PlaySceneMatch:addMjTileToPlayer(mjColor, mjNumber, replaceType)
	local mjTileName = string.format(gt.MJSprFrame, self.playerFixDispSeat, mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.playMjLayer:addChild(mjTileSpr)

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	-- 换三张 牌现在的状态   
	mjTile.mjChooseType = false
	table.insert(roomPlayer.holdMjTiles, mjTile)
	
	if replaceType then
		table.insert(self.replaceNewThreeCardTable,mjTile)
	end

	if mjTile.mjColor == roomPlayer.dingQueColor then
		table.insert(roomPlayer.dingQueTable,mjTile) 
	end

	return mjTile
end

-- start --
--------------------------------
-- @class function
-- @description 玩家麻将牌根据花色，编号重新排序
-- end --
function PlaySceneMatch:sortPlayerMjTiles( isthreeCard )

	isthreeCard = isthreeCard or false
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	local colorsMjTiles = {}
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if not colorsMjTiles[mjTile.mjColor] then
			colorsMjTiles[mjTile.mjColor] = {}
		end
		table.insert(colorsMjTiles[mjTile.mjColor], mjTile)
	end
	-- dump(colorsMjTiles)

	-- 同花色从小到大排序
	local transMjTiles = {}
	for _, sameColorMjTiles in pairs(colorsMjTiles) do
		table.sort(sameColorMjTiles, function(a, b)
			return a.mjNumber < b.mjNumber
		end)
		for _, mjTile in ipairs(sameColorMjTiles) do
			table.insert(transMjTiles, mjTile)
		end
	end
	-- dump(transMjTiles)


	-- 定缺的排序
	-- 定缺的不是3  表示是万 或者 筒的时候才从新排序

	local dingqueTable = {}
	for i = #transMjTiles, 1, -1 do
		local mj = transMjTiles[i]
		if mj.mjColor == roomPlayer.dingQueColor then
			table.insert(dingqueTable,1,mj)
			table.remove(transMjTiles,i)
		end
	end

	for k,v in pairs(dingqueTable) do
		table.insert(transMjTiles,v)
	end
	roomPlayer.dingQueTable = dingqueTable

	
	-- dump(transMjTiles)

	-- 重新放置位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	if not self.ownerWin then
		for k, mjTile in ipairs(transMjTiles) do
			mjTile.mjTileSpr:stopAllActions()
			mjTile.mjTileSpr:setPosition(mjTilePos)
			self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
			mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
			if k == 13 then -- 如果手里有14张得话，那么说明是庄家
				mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))
			end
		end
	end
	-- dump(transMjTiles)

	roomPlayer.holdMjTiles = transMjTiles
end

-- start --
--------------------------------
-- @class function
-- @description 选中玩家麻将牌
-- @return 选中的麻将牌
-- end --
function PlaySceneMatch:touchPlayerMjTiles(touch)
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for idx, mjTile in ipairs(roomPlayer.holdMjTiles) do
		local touchPoint = mjTile.mjTileSpr:convertTouchToNodeSpace(touch)
		local mjTileSize = mjTile.mjTileSpr:getContentSize()
		local mjTileRect = cc.rect(0, 0, mjTileSize.width, mjTileSize.height)
		if cc.rectContainsPoint(mjTileRect, touchPoint) then
			gt.soundEngine:playEffect("common/audio_card_click")
			return mjTile, idx
		end
	end
	return nil
end

-- start --
--------------------------------
-- @class function
-- @description 显示已出牌
-- @param seatIdx 座位号
-- @param mjColor 麻将花色
-- @param mjNumber 麻将编号
-- end --
function PlaySceneMatch:addAlreadyOutMjTiles(seatIdx, mjColor, mjNumber, isHide)
	-- 添加到已出牌列表
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, mjColor, mjNumber))
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.outMjTiles, mjTile)

	-- 玩家已出牌缩小
	if self.playerSeatIdx == seatIdx then
		mjTileSpr:setScale(0.66)
	end

	if isHide then
		mjTileSpr:setVisible( false )
	end

	-- 显示已出牌
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	local lineCount = math.ceil(#roomPlayer.outMjTiles / 10) - 1
	local lineIdx = #roomPlayer.outMjTiles - lineCount * 10 - 1
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))
	mjTileSpr:setPosition(mjTilePos)
	self.playMjLayer:addChild(mjTileSpr, (gt.winSize.height - mjTilePos.y))
end

--出牌检查 检查要出的牌在牌桌上是否有相同的
function PlaySceneMatch:checkOutMjTile( color, number )
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
		for i,outMjTile in ipairs(roomPlayer.outMjTiles) do
			--检查打出去的牌里是否有相同的牌
			if tonumber(outMjTile.mjColor) == tonumber(color) and tonumber(outMjTile.mjNumber) == tonumber(number) then
				outMjTile.mjTileSpr:setColor(cc.c3b(255,255,100))
			else
				outMjTile.mjTileSpr:setColor(cc.c3b(255,255,255))
			end
		end
		for i, pungData in ipairs(roomPlayer.mjTilePungs) do
			--碰
			if tonumber(pungData.mjColor) == tonumber(color) and tonumber(pungData.mjNumber) == tonumber(number) then
				for _, sprite in ipairs(pungData.groupNode:getChildren()) do
					sprite:setColor(cc.c3b(255,255,100))
				end
			else
				for _, sprite in ipairs(pungData.groupNode:getChildren()) do
					sprite:setColor(cc.c3b(255,255,255))
				end
			end
		end
		for i, brightBars in ipairs(roomPlayer.mjTileBrightBars) do
			--明杠
			if tonumber(brightBars.mjColor) == tonumber(color) and tonumber(brightBars.mjNumber) == tonumber(number) then
				for _, sprite in ipairs(brightBars.groupNode:getChildren()) do
					sprite:setColor(cc.c3b(255,255,100))
				end
			else
				for _, sprite in ipairs(brightBars.groupNode:getChildren()) do
					sprite:setColor(cc.c3b(255,255,255))
				end
			end
		end

		for i, darkBars in ipairs(roomPlayer.mjTileDarkBars) do
			--暗杠
			if tonumber(darkBars.mjColor) == tonumber(color) and tonumber(darkBars.mjNumber) == tonumber(number) then
				for _, sprite in ipairs(darkBars.groupNode:getChildren()) do
					sprite:setColor(cc.c3b(255,255,100))
				end
			else
				for _, sprite in ipairs(darkBars.groupNode:getChildren()) do
					sprite:setColor(cc.c3b(255,255,255))
				end
			end
		end
	end
end

--检查 碰 杠 后 是否有多余的牌没有删除
function PlaySceneMatch:checkMjTile()

	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do

		for i, pungData in ipairs(roomPlayer.mjTilePungs) do
			--碰
			if self:checkPengAndGang( false, pungData.mjColor, pungData.mjNumber ) then
				gt.log("555555555555=======" .. pungData.mjColor .. pungData.mjNumber)
				gt.socketClient:reloginServer()
				return
			end
		end

		for i, brightBars in ipairs(roomPlayer.mjTileBrightBars) do
			--明杠
			if self:checkPengAndGang( true, brightBars.mjColor, brightBars.mjNumber ) then
				--gt.log("666666666666=========")
				gt.socketClient:reloginServer()
				return
			end
		end

		for i, darkBars in ipairs(roomPlayer.mjTileDarkBars) do
			--暗杠
			if self:checkPengAndGang( true, darkBars.mjColor, darkBars.mjNumber ) then
				--gt.log("7777777777777============")
				gt.socketClient:reloginServer()
				return
			end
		end
	end
end

function PlaySceneMatch:checkPengAndGang( isGang, color, number )
	
	local mjNumber = 0
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
		for i,outMjTile in ipairs(roomPlayer.outMjTiles) do
			if tonumber(outMjTile.mjColor) == tonumber(color) and tonumber(outMjTile.mjNumber) == tonumber(number) then
				mjNumber = mjNumber + 1
			end
		end
	end

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for idx, mjTile in ipairs(roomPlayer.holdMjTiles) do
			
		if tonumber(mjTile.mjColor) == tonumber(color) and tonumber(mjTile.mjNumber) == tonumber(number) then
			mjNumber = mjNumber + 1
		
		end
	end

	if isGang then
		if mjNumber > 0 then 
			return true
		end
	else
		if mjNumber > 1 then 
			return true
		end
	end
	return false
end


-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlaySceneMatch:removePreRoomPlayerOutMjTile(color, number)
	-- 移除上家打出的牌
	if self.preShowSeatIdx then
		local roomPlayer = self.roomPlayers[self.preShowSeatIdx]
		local endIdx = #roomPlayer.outMjTiles
		local outMjTile = roomPlayer.outMjTiles[endIdx]
		if outMjTile then
			if color and number then
				if tonumber(outMjTile.mjColor) == tonumber(color) and tonumber(outMjTile.mjNumber) == tonumber(number) then
					outMjTile.mjTileSpr:removeFromParent()
					table.remove(roomPlayer.outMjTiles, endIdx)
					-- 隐藏出牌标识箭头
					self.outMjtileSignNode:setVisible(false)
				-- else
				-- 	gt.socketClient:reloginServer()
				end
			else
				outMjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.outMjTiles, endIdx)
				-- 隐藏出牌标识箭头
				self.outMjtileSignNode:setVisible(false)
			end
		end
	else
	
		gt.socketClient:reloginServer()
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示指示出牌标识箭头动画
-- @param seatIdx 座次
-- end --
function PlaySceneMatch:showOutMjtileSign(seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]
	local endIdx = #roomPlayer.outMjTiles
	local outMjTile = roomPlayer.outMjTiles[endIdx]
	self.outMjtileSignNode:setVisible(true)
	self.outMjtileSignNode:setPosition(outMjTile.mjTileSpr:getPosition())
end

-- start --
--------------------------------
-- @class function
-- @description 隐藏碰，杠牌
-- @param seatIdx 座次
-- @param isBar 杠
-- @param isBrightBar 明杠
-- end --
function PlaySceneMatch:hideOtherPlayerMjTiles(seatIdx, isBar, isBrightBar)
	if seatIdx == self.playerSeatIdx then
		return
	end

	isBar = isBar or false
	isBrightBar = isBrightBar or false

	-- 持有牌隐藏已经碰杠牌
	-- 碰2张
	local mjTilesCount = 2
	if isBar then
		-- 明杠3张
		mjTilesCount = 3
		-- 暗杠4张
		if not isBrightBar then
			mjTilesCount = 4
		end
	end

	local roomPlayer = self.roomPlayers[seatIdx]
	local idx = roomPlayer.mjTilesRemainCount - mjTilesCount + 1
	for i = 1, mjTilesCount do
		local mjTile = roomPlayer.holdMjTiles[idx]
		mjTile.mjTileSpr:setVisible(false)
		idx = idx + 1
	end

	roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - mjTilesCount
end

-- start --
--------------------------------
-- @class function
-- @description 碰牌
-- @param seatIdx 座位编号
-- @param mjColor 麻将牌花色
-- @param mjNumber 麻将牌编号
-- end --
function PlaySceneMatch:addMjTilePung(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local pungData = {}
	pungData.mjColor = mjColor
	pungData.mjNumber = mjNumber
	table.insert(roomPlayer.mjTilePungs, pungData)

	pungData.groupNode = self:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber)
end


-- start --
--------------------------------
-- @class function
-- @description 杠牌
-- @param seatIdx 座位编号
-- @param mjColor 麻将牌花色
-- @param mjNumber 麻将牌编号
-- @param isBrightBar 明杠或者暗杠
-- end --
function PlaySceneMatch:addMjTileBar(seatIdx, mjColor, mjNumber, isBrightBar)
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 加入到列表中
	local barData = {}
	barData.mjColor = mjColor
	barData.mjNumber = mjNumber
	if isBrightBar then
		-- 明杠
		table.insert(roomPlayer.mjTileBrightBars, barData)
	else
		-- 暗杠
		table.insert(roomPlayer.mjTileDarkBars, barData)
	end
	dump(barData)

	barData.groupNode = self:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, true, isBrightBar)
end


-- start --
--------------------------------
-- @class function
-- @description 补牌
-- @param seatIdx 座位编号
-- @param mjColor 麻将牌花色
-- @param mjNumber 麻将牌编号
-- @param isBrightBar 明补或者暗补
-- end --
function PlaySceneMatch:addMjTileBu(seatIdx, mjColor, mjNumber, isBrightBu)
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 加入到列表中
	local barData = {}
	barData.mjColor = mjColor
	barData.mjNumber = mjNumber
	if isBrightBu then
		-- 明补
		table.insert(roomPlayer.mjTileBrightBu, barData)
	else
		-- 暗补
		table.insert(roomPlayer.mjTileDarkBu, barData)
	end

	barData.groupNode = self:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, true, isBrightBu)
end

-- start --
--------------------------------
-- 胡牌之后,牌应该推到
-- end --
function PlaySceneMatch:showAllMjTilesWhenWin(seatIdx, m_cardCount, m_cardValue, m_color, m_number)
	dump(m_cardValue)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 显示碰杠牌
	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	local space = cc.p(groupMjTilesPos[2].x - groupMjTilesPos[1].x, groupMjTilesPos[2].y - groupMjTilesPos[1].y)
	local groupNode = cc.Node:create()
	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	self.playMjLayer:addChild(groupNode)

	-- 所有手牌
	local setPos = groupMjTilesPos[1]
	-- for i,mjTile in ipairs(roomPlayer.holdMjTiles) do
	for i,mjTile in ipairs(m_cardValue) do
		local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, mjTile[1], mjTile[2])
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(setPos)
		groupNode:addChild(mjTileSpr, -setPos.y)
		setPos = cc.pAdd(setPos, roomPlayer.mjTilesReferPos.m_huSpace)
	end

	if m_color > 0 and m_color < 5 then
		local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, m_color, m_number)
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		if roomPlayer.displaySeatIdx == 1 then
			mjTileSpr:setPosition(cc.p(setPos.x, setPos.y + 35))
		elseif roomPlayer.displaySeatIdx == 2 then
			mjTileSpr:setPosition(cc.p(setPos.x - 10, setPos.y))
		elseif roomPlayer.displaySeatIdx == 3 then
			mjTileSpr:setPosition(cc.p(setPos.x, setPos.y - 35))
		elseif roomPlayer.displaySeatIdx == 4 then
			mjTileSpr:setPosition(cc.p(setPos.x + 15, setPos.y))
		end
		groupNode:addChild(mjTileSpr, -setPos.y)
	end

	-- 更新持有牌显示位置
	for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
		mjTile.mjTileSpr:removeFromParent()
	end
end


-- start --
--------------------------------
-- @class function
-- @description 碰杠重新排序麻将牌,显示碰杠
-- @param seatIdx
-- @param mjColor
-- @param mjNumber
-- @param isBar
-- @param isBrightBar
-- @return
-- end --
function PlaySceneMatch:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, isBar, isBrightBar)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 显示碰杠牌
	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	local groupNode = cc.Node:create()
	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	self.playMjLayer:addChild(groupNode)
	local mjTilesCount = 3
	if isBar then
		mjTilesCount = 4
	end
	for i = 1, mjTilesCount do
		local mjTileName = nil
		if isBar and not isBrightBar and i <= 3 then
			-- 暗杠前三张牌扣着
			mjTileName = string.format("tdbgs_%d.png", roomPlayer.displaySeatIdx)
		else
			if type(mjNumber) == "number"  then
				mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, mjColor, mjNumber)
			else
				mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, tonumber(mjColor), tonumber(mjNumber[i][1]))
			end
		end
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[i])
		groupNode:addChild(mjTileSpr)
	end
	mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
	mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

	-- 更新持有牌显示位置
	if seatIdx == self.playerSeatIdx then
		-- 玩家自己
		-- 碰2张
		local mjTilesCount = 2
		if isBar then
			-- 明杠3张
			mjTilesCount = 3
			-- 暗杠4张
			if not isBrightBar then
				mjTilesCount = 4
			end
		end
		if type(mjNumber) == "number" then
			if not self.pung then
				local filterMjTilesCount = 0
				local transMjTiles = {}
				for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
					if filterMjTilesCount < mjTilesCount and mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
						mjTile.mjTileSpr:removeFromParent()
						filterMjTilesCount = filterMjTilesCount + 1
					else
						-- 保存其它牌,去除碰杠牌
						table.insert(transMjTiles, mjTile)
					end
				end
				roomPlayer.holdMjTiles = transMjTiles
			end
		else
			local removeTable = {}
			for j = 1, 3 do
				if tonumber(mjNumber[j][2]) ~= tonumber(1) then
					table.insert(removeTable, {mjNumber[j][1], mjNumber[j][3]})
				end
			end

			if #removeTable > 0 then
				for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
					if mjTile.mjNumber == removeTable[1][1] and  mjTile.mjColor == removeTable[1][2] then
						mjTile.mjTileSpr:removeFromParent()
						table.remove(roomPlayer.holdMjTiles, i)
						break
					end
				end
				for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
						if mjTile.mjNumber == removeTable[2][1] and mjTile.mjColor == removeTable[2][2] then
							mjTile.mjTileSpr:removeFromParent()
							table.remove(roomPlayer.holdMjTiles, i)
						break
					end
				end
			end
		end

		-- 重新排序现持有牌
		self:sortPlayerMjTiles()
	else
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local mjTilePos = mjTilesReferPos.holdStart
		for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
			mjTile.mjTileSpr:setPosition(mjTilePos)
			self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))

			mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
		end
	end

	return groupNode
end

-- start --
--------------------------------
-- @class function
-- @description 自摸碰变成明杠
-- @param seatIdx
-- @param mjColor
-- @param mjNumber
-- end --
function PlaySceneMatch:changePungToBrightBar(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	if seatIdx == self.playerSeatIdx then
		for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
			if mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
				mjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles, i)
				break
			end
		end
	else
		roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
		roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1
	end

	-- 查找碰牌
	local brightBarData = nil
	for i, pungData in ipairs(roomPlayer.mjTilePungs) do
		if pungData.mjColor == mjColor and pungData.mjNumber == mjNumber then
			-- 从碰牌列表中删除
			brightBarData = pungData
			table.remove(roomPlayer.mjTilePungs, i)
			break
		end
	end
	self:sortPlayerMjTiles()
	-- 添加到明杠列表
	if brightBarData then
		-- 加入杠牌第4个牌
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
		local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, mjColor, mjNumber)
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[4])
		brightBarData.groupNode:addChild(mjTileSpr)
		table.insert(roomPlayer.mjTileBrightBars, brightBarData)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家接炮胡，自摸胡，明杠，暗杠，碰动画显示
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlaySceneMatch:showDecisionAnimation(seatIdx, decisionType, huCard)
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 四川麻将  杠就是刮风下雨
	if decisionType == PlaySceneMatch.DecisionType.BRIGHT_BAR or 
	   decisionType == PlaySceneMatch.DecisionType.BRIGHT_BU then
	   	-- 刮风
	   	local Node_DecisionAnimate = gt.seekNodeByName(self.rootNode,"Node_DecisionAnimate")
		local node_animate = gt.seekNodeByName(Node_DecisionAnimate,"node_animate_" .. roomPlayer.displaySeatIdx)
		local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/guafeng.csb")
		self.brightBarAnimateNode = brightBarAnimateNode
		self.brightBarAnimate = brightBarAnimate
		brightBarAnimateNode:setPosition(cc.p(node_animate:getPositionX()+550,node_animate:getPositionY()+300))
		self.rootNode:addChild(brightBarAnimateNode, PlaySceneMatch.ZOrder.MJBAR_ANIMATION)

		local callFunc1 = cc.CallFunc:create(function(sender)
			self.brightBarAnimate:play("run", false)
			gt.soundEngine:playEffect("common/guafeng")
		end)
		local callFunc2 = cc.CallFunc:create(function(sender)
			sender:removeFromParent()
		end)
		local delayTime = cc.DelayTime:create(3)
		local seqAction = cc.Sequence:create(callFunc1,delayTime,callFunc2)
		brightBarAnimateNode:runAction(seqAction)

	elseif decisionType == PlaySceneMatch.DecisionType.DARK_BAR or 
	       decisionType == PlaySceneMatch.DecisionType.DARK_BU then
	   	-- 下雨
		local Node_DecisionAnimate = gt.seekNodeByName(self.rootNode,"Node_DecisionAnimate")
		local node_animate = gt.seekNodeByName(Node_DecisionAnimate,"node_animate_" .. roomPlayer.displaySeatIdx)
		local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/xiayu.csb")
		self.brightBarAnimateNode = brightBarAnimateNode
		self.brightBarAnimate = brightBarAnimate
		brightBarAnimateNode:setPosition(cc.p(node_animate:getPositionX()+550,node_animate:getPositionY()+300))
		self.rootNode:addChild(brightBarAnimateNode, PlaySceneMatch.ZOrder.MJBAR_ANIMATION)

		local callFunc1 = cc.CallFunc:create(function(sender)
			self.brightBarAnimate:play("run", false)
			gt.soundEngine:playEffect("common/xiayu")
		end)
		local callFunc2 = cc.CallFunc:create(function(sender)
			sender:removeFromParent()
		end)
		local delayTime = cc.DelayTime:create(3)
		local seqAction = cc.Sequence:create(callFunc1,delayTime,callFunc2)
		brightBarAnimateNode:runAction(seqAction)

	elseif decisionType == PlaySceneMatch.DecisionType.TAKE_CANNON_WIN or
		   decisionType == PlaySceneMatch.DecisionType.SELF_DRAWN_WIN or 
		   decisionType == PlaySceneMatch.DecisionType.QIANG_GANG then
	   	-- 胡牌动画 现在只有一个胡的标志
	   	local decisionSignSpr = nil
	   	if decisionType == PlaySceneMatch.DecisionType.QIANG_GANG then
	   		decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_7.png")
	   	else
	   		decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_1.png")
	   	end
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, PlaySceneMatch.ZOrder.DECISION_SHOW)
		decisionSignSpr:setScale(0)
		local scaleToAction = cc.ScaleTo:create(0.5, 1)
		local easeBackAction = cc.EaseBackOut:create(scaleToAction)
		local fadeOutAction = cc.FadeOut:create(1)
		local callFunc = cc.CallFunc:create(function(sender)
			-- 播放完后移除
			sender:removeFromParent()
		end)
		local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
		decisionSignSpr:runAction(seqAction)
		
		if decisionType == PlaySceneMatch.DecisionType.TAKE_CANNON_WIN or decisionType == PlaySceneMatch.DecisionType.QIANG_GANG then
			gt.soundManager:PlaySpeakSound(roomPlayer.sex, "hu", roomPlayer)
		else
			gt.soundManager:PlaySpeakSound(roomPlayer.sex, "zimo", roomPlayer)
		end

	else
		--其他  碰 四川麻将这里就只有碰了
	   	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_3.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, PlaySceneMatch.ZOrder.DECISION_SHOW)
		decisionSignSpr:setScale(0)
		local scaleToAction = cc.ScaleTo:create(0.5, 1)
		local easeBackAction = cc.EaseBackOut:create(scaleToAction)
		local fadeOutAction = cc.FadeOut:create(1)
		local callFunc = cc.CallFunc:create(function(sender)
			-- 播放完后移除
			sender:removeFromParent()
		end)
		local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
		decisionSignSpr:runAction(seqAction)

		gt.soundManager:PlaySpeakSound(roomPlayer.sex, "peng", roomPlayer)

	end


end

-- start --
--------------------------------
-- @class function
-- @description 显示出牌动画
-- @param seatIdx 座次
-- end --
function PlaySceneMatch:showMjTileAnimation(seatIdx, startPos, mjColor, mjNumber, cbFunc)
	local mjTilePos = startPos

	local roomPlayer = self.roomPlayers[seatIdx]
	local rotateAngle = {-90, 180, 90, 0}

	local mjTileName = string.format(gt.SelfMJSprFrameOut, mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.rootNode:addChild(mjTileSpr, 98)

	self.startMjTileAnimation = mjTileSpr
	self.startMjTileColor = mjColor
	self.startMjTileNumber	= mjNumber

	mjTileSpr:setPosition(mjTilePos)
	local totalTime = 0.05
	local moveToAc_1 = cc.MoveTo:create(totalTime, roomPlayer.mjTilesReferPos.showMjTilePos)
	local rotateToAc_1 = cc.ScaleTo:create(totalTime, 1.5)

	local delayTime = cc.DelayTime:create(0.8)


	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	local mjTilesCount = #roomPlayer.outMjTiles + 1
	local lineCount = math.ceil(mjTilesCount / 10) - 1
	local lineIdx = mjTilesCount - lineCount * 10 - 1
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))

	local moveToAc_2 = cc.MoveTo:create(totalTime, mjTilePos)
	local rotateToAc_2 = cc.ScaleTo:create(totalTime, 1.0)

	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()
		self.startMjTileAnimation = nil
		cbFunc()
	end)
	mjTileSpr:runAction(cc.Sequence:create(cc.Spawn:create(moveToAc_1, rotateToAc_1),
										delayTime,
										cc.Spawn:create(moveToAc_2, rotateToAc_2),
										callFunc));
end

function PlaySceneMatch:InitUI()
	-- 玩家手势隐藏
	self:hidePlayersReadySign()
	self.playMjLayer:removeAllChildren()
end

function PlaySceneMatch:backMainSceneEvt(eventType, isRoomCreater, roomID)
	-- 事件回调
	gt.removeTargetAllEventListener(self)
	-- 消息回调
	self:unregisterAllMsgListener()

	local mainScene = require("app/views/MainScene"):create(false, false, nil)
	cc.Director:getInstance():replaceScene(mainScene)
end

function PlaySceneMatch:createFlimLayer(flimLayerType,cardList)
	-- 一个麻将
	local mjTileName = string.format(gt.SelfMJSprFrameOut, 2, 2)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	local width_oneMJ = mjTileSpr:getContentSize().width
	local space_gang = 20
	local width = 30+mjTileSpr:getContentSize().width*4*(#cardList)+space_gang*(#cardList-1)
	local height = 24+mjTileSpr:getContentSize().height

	local flimLayer = cc.LayerColor:create(cc.c4b(85, 85, 85, 0), width, height)
	flimLayer:setContentSize(cc.size(width,height))
	local function onTouchBegan(touch, event)
		return true
	end

	-- 添加半透明底
	local image_bg = ccui.ImageView:create()
	image_bg:loadTexture("images/otherImages/laoyue_bg.png")
	image_bg:setScale9Enabled(true)
	image_bg:setCapInsets(cc.rect(10,10,1,1))
	image_bg:setContentSize(cc.size(width,height))
	image_bg:setAnchorPoint(cc.p(0,0))
	flimLayer:addChild(image_bg)

	-- 创建麻将
	for idx,value in ipairs(cardList) do
		local flag = value.flag
		local mjColor = value.mjColor
		local mjNumber = value.mjNumber

		local mjSprName = string.format(gt.SelfMJSprFrameOut, mjColor, mjNumber)
		for i=1,4 do
			local button = ccui.Button:create()
			button:loadTextures(mjSprName,mjSprName,"",ccui.TextureResType.plistType)
			button:setTouchEnabled(true)
    		button:setAnchorPoint(cc.p(0,0))
    		button:setPosition(cc.p(15+space_gang*(idx-1)+width_oneMJ*(i-1)+width_oneMJ*4*(idx-1), 10))
   			button:setTag(idx)
   			flimLayer:addChild(button)

    		local function touchEvent(ref, type)
       			if type == ccui.TouchEventType.ended then
        		 	self.isPlayerDecision = false

					self.selfDrawnDcsNode:setVisible(false)

					-- 发送消息
					local cardData = cardList[ref:getTag()]
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_SHOW_MJTILE
					msgToSend.m_type = cardData.flag
					msgToSend.m_think = {}
					local think_temp = {cardData.mjColor,cardData.mjNumber}
					table.insert(msgToSend.m_think,think_temp)
					gt.socketClient:sendMessage(msgToSend)
					
					self.isPlayerShow = false
					
					gt.log("发送消息")
					dump(msgToSend)
					gt.log("发送消息")

					-- 删除弹出框（杠）
					self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR)
					-- 删除弹出框（补）
					self:removeFlimLayer(PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU)
       		 	end
  	  		end
   	 		button:addTouchEventListener(touchEvent)
		end
	end
	return flimLayer
end

function PlaySceneMatch:removeFlimLayer(flimLayerType)
	local child = self:getChildByTag(PlaySceneMatch.TAG.FLIMLAYER_BAR)

	if flimLayerType == PlaySceneMatch.FLIMTYPE.FLIMLAYER_BAR then
		child = self:getChildByTag(PlaySceneMatch.TAG.FLIMLAYER_BAR)
	elseif flimLayerType == PlaySceneMatch.FLIMTYPE.FLIMLAYER_BU then
		child = self:getChildByTag(PlaySceneMatch.TAG.FLIMLAYER_BU)
	else

	end

	if not child then
		return
	end

	child:removeFromParent()

end

--------------------------------
-- @class function
-- @description 显示海底捞月
-- @param isShow 显示标志
-- end --
function PlaySceneMatch:LaoYueNodeVisible(isShow)
	-- body
	local laoYueNode = gt.seekNodeByName(self.rootNode, "Node_Laoyue")
	if(isShow)then
		self.rootNode:reorderChild(laoYueNode, PlaySceneMatch.ZOrder.HAIDILAOYUE)
		laoYueNode:setVisible(true)
		local yaoBtn = gt.seekNodeByName(laoYueNode, "Btn_yao")
		local guoBtn = gt.seekNodeByName(laoYueNode, "Btn_guo")
		gt.addBtnPressedListener(yaoBtn, function ( )
			laoYueNode:setVisible(false)
			self.isPlayerDecision = false
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_CHOOSE_HAIDI
			msgToSend.m_flag = 1
			gt.socketClient:sendMessage(msgToSend)

		end)
		gt.addBtnPressedListener(guoBtn, function ( )
			laoYueNode:setVisible(false)
			self.isPlayerDecision = false
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_CHOOSE_HAIDI
			msgToSend.m_flag = 0
			gt.socketClient:sendMessage(msgToSend)
		end)
	else
		laoYueNode:setVisible(false)
	end
end



function PlaySceneMatch:startAudio()
	if gt.isUseNewMusic() == false then
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "当前客户端版本不支持语音，点击确定前往下载新版本客户端,取消关闭界面。", gt.updateNewApp, nil, false)
		return
	end
	--测试录音
	gt.log("==========cesiluyin")
	self:getLuaBridge()
	if gt.isIOSPlatform() then
		local ok = self.luaBridge.callStaticMethod("AppController", "startVoice",
			{recodePath = gt.audioPath})

	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "startVoice",nil,"()Z")
	end

end

function PlaySceneMatch:stopAudio()
	if gt.isUseNewMusic() == false then
		return
	end
	--停止录音
	self:getLuaBridge()
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "stopVoice")
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "stopVoice",nil,"()Z")
	end

	local getUrl = function ()
		-- body
		self:getLuaBridge()
		local ok, ret
		if gt.isIOSPlatform() then
			ok, ret = self.luaBridge.callStaticMethod("AppController", "getVoiceUrl")
		elseif gt.isAndroidPlatform() then
			ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getVoiceUrl", nil, "()Ljava/lang/String;")
			gt.log("the ret is .." .. ret)
		end

		if string.len(ret) > 0 and self.checkVoiceUrlType then
			gt.log("_______the ret is .." .. ret)

			self.checkVoiceUrlType = false

			--获得到地址上传给服务器
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_CHAT_MSG
			msgToSend.m_type = 4 -- 语音聊天
			msgToSend.m_musicUrl = ret
			gt.socketClient:sendMessage(msgToSend)

			gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
			self.voiceUrlScheduleHandler = nil
		end
	end
	gt.log("------------------- start check voice url")
	self.checkVoiceUrlType = true
	if self.voiceUrlScheduleHandler then
		gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
		self.voiceUrlScheduleHandler = nil
	end
	self.voiceUrlScheduleHandler = gt.scheduler:scheduleScriptFunc(getUrl, 0, false)

end

function PlaySceneMatch:cancelAudio()
	self:getLuaBridge()
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "cancelVoice")
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "cancelVoice",nil,"()Z")
	end
end

-- @class function
-- @description 通知玩家定缺
-- @param msgTbl
-- end --
function PlaySceneMatch:onRecUserDingQue( msgTbl )
	gt.dump(msgTbl)
	for i=1,4 do
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local Image_que = gt.seekNodeByName(playerInfoNode,"Image_dingque")
		if Image_que then
			Image_que:setVisible(false)
		end
	end

	local ownerChooseQue = 0
	local dingqueInfoTab = {}
	for k,v in pairs(msgTbl.m_state) do
		if k == self.playerSeatIdx then
			if v == 0 then
				ownerChooseQue = 1
			end
		else
			local roomPlayer = self.roomPlayers[k]
			if v == 0 then
				-- 0：没订过缺 显示
				local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
				local img_dingque = gt.seekNodeByName(playerNode,"Image_dingque")
				if img_dingque then
					img_dingque:setVisible(true)
				end
				table.insert(dingqueInfoTab,roomPlayer.nickname)
			else
				-- 订过缺  隐藏
				local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
				local img_dingque = gt.seekNodeByName(playerNode,"Image_dingque")
				if img_dingque then
					img_dingque:setVisible(false)
				end
			end
		end
	end

	local function dingquehandler ()
		local SymbolText = ""
		if self.SymbolNum==3 then
			self.SymbolNum = 1
		else
			self.SymbolNum = self.SymbolNum + 1
		end
		for i=1,self.SymbolNum do
			SymbolText = SymbolText.."."
		end
		self.dingqueInfo:setString(self.dingquePlayerInfo.."正在定缺中"..SymbolText)
	end

	if ownerChooseQue == 0 and #dingqueInfoTab>0 then
		self.dingquePlayerInfo = ""
		for i=1,#dingqueInfoTab do
			self.dingquePlayerInfo = self.dingquePlayerInfo.." 玩家:"..dingqueInfoTab[i]
		end
		--显示xx，yy正在定缺中
		local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_4")
		local img_dingque = gt.seekNodeByName(playerNode,"Image_dingque")
		if self.dingqueInfo then
			self.dingqueInfo:setVisible(true)
			self.dingqueInfo:setString(self.dingquePlayerInfo.."正在定缺中...")
		else
			self.dingqueInfo = gt.createTTFLabel(self.dingquePlayerInfo.."正在定缺中...",34)
			gt.setTTFLabelStroke(self.dingqueInfo,cc.c3b(0,0,0),2)
			self.dingqueInfo:setColor(cc.c3b(167,235,71))
			playerNode:addChild(self.dingqueInfo)
		end
		self.dingqueInfo:setAnchorPoint(0,0.5)
		self.dingqueInfo:setPosition(cc.p(img_dingque:getPositionX()-self.dingqueInfo:getContentSize().width*0.5,img_dingque:getPositionY()))
		self.SymbolNum = 3
		if not self.dingqueInfoschedule then
			self.dingqueInfoschedule = gt.scheduler:scheduleScriptFunc(dingquehandler, 0.4, false)
		end
	else
		if self.dingqueInfo then
			self.dingqueInfo:setVisible(false)
		end
		if self.dingqueInfoschedule then
			gt.scheduler:unscheduleScriptEntry(self.dingqueInfoschedule)
			self.dingqueInfoschedule = nil
		end
	end

	if ownerChooseQue == 1 then
		if not self.TimeCDControl then
			self:playTimeCDStart(gt.WaitTime)
			self.TimeCDControl = true
		end
		-- 提示玩家定缺
		--显示定缺
		self.dingque:setVisible(true)
		self.dingqueColorState = false

		local wanBtn = gt.seekNodeByName(self.dingque,"Btn_wan")
		local wanJian = gt.seekNodeByName(wanBtn,"Text_jian")
		wanJian:setVisible(false)
		wanBtn:setScale(1)
		wanBtn:stopAllActions()
		gt.addBtnPressedListener(wanBtn,function ()
			local msgToSend = {}
			msgToSend.m_msgId = gt.GC_USER_DING_QUE
			msgToSend.m_color = 1
			msgToSend.m_pos = self.dingque_pos
			gt.socketClient:sendMessage(msgToSend)
		end)

		local tongBtn = gt.seekNodeByName(self.dingque,"Btn_tong")
		local tongJian = gt.seekNodeByName(tongBtn,"Text_jian")
		tongJian:setVisible(false)
		tongBtn:setScale(1)
		tongBtn:stopAllActions()
		gt.addBtnPressedListener(tongBtn,function ()
			local msgToSend = {}
			msgToSend.m_msgId = gt.GC_USER_DING_QUE
			msgToSend.m_color = 2
			msgToSend.m_pos = self.dingque_pos
			gt.socketClient:sendMessage(msgToSend)
		end)

		local tiaoBtn = gt.seekNodeByName(self.dingque,"Btn_tiao")
		local tiaoJian = gt.seekNodeByName(tiaoBtn,"Text_jian")
		tiaoJian:setVisible(false)
		tiaoBtn:setScale(1)
		tiaoBtn:stopAllActions()
		gt.addBtnPressedListener(tiaoBtn,function ()
			local msgToSend = {}
			msgToSend.m_msgId = gt.GC_USER_DING_QUE
			msgToSend.m_color = 3
			msgToSend.m_pos = self.dingque_pos
			gt.socketClient:sendMessage(msgToSend)
		end)

		--定缺的推荐 动画
		local num1,num2 = self:dingquePrompt()

		if num1 == 0 then
			--只推荐一个定缺 
			if num2 == 1 then
				wanJian:setVisible(true)
			elseif num2 == 2 then
				tongJian:setVisible(true)
			elseif num2 == 3 then
				tiaoJian:setVisible(true)
			end
		else
			-- 推荐两个
			if num1 == 1 then
				wanJian:setVisible(true)
			elseif num1 == 2 then
				tongJian:setVisible(true)
			elseif num1 == 3 then
				tiaoJian:setVisible(true)
			end

			if num2 == 1 then
				wanJian:setVisible(true)
			elseif num2 == 2 then
				tongJian:setVisible(true)
			elseif num2 == 3 then
				tiaoJian:setVisible(true)
			end

		end

		--动画效果
		if wanJian:isVisible() then
			self:jianAnimate(wanBtn)
        end
		if tongJian:isVisible() then
			self:jianAnimate(tongBtn)
        end
		if tiaoJian:isVisible() then
			self:jianAnimate(tiaoBtn)
		end

	else
		self.dingque:setVisible(false)
	end


end

-- 定缺完成
function PlaySceneMatch:onRecUserDingQueComplate( msgTbl )
	gt.dump(msgTbl)
	if self.dingqueInfo then
		self.dingqueInfo:setVisible(false)
	end
	if self.dingqueInfoschedule then
		gt.scheduler:unscheduleScriptEntry(self.dingqueInfoschedule)
		self.dingqueInfoschedule = nil
	end
	if self.dingqueColorState then
		return
	end
	self.dingque:setVisible(false)
	self.dingqueColorState = true
	
	for i=1,4 do
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local Image_que = gt.seekNodeByName(playerInfoNode,"Image_dingque")
		if Image_que then
			Image_que:setVisible(false)
		end
	end

	for k,v in pairs(msgTbl.m_color) do
		self:showDingQueType(k,v)
		if k == self.playerSeatIdx then
			-- 玩家自己
			local roomPlayer = self.roomPlayers[k]
			roomPlayer.dingQueColor = v

			-- 给自己的牌加阴影
			self:sortPlayerMjTiles(true)
			-- dump(roomPlayer.dingQueTable)
			local mjMarkTable = {}
			for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
				if mjTile.mjColor ~= roomPlayer.dingQueColor and #roomPlayer.dingQueTable>0 then
					mjTile.mjTileSpr:setColor(cc.c3b(100,100,100))
					table.insert(mjMarkTable,mjTile)
				end
			end
			self.mjMarkTable = mjMarkTable
			
		end
	end

end

function PlaySceneMatch:showDingQueType( seatIdx, color )
	local roomPlayer = self.roomPlayers[seatIdx]

	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	local Image_que = gt.seekNodeByName(playerInfoNode,"Image_que")
	Image_que:setVisible(true)
	local imgName = nil
	if color == 1 then
		imgName = "playScene46.png"
	elseif color == 2 then
		imgName = "playScene44.png"
	elseif color == 3 then
		imgName = "playScene42.png"
	end
	Image_que:setSpriteFrame(imgName)


end

function PlaySceneMatch:dingquePrompt()

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	if not roomPlayer then -- 还未开始
		return 0,0
	end
	if not roomPlayer.holdMjTiles then
		return 0,0
	end

	local wanCount = 0
	local tongCount = 0
	local tiaoCount = 0
	for k,v in pairs(roomPlayer.holdMjTiles) do
		if v.mjColor == 1 then
			-- 万
			wanCount = wanCount+1
		elseif v.mjColor == 2 then
			-- 筒
			tongCount = tongCount+1
		elseif v.mjColor == 3 then
			-- 条	
			tiaoCount = tiaoCount+1
		end
	end

	if wanCount < tongCount and wanCount < tiaoCount then
		return 0,1
	elseif tongCount < wanCount and tongCount < tiaoCount then
		return 0,2
	elseif tiaoCount < wanCount and tiaoCount < tongCount then
		return 0,3
	end

	if wanCount == tongCount and wanCount < tiaoCount then
		return 1,2
	elseif wanCount == tiaoCount and  wanCount < tongCount then
		return 1,3
	elseif tongCount == tiaoCount and tongCount < wanCount then
		return 2,3
	end

end

function PlaySceneMatch:jianAnimate( node )
	node:stopAllActions()
	local scale = cc.ScaleBy:create(0.3,1.2,1.2)
	local bounce = cc.EaseBounceInOut:create(scale)
	local scaleBack = bounce:reverse()
	local action = cc.Sequence:create(bounce,scaleBack)
	node:runAction(cc.RepeatForever:create(action))

end

function PlaySceneMatch:showHuPaiType( seatIdx ,color, number , mjhuPaiType, isboolBreak, rcvWinCard )

	self.huIndex = self.huIndex + 1

	local index = 1
	if rcvWinCard ~= nil then
		index = rcvWinCard
	else
		index = self.huIndex
	end

	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")

	hutypeNode:setVisible(true)
	self.rootNode:reorderChild(hutypeNode, 800)


	local roomPlayer = self.roomPlayers[seatIdx]
	local huType = gt.seekNodeByName(hutypeNode, "huType" .. roomPlayer.displaySeatIdx)
	gt.log("------------566------")
	huType:setVisible(true)   --显示胡字

	if color ~= 0 and number ~= 0 then
		if mjhuPaiType then
			gt.log("自摸胡牌 ........... ")
			huType:loadTexture("playScene_" .. index .. "zimo.png",1)
			huType:setContentSize(cc.size(92,48))
		else
			gt.log("接炮胡牌............")
			huType:loadTexture("playScene_" .. index .. "hu.png",1)
			huType:setContentSize(cc.size(62,47))
		end
		if seatIdx == self.playerSeatIdx then 
			gt.log("自己胡牌....................")
			-- 添加牌放在末尾
			if isboolBreak == true then--(断线重连)
				self.ownerWin = true
				local mjTilesReferPos = roomPlayer.mjTilesReferPos
				local mjTilePos = mjTilesReferPos.holdStart
				mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
				mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))
				local mjTile = self:addMjTileToPlayer(color, number)
				mjTile.mjTileSpr:setPosition(mjTilePos)
				self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
			end
		else
			gt.log("别人胡牌....................")
			-- 隐藏的牌显出出来
			if isboolBreak == true then--(断线重连)
				local mjTilesReferPos = roomPlayer.mjTilesReferPos
				local mjTilePos = mjTilesReferPos.holdStart
				mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
				roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount + 1
				local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
				vv:setVisible(true)
				local _offsetMap = {{x=0, y=30}, {x=-15, y=0}, {x=0, y=-40}}
				vv:setPosition(cc.pAdd(mjTilePos, _offsetMap[roomPlayer.displaySeatIdx]))
				vv:setSpriteFrame(string.format(gt.MJSprFrameOut,roomPlayer.displaySeatIdx, color, number))
			else
				local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
				vv:setVisible(true)
				vv:setSpriteFrame(string.format(gt.MJSprFrameOut,roomPlayer.displaySeatIdx, color, number))
			end
		end
	end
end

-- 确定可以换的花色
function PlaySceneMatch:promptReplaceThreeCard()
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	if not roomPlayer then -- 还未开始
		return 0
	end
	if not roomPlayer.holdMjTiles then
		return 0
	end

	local function getcolorNum(mjColor)
	    local count = 0
	    for i,v in pairs(roomPlayer.holdMjTiles) do
	       if v.mjColor == mjColor then
	            count = count+1   
	        end
	    end
	    return count
	end
	local Count = {}
	Count[1] = getcolorNum(1)
	Count[2] = getcolorNum(2)
	Count[3] = getcolorNum(3)
	table.sort(Count)
	for i,v in pairs(Count) do
	    if v>=3 then
	        return i
	    end
	end
	return 0
end

function PlaySceneMatch:exhReplaceThreeCard()
	local num = self:promptReplaceThreeCard()

	gt.log("the choose ding color is ... " .. num)

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	local count = 0
	local cardTable = {}
	for k,v in pairs(roomPlayer.holdMjTiles) do
		if v.mjColor == num then
			v.mjChooseType = true
			table.insert(cardTable,v)
			count = count + 1
			if count >= 3 then
				break
			end
		end
	end
	dump(cardTable)
	return cardTable
end

function PlaySceneMatch:replaceThreeCardAction()

	local cardTable = self:exhReplaceThreeCard()
	self.replaceThreeCardTable = cardTable

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for k,v in pairs(roomPlayer.holdMjTiles) do
		if v.mjChooseType == true then
			-- 提出麻将
			local mjTilePos = cc.p(v.mjTileSpr:getPosition())
			local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
			v.mjTileSpr:runAction(moveAction)
		end
	end

	self:checkReplaceOkBtn()

end

function PlaySceneMatch:ThreeCardInsertMjType( mjTile )
	if #self.replaceThreeCardTable >= 3 then
		local mjTilePos = cc.p(self.replaceThreeCardTable[1].mjTileSpr:getPosition())
		local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
		self.replaceThreeCardTable[1].mjTileSpr:runAction(moveAction)
		self.replaceThreeCardTable[1].mjChooseType = false
		self.replaceThreeCardTable[1] = self.replaceThreeCardTable[2]
		self.replaceThreeCardTable[2] = self.replaceThreeCardTable[3]
		mjTile.mjChooseType = true
		self.replaceThreeCardTable[3] = mjTile
	else
		mjTile.mjChooseType = true
		table.insert(self.replaceThreeCardTable,mjTile)
	end

	gt.log("ThreeCardInsertMjType ....................")

	dump(self.replaceThreeCardTable)

	self:checkReplaceOkBtn()

end

function PlaySceneMatch:ThreeCardRemoveMjType( mjTile )
	
	gt.log("ThreeCardRemoveMjType ....................")

	dump(mjTile)
	mjTile.mjChooseType = false
	for i=#self.replaceThreeCardTable, 1, -1 do 

        if self.replaceThreeCardTable[i].mjColor == mjTile.mjColor and
        	self.replaceThreeCardTable[i].mjNumber == mjTile.mjNumber and
        	self.replaceThreeCardTable[i].mjChooseType == false then 
            table.remove(self.replaceThreeCardTable,i) 
            break
        end 

    end

    self:checkReplaceOkBtn()

end

function PlaySceneMatch:onRecUserReplaceCard( msgTbl )
	dump(msgTbl)
	gt.log("开始换三张 。。。。。。。。。。 ")

	-- 先隐藏定缺的提示
	for i = 1, 4 do
		local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local img_dingque = gt.seekNodeByName(playerNode,"Image_dingque")
		if img_dingque then
			img_dingque:setVisible(false)
		end
	end

	if msgTbl.m_time ~= 0 then

		for seatIdx, roomPlayer in ipairs(self.roomPlayers) do

			if roomPlayer.seatIdx ~= self.playerSeatIdx then
				-- 别人换牌
				if roomPlayer.replaceCardType ~= 0 then

					local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
					local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
					if img_replacecard then
						img_replacecard:setVisible(false)
					end
				else
					local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
					local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
					if img_replacecard then
						img_replacecard:setVisible(true)
					end
				end

			end

		end

		self.replaceThreeCardType = false

		local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
		node_ReplaceThreeCard:setVisible(true)

		self:replaceThreeCardAction()
		-- self:playTimeCDStart(gt.WaitTime)
		self:playTimeCDStart(gt.ChangeTime)
		self.TimeCDControl = true
	else
		local seatIdx = msgTbl.m_pos + 1
		local roomPlayer = self.roomPlayers[seatIdx]

		if seatIdx == self.playerSeatIdx then
			-- 玩家自己
			gt.log("玩家自己换三张成功")

			self.ownerReplaceCardType = true

			local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
			node_ReplaceThreeCard:setVisible(false)

			--如果自动换牌的话把服务器选好的牌放入数组
			if msgTbl.m_card and #msgTbl.m_card == 3 then
				self.replaceThreeCardTable = {}
				local roomPlayer = self.roomPlayers[self.playerSeatIdx]
				local val = {}
				for j,v in ipairs(msgTbl.m_card) do
					for i,k in ipairs(roomPlayer.holdMjTiles) do
						if k.mjColor == v[1] and k.mjNumber == v[2] then
							if j==1 then
								gt.dump(k)
								table.insert(self.replaceThreeCardTable,j,k)
								table.insert(val,i)
								break
							elseif i~=val[1] and j==2 then
								gt.dump(k)
								table.insert(self.replaceThreeCardTable,j,k)
								table.insert(val,i)
								break
							elseif i~=val[1] and i~=val[2] and j==3 then
								gt.dump(k)
								table.insert(self.replaceThreeCardTable,j,k)
								table.insert(val,i)
								break
							end
						end
				    end
				end
			end
			gt.dump(roomPlayer.holdMjTiles)
			gt.dump(self.replaceThreeCardTable)

			local layerSize = self.playMjLayer:getContentSize()
			for i=1,3 do
				local moveTo = cc.MoveTo:create(0.3,cc.p(layerSize.width/2,layerSize.height/2))
				local scaleto = cc.ScaleTo:create(0.3, 0)
				local act = cc.Spawn:create(moveTo,scaleto)
				local callback = cc.CallFunc:create(function(sender)
					sender:removeFromParent()
				end)
				self.replaceThreeCardTable[i].mjTileSpr:runAction(cc.Sequence:create(act,callback))
			end

			if msgTbl.m_card and #msgTbl.m_card == 3 then
				--服务器自动换三张
				for j,v in ipairs(msgTbl.m_card) do
					local roomPlayer = self.roomPlayers[self.playerSeatIdx]
					for i=1,#roomPlayer.holdMjTiles do
						local card = roomPlayer.holdMjTiles[i]
						if card.mjColor == v[1] and card.mjNumber == v[2] then
							gt.log("删除自动换三张的牌")
							table.remove(roomPlayer.holdMjTiles,i)
							break
						end
				    end
				end
				gt.dump(roomPlayer.holdMjTiles)
				self:sortPlayerMjTiles()
			else
				self:removeThreeCardFormPlayer()
			end
		else
			gt.log("别的玩家换三张成功")
			gt.log("onRecUserReplaceCard ..............." .. roomPlayer.displaySeatIdx)
			local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
			local img_replacecard = gt.seekNodeByName(playerNode,"Image_threecard")
			if img_replacecard then
				img_replacecard:setVisible(false)
			end
		end

		local hasReplaceIndex = 0
		for k,v in pairs(self.replaceThreeOkType) do
			if tonumber(v) == roomPlayer.displaySeatIdx then
				hasReplaceIndex = 1
				break;
			end
		end
		
		if hasReplaceIndex == 0 then
			table.insert(self.replaceThreeOkType, string.format("%d",roomPlayer.displaySeatIdx))
		end
		
		dump(self.replaceThreeOkType)
		
		if #self.replaceThreeOkType == 4 then
			gt.log("表示4个人都换三张完成 ................ ")
			self.replaceThreeCardType = true
		end
	end
end

function PlaySceneMatch:checkReplaceOkBtn()
	gt.log("checkReplaceOkBtn ....................")

	local type1 = false
	local type2 = false
	local type3 = false
	for k,v in pairs(self.replaceThreeCardTable) do

		if v.mjColor == 1 then
			type1 = true
		elseif v.mjColor == 2 then
			type2 = true
		elseif v.mjColor == 3 then
			type3 = true
		end
	end

	local chooseType = false
	if type1 == true and type2 == false and type3 == false then
		chooseType = true
	elseif type1 == false and type2 == true and type3 == false then
		chooseType = true
	elseif type1 == false and type2 == false and type3 == true then
		chooseType = true
	else
		chooseType = false
	end

	local node_ReplaceThreeCard = gt.seekNodeByName(self.rootNode,"Node_ReplaceThreeCard")
	node_ReplaceThreeCard:setVisible(true)
	local Btn_Replace_ThreeCard = gt.seekNodeByName(node_ReplaceThreeCard,"Btn_Replace_ThreeCard")
	Btn_Replace_ThreeCard:setTouchEnabled(true)
	gt.addBtnPressedListener(Btn_Replace_ThreeCard,function ()
		gt.log("发送给服务器换三张哦。。。。。。。")
		Btn_Replace_ThreeCard:setTouchEnabled(false)
		self.TimeCDControl = false
		self.ownerSendReplaceCardMsg = true
		
		dump(self.replaceThreeCardTable)
		local replaceCard1 = self.replaceThreeCardTable[1]
		local replaceCard2 = self.replaceThreeCardTable[2]
		local replaceCard3 = self.replaceThreeCardTable[3]
		local msgToSend = {}
		msgToSend.m_msgId = gt.GC_REPLACE_CARD
		msgToSend.m_pos = self.dingque_pos
		msgToSend.m_card = {{replaceCard1.mjColor,replaceCard1.mjNumber},{replaceCard2.mjColor,replaceCard2.mjNumber},{replaceCard3.mjColor,replaceCard3.mjNumber}} 
		gt.socketClient:sendMessage(msgToSend)
	end)

	if chooseType == true then
		-- 同花色  
		if table.getn(self.replaceThreeCardTable) == 3 then
			Btn_Replace_ThreeCard:setEnabled(true)
		else
			Btn_Replace_ThreeCard:setEnabled(false)
		end
	else
		Btn_Replace_ThreeCard:setEnabled(false)
	end
	
end

function PlaySceneMatch:onRecUserReplaceCardComplate( msgTbl )
	
	gt.log("onRecUserReplaceCardComplate ...............")

	gt.dump(msgTbl)

	self.replaceThreeCardType = true

	local Image_ReplaceNotice = gt.seekNodeByName(self.rootNode,"Image_ReplaceNotice")
	Image_ReplaceNotice:setVisible(true)
	Image_ReplaceNotice:setPosition(cc.p(640,200))
	self.Image_ReplaceNotice = Image_ReplaceNotice
	local showLabel = gt.seekNodeByName(Image_ReplaceNotice,"label_replace_show")
	if msgTbl.m_flag == 1 or msgTbl.m_flag == 2 then
		showLabel:setString("顺时针换牌")
	elseif msgTbl.m_flag == 3 or msgTbl.m_flag == 4 then
		showLabel:setString("对家换牌")
	elseif msgTbl.m_flag == 5 or msgTbl.m_flag == 6 then
		showLabel:setString("逆时针换牌")
	end

	local act1 = cc.MoveBy:create(2,cc.p(0,150))
	local act2 = cc.FadeIn:create(2)
	local act3 = cc.Spawn:create(act1,act2)
	local act6 = cc.EaseBackOut:create(act3)
	local act4 = cc.CallFunc:create(function()
		self.Image_ReplaceNotice:setVisible(false)
	end)
	local act5 = cc.Sequence:create(act6,cc.DelayTime:create(1),act4)
	self.Image_ReplaceNotice:runAction(act5)

	-- 添加花三张的牌
	for i=1,3 do
		local v = msgTbl.m_card[i]
		self:addMjTileToPlayer(v[1],v[2],true)
	end

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	dump(roomPlayer.holdMjTiles)
    self:sortPlayerMjTiles( true )


    for k,v in pairs(self.replaceNewThreeCardTable) do
    	local mjTilePos = cc.p(v.mjTileSpr:getPosition())
		v.mjTileSpr:setPosition(cc.p(mjTilePos.x, mjTilePos.y + 50))

		local moveAction = cc.MoveTo:create(2, cc.p(mjTilePos.x, mjTilePos.y))
		v.mjTileSpr:runAction(moveAction)

    end

end

function PlaySceneMatch:removeThreeCardFormPlayer()
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for i=#roomPlayer.holdMjTiles, 1, -1 do 
		local card = roomPlayer.holdMjTiles[i]
		if card.mjChooseType then
			table.remove(roomPlayer.holdMjTiles,i) 
		end
    end
    self:sortPlayerMjTiles()
end

function PlaySceneMatch:IsSameIp()
	local tmp = {}
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
	    if not tmp[tostring(roomPlayer.ip)] then
	        tmp[tostring(roomPlayer.ip)] = 1
	    else
	        tmp[tostring(roomPlayer.ip)] = tmp[tostring(roomPlayer.ip)] + 1
	    end
	end
	local showStr = ""
	for k,v in pairs(tmp) do
	    if v > 1 then
        	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
        		if roomPlayer.ip == k then
        			showStr = showStr.." 玩家:"..tostring(roomPlayer.nickname)
        		end
        	end
        	showStr = showStr.."为同一IP\n"
	    end
	end

	if string.len(showStr) > 0 then
		local Sprite_IPsame = gt.seekNodeByName(self.rootNode, "Sprite_IPsame")
		Sprite_IPsame:setZOrder(888)
		local Text_IPTip = gt.seekNodeByName(Sprite_IPsame, "Text_IPTip")
		local RactY = Sprite_IPsame:getContentSize().height
		local position = cc.p(Sprite_IPsame:getPosition())
		local callFunc1 = cc.CallFunc:create(function(sender)
			Text_IPTip:setString(showStr)
			Sprite_IPsame:setVisible(true)
		end)
		local callFunc2 = cc.CallFunc:create(function(sender)
			Sprite_IPsame:setVisible(false)
		end)
		local moveTo = cc.MoveTo:create(1, cc.p(position.x, position.y-RactY))
		local delayTime = cc.DelayTime:create(2)
		local moveTo1 = cc.MoveTo:create(1, position)
		local sequence = cc.Sequence:create(callFunc1,moveTo,delayTime,moveTo1,callFunc2)
		Sprite_IPsame:runAction(sequence)
	end
end

function PlaySceneMatch:showLastFourCard()
	local Image_ReplaceNotice = gt.seekNodeByName(self.rootNode,"Image_ReplaceNotice")
	Image_ReplaceNotice:setVisible(true)
	Image_ReplaceNotice:setPosition(cc.p(640,200))
	self.Image_ReplaceNotice = Image_ReplaceNotice
	local showLabel = gt.seekNodeByName(Image_ReplaceNotice,"label_replace_show")
	showLabel:setString("最后四张牌")

	local act1 = cc.MoveBy:create(2,cc.p(0,150))
	local act2 = cc.FadeIn:create(2)
	local act3 = cc.Spawn:create(act1,act2)
	local act6 = cc.EaseBackOut:create(act3)
	local act4 = cc.CallFunc:create(function()
		self.Image_ReplaceNotice:setVisible(false)
	end)
	local act5 = cc.Sequence:create(act6,cc.DelayTime:create(1),act4)
	self.Image_ReplaceNotice:runAction(act5)
end

return PlaySceneMatch

