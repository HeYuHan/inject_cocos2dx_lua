local gt = cc.exports.gt
local bridge = gt.bridge
local loginStrategy = require("app/LoginIpStrategy")
local PlaySceneBase = require("app/views/PlaySceneBase")

local PlaySceneErRen = class("PlaySceneErRen", PlaySceneBase)

PlaySceneErRen.DecisionType = {
    -- 接炮胡
    TAKE_CANNON_WIN                = 1,
    -- 自摸胡
    SELF_DRAWN_WIN                = 2,
    -- 明杠
    BRIGHT_BAR                    = 3,
    -- 暗杠
    DARK_BAR                    = 4,
    -- 碰
    PUNG                        = 5,
    -- 吃
    EAT                            = 6,
    --眀补
    BRIGHT_BU                   = 7,
    --暗补
    DARK_BU                     = 8,
    --抢杠
    QIANG_GANG                  = 9
}

PlaySceneErRen.ZOrder = {
    MJTABLE                        = 1,
    PLAYER_INFO                    = 2,
    MJTILES                        = 6,
    OUTMJTILE_SIGN                = 7,
    DECISION_BTN                = 8,
    DECISION_SHOW                = 9,
    PLAYER_INFO_TIPS            = 10,
    REPORT                        = 16,
    DISMISS_ROOM                = 17,
    SETTING                        = 18,
    CHAT                        = 20,
    MJBAR_ANIMATION                = 21,
    FLIMLAYER                   = 16,
    HAIDILAOYUE                    = 23,

    ROUND_REPORT                = 66, -- 单局结算界面显示在总结算界面之上
    ROUND_REPORT_Activity        = 67
}

PlaySceneErRen.FLIMTYPE = {
    FLIMLAYER_BAR                = 1,
    FLIMLAYER_BU                = 2,
}

PlaySceneErRen.TAG = {
    FLIMLAYER_BAR                = 50,
    FLIMLAYER_BU                = 51,
}

function PlaySceneErRen:ctor(enterRoomMsgTbl)
    PlaySceneBase.ctor(self, enterRoomMsgTbl)
    gt.log("______________________")
    -- 注册节点事件
    self:registerScriptHandler(handler(self, self.onNodeEvent))

    -- 加载界面资源
    self.rootNode = gt.loadCSB("PlaySceneNeiJiang.csb", self)
    self.rootNode:runAction(cc.CSLoader:createTimeline("PlaySceneNeiJiang.csb"))

    self.rootNode:setAnchorPoint(0.5, 0.5)
    self.rootNode:setPosition(gt.winCenter)
    self:addChild(self.rootNode)
    gt.seekNodeByName(self.rootNode, "Node_WIFI"):setPositionX(gt.seekNodeByName(self.rootNode, "Node_WIFI"):getPositionX()+30)
	gt.seekNodeByName(self.rootNode, "mahjong_title"):setSpriteFrame("playScene96.png")

    self:adjustUIforFixHeight()

    gt.isInit = 1

    self.mjCount = 13 -- 当前牌局张数
    self.playerCount = 4 -- 玩家数量
    if enterRoomMsgTbl.m_state == 118 then
        self.playerCount = 3 -- 玩家数量
    elseif enterRoomMsgTbl.m_state == 120 then
        self.playerCount = 2 -- 玩家数量
    end

    -- 胡牌之后,单据结算界面延迟显示时间
    self.reportDelayTime = 1.2
    -- 海底牌展示时间
    self.haidCardShowTime = 1.2

    -- 牌数不足发送重连消息
    self.flushCardNumFlag = false

    self.finalReportMsg = nil

    self.roundReportMsg = nil

    self.isShowPaiType = false

    -- 房间号
    local roomIDLabel = gt.seekNodeByName(self.rootNode, "Label_roomID")
    roomIDLabel:setString(tostring(enterRoomMsgTbl.m_deskId))
    --复制房间号
    if gt.isInReview == false then
        local readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
        local inviteFriendBtn = gt.seekNodeByName(readyPlayNode, "Btn_inviteFriend")
        local roomIDLabelButton = ccui.Button:create()
        roomIDLabelButton:loadTextures("playScene13.png","playScene13.png","",ccui.TextureResType.plistType)
        -- roomIDLabelButton:setOpacity(0)
        -- roomIDLabelButton:setContentSize(roomIDLabel:getContentSize())
        roomIDLabelButton:setAnchorPoint(inviteFriendBtn:getAnchorPoint())
        roomIDLabelButton:setPosition(cc.p(inviteFriendBtn:getPositionX(),inviteFriendBtn:getPositionY()-80))
        roomIDLabelButton:setTouchEnabled(true)
        readyPlayNode:addChild(roomIDLabelButton)
        gt.addBtnPressedListener(roomIDLabelButton, function()
            if gt.isCopyText() then
                local TypeStr,tableStr = gt.PalyTypeText(enterRoomMsgTbl.m_state,enterRoomMsgTbl.m_playtype)
                local CopyStr = string.format("%s,房号:[%d],%d局\n%s\n(复制此消息打开游戏可直接进入该房间)",TypeStr,enterRoomMsgTbl.m_deskId,enterRoomMsgTbl.m_maxCircle,tableStr)
                gt.CopyText(CopyStr)
                require("app/views/NoticeTips"):create("提示", "复制房间号成功！", nil, nil, true)
            else
                require("app/views/NoticeTips"):create("提示", "当前客户端版本不支持复制，请更新版本。", nil, nil, true)
            end
        end)
    end
    -- 玩法
    -- 玩法类型
    self.playType = 3 --enterRoomMsgTbl.m_state
    gt.log("the play type is ..... " .. self.playType)
    -- 测试用四川
    gt.roomType = gt.RoomType.ROOM_SICHUAN

    gt.log("===enterRoomMsgTbl.m_maxCircle=" .. enterRoomMsgTbl.m_maxCircle .. "--" .. enterRoomMsgTbl.m_state)
    gt.m_maxCircle = tonumber(enterRoomMsgTbl.m_maxCircle)
    gt.m_state = tonumber(enterRoomMsgTbl.m_state)

    self:initHideNodes()

    local _rootNodeList = gt.findNodeArray(self.rootNode,
                                           "Node_playerInfo_#1#4",                   -- 刚进入房间,隐藏玩家信息节点
                                           {"Node_readySign", "Spr_readySign_#1#4"}, -- hidePlayersReadySign
                                           "Node_play",                              -- 隐藏玩家麻将参考位置（麻将参考位置父节点，pos(0，0）)
                                           "Spr_turnPosBg",                          -- 隐藏轮换位置标识（东南西北信息）
                                           "Node_roundState",                        -- 隐藏牌局状态（倒计时，剩余牌局，剩余牌数）
                                           "Node_decisionBtn",                       -- 隐藏玩家决策按钮（碰，杠，胡，过的父节点）
                                           "Node_selfDrawnDecision",                 -- 隐藏自摸决策暗杠，碰转明杠，自摸胡
                                           "Node_playBtns",                          -- 隐藏游戏中设置按钮
                                           "Btn_ready",                              -- 隐藏准备按钮
                                           "Node_chatBg",                            -- 隐藏所有玩家对话框
                                           "Node_hutype", {"Node_hutype", "huType#1#4"},
                                           {"Node_playerInfo_#1#4", "Image_que"},    -- 隐藏定缺的标志
                                           {"Node_playerInfo_#1#4", "Spr_piao"},     -- 隐藏定飘的标志
                                           "OutPaiBgNode",                           -- 隐藏新版本出牌
                                           "Node_ding",                              -- 定缺
                                           "Btn_decision_return",                    --点完躺决策之后出现的返回按钮
                                           "Node_ReplaceThreeCard"):setVisible(false)
    self.dingque               = _rootNodeList.Node_ding
    self.Node_roundState       = _rootNodeList.Node_roundState
    self.Node_ReplaceThreeCard = _rootNodeList.Node_ReplaceThreeCard

    -- 隐藏轮换位置标识（东南西北信息）
    for _, _child in ipairs(_rootNodeList.Spr_turnPosBg:getChildren()) do
        local fadeOut = cc.FadeOut:create(0.4)
        local fadeIn = cc.FadeIn:create(0.4)
        local seqAction = cc.Sequence:create(fadeOut, fadeIn)
        _child:runAction(cc.RepeatForever:create(seqAction))
    end
    self.Spr_turnPosBg = _rootNodeList.Spr_turnPosBg

    -- 倒计时
    self.lbl_playTimeCD:setString("0")

    self.rootNode:reorderChild(_rootNodeList.Node_decisionBtn, PlaySceneErRen.ZOrder.DECISION_BTN)
    self.rootNode:reorderChild(_rootNodeList.Node_selfDrawnDecision, PlaySceneErRen.ZOrder.DECISION_BTN)
    self.rootNode:reorderChild(_rootNodeList.Node_chatBg, PlaySceneErRen.ZOrder.CHAT)
    gt.addBtnPressedListener(_rootNodeList.Btn_ready, handler(self, self.readyBtnClickEvt))

    local settingBtn = gt.seekNodeByName(_rootNodeList.Node_playBtns, "Btn_setting")
    gt.addBtnPressedListener(settingBtn, function()
        local settingPanel = require("app/views/Setting"):create(enterRoomMsgTbl.m_pos,1)
        self:addChild(settingPanel, PlaySceneErRen.ZOrder.SETTING,102)
    end)

    local messageBtn = gt.seekNodeByName(_rootNodeList.Node_playBtns, "Btn_message")
    gt.addBtnPressedListener(messageBtn, function()
        local chatPanel = require("app/views/ChatPanel"):create()
        self:addChild(chatPanel, PlaySceneErRen.ZOrder.CHAT, 101)
    end)

    -- 麻将层
    local playMjLayer = cc.Layer:create()
    self.rootNode:addChild(playMjLayer, PlaySceneErRen.ZOrder.MJTILES)
    self.playMjLayer = playMjLayer

    -- 出的牌标识动画
    local outMjtileSignNode, outMjtileSignAnime = gt.createCSAnimation("animation/OutMjtileSign.csb")
    outMjtileSignAnime:play("run", true)
    outMjtileSignNode:setVisible(false)
    self.rootNode:addChild(outMjtileSignNode, PlaySceneErRen.ZOrder.OUTMJTILE_SIGN)
    self.outMjtileSignNode = outMjtileSignNode

    -- 头像下载管理器
    local playerHeadMgr = require("app/PlayerHeadManager"):create()
    self.rootNode:addChild(playerHeadMgr)
    self.playerHeadMgr = playerHeadMgr

    -- 玩家进入房间
    gt.log("yyyyy==")
    self:playerEnterRoom(enterRoomMsgTbl)

    -- 最大局数
    self.roundMaxCount = enterRoomMsgTbl.m_maxCircle
    -- 准备界面逻辑
    local paramTbl = {}
    paramTbl.roomID = enterRoomMsgTbl.m_deskId
    paramTbl.playerSeatPos = enterRoomMsgTbl.m_pos
    paramTbl.m_state = enterRoomMsgTbl.m_state
    paramTbl.roundMaxCount = enterRoomMsgTbl.m_maxCircle
    -- paramTbl.maxFanCount = enterRoomMsgTbl.m_maxFan
    paramTbl.playtypebranch = enterRoomMsgTbl.m_playtype
    self.readyPlay = require("app/views/ReadyPlay"):create(self.rootNode, paramTbl)

    -- 解散房间
    self.applyDimissRoom = require("app/views/ApplyDismissRoom"):create(self.roomPlayers, self.playerSeatIdx)
    self:addChild(self.applyDimissRoom, PlaySceneErRen.ZOrder.DISMISS_ROOM)

    if gt.isIOSPlatform() or gt.isAndroidPlatform() or cc.PLATFORM_OS_MAC == gt.targetPlatform then
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
    self.hasDingquePlay = false -- 是否有定缺玩法

    local dingqueColorTable = {}
    self.dingqueColorTable = dingqueColorTable

    self.isReplace3CardAllPlayerDone = false -- 是否所有玩家都完成了换三张
    self.replace3CardDoneUsers = {}          -- 完成了换三张的玩家的displaySeatIdx

    -- 用户选择的三张牌
    local replaceThreeCardTable = {}
    self.replaceThreeCardTable = replaceThreeCardTable

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

    -- 胡牌索引
    self.huIndex = 0

    -- 报叫
	self.isBaoJiaoSelected = false
	self.isBaoJiaoState = false

    self:initYuyin()
    self:registerAllMsgListener()

    self:adjustUIfor7Pai()    -- 为7张拍调整UI
    self:adjustUIfor2People() -- 为两人玩法调整UI

    self:initShowRemainTiles(enterRoomMsgTbl)

    self.nod_decisions:setLocalZOrder(100)
end

function PlaySceneErRen:adjustUIforFixHeight()
    if display.autoscale == "FIXED_HEIGHT" then
        self.rootNode:setScale(0.75)
        -- mahjongDeskbj:setScaleY(1280/960)
        gt.seekNodeByName(self.rootNode, "mahjong_table"):setScale(1280/960)
        gt.seekNodeByName(self.rootNode, "Label_time"):setPositionY(808)
        gt.seekNodeByName(self.rootNode, "Label_roomtext"):setPositionY(808)
        gt.seekNodeByName(self.rootNode, "Label_roomID"):setPositionY(808)
		gt.seekNodeByName(self.rootNode, "Text_TableType_BG"):setPositionY(808)
        gt.seekNodeByName(self.rootNode, "Btn_outRoom"):setPositionY(740)
        gt.seekNodeByName(self.rootNode, "Btn_dimissRoom"):setPositionY(-70)
        gt.seekNodeByName(self.rootNode, "Btn_setting"):setPositionY(740)
        gt.seekNodeByName(self.rootNode, "Btn_message"):setPositionY(660)
        gt.seekNodeByName(self.rootNode, "Image_52"):setPositionY(810)
        gt.seekNodeByName(self.rootNode, "LoadingBar_Battery"):setPositionY(810)
        gt.seekNodeByName(self.rootNode, "FileNode_wifi"):setPositionY(810)
        gt.seekNodeByName(self.rootNode, "Node_playerInfo_2"):setPositionY(670)
        gt.seekNodeByName(self.rootNode, "Node_playerInfo_4"):setPositionY(154)

        gt.seekNodeByName(self.rootNode, "Btn_Voice"):setPosition(1200,300)--语音

        local Node_playerMjTiles_2 = gt.seekNodeByName(self.rootNode, "Node_playerMjTiles_2")
        gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileHold_1"):setPositionY(730)
        gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileHold_2"):setPositionY(730)
        gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileOut_1"):setPositionY(658)
        gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileOut_2"):setPositionY(658)
        gt.seekNodeByName(Node_playerMjTiles_2, "Spr_mjTileOut_3"):setPositionY(617)
        gt.seekNodeByName(Node_playerMjTiles_2, "Panel_mjTileGroup"):setPositionY(702)
        gt.seekNodeByName(Node_playerMjTiles_2, "Node_showMjTile"):setPositionY(616)

        local Node_playerMjTiles_4 = gt.seekNodeByName(self.rootNode, "Node_playerMjTiles_4")
        gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileHold_1"):setPositionY(-20)
        gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileHold_2"):setPositionY(-20)
        gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileOut_1"):setPositionY(78)
        gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileOut_2"):setPositionY(78)
        gt.seekNodeByName(Node_playerMjTiles_4, "Spr_mjTileOut_3"):setPositionY(119)
        gt.seekNodeByName(Node_playerMjTiles_4, "Panel_mjTileGroup"):setPositionY(-77)
        gt.seekNodeByName(Node_playerMjTiles_4, "Node_showMjTile"):setPositionY(106)

        if self.nod_ip then
            self.nod_ip:setPositionY(835)
        end
    end
end

function PlaySceneErRen:adjustUIfor7Pai()
    if self.mjCount ~= 7 then return end
    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerMjTiles_#1#4", "Spr_mjTileOut_#1#3"}, "Node_playerInfo_#1#4")

    local _mjOffsetMap = {
        {x = 0, y = 180  - self.mjCount * 20},
        {x = -self.mjCount * 20, y = 0},
        {x = 0, y = -260 + self.mjCount * 20},
        {x = 650 - self.mjCount * 50, y = 0}
    }

    local _infoOffsetMap = {
        {x=0, y=0}, {x=0, y=0},
        {x=0, y=0}, {x=0, y=-60}
    }

    local _outOffsetMap = {
        {x=0, y=0}, {x=100, y=0},
        {x=0, y=0}, {x=-300, y=0}
    }

    for i=1, 4 do
        local _tilesNode = _nodeList["Node_playerMjTiles_" .. i]
        for _, _child in ipairs(_tilesNode:getChildren()) do
            if _child:getName() ~= "Node_showMjTile" then
                _child:setPosition(cc.pAdd(cc.p(_child:getPosition()), _mjOffsetMap[i]))
            end
        end
        _tilesNode.Spr_mjTileOut_1:setPosition(cc.pAdd(cc.p(_tilesNode.Spr_mjTileOut_1:getPosition()), _outOffsetMap[i]))
        _tilesNode.Spr_mjTileOut_2:setPosition(cc.pAdd(cc.p(_tilesNode.Spr_mjTileOut_2:getPosition()), _outOffsetMap[i]))
        _tilesNode.Spr_mjTileOut_3:setPosition(cc.pAdd(cc.p(_tilesNode.Spr_mjTileOut_3:getPosition()), _outOffsetMap[i]))

        local _infoNode = _nodeList["Node_playerInfo_" .. i]
        _infoNode:setPosition(cc.pAdd(cc.p(_infoNode:getPosition()), _infoOffsetMap[i]))
    end
end

function PlaySceneErRen:adjustUIfor2People()
    if self.playerCount ~= 2 then return end
    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerMjTiles_#1#4", "Spr_mjTileOut_#1#3"}, "Node_playerInfo_2")

    local _outOffsetMap = {{}, {x=162, y=0}, {}, {x=-120, y=0}}

    for i=2, 4, 2 do
        local _t = _nodeList["Node_playerMjTiles_" .. i]
        local _t1, _t2, _t3 = unpack({_t.Spr_mjTileOut_1, _t.Spr_mjTileOut_2, _t.Spr_mjTileOut_3})

        _t1:setPositionX(_t1:getPositionX() + _outOffsetMap[i].x)
        _t2:setPositionX(_t2:getPositionX() + _outOffsetMap[i].x)
        _t3:setPositionX(_t3:getPositionX() + _outOffsetMap[i].x)
    end

    _nodeList.Node_playerInfo_2:setPositionX(_nodeList.Node_playerInfo_2:getPositionX() + 100)
end

-- 初始化时隐藏节点
function PlaySceneErRen:initHideNodes()
    self.nod_Piao:setVisible(false)
end

function PlaySceneErRen:initYuyin()
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

    -- 正式包点击语音按钮回调函数
    self.starAudioTime = 0
    local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.began then

            self.sendVocie = false
            gt.soundEngine:pauseAllSound()
            self.sendVocie = true
            self.yuyinNode:setVisible(true)
            self.rootNode:reorderChild(self.yuyinNode, 100)
            self:playYuYinAnimation()
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
end

function PlaySceneErRen:playYuYinAnimation()
    local action = nil
    local yuyinNode, action = gt.createCSAnimation("huatong.csb")
    action:play("huatong", true)
    yuyinNode:setPosition(cc.p(self.yuyinNode:getContentSize().width/2,
                               self.yuyinNode:getContentSize().height/2))
    self.yuyinNode:addChild(yuyinNode, 1000)
    self.m_yuyinNode = yuyinNode
end

function PlaySceneErRen:cancelYuYinAnimation()
    if self.m_yuyinNode then
        self.m_yuyinNode:removeFromParent()
        self.m_yuyinNode = nil
    end
end

function PlaySceneErRen:registerAllMsgListener()
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
    gt.socketClient:registerMsgListener(gt.GC_ROUND_REPORT, self, self.onRcvRoundReport)
    gt.socketClient:registerMsgListener(gt.GC_FINAL_REPORT, self, self.onRcvFinalReport)

    gt.registerEventListener(gt.EventType.BACK_MAIN_SCENE, self, self.backMainSceneEvt)

    -- gt.socketClient:registerMsgListener(gt.GC_START_DECISION, self, self.onRcvStartDecision)
    gt.socketClient:registerMsgListener(gt.GC_SYNC_START_PLAYER_DECISION, self, self.onRcvSyncStartDecision)
    gt.socketClient:registerMsgListener(gt.GC_SYNC_BAR_TWOCARD, self, self.onRcvSyncBarTwoCard)

    -- 断线重连
    gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)

    -- 跑马灯
    gt.socketClient:registerMsgListener(gt.GC_MARQUEE, self, self.onRcvMarquee)

    -- 新命令 换三张
    gt.socketClient:registerMsgListener(gt.CG_REPLACE_CARD, self, self.onRecUserReplaceCard)
    -- 换牌结果
    gt.socketClient:registerMsgListener(gt.CG_REPLACE_CARD_CHOOSE, self, self.onRecUserReplaceCardComplate)

    gt.socketClient:registerMsgListener(gt.CG_REMOVE_BAR_CARD,self,self.onRecUserRemoveBarCard)

    --解散房间后回调
    gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER,self,self.onRcvLoginServer)

    gt.socketClient:registerMsgListener(gt.GC_LOGIN_GATE, self, self.onRcvLoginGate)

	gt.socketClient:registerMsgListener(gt.GC_BAOJIAO, self, self.onRecBaoJiao)
	gt.socketClient:registerMsgListener(gt.GC_BAOJIAO_COMPLATE, self, self.onRecUserDBaoJiaoComplate)

    -- self.CG_DING_PIAO = gt.CG_USER_DING_QUE
    -- self.CG_DING_PIAO_COMPLATE = gt.CG_USER_DING_QUE_COMPLATE
    -- self.GC_DING_PIAO = gt.GC_USER_DING_QUE
	-- gt.socketClient:registerMsgListener(self.CG_DING_PIAO, self, self.onRcvDingPiao)
	-- gt.socketClient:registerMsgListener(self.CG_DING_PIAO_COMPLATE, self, self.onRcvDingPiaoComplate)

    gt.socketClient:registerMsgListener(gt.CG_USER_DING_QUE, self, self.onRecUserDingQue)
	gt.socketClient:registerMsgListener(gt.CG_USER_DING_QUE_COMPLATE, self, self.onRecUserDingQueComplate)
end

function PlaySceneErRen:unregisterAllMsgListener()
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
    gt.socketClient:unregisterMsgListener(gt.GC_ROUND_REPORT)
    gt.socketClient:unregisterMsgListener(gt.GC_FINAL_REPORT)
    -- gt.socketClient:unregisterMsgListener(gt.GC_START_DECISION)
    gt.socketClient:unregisterMsgListener(gt.GC_SYNC_START_PLAYER_DECISION)
    gt.socketClient:unregisterMsgListener(gt.GC_SYNC_BAR_TWOCARD)


    gt.socketClient:unregisterMsgListener(gt.GC_LOGIN)

    gt.socketClient:unregisterMsgListener(gt.GC_BAOJIAO)
    gt.socketClient:unregisterMsgListener(gt.GC_BAOJIAO_COMPLATE)

    gt.socketClient:unregisterMsgListener(gt.CG_REPLACE_CARD)
    gt.socketClient:unregisterMsgListener(gt.CG_REPLACE_CARD_CHOOSE)

    gt.socketClient:unregisterMsgListener(gt.CG_REMOVE_BAR_CARD)

    gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)

    gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_GATE)

    gt.socketClient:unregisterMsgListener(gt.GC_MARQUEE)

    gt.socketClient:unregisterMsgListener(gt.CG_USER_DING_QUE)
    gt.socketClient:unregisterMsgListener(gt.CG_USER_DING_QUE_COMPLATE)
end

function PlaySceneErRen:initShowRemainTiles(msgTbl)
    if table.contains(msgTbl.m_playtype, 42) then     -- 两房
        self.lbl_remainTiles:setString("72")
    elseif table.contains(msgTbl.m_playtype, 43) then -- 三房
        self.lbl_remainTiles:setString("108")
    end
end

-- start --
--------------------------------
-- @class function
-- @description 服务器返回登录大厅结果
-- end --
function PlaySceneErRen:onRcvLoginServer(msgTbl)

	self.startGame = true
    gt.removeLoadingTips()
    gt.socketClient:setIsStartGame(true)
    gt.socketClient:setIsCloseHeartBeat(false)

    if self.finalReport == nil then
        -- 判断进入大厅还是房间
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

-- 断线重连,走一次登录流程
function PlaySceneErRen:reLogin()
    print("========重连登录1")
    local accessToken     = cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
    local refreshToken     = cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
    local openid         = cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

    local unionid         = cc.UserDefault:getInstance():getStringForKey( "WX_Uuid" )
    local sex             = cc.UserDefault:getInstance():getStringForKey( "WX_Sex" )
    local nickname         = gt.wxNickName--cc.UserDefault:getInstance():getStringForKey( "WX_Nickname" )
    local headimgurl     = cc.UserDefault:getInstance():getStringForKey( "WX_ImageUrl" )

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
    -- dump(msgToSend)
    print("========重连登录2")
end

function PlaySceneErRen:onRcvLogin(msgTbl)

    -- 去掉转圈
    -- gt.removeLoadingTips()

    -- 发送登录gate消息
    gt.loginSeed         = msgTbl.m_seed
    -- gt.GateServer.ip     = gt.socketClient.serverIp
    gt.GateServer.port     = tostring(msgTbl.m_gatePort)

    gt.socketClient:close()
    -- print("===走这里,那么ip port是什么?",gt.GateServer.ip, gt.GateServer.port)
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
    -- -- print("========重连登录5")

end

--服务器返回gate登录
function PlaySceneErRen:onRcvLoginGate(msgTbl)

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

function PlaySceneErRen:onNodeEvent(eventName)
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

        -- 切到后台
        self._listener1 = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND_EVENT", handler(self, self.onEnterBackground) )
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithFixedPriority(self._listener1, 1)
         local function onEvent2(event)
             gt.resume_time = 1
        end

        --返回前台
        self.foregroundEvent = cc.EventListenerCustom:create("APP_ENTER_FOREGROUND_EVENT", onEvent2)
        eventDispatcher:addEventListenerWithFixedPriority(self.foregroundEvent, 1)

    elseif "exit" == eventName then
        local eventDispatcher = self.playMjLayer:getEventDispatcher()
        eventDispatcher:removeEventListenersForTarget(self.playMjLayer)

        gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
        -- 屏蔽掉音效的update
        if self.voiceUrlScheduleHandler then
            gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
            self.voiceUrlScheduleHandler = nil
        end

        gt.soundEngine:playMusic("bgm1", true)
    end
end

function PlaySceneErRen:onRecUserRemoveBarCard( msgTbl )
    self.isPlayerShow = false
    gt.log("onRecUserRemoveBarCard ........ ")
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

-- 当前房间的玩法   支持换三张吗 支持定缺(广安定缺可选)
function PlaySceneErRen:onTablePlayState( msgTbl )
    if msgTbl.m_playtype then
        gt.log("_______________   onTablePlayState ")
        dump(msgTbl.m_playtype)
        self.isPlayThreeCardState = table.contains(msgTbl.m_playtype, 20)
        self.hasDingquePlay = table.contains(msgTbl.m_playtype, 180)

        if table.contains(msgTbl.m_playtype, 35) then
            self.mjCount = 7
        elseif table.contains(msgTbl.m_playtype, 37) then
            self.mjCount = 13
        end

        self.hasBaozi   = table.contains(msgTbl.m_playtype, 193)
        self.hasPiao    = table.contains(msgTbl.m_playtype, 104)
        self.hasBaoJiao = table.contains(msgTbl.m_playtype, 52 )

        self.fangCount = 2
        if table.contains(msgTbl.m_playtype, 43) then
            self.fangCount = 3
        end
    end
end

-- start --
--------------------------------
-- @class function
-- @description 接收跑游戏桌面马灯消息
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:onRcvPlaySeceneCSMarquee(msgTbl)
    if gt.isIOSPlatform() and gt.isInReview then
        local str_des = gt.getLocationString("LTKey_0048")
        self.marqueeMsg:showMsg(str_des, 3)
    else
        self.marqueeMsg:showMsg(msgTbl.m_str, 3)
    end
end

--切到后台 恢复鼠标事件
function PlaySceneErRen:onEnterBackground()

    if self.isTouchBegan then
        self.isTouchBegan = false
    end

    --如果鼠标正在拖动，将牌放回原来的位置 不出牌
    if self.isTouchMoved and self.chooseMjTile and self.chooseMjTile.mjTileSpr then
        self.chooseMjTile.mjTileSpr:setPosition(self.mjTileOriginPos)
        self.playMjLayer:reorderChild(self.chooseMjTile.mjTileSpr, self.mjTileOriginPos.y)

        self.isTouchMoved = false
    end
end

function PlaySceneErRen:onTouchCancelled(touch, event)
    self.isTouchBegan = false
end

function PlaySceneErRen:onTouchBegan(touch, event)
    gt.log("touch11111111111111111111")
    if self.startGame then
        return false
    end
    gt.log("touch1111111---------------")
    if self.isTouchBegan then
        return false
    end
    gt.log("touch22222222222222222222222")
    if self.isPlayThreeCardState == false then

        -- 不需要换三张
        -- 胡牌后不可以出牌了

        if self.hasDingquePlay and (self.dingqueColorState == false) then
            -- 没定缺完成限制点击
            return false
        end
        gt.log("touch333333333333333333")
        if self.ownerWin then
            return false
        end

        if not self.isPlayerShow or self.isPlayerDecision then
            gt.log("touch4444444444444444444")
            return false
        end

        local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
        if not touchMjTile or touchMjTile.isMark then
            return false
        end
        gt.log("touch5555555555555555555555")
        -- --判断选中的花色为灰色则返回false
        -- if self.mjTangTable then
        --     for i,v in ipairs(self.mjTangTable) do
        --         if touchMjTile.mjColor == v.mjColor and touchMjTile.mjNumber == v.mjNumber and self.IsShowTang then
        --             gt.log("此麻将无法点击")
        --             return false
        --         end
        --     end
        -- end
        gt.log("touch666666666666666666666")
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

        -- 选择了换三张玩法

        if self.isReplace3CardAllPlayerDone then
            -- 表示都换完了  按照正常流程走

            if self.hasDingquePlay and (self.dingqueColorState == false) then
                -- 没定缺完成限制点击
                return false
            end

            if self.ownerWin then
                return false
            end

            if not self.isPlayerShow or self.isPlayerDecision then
                return false
            end

            local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
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
            -- 表示自己发送了换三张消息
            if self.ownerSendReplaceCardMsg then
                return false
            end
            -- 表示别人没换完  但自己换完了
            if self.ownerReplaceCardType then
                return false
            end

            -- 表示没换完
            local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
            if not touchMjTile then
                return false
            end

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

function PlaySceneErRen:onTouchMoved(touch, event)
    local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
    if cc.pGetDistance(self.preTouchPoint, touchPoint) < 10 then
        return
    end
    if self.isPlayThreeCardState then
        if self.isReplace3CardAllPlayerDone then
            local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
            self.chooseMjTile.mjTileSpr:setPosition(touchPoint)
            self.isTouchMoved = true
        end
    else
        local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
        self.chooseMjTile.mjTileSpr:setPosition(touchPoint)
        self.isTouchMoved = true
    end

end

function PlaySceneErRen:onTouchEnded(touch, event)
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

        -- --点击牌后出现躺节点
        -- if self.IsShowTang then
        --     -- 放回原来的位置,不出牌
        --     self.chooseMjTile.mjTileSpr:setPosition(self.mjTileOriginPos)
        --     self.playMjLayer:reorderChild(self.chooseMjTile.mjTileSpr, self.mjTileOriginPos.y)

        --     self:BtnTangCallBack(self.chooseMjTile)
        --     return
        -- end

        if isShowMjTile then
            -- 发送出牌消息
            local msgToSend = {}
            msgToSend.m_msgId = gt.CG_SHOW_MJTILE
            -- 出牌标识
            msgToSend.m_type = 1
            msgToSend.m_think = {}
            if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                if msgToSend.m_type == 3 then
                    msgToSend.m_type = 4
                    elseif msgToSend.m_type == 4 then
                    msgToSend.m_type = 8
                end
            end
            local think_temp = {self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber}
            table.insert(msgToSend.m_think,think_temp)
            gt.socketClient:sendMessage(msgToSend)

            self.isPlayerShow = false
            self.preClickMjTile = nil
            -- 停止倒计时音效
            if self.playCDAudioID then
                gt.soundEngine:stopEffect(self.playCDAudioID)
                self.playCDAudioID = nil
            end


            -- 把牌先打出去
            self:addAlreadyOutMjTiles(self.playerSeatIdx, self.chooseMjTile.mjColor, self.chooseMjTile.mjNumber)
            -- self:checkMjTile()
            -- 显示出的牌箭头标识
            self:showOutMjtileSign(self.playerSeatIdx)

            --屏蔽报叫的牌
            if self.isBaoJiaoState then
                self:setAllMaskLayer2(true)
            end

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
        if self.isReplace3CardAllPlayerDone then

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
                if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                    if msgToSend.m_type == 3 then
                        msgToSend.m_type = 4
                        elseif msgToSend.m_type == 4 then
                        msgToSend.m_type = 8
                    end
                end
                local think_temp = {self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber}
                table.insert(msgToSend.m_think,think_temp)
                gt.socketClient:sendMessage(msgToSend)

                self.isPlayerShow = false
                self.preClickMjTile = nil
                -- 停止倒计时音效
                if self.playCDAudioID then
                    gt.soundEngine:stopEffect(self.playCDAudioID)
                    self.playCDAudioID = nil
                end

                -- 把牌先打出去
                self:addAlreadyOutMjTiles(self.playerSeatIdx, self.chooseMjTile.mjColor, self.chooseMjTile.mjNumber)
                -- self:checkMjTile()
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
            -- dump(self.chooseMjTile)
            -- 换三张
            if self.chooseMjTile.mjChooseType == true then
                gt.log(" touch bengan 复原 ............. ")

                local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
                local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
                self.chooseMjTile.mjTileSpr:runAction(moveAction)

                self:replace3CardRemoveChoose(self.chooseMjTile)
            else
                if self:replace3CardAddChoose(self.chooseMjTile) then
                    gt.log(" touch bengan 弹起 ............. ")

                    local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
                    local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
                    self.chooseMjTile.mjTileSpr:runAction(moveAction)
                end
            end
        end
    end
    self.isTouchBegan = false
    self.isTouchMoved = false
end

function PlaySceneErRen:outPaiBigAnimate(seatIdx, color, number ,isShow)

    --播放出牌音效
    gt.soundEngine:playEffect("common/audio_outpai")

    local roomPlayer = self.roomPlayers[seatIdx]
    local OutPaiBgNode = gt.seekNodeByName(self.rootNode,"OutPaiBgNode")
    OutPaiBgNode:setVisible(true)
    OutPaiBgNode:setLocalZOrder(10009)
    self:reorderChild(OutPaiBgNode, gt.winSize.height)
    for i=1,4 do
        local outPaiBg = gt.seekNodeByName(OutPaiBgNode,"outPaiBg"..i)
        outPaiBg:setVisible(false)
    end
    gt.log("111111111111..........")
    gt.log("the isshow is .. " .. isShow)
    if isShow == 1 then
        gt.log("2222222222222..........")
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
    gt.log("333333333333333..........")

end

function PlaySceneErRen:update(delta)
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
        -- gt.log("timenow = "..timenow.."currtime = "..self.currtime)
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


    -- -- 如果不是13或者14张牌,直接重新登录
    -- if self:checkRightCradNum() == 2 and self.flushCardNumFlag == true then
    --     self.flushCardNumFlag = false
    --     gt.socketClient.isCheckNet = false
    --     -- 心跳时间稍微长一些,等待重新登录消息返回
    --     gt.socketClient.heartbeatCD = gt.socketClient.heatTime
    --     -- 监测网络状况下,心跳回复超时发送重新登录消息
    --     gt.socketClient:reloginServer()
    -- end
end

function PlaySceneErRen:checkVersion()
    local appVersion = bridge.getVersionName()

    local versionNumber = string.split(appVersion, '.')
    if tonumber(versionNumber[3]) < 7 then
        return false
    end
    return true
end

function PlaySceneErRen:initPaoMaDeng()
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

function PlaySceneErRen:onRcvMarquee(msgTbl)
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

function PlaySceneErRen:initWifi()

    local Node_Wifi = gt.seekNodeByName(self.rootNode, "Node_WIFI")
    -- 电量
    self.LoadingBar_Battery = gt.seekNodeByName(Node_Wifi, "LoadingBar_Battery")
    local battery = bridge.getDeviceBattery()
    gt.log("battery = "..battery)
    self.LoadingBar_Battery:setPercent(battery)
    -- wifi信号
    local FileNode_wifi = gt.seekNodeByName(Node_Wifi, "FileNode_wifi")
    local wifiNode, wifiAction = gt.createCSAnimation("Wifi.csb")
    wifiNode:setScale(0.8)
    self.wifiAction = wifiAction
    self.wifiNode = wifiNode
    FileNode_wifi:addChild(wifiNode)
    self.updateWifiTime = 0

    --网络延迟
    self.currtimeLabel = gt.createTTFLabel("0ms",24)
    self.currtimeLabel:setPosition(cc.p(FileNode_wifi:getPositionX()-50, FileNode_wifi:getPositionY()))
    self.currtimeLabel:setTextColor(cc.RED)
    Node_Wifi:addChild(self.currtimeLabel)
end

function PlaySceneErRen:updateWifi()
    -- if not self:checkVersion() then
    --     return false
    -- end

    local signalStatus = bridge.getDeviceSignalStatus()
    local signalLevel = bridge.getDeviceSignalLevel()

    if signalStatus == "WIFI" then
        if signalLevel >= 0 and signalLevel <= 3 then
            self.wifiAction:play("wifi" .. signalLevel, true)
            -- gt.log("signalLevel = "..signalLevel)
            self.wifiNode:setScale(0.7)
        end
    else
        if signalLevel >= 0 and signalLevel <= 4 then
            self.wifiAction:play("mobile" .. (tonumber(signalLevel) + 1), true)
            self.wifiNode:setScale(1.0)
        end
    end

    local battery = bridge.getDeviceBattery()
    self.LoadingBar_Battery:setPercent(battery)
end

-- 检查手牌是否低于13张牌
function PlaySceneErRen:checkRightCradNum()
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
function PlaySceneErRen:onRcvRoomCard(msgTbl)
    if msgTbl.m_coins then
        gt.playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3,msgTbl.m_coins}
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
function PlaySceneErRen:onRcvEnterRoom(msgTbl)
    gt.removeLoadingTips()

    gt.log("________ onRcvEnterRoom ")

    dump(msgTbl)

    self.playMjLayer:removeAllChildren()
    self:playerEnterRoom(msgTbl)

    local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
    if hutypeNode:isVisible() then
        hutypeNode:setVisible(false)
    end
    if self.outMjtileSignNode:isVisible() then
        self.outMjtileSignNode:setVisible(false)
    end
end

-- start --
--------------------------------
-- @class function
-- @description 接收房间添加玩家消息
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:onRcvAddPlayer(msgTbl)
    dump(msgTbl)
    -- 封装消息数据放入到房间玩家表中
    local roomPlayer = {}
    roomPlayer.uid = msgTbl.m_userId
    roomPlayer.nickname = msgTbl.m_nike
    roomPlayer.headURL = string.sub(msgTbl.m_face, 1, string.lastString(msgTbl.m_face, "/")) .. "96"
    roomPlayer.sex = msgTbl.m_sex
    roomPlayer.ip = msgTbl.m_ip
    roomPlayer.m_credit = msgTbl.m_credits
    -- 服务器位置从0开始
    -- 客户端位置从1开始
    roomPlayer.seatIdx = msgTbl.m_pos + 1
    -- 显示座位编号
    roomPlayer.displaySeatIdx = self:getDisplaySeatIdxByMPos(msgTbl.m_pos)
    roomPlayer.readyState = msgTbl.m_ready
    roomPlayer.score = msgTbl.m_score

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
function PlaySceneErRen:onRcvRemovePlayer(msgTbl)
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
function PlaySceneErRen:onRcvSyncRoomState(msgTbl)

    gt.log("____________33__ onRcvSyncRoomState ")
    dump(msgTbl)

    -- 停止所有事件   删除牌桌所有牌
    self:stopAllActions()
    self.playMjLayer:removeAllChildren()

    if msgTbl.m_state == 1 then
        -- 等待状态
        return
    end

    self.pung = true

    gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Image_threecard", "Image_dingque"}):setVisible(false)

    -- 断线重连后,当前所选牌,索引等需要清理掉
    self.chooseMjTile         = nil
    self.chooseMjTileIdx     = nil
    self.preClickMjTile = nil

    self.huIndex = 0

    -- 定缺的标志
    self.dingqueTypeTable = {}

    -- 定缺的状态 false 没有定缺
    self.dingqueColorState = false
    self.hasDingquePlay = false -- 是否有定缺玩法

    self.dingqueColorTable = {}

    -- 用户选择的三张牌
    self.replaceThreeCardTable = {}

    self.replace3CardDoneUsers = {}

    self.startGame = false

    if self.applyDimissRoom and self.applyDimissRoom:isVisible() == true then
        self.applyDimissRoom:setVisible(false)
    end

    -- 隐藏等待界面元素
    local readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
    readyPlayNode:setVisible(false)
    -- 游戏开始后隐藏准备标识
    self:hidePlayersReadySign()
    local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
    readyBtn:setVisible(false)

    -- 显示轮转座位标识
    local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
    turnPosBgSpr:setVisible(true)
    -- 显示游戏中按钮
    local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
    playBtnsNode:setVisible(true)

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
        self:setTurnSeatSign(self:getDisplaySeatIdxByMPos(msgTbl.m_pos))
        self.isPlayerShow = seatIdx == self.playerSeatIdx
    end

    -- 牌局状态,剩余牌
    self.lbl_remainTiles:setString(tostring(msgTbl.m_dCount))

    -- 判断最后四张牌提示
    if msgTbl.m_dCount == 4 then
        self:showSmallToast("最后四张牌")
    end

    -- 庄家座位号
    local bankerSeatIdx = msgTbl.m_zhuang + 1

    self.isBaoJiaoState = false

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

		roomPlayer.isBaoJiaoState = false

        -- 换三张 1是换过的 0是没换的
        roomPlayer.isReplace3CardPlayerDone = false
        if msgTbl.m_bchange then
            roomPlayer.isReplace3CardPlayerDone = msgTbl.m_bchange[seatIdx] == 1
        end

        roomPlayer.hasHuCard = {}
        if msgTbl.m_winCard then
            roomPlayer.hasHuCard = msgTbl.m_winCard[seatIdx]
        end

        if roomPlayer.seatIdx == self.playerSeatIdx then
            self.ownerWin = false
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

        -- if msgTbl.Id == 35 then
        --     --已胡牌
        --     local huMjTilesAry = msgTbl.m_winCard[seatIdx]
        --     if huMjTilesAry and #huMjTilesAry > 0 then
        --         self:addMjTileToPlayer(seatIdx, huMjTilesAry[1], huMjTilesAry[2])
        --     end
        -- end

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

    if self.isPlayThreeCardState then -- 上面已经隐藏了"Image_threecard"换三张节点
        self:onRcvSyncReplaceCardType()
    end

    if self.startMjTileAnimation ~= nil then
        self.startMjTileAnimation:stopAllActions()
        self.startMjTileAnimation:removeFromParent()
        self.startMjTileAnimation = nil
    end

    -- 这里开始验证牌数量是否为13或者14
    self.flushCardNumFlag = true

    if self.outMjtileSignNode then
        self.outMjtileSignNode:setVisible(false)
    end
    self:CheckScore()
    --躺
    -- self.Node_Tang = gt.seekNodeByName(self.rootNode,"Node_Tang")
    -- self.Node_Tang:setVisible(false)

    self:showBaoziAnimation(msgTbl)
end

--检测总分和是否为0
function PlaySceneErRen:CheckScore()
    gt.log("CheckScore is 0")
    local ScoreData = 0
    for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
        ScoreData = ScoreData + roomPlayer.score
    end
    if ScoreData ~= 0 then
        gt.socketClient:reloginServer()
    end
end

function PlaySceneErRen:onRcvWinCard(msgTbl)
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

-- start --
--------------------------------
-- @class function
-- @description 玩家准备手势
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:onRcvReady(msgTbl)
    gt.dump(msgTbl)
    self:updatePlayerInfo()
    local seatIdx = msgTbl.m_pos + 1
    self:playerGetReady(seatIdx)
end

-- start --
--------------------------------
-- @class function
-- @description 玩家在线标识
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:onRcvOffLineState(msgTbl)
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
function PlaySceneErRen:onRcvRoundState(msgTbl)
    -- 牌局状态,剩余牌
    self.Node_roundState:setVisible(true)
    self.lbl_remainRounds:setString(string.format("%d/%d", (msgTbl.m_curCircle + 1), msgTbl.m_curMaxCircle))

    self:onTablePlayState(msgTbl)
end

-- start --
--------------------------------
-- @class function
-- @description 游戏开始
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:onRcvStartGame(msgTbl)

    gt.CopyText(" ")

    self.startGame = true

    self.playMjLayer:removeAllChildren()

    self:onRcvSyncRoomState(msgTbl)
    self:IsSameIp()
    self.fastTouchBugType = true

    --开始游戏  放开语音按钮
    self.yuyinBtn:setVisible(true)
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家出牌
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:onRcvTurnShowMjTile(msgTbl)
    dump(msgTbl)
    gt.log("通知玩家出牌")
    -- 牌局状态,剩余牌
    self.lbl_remainTiles:setString(tostring(msgTbl.m_dCount))

    -- 判断最后四张牌提示
    self.m_dCount = msgTbl.m_dCount
    if msgTbl.m_dCount == 4 then
        self:showSmallToast("最后四张牌")
    end

    local seatIdx = msgTbl.m_pos + 1
    -- 当前出牌座位
    self:setTurnSeatSign(self:getDisplaySeatIdxByMPos(msgTbl.m_pos))

    -- 出牌倒计时
    self:playTimeCDStart(msgTbl.m_time)
    local roomPlayer = self.roomPlayers[seatIdx]

    if seatIdx == self.playerSeatIdx then
        gt.log("self.isPlayerShow = true")
        -- 轮到玩家出牌
        self.isPlayerShow = true

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

		self.isBaojiaoHu = false
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
					self.isBaojiaoHu = true
                    -- 胡
                    -- b_isHu = true
                    local decisionData = {}
                    decisionData.flag = 2
                    -- decisionData.mjColor = msgTbl.m_color
                    -- decisionData.mjNumber = msgTbl.m_number
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
            self.isPlayerDecision = true

            local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
            selfDrawnDcsNode:setVisible(true)

            for _, decisionBtn in ipairs(selfDrawnDcsNode:getChildren()) do
                local nodeName = decisionBtn:getName()
                if nodeName == "Btn_decisionPass" then
                    -- 设置不存在的索引值
                    decisionBtn:setTag(0)
                    gt.addBtnPressedListener(decisionBtn, function()
                        local function passDecision()
                            self.isPlayerDecision = false
							self.isBaojiaoHu = false

                            -- 刚开局
                            if self.isBaoJiaoSelected and self:isBaoJiaoFirstStart(self.m_dCount) then
                                gt.log("===========3=2====")
                                local roomPlayer = self.roomPlayers[self.playerSeatIdx]
                                self:checkOtherTingCards(roomPlayer, msgTbl.m_ting)
							end

                            local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
                            selfDrawnDcsNode:setVisible(false)
                            -- 删除弹出框（杠）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                            -- 删除弹出框（补）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)

                            local msgToSend = {}
                            msgToSend.m_msgId = gt.CG_SHOW_MJTILE
                            msgToSend.m_type = 0
                            msgToSend.m_think = {{1,1}}

                            gt.socketClient:sendMessage(msgToSend)
                        end
                            passDecision()
                            -- self.IsShowTang = false
                    end)
                else
                    decisionBtn:setVisible(false)
                end
            end

            local decisionBtn_pass = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionPass")
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

                -- if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                --     if decisionData.flag == 7 then
                --         decisionData.flag = 3
                --     elseif decisionData.flag == 8 then
                --         decisionData.flag = 4
                --     end
                -- end

                if decisionData.flag == 2 then
                    -- 胡
                    decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionWin")

                    if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                        local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
                        if mjTileSpr then
                            if decisionData.mjColor==0 and decisionData.mjNumber==0 then
                                mjTileSpr:setVisible( false )
                            else
                                mjTileSpr:setSpriteFrame(string.format(gt.SelfMJSprFrameOut, decisionData.mjColor, decisionData.mjNumber))
                            end
                        end
                    end
                    -- 杠的显示优先级为1
                    table.insert(btn_presentList,{1,decisionBtn})
                elseif decisionData.flag == 3 or decisionData.flag == 4 then
                    -- 明暗杠
                    local btn_bar_name = "Btn_decisionBar_1"
                    if self.playType == gt.RoomType.ROOM_SICHUAN then
                        btn_bar_name = "Btn_decisionBar"
                    end
                    decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, btn_bar_name)
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
                    local btn_bar_name = "Btn_decisionBar_1"
                    if self.playType == gt.RoomType.ROOM_SICHUAN then
                        btn_bar_name = "Btn_decisionBar"
                    end
                    decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, btn_bar_name)
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

                            local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
                            selfDrawnDcsNode:setVisible(false)

                            -- 删除弹出框（杠）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                            -- 删除弹出框（补）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)
                            -- 发送消息
                            local btnTag = sender:getTag()
                            local decisionData = decisionTypes[sender:getTag()]
                            local msgToSend = {}
                            msgToSend.m_msgId = gt.CG_SHOW_MJTILE
                            msgToSend.m_type = decisionData.flag
                            msgToSend.m_think = {}
                            -- if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                            --     if msgToSend.m_type == 3 then
                            --         msgToSend.m_type = 7
                            --         elseif msgToSend.m_type == 4 then
                            --         msgToSend.m_type = 8
                            --     end
                            -- end
                            local think_temp = {decisionData.cardList[1].mjColor,decisionData.cardList[1].mjNumber}
                            table.insert(msgToSend.m_think,think_temp)
                            gt.socketClient:sendMessage(msgToSend)

                            if self.playType == gt.RoomType.ROOM_SICHUAN then
                                self.isPlayerShow = false
                            end

                            -- dump(msgToSend)
                            -- dump(decisionData)

                        end)
                    else
                        gt.addBtnPressedListener(decisionBtn, function(sender)
                            -- 删除弹出框（杠）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                            -- 删除弹出框（补）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)
                            -- add new
                            local flimLayer = self:createFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR,cardList_bar)
                            self:addChild(flimLayer,PlaySceneErRen.ZOrder.FLIMLAYER,PlaySceneErRen.TAG.FLIMLAYER_BAR)
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

                        local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
                        selfDrawnDcsNode:setVisible(false)

                        -- 删除弹出框（杠）
                        self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                        -- 删除弹出框（补）
                        self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)

                        -- 发送消息
                        local btnTag = sender:getTag()
                        local decisionData = decisionTypes[sender:getTag()]
                        local msgToSend = {}
                        msgToSend.m_msgId = gt.CG_SHOW_MJTILE
                        msgToSend.m_type = decisionData.flag
                        msgToSend.m_think = {}
                        gt.log("send flag is ... " .. decisionData.flag)
                        -- if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                        --     if msgToSend.m_type == 3 then
                        --         msgToSend.m_type = 7
                        --         elseif msgToSend.m_type == 4 then
                        --         msgToSend.m_type = 8
                        --     end
                        -- end
                        local think_temp = {decisionData.cardList[1].mjColor,decisionData.cardList[1].mjNumber}
                        table.insert(msgToSend.m_think,think_temp)
                        gt.socketClient:sendMessage(msgToSend)
                        end)
                    else
                        gt.addBtnPressedListener(decisionBtn, function(sender)
                            -- 删除弹出框（杠）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                            -- 删除弹出框（补）
                            self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)
                            -- add new
                            local flimLayer = self:createFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU,cardList_bu)
                            self:addChild(flimLayer,PlaySceneErRen.ZOrder.FLIMLAYER,PlaySceneErRen.TAG.FLIMLAYER_BU)
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

                        local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
                        selfDrawnDcsNode:setVisible(false)

                        -- 删除弹出框（杠）
                        self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                        -- 删除弹出框（补）
                        self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)

                        -- 发送消息
                        local btnTag = sender:getTag()
                        local decisionData = decisionTypes[sender:getTag()]
                        local msgToSend = {}
                        msgToSend.m_msgId = gt.CG_SHOW_MJTILE
                        msgToSend.m_type = decisionData.flag
                        msgToSend.m_think = {}
                        if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                            if msgToSend.m_type == 3 then
                                msgToSend.m_type = 7
                                elseif msgToSend.m_type == 4 then
                                msgToSend.m_type = 8
                            end
                        end
                        local think_temp = {decisionData.mjColor,decisionData.mjNumber}
                        if decisionData.mjColor~=0 or decisionData.mjNumber~=0 then
                            table.insert(msgToSend.m_think,think_temp)
                            gt.log("insert think_temp to m_think")
                        end
                        gt.socketClient:sendMessage(msgToSend)
                        gt.log("进入胡按钮回调")
                        dump(msgToSend)
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

        dump({self.isBaoJiaoState, self.m_dCount, self.mjCount})
        if self.hasBaoJiao then
            if self.isBaoJiaoState and self:isBaoJiaoFirstStart(self.m_dCount) then
                if not self.isBaojiaoHu then
                    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
                    self:checkOtherTingCards(roomPlayer, msgTbl.m_ting)
                end
            elseif self.isBaoJiaoState and (not self:isBaoJiaoFirstStart(self.m_dCount)) then
                self:setAllMaskLayer(true)
            else
                self:setAllMaskLayer(false)
            end
        end
    else
        gt.log("self.isPlayerShow = false")
        self.isPlayerShow = false

        -- 摸牌
        if msgTbl.m_flag == 0 then
            local mjTilesReferPos = roomPlayer.mjTilesReferPos
            local mjTilePos = mjTilesReferPos.holdStart
            mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
            roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount + 1
            local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
            vv:setVisible(true)

            local _offsetMap = {
                {x= 0,   y= 30  },
                {x= -15, y= 0   },
                {x= 0,   y= -40 }
            }

            vv:setPosition(cc.pAdd(mjTilePos, _offsetMap[roomPlayer.displaySeatIdx]))
        end
    end
    --显示玩家自己的手牌
    local playerOwner = self.roomPlayers[self.playerSeatIdx]
    for i, mjTile in ipairs(playerOwner.holdMjTiles) do
        mjTile.mjTileSpr:setVisible(true)
    end
end

function PlaySceneErRen:createMaskLayer(opacity)
    if not opacity then
        -- 用默认透明度
        opacity = gt.MASK_LAYER_OPACITY
    end
    local ownSize = gt.seekNodeByName(self.rootNode, "mahjong_table"):getContentSize()
    local maskLayer = cc.LayerColor:create(cc.c4b(85, 85, 85, opacity), ownSize.width, ownSize.height)
    -- maskLayer:setAnchorPoint(cc.p(0.5,0))
    maskLayer:setScale(2)
    local function onTouchBegan(touch, event)
        return true
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = maskLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, maskLayer)

    return maskLayer
end

function PlaySceneErRen:BtnTangCallBack(m_mjdata)
    if self.m_tang == nil then return end
    if m_mjdata == nil then return end
    gt.log("进入躺决策按钮回调")
    --添加不能触摸层
    self.MaskLayer = self:createMaskLayer()
    gt.pushLayer(self.MaskLayer,false,self.rootNode,111)

    --点完躺决策之后出现的返回按钮
    local Btn_decision_return = gt.seekNodeByName(self.rootNode, "Btn_decision_return")
    Btn_decision_return:setVisible(false)
    local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
    selfDrawnDcsNode:setVisible(false)
    local Node_Tang = gt.seekNodeByName(self.rootNode, "Node_Tang")
    Node_Tang:setZOrder(112)
    Node_Tang:setVisible(true)
    --躺牌背景
    local tangbg = gt.seekNodeByName(Node_Tang, "Img_bg")
    tangbg:setContentSize(cc.size(#self.mjTangTable*70,tangbg:getContentSize().height))
    if tangbg:isVisible() then
        gt.log("tangbg is show!!!")
        gt.log("tangbg is position = "..tangbg:getPositionX()..tangbg:getPositionY())
    else
        gt.log("tangbg is not show!!!")
    end
    local setPos = cc.p(70,tangbg:getContentSize().height*0.5) -- 躺牌起始坐标
    if #self.mjTangTable== 1 then
        tangbg:setContentSize(cc.size(280,tangbg:getContentSize().height))
        setPos = cc.p(tangbg:getContentSize().width*0.5,tangbg:getContentSize().height*0.5)
    elseif #self.mjTangTable == 2 then
        tangbg:setContentSize(cc.size(280,tangbg:getContentSize().height))
        setPos = cc.p(tangbg:getContentSize().width*0.4,tangbg:getContentSize().height*0.5)
    end
    --可选的躺牌
    for i,m_data in ipairs(self.mjTangTable) do
        local mjTileName = string.format(gt.SelfMJSprFrame, m_data.mjColor, m_data.mjNumber)
        local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
        mjTileSpr:setPosition(setPos)
        mjTileSpr:setScale(0.6)
        tangbg:addChild(mjTileSpr)
        setPos = cc.pAdd(setPos, cc.p(60,0))
    end
    --返回按钮
    local Btn_return = gt.seekNodeByName(Node_Tang, "Btn_return")
    Btn_return:setPositionX(0)
    gt.addBtnPressedListener(Btn_return,function (sender)
        gt.popLayer()
        self.isTouchBegan = false
        sender:getParent():getParent():setVisible(false)
        --点完躺决策之后出现的返回按钮
        local Btn_decision_return = gt.seekNodeByName(self.rootNode, "Btn_decision_return")
        Btn_decision_return:setVisible(true)
        selfDrawnDcsNode:setVisible(false)
    end)
    --确定按钮
    local Btn_sure = gt.seekNodeByName(Node_Tang, "Btn_sure")
    Btn_sure:setPositionX(tangbg:getContentSize().width)
    gt.addBtnPressedListener(Btn_sure,function (sender)
        gt.popLayer()
        self.isTouchBegan = false
        sender:getParent():getParent():setVisible(false)
        local msgToSend = {}
        msgToSend.m_msgId = gt.CG_TANG_CARD
        msgToSend.m_pos = self.playerSeatIdx
        msgToSend.m_cardValue = {}
        msgToSend.m_outCard = {}
        gt.socketClient:sendMessage(msgToSend)
    end)
end

function  PlaySceneErRen:updatePlayerInfo()
    for i = 1, 4 do
        local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)


        local scoreLabel = gt.seekNodeByName(playerInfoNode, "Label_score")
        for j = 1 , 4  do
            if self.roomPlayers[j] and self.roomPlayers[j].displaySeatIdx == i then

                dump(self.roomPlayers)
                if self.roomPlayers ~= nil and self.roomPlayers[j] ~= nil then
                    local roomPlayer = self.roomPlayers[j]
                    if roomPlayer.score ~= nil then
                        scoreLabel:setString(tostring(roomPlayer.score))
                    end
                end

            end
        end

    end
end

-- start --
--------------------------------
-- @class function
-- @description 广播玩家出牌
-- end --
function PlaySceneErRen:onRcvSyncShowMjTile(msgTbl)

    gt.log("广播玩家出牌")
    dump(msgTbl)

    -- if self:checkRightCradNum() == false then
    --     gt.socketClient:reloginServer()
    -- return

    if msgTbl.m_errorCode ~= 0 then
        gt.socketClient:reloginServer()
        return
    end

    -- gt.log("定缺的牌的数量："..#self.mjMarkTable)
    -- 去掉遮罩层
    if #self.mjMarkTable ~= 0 then
        for _, mjTile in ipairs(self.mjMarkTable) do
            -- gt.log("定缺的牌："..mjTile.mjColor..mjTile.mjNumber)
            if mjTile.mjTileSpr then
                mjTile.mjTileSpr:setColor(cc.c3b(255,255,255))
            end
        end
    end

    -- 座位号（1，2，3，4）
    local seatIdx = msgTbl.m_pos + 1
    local roomPlayer = self.roomPlayers[seatIdx]
    if msgTbl.m_type == 2 then
        -- 自摸胡
        self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.SELF_DRAWN_WIN, msgTbl.m_hu)

        if msgTbl.m_rewardCardNum and tonumber(msgTbl.m_rewardCardNum) > 0 then
            self:showFangjianYuAnimation(msgTbl, seatIdx)
        end

        self:showHuPaiType(seatIdx,msgTbl.m_color, msgTbl.m_number,true,false)

    elseif msgTbl.m_type == 9 then
        -- 胡
        self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.TAKE_CANNON_WIN, msgTbl.m_hu)

        if msgTbl.m_rewardCardNum and  tonumber(msgTbl.m_rewardCardNum) > 0 then
            self:showFangjianYuAnimation(msgTbl, seatIdx)
        end

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
            -- 添加牌放在末尾
            self.isPlayerShow = false
        else
            -- 显示出的牌
            self:addAlreadyOutMjTiles(seatIdx, mj_color, mj_number)
            -- 显示出的牌箭头标识
            self:showOutMjtileSign(seatIdx)
            self:outPaiBigAnimate(seatIdx,mj_color,mj_number,1)
            gt.soundManager:PlayCardSound(roomPlayer.sex, mj_color, mj_number)
        end
        roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
        roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1

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
            self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.DARK_BAR)
        end
    elseif msgTbl.m_type == 7 then
        -- 暗补
        gt.log("     暗补     ")
        if (next(msgTbl.m_think) ~= nil) then
            local  mj_color = msgTbl.m_think[1][1]
            local  mj_number = msgTbl.m_think[1][2]
            self:addMjTileBar(seatIdx, mj_color, mj_number, false)
            self:hideOtherPlayerMjTiles(seatIdx, true, false)
            self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.DARK_BU)
        end
    elseif msgTbl.m_type == 4 then
        -- 碰转明杠
        gt.log("     碰转明杠     ")
        if (next(msgTbl.m_think) ~= nil) then
            local  mj_color = msgTbl.m_think[1][1]
            local  mj_number = msgTbl.m_think[1][2]
            self:changePungToBrightBar(seatIdx, mj_color, mj_number)
            self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.BRIGHT_BAR)
        end
    elseif msgTbl.m_type == 8 then
        -- 明补
        gt.log("     明补     ")
        if (next(msgTbl.m_think) ~= nil) then
            local  mj_color = msgTbl.m_think[1][1]
            local  mj_number = msgTbl.m_think[1][2]
            self:changePungToBrightBar(seatIdx, mj_color, mj_number)
            self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.BRIGHT_BU)
        end
    end

    --显示玩家自己的手牌
    local playerOwner = self.roomPlayers[self.playerSeatIdx]
    for i, mjTile in ipairs(playerOwner.holdMjTiles) do
        mjTile.mjTileSpr:setVisible(true)
    end

end

-- start --
--------------------------------
-- @class function
-- @description 服务器广播玩家起手胡牌
-- end --
function PlaySceneErRen:onRcvSyncStartDecision(msgTbl)
    local seatIdx = msgTbl.m_pos + 1
    if msgTbl.m_type == 1 then
        -- 缺一色
        self:showStartDecisionAnimation(seatIdx, gt.StartDecisionType.TYPE_QUEYISE, msgTbl.m_card)
    elseif msgTbl.m_type == 2 then
        -- 板板胡
        self:showStartDecisionAnimation(seatIdx, gt.StartDecisionType.TYPE_BANBANHU, msgTbl.m_card)
    elseif msgTbl.m_type == 3 then
        -- 大四喜
        self:showStartDecisionAnimation(seatIdx, gt.StartDecisionType.TYPE_DASIXI, msgTbl.m_card)
    elseif msgTbl.m_type == 4 then
        -- 六六顺
        self:showStartDecisionAnimation(seatIdx, gt.StartDecisionType.TYPE_LIULIUSHUN, msgTbl.m_card)
    end
end

-- start --
--------------------------------
-- @class function
-- @description 广播玩家杠2张牌
-- end --
function PlaySceneErRen:onRcvSyncBarTwoCard(msgTbl)
    -- set test data
    -- auto yang
    -- msgTbl = {}
    -- msgTbl.m_msgId = 68
    -- msgTbl.m_pos = 0
    -- msgTbl.flag = 0
    -- msgTbl.m_card = {}
    -- table.insert(msgTbl.m_card,{1,1})
    -- table.insert(msgTbl.m_card,{1,2})

    local seatIdx = msgTbl.m_pos + 1
    -- 是否自摸（0:没有 1：自摸）
    local flag = msgTbl.m_flag
    -- 如果胡了则不需要展示
    if flag == 1 then
        return
    end
    -- 显示杠后两张牌
    self:showBarTwoCardAnimation(seatIdx,msgTbl.m_card)
end

-- start --
--------------------------------
-- @class function
-- @description 展示杠两张牌
-- end --
function PlaySceneErRen:showBarTwoCardAnimation(seatIdx,cardList)
    local roomPlayer = self.roomPlayers[seatIdx]

    local mjTileName = string.format(gt.SelfMJSprFrameOut, 2, 2)
    local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
    local width_oneMJ = mjTileSpr:getContentSize().width
    local width = 30+mjTileSpr:getContentSize().width*(#cardList)
    local height = 24+mjTileSpr:getContentSize().height
    -- 添加半透明底
    local image_bg = ccui.ImageView:create()
    image_bg:loadTexture("images/otherImages/laoyue_bg.png")
    image_bg:setScale9Enabled(true)
    image_bg:setCapInsets(cc.rect(10,10,1,1))
    image_bg:setContentSize(cc.size(width,height))
    image_bg:setAnchorPoint(cc.p(0.5,0.5))
    self:addChild(image_bg,PlaySceneErRen.ZOrder.HAIDILAOYUE)
    image_bg:setScale(0)
    -- 设置坐标位置
    local  m_curPos_x = 1
    local  m_curPos_y = 1
    if roomPlayer.displaySeatIdx == 1 or roomPlayer.displaySeatIdx == 3 then
        m_curPos_x = roomPlayer.mjTilesReferPos.holdStart.x
        m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
    elseif roomPlayer.displaySeatIdx == 2 or roomPlayer.displaySeatIdx == 4 then
        m_curPos_x = roomPlayer.mjTilesReferPos.showMjTilePos.x
        m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
    end

    image_bg:setPosition(cc.p(m_curPos_x,m_curPos_y))

    -- 添加两个麻将
    for _,v in pairs(cardList) do
        local mjSprName = string.format(gt.SelfMJSprFrameOut, v[1], v[2])
        local image_mj = ccui.Button:create()
        image_mj:loadTextures(mjSprName,mjSprName,"",ccui.TextureResType.plistType)
        image_mj:setAnchorPoint(cc.p(0,0))
        image_mj:setPosition(cc.p(15+width_oneMJ*(_-1), 10))
           image_bg:addChild(image_mj)
    end

    -- 播放动画
    local scaleToAction = cc.ScaleTo:create(0.2, 1)
    local easeBackAction = cc.EaseBackOut:create(scaleToAction)
    local present_delayTime = cc.DelayTime:create(1.5)
    local fadeOutAction = cc.FadeOut:create(0.5)
    local callFunc_dontPresent = cc.CallFunc:create(function(sender)
        -- 播放完后隐藏
        sender:setVisible(false)
    end)
    local callFunc_present_first = cc.CallFunc:create(function(sender)
        -- 打出第一张牌
        gt.log("打出第一张牌")
        for idx,data in pairs(cardList) do
            if 1 == idx then
                   self:discardsOneCard(seatIdx,data[1], data[2])
                   break
               end
        end
    end)
    local delayTime_f_s = cc.DelayTime:create(0.7)
    local callFunc_present_second = cc.CallFunc:create(function(sender)
        -- 打出第二张牌
        gt.log("打出第二张牌")
        for idx,data in pairs(cardList) do
            if 2 == idx then
                   self:discardsOneCard(seatIdx,data[1], data[2])
                   break
               end
        end
    end)
    local callFunc_remove = cc.CallFunc:create(function(sender)
        -- 播放完后移除
        sender:removeFromParent()
    end)
    local seqAction = cc.Sequence:create(easeBackAction, present_delayTime, fadeOutAction, callFunc_dontPresent,
        callFunc_present_first, delayTime_f_s, callFunc_present_second,callFunc_remove)
    image_bg:runAction(seqAction)

end

function PlaySceneErRen:discardsOneCard(seatIdx,mjColor,mjNumber)
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
-- @description 显示玩家开局胡牌动画,比如 1-缺一色 2-板板胡 3-大四喜 4-六六顺
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlaySceneErRen:showStartDecisionAnimation(seatIdx, decisionType, showCard)
    -- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
    local decisionSuffixs = {1, 4, 2, 2, 3}
    local decisionSfx = {"queyise", "banbanhu", "sixi", "liuliushun"}
    -- 显示决策标识
    local roomPlayer = self.roomPlayers[seatIdx]
    local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("tile_cs_%s.png", decisionSfx[decisionType]))
    decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
    self.rootNode:addChild(decisionSignSpr, PlaySceneErRen.ZOrder.DECISION_SHOW)
    -- 标识显示动画
    decisionSignSpr:setScale(0)
    local scaleToAction = cc.ScaleTo:create(0.2, 1)
    local easeBackAction = cc.EaseBackOut:create(scaleToAction)
    local fadeOutAction = cc.FadeOut:create(0.5)
    local callFunc = cc.CallFunc:create(function(sender)
        -- 播放完后移除
        sender:removeFromParent()
    end)
    local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
    decisionSignSpr:runAction(seqAction)

    -- 展示起手胡牌型
    local copyNum = 1
    if decisionType == gt.StartDecisionType.TYPE_QUEYISE then
        copyNum = 1
    elseif decisionType == gt.StartDecisionType.TYPE_BANBANHU then
        copyNum = 1
    elseif decisionType == gt.StartDecisionType.TYPE_DASIXI then
        copyNum = 4
    elseif decisionType == gt.StartDecisionType.TYPE_LIULIUSHUN then
        copyNum = 3
    end

    local groupNode = cc.Node:create()
    groupNode:setCascadeOpacityEnabled( true )
    groupNode:setPosition( roomPlayer.mjTilesReferPos.showMjTilePos )
    self.playMjLayer:addChild(groupNode)

    local mjTilesReferPos = roomPlayer.mjTilesReferPos

    -- dump( showCard )
    local demoSpr = cc.Sprite:createWithSpriteFrameName( string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, 1, 1) )
    local tileWidthX = 0
    local tileWidthY = 0
    if roomPlayer.displaySeatIdx == 1 then
        tileWidthX = 0
        tileWidthY = mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
    elseif roomPlayer.displaySeatIdx == 2 then
        tileWidthX = -demoSpr:getContentSize().width
        tileWidthY = 0
    elseif roomPlayer.displaySeatIdx == 3 then
        tileWidthX = 0
        tileWidthY = -mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
    elseif roomPlayer.displaySeatIdx == 4 then
        tileWidthX = demoSpr:getContentSize().width
        tileWidthY = 0
    end

    -- 服务器返回消息
    local totalWidthX = (#showCard)*tileWidthX
    local totalWidthY = (#showCard)*tileWidthY
    for i,v in ipairs(showCard) do
        local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displaySeatIdx, v[1], v[2])
        local mjTileSpr = cc.Sprite:createWithSpriteFrameName( mjTileName )
        mjTileSpr:setPosition( cc.p(tileWidthX*(i-1),tileWidthY*(i-1)) )
        groupNode:addChild( mjTileSpr, (gt.winSize.height - mjTileSpr:getPositionY()) )
    end
    groupNode:setPosition( cc.pAdd( roomPlayer.mjTilesReferPos.showMjTilePos, cc.p(-totalWidthX/2,-totalWidthY/2) ) )

    -- 显示3s,渐隐消失
    local delayTime = cc.DelayTime:create(3)
    local fadeOutAction = cc.FadeOut:create(2)
    local callFunc = cc.CallFunc:create(function(sender)
        sender:removeFromParent()
    end)
    groupNode:runAction(cc.Sequence:create(delayTime, fadeOutAction, callFunc))

    -- dj revise
    gt.soundManager:PlaySpeakSound(roomPlayer.sex, decisionSfx[decisionType])
end

function PlaySceneErRen:createStartDecisionFlimLayer(flimLayerType,cardList, posx, posy)
    -- 如果已经存在了显示层,那么看是否已经是相同类型
    if self.m_startFlimLayer then
        if self.m_startFlimLayer.flimLayerType == flimLayerType then
            return
        else
            self.m_startFlimLayer:removeFromParent()
            self.m_startFlimLayer = nil
        end
    end

    -- 一个麻将
    local mjTileName = string.format(gt.SelfMJSprFrameOut, 2, 2)
    local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
    local width_oneMJ = mjTileSpr:getContentSize().width

    local space_gang = 20
    local width = 60+mjTileSpr:getContentSize().width*4*(#cardList)+space_gang*(#cardList-1)
    local height = 50+mjTileSpr:getContentSize().height

    local flimLayer = cc.LayerColor:create(cc.c4b(85, 85, 85, 0), width, height)
    flimLayer:setContentSize(cc.size(width,height))

    -- 添加半透明底
    local image_bg = ccui.ImageView:create()
    image_bg:loadTexture("images/otherImages/laoyue_bg.png")
    image_bg:setScale9Enabled(true)
    image_bg:setCapInsets(cc.rect(10,10,1,1))
    image_bg:setContentSize(cc.size(width-20,height))
    image_bg:setAnchorPoint(cc.p(0,0))
    flimLayer:addChild(image_bg)

    local cardNum = 3 -- 一组有几个麻将要显示
    if flimLayerType == 3 then -- 四喜
        cardNum = 4
    elseif flimLayerType == 4 then -- 六六顺
        cardNum = 3
    end

    table.sort(cardList,function(a, b)
        return a[2] < b[2]
    end)

    -- 记录所有的显示的牌
    self.allStartButton = {}

    -- 创建麻将
    for idx,value in ipairs(cardList) do
        local mjColor = value[1]
        local mjNumber = value[2]

        local mjSprName = string.format(gt.SelfMJSprFrameOut, mjColor, mjNumber)
        for i=1,cardNum do
            local button = ccui.Button:create()
            table.insert( self.allStartButton, button )
            button:loadTextures(mjSprName,mjSprName,"",ccui.TextureResType.plistType)
            button:setTouchEnabled(true)
            button:setAnchorPoint(cc.p(0,0))
            button:setPosition(cc.p(30+space_gang*(idx-1)+width_oneMJ*(i-1)+width_oneMJ*4*(idx-1), 20))
               button:setTag( flimLayerType )
               button.myDate = value
               button.myIndex = cardNum + (idx-1)*cardNum
               flimLayer:addChild(button)

            local function touchEvent(ref, type)
                   if type == ccui.TouchEventType.ended then
                    if ref:getTag() == 4 then -- 六六顺,需要选择两组才可以出牌
                        if self.startDecisionTypeLiuliushun then
                            if ref.isChoose == true then -- 如果已经选择了,那么显示回去颜色
                                local curIndex = math.floor((ref.myIndex-1) / 3)
                                for k=1,3 do
                                    self.allStartButton[curIndex*3+k].isChoose = false
                                    self.allStartButton[curIndex*3+k]:setColor( cc.c3b(255,255,255) )
                                end

                                local detTab = {} -- 没被点击的
                                for i,v in ipairs(self.startDecisionTypeLiuliushun) do
                                    if v[1] == ref.myDate[1] and v[2] == ref.myDate[2] then
                                        -- ...
                                    else
                                        table.insert( detTab, v )
                                    end
                                end
                                self.startDecisionTypeLiuliushun = detTab
                            else
                                local curIndex = math.floor((ref.myIndex-1) / 3)
                                for k=1,3 do
                                    self.allStartButton[curIndex*3+k].isChoose = true
                                    self.allStartButton[curIndex*3+k]:setColor( cc.c3b(255,0,0) )
                                end
                                table.insert( self.startDecisionTypeLiuliushun, ref.myDate )

                                if #self.startDecisionTypeLiuliushun == 2 then -- 需要给服务器发送消息
                                    self:onSendMSg66( 4, self.startDecisionTypeLiuliushun )
                                    self.startDecisionTypeLiuliushun = nil
                                end
                            end
                        else
                            self.startDecisionTypeLiuliushun = {}
                            local curIndex = math.floor((ref.myIndex-1) / 3)
                            for k=1,3 do
                                self.allStartButton[curIndex*3+k].isChoose = true
                                self.allStartButton[curIndex*3+k]:setColor( cc.c3b(255,0,0) )
                            end
                            table.insert( self.startDecisionTypeLiuliushun, ref.myDate )
                        end
                    elseif ref:getTag() == 3 then -- 四喜
                        self:onSendMSg66( 3, {ref.myDate} )
                    end
                    end
                end
                button:addTouchEventListener(touchEvent)
        end
    end

    self:addChild(flimLayer,PlaySceneErRen.ZOrder.FLIMLAYER,PlaySceneErRen.TAG.FLIMLAYER_BAR)
    flimLayer:ignoreAnchorPointForPosition(false)
    flimLayer:setAnchorPoint(0.5,0)
    local pos_x = 0
    if posx+flimLayer:getContentSize().width/2 > gt.winSize.width then
        flimLayer:setPositionX(gt.winSize.width-flimLayer:getContentSize().width/2)
    elseif posx-flimLayer:getContentSize().width/2 < 0 then
        flimLayer:setPositionX(flimLayer:getContentSize().width/2)
    else
        flimLayer:setPositionX(posx)
    end
    flimLayer:setPositionY(posy+flimLayer:getContentSize().height/2)

    self.m_startFlimLayer = flimLayer
    self.m_startFlimLayer.flimLayerType = flimLayerType -- 3四喜,4六六顺

end

function PlaySceneErRen:onSendMSg66( cartType, cardarray )
    self.isPlayerDecision = false
    -- 隐藏决策按键
    -- local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_start_decisionBtn")
    -- decisionBtnNode:setVisible(false)
    -- 隐藏第二层
    if self.m_startFlimLayer then
        self.m_startFlimLayer:removeFromParent()
        self.m_startFlimLayer = nil
    end

    local msgToSend = {}
    msgToSend.m_msgId = gt.CG_START_PLAYER_DECISION
    msgToSend.m_type = cartType
    msgToSend.m_card = cardarray
    -- dump( msgToSend )
    gt.socketClient:sendMessage(msgToSend)
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家决策
-- end --
function PlaySceneErRen:onRcvMakeDecision(msgTbl)
--msgTbl.m_think = {{6, {{3,4},{3,5}}}}
--msgTbl.m_think = {{6, {{3,4},{3,5}}}, {6, {{3,7}, {3,8}}}  }
--msgTbl.m_think = {{6, {{3,4},{3,5}}}, {6, {{3,7}, {3,8}}}, {6, {{3,5},{3,7}}}   }
    dump(msgTbl)
    gt.log("通知玩家决策")
    --显示玩家自己的手牌
    local playerOwner = self.roomPlayers[self.playerSeatIdx]
    for i, mjTile in ipairs(playerOwner.holdMjTiles) do
        mjTile.mjTileSpr:setVisible(true)
    end

    self.isShowEat = false

    if msgTbl.m_flag == 1 then
        -- 玩家决策
        self.isPlayerDecision = true

        -- 决策倒计时
        self:playTimeCDStart(msgTbl.m_time)


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
        local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn") --显示所有的按键决策
        decisionBtnNode:setVisible(true)

        for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
            decisionBtn:setVisible(false)
        end
        local Btn_decision_0 = gt.seekNodeByName(decisionBtnNode, "Btn_decision_0")
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
        -- dump(noSame)
        for i, v in ipairs(noSame) do
            -- v[1]: 1-出牌 2-胡，3-暗杠 4-明杠，5-碰，6-吃，7-暗补、8-明补
            --m_type: 1-胡 2-杠 3-碰 4-吃 5-补 6-抢杠
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
            -- if self.playType ~= gt.RoomType.ROOM_SICHUAN and m_type == 5 then
            --     m_type = 2
            -- end

            gt.log("Btn_decision_" .. m_type .. " is show")
            local decisionBtn = gt.seekNodeByName(decisionBtnNode, "Btn_decision_" .. m_type)
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
            if self.playType == gt.RoomType.ROOM_SICHUAN and (m_type == 1 or m_type == 6) then
                mjTileSpr:setVisible(false)
            end

            -- 响应决策按键事件
            gt.addBtnPressedListener(decisionBtn, function(sender)
                local function makeDecision(decisionType, m_type)
                    self.isPlayerDecision = false
                    self.isShowEat = false

                    -- 隐藏决策按键
                    local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
                    decisionBtnNode:setVisible(false)
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
                        local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
                        decisionBtnNode:setVisible(false)

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
                            local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
                            decisionBtnNode:setVisible(false)
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
function PlaySceneErRen:onRcvSyncMakeDecision(msgTbl)

    dump(msgTbl)

    if msgTbl.m_errorCode ~= 0 then
        return
    end

    -- 广安玩法支持碰杠胡，不需要在其他玩家决策时剔除非胡按钮 隐藏决策按键
    -- local decision_str = ""
    -- local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
    -- if decisionBtnNode:isVisible() == true then
    --     local isCanHuFlag = false
    --     for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
    --         if  decisionBtn:getName() == "Btn_decision_1" or decisionBtn:getName() == "Btn_decision_6"  then
    --             if decisionBtn:isVisible() == true then
    --                 decision_str = tostring(decisionBtn:getName())
    --                 isCanHuFlag = true
    --                 break
    --             end
    --
    --         end
    --     end
    --
    --     if isCanHuFlag == true then -- 有胡
    --         for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
    --              if decisionBtn:getName() == "Btn_decision_0" or tostring(decisionBtn:getName()) == decision_str then
    --                 decisionBtn:setVisible(true)
    --             else
    --                 decisionBtn:setVisible(false)
    --             end
    --         end
    --     end
    --
    --     -- if isCanHuFlag == false then
    --         -- self.isPlayerDecision = false
    --         -- decisionBtnNode:setVisible( false )
    --     -- end
    -- end
    --
    if msgTbl.m_think ~= 0 then -- 吃,碰,杠,胡
        if self.startMjTileAnimation ~= nil then
            self.startMjTileAnimation:stopAllActions()
            self.startMjTileAnimation:removeFromParent()
            self.startMjTileAnimation = nil
            self:addAlreadyOutMjTiles(self.preShowSeatIdx, self.startMjTileColor, self.startMjTileNumber, true)
        end
    end

    local seatIdx = msgTbl.m_pos + 1

    if msgTbl.m_think[1] == 2 or msgTbl.m_think[1] == 10 then
        -- 接炮胡m_hu
        if msgTbl.m_think[1] == 2 then
            self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.TAKE_CANNON_WIN, msgTbl.m_hu)
        else
            self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.QIANG_GANG, msgTbl.m_hu)
            if #self.mjMarkTable ~= 0 then
                for _, mjTile in ipairs(self.mjMarkTable) do
                    if mjTile.mjTileSpr then
                        mjTile.mjTileSpr:setColor(cc.c3b(255,255,255))
                    end
                end
                self.mjMarkTable = {}
            end
        end

        if msgTbl.m_rewardCardNum and tonumber(msgTbl.m_rewardCardNum) > 0 then
            self:showFangjianYuAnimation(msgTbl, seatIdx)
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
        self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.BRIGHT_BAR)

        -- 隐藏持有牌中打出的牌
        self:hideOtherPlayerMjTiles(seatIdx, true, true)

        -- 移除上家打出的牌
        self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)

    elseif msgTbl.m_think[1] == 5 then
        -- 碰牌
        self:addMjTilePung(seatIdx, msgTbl.m_color, msgTbl.m_number)
        -- 碰牌动画
        self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.PUNG)

        -- 隐藏持有牌中打出的牌
        self:hideOtherPlayerMjTiles(seatIdx, false)
        -- 移除上家打出的牌
        self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
    elseif msgTbl.m_think[1] == 6 then
        local eatGroup = {}
        table.insert(eatGroup,{msgTbl.m_think[2][1][2], 0, msgTbl.m_color})
        table.insert(eatGroup,{msgTbl.m_number, 1, msgTbl.m_color})
        table.insert(eatGroup,{msgTbl.m_think[2][2][2], 0, msgTbl.m_color})
        --table.sort(eatGroup, function(a, b)
            --return a[1] < b[1]
        --end)

        -- 吃牌
        local roomPlayer = self.roomPlayers[seatIdx]
        table.insert(roomPlayer.mjTileEat, eatGroup)

        self:pungBarReorderMjTiles(seatIdx, msgTbl.m_color, eatGroup)
        -- 碰牌动画
        self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.EAT)

        -- 隐藏持有牌中打出的牌
        self:hideOtherPlayerMjTiles(seatIdx, false)
        -- 移除上家打出的牌
        self:removePreRoomPlayerOutMjTile()

    elseif msgTbl.m_think[1] == 7 or msgTbl.m_think[1] == 8 then

        self:addMjTileBu(seatIdx, msgTbl.m_color, msgTbl.m_number, true)
        -- 杠牌动画
        self:showDecisionAnimation(seatIdx, PlaySceneErRen.DecisionType.BRIGHT_BAR)

        -- 隐藏持有牌中打出的牌
        self:hideOtherPlayerMjTiles(seatIdx, true, true)
        -- 移除上家打出的牌
        self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
    end

    self:checkMjTile()


    local playerOwner = self.roomPlayers[self.playerSeatIdx]
    for i, mjTile in ipairs(playerOwner.holdMjTiles) do
        mjTile.mjTileSpr:setVisible(true)
    end

end

function PlaySceneErRen:onRcvChatMsg(msgTbl)
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

        bridge.playVoice(curUrl)

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

--单局结束
function PlaySceneErRen:onRcvRoundReport(msgTbl)
    gt.log("00000---")
    gt.dump(msgTbl)
    self.roundReportMsg = nil
    self.curRoomPlayers = self:copyTab(self.roomPlayers)
    for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
        if self.playerSeatIdx == seatIdx then
            local m_rewardCardNum = msgTbl.m_rewardCardNum[seatIdx]
            if tonumber(m_rewardCardNum) > 0 then
                gt.log("-------fg-g--------")
                self.roundReportMsg = msgTbl
                if not self.isAnimation then
                    gt.log("----1--11---")
                    if not self.isShowPaiType then
                        self.isShowPaiType = true
                        self:showPaiType(self.roundReportMsg, seatIdx)
                        self:showRoundReport(self.roundReportMsg)
                    end
                end
            end
        end
    end

    if not self.roundReportMsg then
        gt.log("====55===555===")
        if not self.isShowPaiType then
            self.isShowPaiType = true
            self:showRoundReport(msgTbl)
        end
    end
end

--显示单局结算
function PlaySceneErRen:showRoundReport(msgTbl)
	self.isBaoJiaoSelected = false
	self.isBaoJiaoState = false

    --删除聊天框
    if self:getChildByTag(101) then
        self:getChildByTag(101):removeFromParent()
    end
    --删除设置
    if self:getChildByTag(102) then
        self:getChildByTag(102):removeFromParent()
    end
    gt.log("onRcvRoundReport ........... ")
    -- dump(msgTbl)

    --local curRoomPlayers = {}
    --curRoomPlayers = self:copyTab(self.roomPlayers)
    local allDelayTimy = self.reportDelayTime -- 需要延迟的时间,如果存在海底牌,需要将海底牌展示结束方可
    if self.haveHaidiPai then
        allDelayTimy = allDelayTimy + self.haidCardShowTime
    end
    local delayTime = cc.DelayTime:create(allDelayTimy)
    local callFunc = cc.CallFunc:create(function(sender)
        -- 显示准备按钮
        local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
        readyBtn:setVisible(true)

        -- 停止未完成动作
        if self.startMjTileAnimation ~= nil then
            self.startMjTileAnimation:stopAllActions()
            self.startMjTileAnimation:removeFromParent()
            self.startMjTileAnimation = nil
        end

        -- 停止倒计时音效
        self.playTimeCD = nil

        -- 移除所有麻将
        self.playMjLayer:removeAllChildren()

        -- 是否是胡牌状态 false表示没有胡牌
        self.ownerWin = false

        -- 定缺的标志
        self.dingqueTypeTable = {}

        -- 定缺的状态 false 没有定缺
        self.dingqueColorState = false
        self.hasDingquePlay = false -- 是否有定缺玩法

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

        self.Node_ReplaceThreeCard:setVisible(false)
        self.isReplace3CardAllPlayerDone = false
        self.replace3CardDoneUsers = {}

        -- 用户选择的三张牌
        self.replaceThreeCardTable = {}

        -- 自己换三张后锁定状态
        self.ownerReplaceCardType = false
        self.ownerSendReplaceCardMsg = false

        -- 限制发牌之前  手速过快点击 闪退bug
        self.fastTouchBugType = false

        -- 是否支持换三张
        self.isPlayThreeCardState = false

        self.startGame = true

        --是否有单局结算信息
        self.roundReportMsg = nil

        self.isShowPaiType = false

        -- 玩家准备手势隐藏
        self:hidePlayersReadySign()

        -- 隐藏座次标识
        local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
        turnPosBgSpr:setVisible(false)

        -- 隐藏牌局状态
        self.Node_roundState:setVisible(false)

        -- 隐藏倒计时
        self.lbl_playTimeCD:setVisible(false)

        -- 隐藏出牌标识
        self.outMjtileSignNode:setVisible(false)

        self.spr_baozi:setVisible(false)

        -- 隐藏决策
        local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
        decisionBtnNode:setVisible(false)

        local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
        selfDrawnDcsNode:setVisible(false)

        -- 隐藏胡牌标记
        local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
        hutypeNode:setVisible(false)
        for i=1,4 do
            local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
            hutypeSubNode:setVisible(false)
        end

        -- self.preShowSeatIdx = nil

        -- 弹出局结算界面
        if self.hasPiao or self.hasBaoJiao then
            if msgTbl.m_end == 0 then -- 不是最后一局
                local roundReport = require("app/views/RoundReport_NJ"):create(self.roomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
                self:addChild(roundReport, PlaySceneErRen.ZOrder.ROUND_REPORT)
            else
                gt.isZan = true
                local roundReport = require("app/views/RoundReport_NJ"):create(self.curRoomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
                self:addChild(roundReport, PlaySceneErRen.ZOrder.ROUND_REPORT)
            end
        else
            if msgTbl.m_end == 0 then -- 不是最后一局
                local roundReport = require("app/views/RoundReport"):create(self.roomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
                self:addChild(roundReport, PlaySceneErRen.ZOrder.ROUND_REPORT)
            else
                gt.isZan = true
                local roundReport = require("app/views/RoundReport"):create(self.curRoomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
                self:addChild(roundReport, PlaySceneErRen.ZOrder.ROUND_REPORT)
            end
        end

        self.lastRound = false
    end)

    local seqAction = cc.Sequence:create(delayTime, callFunc)
    self:runAction(seqAction)
end

function PlaySceneErRen:copyTab(st)
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

--八局结束总结
function PlaySceneErRen:onRcvFinalReport(msgTbl)
    self.curRoomPlayers = self:copyTab(self.roomPlayers)
    if self.isAnimation then
        self.finalReportMsg = msgTbl
        gt.log("8888--")
    else
        self:showFinalReport(msgTbl)
    end
end


function PlaySceneErRen:showFinalReport(msgTbl)

    gt.log("jinru 总结")
    -- dump(msgTbl)

    self.lastRound = true

    self.finalReportMsg = nil

	self.isBaoJiaoState = false
	self.isBaoJiaoSelected = false

    --local curRoomPlayers = {}
    --curRoomPlayers = self:copyTab(self.roomPlayers)

    gt.log("111111111111111")

    self.finalReport = require("app/views/FinalReport"):create(self.curRoomPlayers, msgTbl)
    self.finalReport:setVisible(false)
    self:addChild(self.finalReport, PlaySceneErRen.ZOrder.REPORT)
    local allDelayTimy = self.reportDelayTime+0.5
    -- 如果是海底牌的话,最后一局,需要多等1.5秒,然后展示总结算
    if self.haveHaidiPai then
        allDelayTimy = allDelayTimy + self.haidCardShowTime
    end
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
function PlaySceneErRen:updateCurrentTime()
    local timeLabel = gt.seekNodeByName(self, "Label_time")
    local curTimeStr = os.date("%X", os.time())
    local timeSections = string.split(curTimeStr, ":")
    -- 时:分
    timeLabel:setString(string.format("%s:%s", timeSections[1], timeSections[2]))
end

function PlaySceneErRen:checkPlayName( str )
    local retStr = ""
    local num = 0
    local lenInByte = #str
    local x = 1
    for i=1,lenInByte do
        i = x
        local curByte = string.byte(str, x)
        local byteCount = 1;
        if curByte>0 and curByte<=127 then
            byteCount = 1
        elseif curByte>127 and curByte<240 then
            byteCount = 3
        elseif curByte>=240 and curByte<=247 then
            byteCount = 4
        end
        local curStr = string.sub(str, i, i+byteCount-1)
        retStr = retStr .. curStr
        x = x + byteCount
        if x > lenInByte then
            return retStr
        end
        num = num + 1
        if num >= 4 then
            return retStr
        end
    end

    return retStr
end

-- start --
--------------------------------
-- @class function
-- @description 房间添加玩家
-- @param roomPlayer 玩家信息
-- end --
function PlaySceneErRen:roomAddPlayer(roomPlayer)
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
    nicknameLabel:setString( self:checkPlayName(nickname) )
    -- 积分
    local scoreLabel = gt.seekNodeByName(playerInfoNode, "Label_score")
    scoreLabel:setString(tostring(roomPlayer.score))
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

    -- 如果已经四个人了,隐藏微信分享按钮,显示聊天,设置按钮
    if #self.roomPlayers == self.playerCount then
        -- 隐藏等待界面元素
        local readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
        readyPlayNode:setVisible(false)
        -- 显示游戏中按钮（消息，设置）
        local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
        playBtnsNode:setVisible(true)
    end
end

-- start --
--------------------------------
-- @class function
-- @description 玩家自己进入房间
-- @param msgTbl 消息体
-- end --
function PlaySceneErRen:playerEnterRoom(msgTbl)

    gt.log("playerEnterRoom..............")
    dump(msgTbl)

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
    roomPlayer.m_credit = msgTbl.m_credits
    -- 玩家座位显示位置
    roomPlayer.displaySeatIdx = 4
    roomPlayer.readyState = msgTbl.m_ready
    roomPlayer.score = msgTbl.m_score
    -- 添加玩家自己
    self:roomAddPlayer(roomPlayer)

    -- 房间编号
    self.roomID = msgTbl.m_deskId
    -- 玩家座位编号
    self.playerSeatIdx = roomPlayer.seatIdx
    -- 玩家显示固定座位号
    self.playerFixDispSeat = 4
    self.currentUserMPos = msgTbl.m_pos
    -- 旋转座次标识
    local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
    for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
        turnPosSpr:setVisible(false)
    end
    -- 玩家出牌类型
    self.isPlayerShow = false
    self.isPlayerDecision = false

    -- 牌桌类型
    local tableType = gt.seekNodeByName(self.rootNode,"Text_TableType")

    local TypeStr,tableStr = gt.PalyTypeText(msgTbl.m_state,msgTbl.m_playtype)
    tableType:setString(tableStr)
    while tableType:getVirtualRendererSize().width > tableType:getContentSize().width do
        local fs = tableType:getFontSize() - 2
        tableType:setFontSize(fs)
    end

    self.paiTypeActivity = false

    if roomPlayer.readyState == 0 then
        -- 未准备显示准备按钮
        local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
        readyBtn:setVisible(true)
        gt.log("---===ooooo")
    else
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
-- @description 发送玩家准备请求消息
-- end --
function PlaySceneErRen:readyBtnClickEvt()
    local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
    readyBtn:setVisible(false)

    local msgToSend = {}
    msgToSend.m_msgId = gt.CG_READY
    msgToSend.m_pos = self.playerSeatIdx - 1
    gt.socketClient:sendMessage(msgToSend)
end

-- start --
--------------------------------
-- @class function
-- @description 玩家进入准备状态
-- @param seatIdx 座次
-- end --
function PlaySceneErRen:playerGetReady(seatIdx)
    local roomPlayer = self.roomPlayers[seatIdx]

    if self["fangkayuScb" .. seatIdx] then
        self.rootNode:removeChild(self["fangkayuScb" .. seatIdx],true)
    end
    if self["fangkayuNode" .. seatIdx] then
        self.rootNode:removeChild(self["fangkayuNode" .. seatIdx],true)
    end

    -- 显示玩家准备手势
    local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
    local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. roomPlayer.displaySeatIdx)
    readySignSpr:setVisible(true)

    -- 玩家本身
    if seatIdx == self.playerSeatIdx then
        -- 隐藏准备按钮
        local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
        readyBtn:setVisible(false)

        -- 隐藏牌局状态
        self.Node_roundState:setVisible(false)
    end
end

-- start --
--------------------------------
-- @class function
-- @description 隐藏所有玩家准备手势标识
-- end --
function PlaySceneErRen:hidePlayersReadySign()
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
function PlaySceneErRen:showPlayerInfo(sender)
    local senderTag = sender:getTag()
    local roomPlayer = self.roomPlayers[senderTag]
    if not roomPlayer then
        return
    end

    local playerInfoTips = require("app/views/PlayerInfoTips"):create(roomPlayer)
    self:addChild(playerInfoTips, PlaySceneErRen.ZOrder.PLAYER_INFO_TIPS)
end

-- start --
--------------------------------
-- @class function
-- @description 设置玩家麻将基础参考位置
-- @param displaySeatIdx 显示座位编号
-- @return 玩家麻将基础参考位置
-- end --
function PlaySceneErRen:setPlayerMjTilesReferPos(displaySeatIdx)
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
-- @param displaySeatIdx 座位编号
-- end --
function PlaySceneErRen:setTurnSeatSign(displaySeatIdx)
    -- 显示轮到的玩家座位标识
    local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
    -- 显示当先座位标识
    local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. displaySeatIdx)
    turnPosSpr:setVisible(true)
    if self.preTurnSeatIdx and self.preTurnSeatIdx ~= displaySeatIdx then
        -- 隐藏上次座位标识
        local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
        turnPosSpr:setVisible(false)
    end
    self.preTurnSeatIdx = displaySeatIdx
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
function PlaySceneErRen:playTimeCDStart(timeDuration)
    self.playTimeCD = timeDuration

    self.isVibrateAlarm = false
    self.lbl_playTimeCD:setVisible(true)
    self.lbl_playTimeCD:setString(tostring(timeDuration))
end

-- start --
--------------------------------
-- @class function
-- @description 更新出牌倒计时
-- @param delta 定时器周期
-- end --
function PlaySceneErRen:playTimeCDUpdate(delta)
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
    self.lbl_playTimeCD:setString(tostring(timeCD))
end

-- start --
--------------------------------
-- @class function
-- @description 给玩家发牌
-- @param mjColor
-- @param mjNumber
-- @param replaceType
-- end --
function PlaySceneErRen:addMjTileToPlayer(mjColor, mjNumber)
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
function PlaySceneErRen:sortPlayerMjTiles( isthreeCard )

    gt.log("sortPlayerMjTiles ...... ")
    isthreeCard = isthreeCard or false

    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
    -- 按照花色分类
    -- local colorsMjTiles = {}
    -- table.sort(roomPlayer.holdMjTiles, function(a, b)
    --     return a.mjColor < b.mjColor
    -- end)

    -- dump(roomPlayer.holdMjTiles)

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


    dump(transMjTiles)

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
function PlaySceneErRen:touchPlayerMjTiles(touch)
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
function PlaySceneErRen:addAlreadyOutMjTiles(seatIdx, mjColor, mjNumber, isHide)
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

    local tilesIn1Line = (self.playerCount == 2) and 18 or 10

    -- 显示已出牌
    local mjTilesReferPos = roomPlayer.mjTilesReferPos
    local mjTilePos = mjTilesReferPos.outStart
    local lineCount = math.ceil(#roomPlayer.outMjTiles / tilesIn1Line) - 1
    local lineIdx = #roomPlayer.outMjTiles - lineCount * tilesIn1Line - 1
    mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
    mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))
    mjTileSpr:setPosition(mjTilePos)
    self.playMjLayer:addChild(mjTileSpr, (gt.winSize.height - mjTilePos.y))
end

--出牌检查 检查要出的牌在牌桌上是否有相同的
function PlaySceneErRen:checkOutMjTile( color, number )
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
function PlaySceneErRen:checkMjTile()

    for seatIdx, roomPlayer in ipairs(self.roomPlayers) do

        for i, pungData in ipairs(roomPlayer.mjTilePungs) do
            --碰
            if self:checkPengAndGang( false, pungData.mjColor, pungData.mjNumber ) then
                -- gt.socketClient:reloginServer()
                return
            end
        end

        for i, brightBars in ipairs(roomPlayer.mjTileBrightBars) do
            --明杠
            if self:checkPengAndGang( true, brightBars.mjColor, brightBars.mjNumber ) then
                -- gt.socketClient:reloginServer()
                return
            end
        end

        for i, darkBars in ipairs(roomPlayer.mjTileDarkBars) do
            --暗杠
            if self:checkPengAndGang( true, darkBars.mjColor, darkBars.mjNumber ) then
                gt.socketClient:reloginServer()
                return
            end
        end
    end
end

function PlaySceneErRen:checkPengAndGang( isGang, color, number )
    local mjNumber = 0
    for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
        for i,outMjTile in ipairs(roomPlayer.outMjTiles) do
            --检查打出去的牌里是否还有碰 杠的牌
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
function PlaySceneErRen:removePreRoomPlayerOutMjTile(color,number)
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
                --     gt.socketClient:reloginServer()
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
function PlaySceneErRen:showOutMjtileSign(seatIdx)
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
function PlaySceneErRen:hideOtherPlayerMjTiles(seatIdx, isBar, isBrightBar)
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
function PlaySceneErRen:addMjTilePung(seatIdx, mjColor, mjNumber)
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
function PlaySceneErRen:addMjTileBar(seatIdx, mjColor, mjNumber, isBrightBar)
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
function PlaySceneErRen:addMjTileBu(seatIdx, mjColor, mjNumber, isBrightBu)
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
function PlaySceneErRen:showAllMjTilesWhenWin(seatIdx, m_cardCount, m_cardValue, m_color, m_number)
    -- dump(m_cardValue)
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
function PlaySceneErRen:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, isBar, isBrightBar)
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
function PlaySceneErRen:changePungToBrightBar(seatIdx, mjColor, mjNumber)
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
function PlaySceneErRen:showDecisionAnimation(seatIdx, decisionType, huCard)
    local roomPlayer = self.roomPlayers[seatIdx]
    -- 四川麻将  杠就是刮风下雨
    if decisionType == PlaySceneErRen.DecisionType.BRIGHT_BAR or
       decisionType == PlaySceneErRen.DecisionType.BRIGHT_BU then
           -- 刮风
           local Node_DecisionAnimate = gt.seekNodeByName(self.rootNode,"Node_DecisionAnimate")
        local node_animate = gt.seekNodeByName(Node_DecisionAnimate,"node_animate_" .. roomPlayer.displaySeatIdx)
        local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/guafeng.csb")
        self.brightBarAnimateNode = brightBarAnimateNode
        self.brightBarAnimate = brightBarAnimate
        brightBarAnimateNode:setPosition(cc.p(node_animate:getPositionX()+550,node_animate:getPositionY()+300))
        self.rootNode:addChild(brightBarAnimateNode, PlaySceneErRen.ZOrder.MJBAR_ANIMATION)

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

    elseif decisionType == PlaySceneErRen.DecisionType.DARK_BAR or
           decisionType == PlaySceneErRen.DecisionType.DARK_BU then
           -- 下雨
        local Node_DecisionAnimate = gt.seekNodeByName(self.rootNode,"Node_DecisionAnimate")
        local node_animate = gt.seekNodeByName(Node_DecisionAnimate,"node_animate_" .. roomPlayer.displaySeatIdx)
        local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/xiayu.csb")
        self.brightBarAnimateNode = brightBarAnimateNode
        self.brightBarAnimate = brightBarAnimate
        brightBarAnimateNode:setPosition(cc.p(node_animate:getPositionX()+550,node_animate:getPositionY()+300))
        self.rootNode:addChild(brightBarAnimateNode, PlaySceneErRen.ZOrder.MJBAR_ANIMATION)

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

    elseif decisionType == PlaySceneErRen.DecisionType.TAKE_CANNON_WIN or
           decisionType == PlaySceneErRen.DecisionType.SELF_DRAWN_WIN or
           decisionType == PlaySceneErRen.DecisionType.QIANG_GANG then
           -- 胡牌动画 现在只有一个胡的标志
           local decisionSignSpr = nil
           if decisionType == PlaySceneErRen.DecisionType.QIANG_GANG then
               decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_7.png")
           else
               decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_1.png")
           end
        decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
        self.rootNode:addChild(decisionSignSpr, PlaySceneErRen.ZOrder.DECISION_SHOW)
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

        if decisionType == PlaySceneErRen.DecisionType.TAKE_CANNON_WIN or decisionType == PlaySceneErRen.DecisionType.QIANG_GANG then
            gt.soundManager:PlaySpeakSound(roomPlayer.sex, "hu", roomPlayer)
        else
            gt.soundManager:PlaySpeakSound(roomPlayer.sex, "zimo", roomPlayer)
        end

    else
        --其他  碰 四川麻将这里就只有碰了

           local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_3.png")
        decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
        self.rootNode:addChild(decisionSignSpr, PlaySceneErRen.ZOrder.DECISION_SHOW)
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
function PlaySceneErRen:showMjTileAnimation(seatIdx, startPos, mjColor, mjNumber, cbFunc)
    local mjTilePos = startPos

    local roomPlayer = self.roomPlayers[seatIdx]
    local rotateAngle = {-90, 180, 90, 0}

    local mjTileName = string.format(gt.SelfMJSprFrameOut, mjColor, mjNumber)
    local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
    self.rootNode:addChild(mjTileSpr, 98)

    self.startMjTileAnimation = mjTileSpr
    self.startMjTileColor = mjColor
    self.startMjTileNumber    = mjNumber

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

function PlaySceneErRen:reset()
    -- 玩家手势隐藏
    self:hidePlayersReadySign()

    self.playMjLayer:removeAllChildren()
end

function PlaySceneErRen:backMainSceneEvt(eventType, isRoomCreater, roomID)
    -- 事件回调
    gt.removeTargetAllEventListener(self)
    -- 消息回调
    self:unregisterAllMsgListener()

    local mainScene = require("app/views/MainScene"):create(false, isRoomCreater, roomID)
    cc.Director:getInstance():replaceScene(mainScene)
end

function PlaySceneErRen:createFlimLayer(flimLayerType,cardList)
    -- 一个麻将
    local mjTileName = string.format(gt.SelfMJSprFrameOut, 2, 2)
    local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
    local width_oneMJ = mjTileSpr:getContentSize().width
    local space_gang = 20
    local width = 30+mjTileSpr:getContentSize().width*4*(#cardList)+space_gang*(#cardList-1)
    local height = 24+mjTileSpr:getContentSize().height

    local flimLayer = cc.LayerColor:create(cc.c4b(85, 85, 85, 0), width, height)
    flimLayer:setContentSize(cc.size(width,height))

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

                    local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
                    selfDrawnDcsNode:setVisible(false)

                    -- 发送消息
                    local cardData = cardList[ref:getTag()]
                    local msgToSend = {}
                    msgToSend.m_msgId = gt.CG_SHOW_MJTILE
                    msgToSend.m_type = cardData.flag
                    msgToSend.m_think = {}
                    if self.playType ~= gt.RoomType.ROOM_SICHUAN then
                        if msgToSend.m_type == 3 then
                            msgToSend.m_type = 7
                            elseif msgToSend.m_type == 4 then
                            msgToSend.m_type = 8
                        end
                    end
                    local think_temp = {cardData.mjColor,cardData.mjNumber}
                    table.insert(msgToSend.m_think,think_temp)
                    gt.socketClient:sendMessage(msgToSend)

                    -- gt.log("发送消息")
                    dump(msgToSend)
                    -- gt.log("发送消息")

                    if self.playType == gt.RoomType.ROOM_SICHUAN then
                        self.isPlayerShow = false
                    end

                    -- 删除弹出框（杠）
                    self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR)
                    -- 删除弹出框（补）
                    self:removeFlimLayer(PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU)
                    end
                end
                button:addTouchEventListener(touchEvent)
        end
    end
    return flimLayer
end

function PlaySceneErRen:removeFlimLayer(flimLayerType)
    local child = self:getChildByTag(PlaySceneErRen.TAG.FLIMLAYER_BAR)

    if flimLayerType == PlaySceneErRen.FLIMTYPE.FLIMLAYER_BAR then
        child = self:getChildByTag(PlaySceneErRen.TAG.FLIMLAYER_BAR)
    elseif flimLayerType == PlaySceneErRen.FLIMTYPE.FLIMLAYER_BU then
        child = self:getChildByTag(PlaySceneErRen.TAG.FLIMLAYER_BU)
    else

    end

    if not child then
        return
    end

    child:removeFromParent()

end

function PlaySceneErRen:startAudio()
    if gt.isUseNewMusic() == false then
        require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "当前客户端版本不支持语音，点击确定前往下载新版本客户端,取消关闭界面。", gt.updateNewApp, nil, false)
        return
    end
    --测试录音
    gt.log("==========cesiluyin")
    bridge.startVoice(gt.audioPath)
end

function PlaySceneErRen:stopAudio()
    if gt.isUseNewMusic() == false then
        return
    end

    bridge.stopVoice() --停止录音

    local getUrl = function ()
        -- body
        local ret = bridge.getVoiceUrl()

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

function PlaySceneErRen:cancelAudio()
    bridge.cancelVoice()
end

function PlaySceneErRen:onRcvDingPiao(msgTbl)
    dump(msgTbl)

    self:hidePlayersReadySign()
    self.Spr_turnPosBg:setVisible(true)

    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Spr_piao"})
    for i=1, self.playerCount do
        local _displaySeatIdx = self.roomPlayers[i].displaySeatIdx
        _nodeList["Node_playerInfo_".._displaySeatIdx].Spr_piao:setVisible(msgTbl.m_state[i] == 2)
    end

    local currentPlayerNeedDingPiao = msgTbl.m_state[self.playerSeatIdx] == 0
    self.nod_Piao:setVisible(currentPlayerNeedDingPiao)
    if currentPlayerNeedDingPiao then
        self:showDingPiao()
    end
end

function PlaySceneErRen:showDingPiao()
    local roomPlayer = self.roomPlayers[self.playerSeatIdx]

    local function _sendDingPiao(value, sound)
        local msgToSend = {}
        msgToSend.m_msgId = gt.GC_USER_DING_QUE
        msgToSend.m_color = value
        msgToSend.m_pos = 0
        gt.socketClient:sendMessage(msgToSend)
        gt.soundManager:PlaySpeakSound(roomPlayer.sex, sound, roomPlayer)
    end

    gt.addBtnPressedListener(self.btn_piao,   function() _sendDingPiao(2, "piao"  ) end)
    gt.addBtnPressedListener(self.btn_bupiao, function() _sendDingPiao(1, "bupiao") end)
end

function PlaySceneErRen:onRcvDingPiaoComplate(msgTbl)
	dump(msgTbl)
	self.nod_Piao:setVisible(false)

    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Spr_piao"})
    for i=1, self.playerCount do
        local _displaySeatIdx = self.roomPlayers[i].displaySeatIdx
        _nodeList["Node_playerInfo_".._displaySeatIdx].Spr_piao:setVisible(msgTbl.m_color[i] == 2)
    end
end

-- @class function
-- @description 通知玩家定缺
-- @param msgTbl
-- end --
function PlaySceneErRen:onRecUserDingQue( msgTbl )
    gt.log("11111111111 onRecUserDingQue ")
    dump(msgTbl)
    self.isPlayerShow = false

    local _list = gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Image_dingque"}):setVisible(false)

    local _currentPlayerMustChooseQue = msgTbl.m_state[self.playerSeatIdx] == 0
    self.dingque:setVisible(_currentPlayerMustChooseQue)
    if _currentPlayerMustChooseQue then
        self:showDingQue()
    end

    local _notDingqueUser = {}
    for k,v in pairs(msgTbl.m_state) do
        if k ~= self.playerSeatIdx then
            local roomPlayer = self.roomPlayers[k]
            if roomPlayer then
                _list["Node_playerInfo_" .. roomPlayer.displaySeatIdx].Image_dingque:setVisible(v == 0)
				table.insert(_notDingqueUser, roomPlayer.nickname)
            end
        end
    end

    self.nod_userdingqueing:setVisible(not _currentPlayerMustChooseQue and #_notDingqueUser > 0)
    if not _currentPlayerMustChooseQue and #_notDingqueUser > 0 then
        gt.runCSBAction(self.nod_userdingqueing, "res/playscene/UserDingQueIng.csb", true)
        self.lbl_userdingque_msg:setString("玩家: " .. table.concat(_notDingqueUser, " ") .. " 正在定缺中")
        gt.NodeArray(self.lbl_dot1, self.lbl_dot2, self.lbl_dot3):setPositionX(self.lbl_userdingque_msg:getContentSize().width)
    end
end

function PlaySceneErRen:showDingQue()
  -- 提示玩家定缺
  -- 显示定缺
  self.dingqueColorState = false

  local wanBtn = gt.seekNodeByName(self.dingque,"Btn_wan")
  local wanJian = gt.seekNodeByName(wanBtn,"Text_jian")
  local tongBtn = gt.seekNodeByName(self.dingque,"Btn_tong")
  local tongJian = gt.seekNodeByName(tongBtn,"Text_jian")
  local tiaoBtn = gt.seekNodeByName(self.dingque,"Btn_tiao")
  local tiaoJian = gt.seekNodeByName(tiaoBtn,"Text_jian")

  local function _onPressDingQue(sender)
    local msgToSend = {}
    msgToSend.m_msgId = gt.GC_USER_DING_QUE
    msgToSend.m_color = sender.m_color
    msgToSend.m_pos = self.dingque_pos
    gt.socketClient:sendMessage(msgToSend)
  end

  gt.NodeArray(wanJian, tongJian, tiaoJian):setVisible(false)
  gt.NodeArray(wanBtn, tongBtn, tiaoBtn):setScale(1):stopAllActions()

  wanBtn.m_color = 1
  tongBtn.m_color = 2
  tiaoBtn.m_color = 3

  gt.addBtnPressedListener(wanBtn, _onPressDingQue)
  gt.addBtnPressedListener(tongBtn, _onPressDingQue)
  gt.addBtnPressedListener(tiaoBtn, _onPressDingQue)

  --定缺的推荐 动画
  local dingqueArray = {wanJian, tongJian, tiaoJian}
  local dingqueBtnArray = {wanBtn, tongBtn, tiaoBtn}
  local numArray = self:dingquePrompt()

  for _, _numElement in ipairs(numArray) do
    if dingqueArray[_numElement] then
      dingqueArray[_numElement]:setVisible(true)
      self:jianAnimate(dingqueBtnArray[_numElement])
    end
  end
end

-- 定缺完成
function PlaySceneErRen:onRecUserDingQueComplate( msgTbl )

    if self.dingqueColorState then
        return
    end

    self.nod_userdingqueing:setVisible(false)
    self.dingque:setVisible(false)
    self.dingqueColorState = true

    gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Image_dingque"}):setVisible(false)

    for k,v in pairs(msgTbl.m_color) do
        self:showDingQueType(k,v)
        if k == self.playerSeatIdx then
            -- 玩家自己
            local roomPlayer = self.roomPlayers[k]
            roomPlayer.dingQueColor = v

            -- 给自己的牌加阴影
            if self.ownerWin ~= true then
                self:sortPlayerMjTiles(true)
            end
            dump(roomPlayer.dingQueTable)
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

function PlaySceneErRen:showDingQueType( seatIdx, color )
    local roomPlayer = self.roomPlayers[seatIdx]
    if not roomPlayer then return end

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

-- 返回 {color1, color2} 分别代表选中的牌花色, 可能含有0,1,2个花色，
function PlaySceneErRen:dingquePrompt()
    local _result = {}

    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
    if (not roomPlayer) or (not roomPlayer.holdMjTiles) then -- 还未开始
        return _result
    end

    local _t = {0, 0, 0} -- 万桶条初始为0
    local _dingqueMatch = {true, true, true} -- 只匹配万筒条
    for k,v in pairs(roomPlayer.holdMjTiles) do
        if _dingqueMatch[v.mjColor] then
            _t[v.mjColor] = _t[v.mjColor] + 1
        end
    end

    local min = math.min(_t[1], _t[2], _t[3])

    for _key, _el in ipairs(_t) do
        if _el == min then
            table.insert(_result, _key)
        end
    end

    return _result
end

function PlaySceneErRen:jianAnimate( node )

    node:stopAllActions()
    local scale = cc.ScaleBy:create(0.3,1.2,1.2)
    local bounce = cc.EaseBounceInOut:create(scale)
    local scaleBack = bounce:reverse()
    local action = cc.Sequence:create(bounce,scaleBack)
    node:runAction(cc.RepeatForever:create(action))

end

function PlaySceneErRen:showHuPaiType( seatIdx ,color, number , mjhuPaiType, isboolBreak, rcvWinCard )

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
        -- if mjhuPaiType then
        --     -- 自摸
        --     huType:loadTexture("playScene_" .. index .. "zimo.png",1)
        --     huType:setContentSize(cc.size(92,48))
        --     gt.log("自摸胡牌 ........... ")
        --     if seatIdx ~= self.playerSeatIdx then
        --         -- 别人胡牌  把胡的牌亮出来
        --         local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
        --         vv:setVisible(true)
        --         vv:setSpriteFrame(string.format(gt.MJSprFrameOut,roomPlayer.displaySeatIdx, color, number))
        --     else
        --         self.ownerWin = true
        --         gt.log("自摸胡的牌是："..color..number)
        --         if isboolBreak == true then--(断线重连)
        --             self.ownerWin = true
        --             -- 添加牌放在末尾
        --             local mjTilesReferPos = roomPlayer.mjTilesReferPos
        --             local mjTilePos = mjTilesReferPos.holdStart
        --             mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
        --             mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))

        --             gt.log("isboolBreak == true"..mjTilePos.x..mjTilePos.y.."胡牌"..color..number)
        --             local mjTile = self:addMjTileToPlayer(color, number)
        --             mjTile.mjTileSpr:setPosition(mjTilePos)
        --             self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
        --         end
        --     end

        -- else
        --     --  接炮胡 要创建牌
        --     huType:loadTexture("playScene_" .. index .. "hu.png",1)
        --     huType:setContentSize(cc.size(62,47))
        --     gt.log("接炮胡牌 ........... ")
        --     if seatIdx == self.playerSeatIdx then
        --         gt.log("自己接炮胡牌....................")

        --         -- 添加牌放在末尾
        --         if isboolBreak == true then--(断线重连)
        --             self.ownerWin = true

        --             local mjTilesReferPos = roomPlayer.mjTilesReferPos
        --             local mjTilePos = mjTilesReferPos.holdStart
        --             mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
        --             mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))

        --             local mjTile = self:addMjTileToPlayer(color, number)
        --             mjTile.mjTileSpr:setPosition(mjTilePos)
        --             self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
        --         end
        --     else

        --         gt.log("别人接炮胡牌....................")

        --         if isboolBreak == true then--(断线重连)
        --             -- 隐藏的牌显出出来
        --             local mjTilesReferPos = roomPlayer.mjTilesReferPos
        --             local mjTilePos = mjTilesReferPos.holdStart
        --             mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
        --             roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount + 1
        --             local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
        --             vv:setVisible(true)
        --             local _offsetMap = {{x=0, y=30}, {x=-15, y=0}, {x=0, y=-40}}
        --             vv:setPosition(cc.pAdd(mjTilePos, _offsetMap[roomPlayer.displaySeatIdx]))
        --             dump(string.format(gt.MJSprFrameOut,roomPlayer.displaySeatIdx, color, number))
        --             vv:setSpriteFrame(string.format(gt.MJSprFrameOut,roomPlayer.displaySeatIdx, color, number))
        --         end
        --     end
        -- end
    end
end

-- 换三张相关代码开始
function PlaySceneErRen:replace3CardPromptColor()
    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
    if not roomPlayer or not roomPlayer.holdMjTiles then -- 还未开始
        return 0
    end

    local _colorArray = {{1, 0}, {2, 0}, {3, 0}}
    for k,v in pairs(roomPlayer.holdMjTiles) do
        _colorArray[v.mjColor][2] = _colorArray[v.mjColor][2] + 1
    end

    -- 删除数量小于3的花色
    for i=#_colorArray, 1, -1 do
        if _colorArray[i][2] < 3 then
            table.remove(_colorArray, i)
        end
    end

    -- 按大小排序
    table.sort(_colorArray, function(a, b)
                   return a[2] < b[2]
    end)

    -- 排序后，可能有1个，2个，3个元素
    -- 如果第1，第2个元素不等则选第一个元素
    -- 如果相等，则按万=>条=>筒=>万的循环优先级选择
    -- 不可能选择第三个元素
    local _colorArray2Count = _colorArray[2] and _colorArray[2][2] or 0
    if _colorArray[1][2] == _colorArray2Count then
        -- 循环优先级: 万(1)+条(3)=(4) 选条(3)
        --             条(3)+筒(2)=(5) 选筒(2)
        --             筒(2)+万(1)=(3) 选万(1)
        local _colorPriority = {[4]=3, [5]=2, [3]=1}
        return _colorPriority[_colorArray[1][1] + _colorArray[2][1]]
    end

    return _colorArray[1][1]
end

function PlaySceneErRen:replace3CardPromptCards()
    local num = self:replace3CardPromptColor()

    gt.log("the choose replace3CardPromptColor color is ... " .. num)

    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
    local cardTable = {}
    for k,v in pairs(roomPlayer.holdMjTiles) do
        if v.mjColor == num then
            v.mjChooseType = true
            table.insert(cardTable,v)
            if #cardTable >= 3 then
                break
            end
        end
    end
    dump(cardTable)
    return cardTable
end

function PlaySceneErRen:replace3CardPromptCardsUpAction()
    local cardTable = self:replace3CardPromptCards()
    gt.log("===cardTable===")
    -- dump(cardTable)
    self.replaceThreeCardTable = cardTable
    -- dump(self.replaceThreeCardTable)
    for _, v in ipairs(cardTable) do
        local mjTilePos = cc.p(v.mjTileSpr:getPosition())
        local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
        v.mjTileSpr:runAction(moveAction)
    end

    self:checkReplaceOkBtn()
end

function PlaySceneErRen:onRcvSyncReplaceCardType( )
    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Image_threecard", "Image_dingque"}):setVisible(false)

    for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
        if roomPlayer.isReplace3CardPlayerDone then
            table.insert(self.replace3CardDoneUsers, roomPlayer.displaySeatIdx)
        end

        if roomPlayer.seatIdx == self.playerSeatIdx then
            if roomPlayer.isReplace3CardPlayerDone then
                self.ownerReplaceCardType = true

                self.Node_ReplaceThreeCard:setVisible(false)
            end
        else
            _nodeList["Node_playerInfo_" .. roomPlayer.displaySeatIdx].Image_threecard:setVisible(not roomPlayer.isReplace3CardPlayerDone)
        end
    end

    self.isReplace3CardAllPlayerDone = #self.replace3CardDoneUsers == self.playerCount
end

function PlaySceneErRen:replace3CardAddChoose( mjTile )
    if #self.replaceThreeCardTable >= 3 then
        local unchooseCard = self.replaceThreeCardTable[1]

        local mjTilePos = cc.p(unchooseCard.mjTileSpr:getPosition())
        local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
        unchooseCard.mjTileSpr:runAction(moveAction)
        unchooseCard.mjChooseType = false

        table.remove(self.replaceThreeCardTable, 1)
    end

    gt.log("replace3CardAddChoose....................")
    mjTile.mjChooseType = true
    table.insert(self.replaceThreeCardTable,mjTile)

    self:checkReplaceOkBtn()
    return true
end

function PlaySceneErRen:replace3CardRemoveChoose( mjTile )
    gt.log("replace3CardRemoveChoose....................")

    mjTile.mjChooseType = false
    table.removebyvalue(self.replaceThreeCardTable, mjTile)

    self:checkReplaceOkBtn()
end

function PlaySceneErRen:onRecUserReplaceCard( msgTbl )
    dump(msgTbl)
    gt.log("开始换三张 。。。。。。。。。。 ")
    -- self.fastTouchBugType = true

    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerInfo_#1#4", "Image_dingque"}):setVisible(false) -- 先隐藏定缺的提示

    if msgTbl.m_time ~= 0 then
        for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
            if roomPlayer.seatIdx ~= self.playerSeatIdx then
                -- 别人换牌
                _nodeList["Node_playerInfo_" .. roomPlayer.displaySeatIdx].Image_threecard:setVisible(not roomPlayer.isReplace3CardPlayerDone)
            end
        end

        self.isReplace3CardAllPlayerDone = false
        self.Node_ReplaceThreeCard:setVisible(true)

        self:replace3CardPromptCardsUpAction()
    else
        local seatIdx = msgTbl.m_pos + 1
        local roomPlayer = self.roomPlayers[seatIdx]

        if seatIdx == self.playerSeatIdx then
            -- 玩家自己
            gt.log("玩家自己换三张成功")

            self.ownerReplaceCardType = true
            self.Node_ReplaceThreeCard:setVisible(false)

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

            self:removeThreeCardFormPlayer()
        else
            gt.log("别的玩家换三张成功")
            gt.log("onRecUserReplaceCard ..............." .. roomPlayer.displaySeatIdx)
            _nodeList["Node_playerInfo_" .. roomPlayer.displaySeatIdx].Image_threecard:setVisible(false)
        end

        if not table.contains(self.replace3CardDoneUsers, roomPlayer.displaySeatIdx) then
            table.insert(self.replace3CardDoneUsers, roomPlayer.displaySeatIdx)
        end

        self.isReplace3CardAllPlayerDone = #self.replace3CardDoneUsers == self.playerCount
    end
end

function PlaySceneErRen:checkReplaceOkBtn()
    gt.log("checkReplaceOkBtn ....................")
    -- dump(self.replaceThreeCardTable)

    local _colorArray = {0, 0, 0}
    for k,v in pairs(self.replaceThreeCardTable) do
        _colorArray[v.mjColor] = _colorArray[v.mjColor] + 1
    end

    local isChooseOK= math.max(unpack(_colorArray)) == 3 -- 三张同花色的

    self.Node_ReplaceThreeCard:setVisible(true)
    local Btn_Replace_ThreeCard = gt.seekNodeByName(self.Node_ReplaceThreeCard, "Btn_Replace_ThreeCard")
    Btn_Replace_ThreeCard:setEnabled(isChooseOK)

    gt.addBtnPressedListener(Btn_Replace_ThreeCard,function ()
        gt.log("发送给服务器换三张哦。。。。。。。")

        self.ownerSendReplaceCardMsg = true

        -- dump(self.replaceThreeCardTable)
        local replaceCard1 = self.replaceThreeCardTable[1]
        local replaceCard2 = self.replaceThreeCardTable[2]
        local replaceCard3 = self.replaceThreeCardTable[3]
        local msgToSend = {}
        msgToSend.m_msgId = gt.GC_REPLACE_CARD
        msgToSend.m_pos = self.dingque_pos
        msgToSend.m_card = {{replaceCard1.mjColor,replaceCard1.mjNumber},{replaceCard2.mjColor,replaceCard2.mjNumber},{replaceCard3.mjColor,replaceCard3.mjNumber}}
        gt.socketClient:sendMessage(msgToSend)
    end)
end

function PlaySceneErRen:onRecUserReplaceCardComplate( msgTbl )

    gt.log("onRecUserReplaceCardComplate ...............")

    -- dump(msgTbl)

    self.isReplace3CardAllPlayerDone = true

    local _flagTable = {"顺时针换牌", "顺时针换牌", "对家换牌", "对家换牌", "逆时针换牌", "逆时针换牌"}
    self:showSmallToast(_flagTable[msgTbl.m_flag])

    -- 添加花三张的牌
    local _replace3CardGotNewCards = {}
    for i=1,3 do
        local v = msgTbl.m_card[i]
        local mjTile = self:addMjTileToPlayer(v[1], v[2])
        table.insert(_replace3CardGotNewCards, mjTile)
    end

    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
    -- dump(roomPlayer.holdMjTiles)
    self:sortPlayerMjTiles( true )

    for k,v in pairs(_replace3CardGotNewCards) do
        local mjTilePos = cc.p(v.mjTileSpr:getPosition())
        v.mjTileSpr:setPosition(cc.p(mjTilePos.x, mjTilePos.y + 50))

        local moveAction = cc.MoveTo:create(2, cc.p(mjTilePos.x, mjTilePos.y))
        v.mjTileSpr:runAction(moveAction)
    end
end

function PlaySceneErRen:removeThreeCardFormPlayer()

    gt.log("removeThreeCardFormPlayer ...................")

    local roomPlayer = self.roomPlayers[self.playerSeatIdx]
    -- dump(roomPlayer.holdMjTiles)

    for i=#roomPlayer.holdMjTiles, 1, -1 do

        local card = roomPlayer.holdMjTiles[i]

        if card.mjChooseType then
            table.remove(roomPlayer.holdMjTiles,i)
        end

    end

    -- dump(roomPlayer.holdMjTiles)
    self:sortPlayerMjTiles()

end
-- 换三张相关代码结束

function PlaySceneErRen:showFangjianYuAnimation(msgTbl, seatIdx)
    self.curRoomPlayers = self:copyTab(self.roomPlayers)
    self.isAnimation = true
    self.roundReportMsg = nil
    local callFunc1 = cc.CallFunc:create(function(sender)
        -- 出的牌标识动画
        local fangkayuNode, fangkayuAnime = gt.createCSAnimation("animation/jiangli_fangka.csb")
        fangkayuAnime:play("fangkayu", true)
        fangkayuNode:setVisible(true)
        self.rootNode:addChild(fangkayuNode, 100)
        fangkayuNode:setAnchorPoint(0.5, 0.5)
        fangkayuNode:setPosition(cc.p(gt.winSize.width / 2, gt.winSize.height / 2))
        if display.autoscale == "FIXED_HEIGHT" then
            --self.rootNode:setScale(0.75)
            fangkayuNode:setPosition(cc.p(gt.winSize.width / 3 * 2, gt.winSize.height / 2))
        end
        self["fangkayuNode" .. seatIdx] = fangkayuNode

        local function callFunc2()
            --获取房卡
            local fangkayuScb = gt.createCSAnimation("FangKaYu.csb")

            local node_1 = gt.seekNodeByName(fangkayuScb, "Node_1")
            local node_2 = gt.seekNodeByName(fangkayuScb, "Node_2")
            local atl_number = 0
            if self.playerSeatIdx == seatIdx then
                node_1:setVisible(true)
                node_2:setVisible(false)
                atl_number = gt.seekNodeByName(node_1, "Atl_number")
            else
                node_1:setVisible(false)
                node_2:setVisible(true)
                atl_number = gt.seekNodeByName(node_2, "Atl_number")
                local text_PlayerName = gt.seekNodeByName(node_2, "Text_PlayerName")

                -- 名字只取四个字,并且清理掉其中的空格
                local roomPlayer = self.roomPlayers[seatIdx]
                local nickname = string.gsub(roomPlayer.nickname," ","")
                text_PlayerName:setString(self:checkPlayName(nickname))
            end
            atl_number:setString(msgTbl.m_rewardCardNum)
            self.rootNode:addChild(fangkayuScb, 101)
            fangkayuScb:setPosition(cc.p(gt.winSize.width / 2, gt.winSize.height / 2))
            self["fangkayuScb" .. seatIdx] = fangkayuScb

            if display.autoscale == "FIXED_HEIGHT" then
                self.rootNode:setScale(0.75)
                fangkayuScb:setPosition(cc.p(gt.winSize.width / 3 * 2, gt.winSize.height / 2))
            end

            local callFunc3 = cc.CallFunc:create(function(sender)
                -- if self.fangkayuScb then
                --     self.fangkayuScb:removeFromParent()
                -- end
                self.isAnimation = false

                if self["fangkayuScb" .. seatIdx] then
                    self.rootNode:removeChild(self["fangkayuScb" .. seatIdx],true)
                end

                -- 出的牌标识动画
                if self.roundReportMsg then
                    --显示单局结算界面
                    if not self.isShowPaiType then
                        self.isShowPaiType = true
                        --显示活动牌型分享界面
                        gt.log("===4==4=4===")
                        self:showPaiType(self.roundReportMsg, seatIdx)
                        self:showRoundReport(self.roundReportMsg)
                    end
                end
                --八局结束总结
                if self.finalReportMsg then
                    self:showFinalReport(self.finalReportMsg)
                end
            end)

            local scaleAction = cc.ScaleBy:create(0.3, 2)
            local action = cc.Sequence:create(scaleAction,scaleAction:reverse(),cc.DelayTime:create(1.5), callFunc3)
            fangkayuScb:runAction(action)
        end

        fangkayuAnime:setFrameEventCallFunc(function(frame)---setLastFrameCallFunc
            if self["fangkayuNode" .. seatIdx] then
                self.rootNode:removeChild(self["fangkayuNode" .. seatIdx],true)
            end
            callFunc2()
        end)
    end)

    local seqAction = cc.Sequence:create(callFunc1)
    --local seqAction = cc.Sequence:create(callFunc1, callFunc2, cc.DelayTime:create(1.5), callFunc3)
    self.rootNode:runAction(seqAction)
end


function PlaySceneErRen:showPaiType(roundReportMsg, seatIdx)
    self.paiTypeActivity = require("app/views/PaiTypeActivity"):create(roundReportMsg, self.playerSeatIdx, self.curRoomPlayers)
    self:addChild(self.paiTypeActivity, PlaySceneErRen.ZOrder.ROUND_REPORT_Activity)
end

function PlaySceneErRen:onRecUserDBaoJiaoComplate( msgTbl )
	self.isBaoJiaoDecision = false
	self.isPlayerDecision = false

    self.nod_baojiao:setVisible(false)
end

-- 具体注释见自贡同名函数
function PlaySceneErRen:onRecBaoJiao( msgTbl )
	gt.dump(msgTbl)

    local currentUserBaoJiao = msgTbl.m_state[self.playerSeatIdx]

    self.nod_baojiao:setVisible(currentUserBaoJiao == 1)

    local _isBaoJiao = {[-1]=true, [0]=false, [1]=false, [2]=true}
    self.isBaoJiaoSelected = _isBaoJiao[currentUserBaoJiao]
    self.isBaoJiaoState = _isBaoJiao[currentUserBaoJiao]
    self.roomPlayers[self.playerSeatIdx].isBaoJiaoState = _isBaoJiao[currentUserBaoJiao]

    if currentUserBaoJiao == 1 then -- 当前用户有报叫
        self.isPlayerDecision = true

        local function _baoJiaoNet(state)
            self.isBaoJiaoSelected = true

            local msgToSend = {}
            msgToSend.m_msgId = gt.CG_BAOJIAO
            msgToSend.m_state = state
            msgToSend.m_pos = self.dingque_pos
            gt.socketClient:sendMessage(msgToSend)
        end

        gt.addBtnPressedListener(self.btn_baojiao, function() _baoJiaoNet(1) end)
        gt.addBtnPressedListener(self.btn_baojiao_guo, function() _baoJiaoNet(0) end)
    elseif currentUserBaoJiao == 2 then
        gt.log("----22--")
        if not self:isBaoJiaoFirstStart(self.m_dCount) then
            self:setAllMaskLayer2(true)
        end
    elseif currentUserBaoJiao == -1 then
        if self.bankerSeatIdx ~= self.playerSeatIdx then
            self:setAllMaskLayer(true, 1)
        end
        self:showBCDecisionAnimation(self.playerSeatIdx)
    end

	for k,v in pairs(msgTbl.m_state) do
        if (k ~= self.playerSeatIdx) and (v == -1) then -- 其他玩家选择了报叫
            gt.log("=========bb====")
            self:showBCDecisionAnimation(k)
        end
	end
end

--全部屏蔽遮罩层true:遮挡false:不遮挡
function PlaySceneErRen:setAllMaskLayer(isMark, isAllMask)
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for j, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if isAllMask == 1 then
			mjTile.mjTileSpr:setColor(self.colorGray)
			mjTile.isMark = isMark
		else
			if j < #roomPlayer.holdMjTiles then
				if isMark then
					mjTile.mjTileSpr:setColor(self.colorGray)
				else
					mjTile.mjTileSpr:setColor(self.colorWhite)
				end
				mjTile.isMark = isMark
			end
		end
	end
end

--全部屏蔽遮罩层true:遮挡false:不遮挡
function PlaySceneErRen:setAllMaskLayer2(isMark, isAllMask)
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for j, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if isAllMask == 1 then
			mjTile.mjTileSpr:setColor(self.colorGray)
			mjTile.isMark = isMark
		else
			if isMark then
				mjTile.mjTileSpr:setColor(self.colorGray)
			else
				mjTile.mjTileSpr:setColor(self.colorWhite)
			end
			mjTile.isMark = isMark
		end
	end
end

function PlaySceneErRen:showBCDecisionAnimation(seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]

    local node = gt.loadCSB("playscene/BaoJiao.csb")
    gt.runCSBActionOnce(node, "playscene/BaoJiao.csb")

    node:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
    self.rootNode:addChild(node, 100)
end

function PlaySceneErRen:checkOtherTingCards(roomPlayer, m_tingCards)
	local maskCardTbl = {}

	for i = 1, #m_tingCards do
		local tingCards = {}
		table.insert(tingCards, m_tingCards[i][1][1])
		table.insert(tingCards, m_tingCards[i][1][2])
		table.insert(maskCardTbl, tingCards)
	end
	self:setMySelfMaskLayer(roomPlayer, maskCardTbl)
end

function PlaySceneErRen:setMySelfMaskLayer(roomPlayer, tingInfo)
	local num = #tingInfo
	gt.dump(tingInfo)
	if num < 1 then
		return
	end
	gt.log("function name is setMySelfMaskLayer")
	for j, mjTile in ipairs(roomPlayer.holdMjTiles) do
		mjTile.mjTileSpr:setColor(self.colorGray)
		mjTile.isMark = true
		for i = 1, num do
			if mjTile.mjColor == tingInfo[i][1] and mjTile.mjNumber == tingInfo[i][2] then
				mjTile.mjTileSpr:setColor(self.colorWhite)
				mjTile.isMark = false
				table.remove(tingInfo, i)
				num = #tingInfo
				break
			end
		end
	end
end

-- 是否是报叫开局的时候
function PlaySceneErRen:isBaoJiaoFirstStart(m_dCount)
    local _cardCount = 36*self.fangCount - self.playerCount*self.mjCount - 1

    return m_dCount == _cardCount
end

function PlaySceneErRen:getDisplaySeatIdxByMPos(m_pos)
    local _displaySeatMap = {
        [2] = {[0]=4, [1]=2},
        [3] = {[0]=4, [1]=1, [2]=3},
        [4] = {[0]=4, [1]=1, [2]=2, [3]=3}
    }
    return _displaySeatMap[self.playerCount][(m_pos - self.currentUserMPos) % self.playerCount]
end

function PlaySceneErRen:showBaoziAnimation(msgTbl)
    self.spr_baozi:setVisible(self.hasBaozi and msgTbl.m_isBaozi)

    if not self.hasBaozi or not msgTbl.m_dice then return end
    dump(msgTbl.m_dice)

    self.startGame = true
    self.playMjLayer:setVisible(false)
    self.nod_decisions:setVisible(false)
    self.nod_baojiao:setVisible(false)

    local _nodeList = gt.findNodeArray(self.rootNode, {"Spr_turnPosBg", "Spr_turnPos_#1#4"}):setVisible(false)

    cc.SpriteFrameCache:getInstance():addSpriteFrames("images/shaizi_dianshu.plist")
    local node = gt.loadCSB("playscene/Saizi.csb")
    gt.runCSBAction(node, "playscene/Saizi.csb", true)
    node:setPosition(cc.p(_nodeList.Spr_turnPosBg:getPosition()))
    self.rootNode:addChild(node, 100)

    local function _endBaozi()
        self.startGame = false
        self.playMjLayer:setVisible(true)
        self.nod_decisions:setVisible(true)
        self.spr_baozi:setVisible(msgTbl.m_dice[1] == msgTbl.m_dice[2])
        self.isShowingBaozi = false
    end
    local stopTime = math.random(100, 140)/60
    dump(stopTime)
    local function _showResult()
        node:stopAllActions()

        node.spr_run1:setVisible(false)
        node.spr_run2:setVisible(false)
        node.spr_stop1:setVisible(true)
        node.spr_stop2:setVisible(true)
        node.spr_stop1:setSpriteFrame(string.format("D%d.png", msgTbl.m_dice[1]))
        node.spr_stop2:setSpriteFrame(string.format("D%d.png", msgTbl.m_dice[2]))

        local action = cc.Sequence:create(cc.DelayTime:create(2.2),
                                          cc.CallFunc:create(_endBaozi),
                                          cc.RemoveSelf:create())
        node:runAction(action)
    end
    local action = cc.Sequence:create(cc.DelayTime:create(stopTime), cc.CallFunc:create(_showResult))
    node:runAction(action)
end

return PlaySceneErRen
