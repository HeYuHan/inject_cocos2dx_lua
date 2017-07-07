
local gt = cc.exports.gt

local PlayManager_Base = {}
gt.PlayManager_Base = PlayManager_Base

function PlayManager_Base:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end


function PlayManager_Base:ctor(rootNode, paramTbl, playerNum)
	

	self.rootNode = rootNode
	-- 房间号
	self.roomID = paramTbl.roomID

	self.mjCount = paramTbl.mjCount
	-- 玩法类型
	--self.playType = paramTbl.playType

	-- 最大番数
	--self.maxFan = paramTbl.m_maxFan
	-- 玩家显示固定座位号
	self.playerDisplayIdx = tonumber(playerNum)

	--玩家人数
	self.playerNum = tonumber(playerNum)

	self.playerSeatIdx = paramTbl.playerSeatIdx

	self.dismissTag = gt.seekNodeByName(self.rootNode, "dismissTag")

	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	self.remainTilesLabel = gt.seekNodeByName(roundStateNode, "Label_remainTiles")
	
	if self.dismissTag then
		self.dismissTag:setVisible(false)
	end

	if tonumber(self.playerNum) == 3 then
		self.pdbdd_img = gt.SR_MJSprFrame
		self.tbgsd_img = "sr_tbgs_%d.png"
		self.pdsdd_img = gt.SR_MJSprFrameOut
		self.tdbgsd_img = "sr_tdbgs_%d.png"
	elseif tonumber(self.playerNum) == 4 or tonumber(self.playerNum) == 2 then
		self.pdbdd_img = gt.MJSprFrame
		self.tbgsd_img = "tbgs_%d.png"
		self.tdbgsd_img = "tdbgs_%d.png"
		self.pdsdd_img = gt.MJSprFrameOut--gt.MJSprFrameOut
	end

	-- 头像下载管理器
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	self.rootNode:addChild(playerHeadMgr)
	self.playerHeadMgr = playerHeadMgr

	self.WanNengPaiCarTable = {}

	self:initUI(paramTbl)
end

function PlayManager_Base:initUI(msgTbl)
	-- 隐藏玩家麻将参考位置
	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	playNode:setVisible(false)

	-- 房间号
	local roomIDLabel = gt.seekNodeByName(self.rootNode, "Label_roomID")
	roomIDLabel:setString("房间号" .. gt.getLocationString("LTKey_0013", self.roomID))
	
	local Lab_Play = gt.seekNodeByName(self.rootNode, "Lab_Play")

	local TypeStr,tableStr = gt.PalyTypeText(msgTbl.playType, msgTbl.m_playtype, msgTbl.m_baseScore)
	Lab_Play:setString(tableStr)
	if string.len(tableStr)>85 then
		Lab_Play:setFontSize(18)
	end

	self:hideInfo()

	-- 麻将层
	local playMjLayer = cc.Layer:create()
	self.rootNode:addChild(playMjLayer, gt.PlayZOrder.MJTILES_LAYER)
	self.playMjLayer = playMjLayer
	
	-- 出的牌标识动画
	local outMjtileSignNode, outMjtileSignAnime = gt.createCSAnimation("animation/OutMjtileSign.csb")
	outMjtileSignAnime:play("run", true)
	outMjtileSignNode:setVisible(false)
	self.rootNode:addChild(outMjtileSignNode, gt.PlayZOrder.OUTMJTILE_SIGN)
	self.outMjtileSignNode = outMjtileSignNode

	-- 逻辑座位和显示座位偏移量(从0编号开始)
	local seatOffset = self.playerDisplayIdx - self.playerSeatIdx
	self.seatOffset = seatOffset
	-- 旋转座次标识,座次方位和显示对应
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setRotation(-seatOffset * 90)
	for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end

	--self.remainCard = gt.createTTFLabel("剩余排数", 28) --剩余牌数
	--turnPosBgSpr:addChild(self.remainCard)
	--remainCard:setPosition(cc.p(self.playMjLayer:getContentSize().width / 2, self.playMjLayer:getContentSize().height / 2))

end

function PlayManager_Base:hideInfo()
	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	hutypeNode:setVisible(false)
	for i=1, self.playerNum do
		local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
		hutypeSubNode:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 房间添加玩家
-- @param playerData 玩家数据
-- end --
function PlayManager_Base:roomAddPlayer(roomPlayer)
	-- 玩家自己
	roomPlayer.isOneself = false
	if roomPlayer.seatIdx == self.playerSeatIdx then
		roomPlayer.isOneself = true
	end
	-- 显示索引
	roomPlayer.displayIdx = (roomPlayer.seatIdx + self.seatOffset - 1) % self.playerNum + 1

	-- 玩家信息
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	playerInfoNode:setVisible(true)
	-- 头像
	roomPlayer.headURL = string.sub(roomPlayer.headURL, 1, string.lastString(roomPlayer.headURL, "/")) .. "96"
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	self.playerHeadMgr:attach(headSpr, roomPlayer.uid, roomPlayer.headURL,roomPlayer.sex)
	-- 昵称
	local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Label_nickname")
	nicknameLabel:setString(roomPlayer.nickname)
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

	self:addTileTable(roomPlayer)
	-- 玩家持有牌
	roomPlayer.holdMjTiles = {}
	-- 玩家已出牌
	roomPlayer.outMjTiles = {}
	-- 碰
	roomPlayer.mjTilePungs = {}
	--飞
	roomPlayer.mjTileFeis = {}
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

	--狼起牌
	roomPlayer.langMjTiles = {}
	
	-- 麻将放置参考点
	roomPlayer.mjTilesReferPos = self:getPlayerMjTilesReferPos(roomPlayer.displayIdx)

	-- 添加入缓冲
	if not self.roomPlayers then
		self.roomPlayers = {}
	end
	self.roomPlayers[roomPlayer.seatIdx] = roomPlayer
end

function PlayManager_Base:addTileTable(roomPlayer)
	
end
-- start --
--------------------------------
-- @class function
-- @description 设置座位编号标识
-- @param seatIdx 座位编号
-- end --
function PlayManager_Base:setTurnSeatSign(seatIdx)
	-- 显示轮到的玩家座位标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	-- 显示当先座位标识
	local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. seatIdx)
	turnPosSpr:setVisible(true)
	if self.preTurnSeatIdx and self.preTurnSeatIdx ~= seatIdx then
		-- 隐藏上次座位标识
		local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
		turnPosSpr:setVisible(false)
	end
	self.preTurnSeatIdx = seatIdx
end

function PlayManager_Base:drawMjTile(seatIdx, mjColor, mjNumber)
	self.qianGangSeatIdx = seatIdx

	local roomPlayer = self.roomPlayers[seatIdx]

	-- 添加牌放在末尾
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
	mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.drawSpace)

	local mjTile = self:addMjTile(roomPlayer, mjColor, mjNumber)
	mjTile.mjTileSpr:setPosition(mjTilePos)
	self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))

	
	--self.remainTilesLabel:setString(tostring(108 - tonumber(self.playMjLayer:getChildrenCount())))
	--self.remainCard:setString("ddd")
end

-- 清理掉所有出的牌
function PlayManager_Base:cleanMjFormLayer()
	self.playMjLayer:removeAllChildren()

	self.outMjtileSignNode:setVisible(false)

	--清理胡牌字
	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	for i = 1, self.playerNum do

		--清理决策背景
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")
		Node_ReplayBtn:setVisible(false)

		--清理
		local huType = gt.seekNodeByName(hutypeNode, "huType" .. i)
		huType:setVisible(false)
	end

	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 给玩家添加牌
-- @param seatIdx 座位号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --

function PlayManager_Base:addMjTile(roomPlayer, mjColor, mjNumber)
	-- local roomPlayer = self.roomPlayers[seatIdx]
	cc.SpriteFrameCache:getInstance():addSpriteFrames("images/mahjonghn_tiles_sr.plist")
	local mjTileName = ""
	if roomPlayer.isOneself then
		-- 玩家自己
		mjTileName = string.format(self.pdbdd_img, roomPlayer.displayIdx, mjColor, mjNumber)
	else
		if roomPlayer.isHidden then
			-- 持有牌隐藏
			mjTileName = string.format(self.tbgsd_img, roomPlayer.displayIdx)
		else
			mjTileName = string.format(self.pdsdd_img, roomPlayer.displayIdx, mjColor, mjNumber)
		end
	end
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.playMjLayer:addChild(mjTileSpr)
	for i,wan in ipairs(self.WanNengPaiCarTable) do
		if mjColor == wan[1] and mjNumber == wan[2] then
			mjTileSpr:setColor(cc.c3b(255,255,100))
		end
	end
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.holdMjTiles, mjTile)

	return mjTile
end

-- start --
--------------------------------
-- @class function
-- @description 出牌
-- @param
-- @param
-- @param
-- @return
-- end --
function PlayManager_Base:playOutMjTile(seatIdx, mjColor, mjNumber)
	gt.log("function = playOutMjTile")
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 持有牌删除对应麻将
	self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, 1)

	-- 显示出牌动画
	self:showOutMjTileAnimation(roomPlayer, mjColor, mjNumber, function()
		-- 添加出牌
		self:outMjTile(roomPlayer, mjColor, mjNumber)

		-- 显示出牌标识
		self:showOutMjtileSign(roomPlayer)
	end)

	-- 记录出牌的上家
	self.prePlaySeatIdx = seatIdx

	-- dj revise
	gt.soundManager:PlayCardSound(roomPlayer.sex, mjColor, mjNumber)

end

-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlayManager_Base:removePrePlayerLangMjTile(seatIdx, langMjTiles)
	gt.log("function = removePrePlayerLangMjTile")
	gt.dump(langMjTiles)
	local roomPlayer = self.roomPlayers[seatIdx]
	langMjTiles = langMjTiles or {}
	for i = 2, #langMjTiles do
		for j, mjTile in ipairs(roomPlayer.holdMjTiles) do
			if  langMjTiles[i][2] == mjTile.mjNumber and langMjTiles[i][1] == mjTile.mjColor then
				mjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles, j)
				break
			end
		end
	end
	self:sortHoldMjTiles(roomPlayer)
end

-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlayManager_Base:removePrePlayerLangOneMjTile(seatIdx, mjColor, mjNumber)
	gt.log("function = removePrePlayerLangOneMjTile")
	gt.dump(langMjTiles)
	local roomPlayer = self.roomPlayers[seatIdx]

	for j, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if  mjNumber == mjTile.mjNumber and mjColor == mjTile.mjColor then
			mjTile.mjTileSpr:removeFromParent()
			table.remove(roomPlayer.holdMjTiles, j)
			break
		end
	end
	self:sortHoldMjTiles(roomPlayer)
end

-- 快速出牌,屏蔽出牌动画
function PlayManager_Base:playOutMjTileQuick(seatIdx, mjColor, mjNumber)
	gt.log("function = playOutMjTileQuick")
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 持有牌删除对应麻将
	self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, 1)

	-- 添加出牌
	self:outMjTile(roomPlayer, mjColor, mjNumber)

	-- 显示出牌标识
	self:showOutMjtileSign(roomPlayer)

	-- 记录出牌的上家
	self.prePlaySeatIdx = seatIdx
end

-- start --
--------------------------------
-- @class function
-- @description 显示用户的海底牌
-- @param seatIdx 座位索引
-- end --
function PlayManager_Base:showHaidiDecision(seatIdx,isQuick)
	if isQuick then
		local roomPlayer = self.roomPlayers[seatIdx]
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
		local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_haidiBtn")
		Node_ReplayBtn:setVisible(false)
		return
	end

	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	self.rootNode:reorderChild(playerInfoNode, 200)
	local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_haidiBtn")
	Node_ReplayBtn:setVisible(true)
end

-- start --
--------------------------------
-- @class function
-- @description 用户海底要
-- @param seatIdx 座位索引
-- end --
function PlayManager_Base:decisionHaidiResult(seatIdx,isChoose,isQuick)
	if isQuick then
		local roomPlayer = self.roomPlayers[seatIdx]
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
		local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_haidiBtn")
		Node_ReplayBtn:setVisible(false)
		return
	end

	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	self.rootNode:reorderChild(playerInfoNode, 200)
	local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_haidiBtn")

	local node
	if isChoose == true then -- 海底要
		node = gt.seekNodeByName(Node_ReplayBtn,"Imgml1")
	else
		node = gt.seekNodeByName(Node_ReplayBtn,"Imgml2")
	end

	--添加手势测试
	local replayGesture = ccui.ImageView:create()
    replayGesture:loadTexture("sd/images/otherImages/replayGesture.png")
    replayGesture:setPosition(cc.p(node:getPositionX(),node:getPositionY()-25) )
    Node_ReplayBtn:addChild(replayGesture,300)

    local  sc2 = cc.ScaleBy:create(0.3,0.65)
    local  sc3 = cc.EaseInOut:create(sc2, 0.3)
    local  sc2_back = sc3:reverse()
    local function stopAction()
        replayGesture:stopAllActions()
        replayGesture:removeFromParent()
        Node_ReplayBtn:setVisible(false)
    end

    local callfunc = cc.CallFunc:create(stopAction)
    replayGesture:runAction( cc.Sequence:create(sc3, callfunc))
end

function PlayManager_Base:showHaidiResult( mjColor, mhNumber, isQuick )
	if isQuick then
		local dipaiNode = gt.seekNodeByName(self.rootNode, "Node_HaidiPai")
		dipaiNode:setVisible( false )
		return
	end
	local dipaiNode = gt.seekNodeByName(self.rootNode, "Node_HaidiPai")
	dipaiNode:setVisible( true )
	local spr = gt.seekNodeByName(dipaiNode, "Sprite_pai")
	spr:setSpriteFrame(string.format(gt.SelfMJSprFrameOut, mjColor, mhNumber))

	dipaiNode:stopAllActions()
	local delayTime = cc.DelayTime:create(1.5)
	local callFunc = cc.CallFunc:create(function(sender)
		dipaiNode:setVisible( false )
	end)

	local seqAction = cc.Sequence:create(delayTime, callFunc)
	dipaiNode:runAction(seqAction)
end

-- start --
--------------------------------
-- @class function
-- @description 显示用户的决策
-- @param seatIdx 座位索引
-- @param decisionList 决策的类型列表
-- end --
function PlayManager_Base:showMakeDecision(seatIdx,decisionList,isQuick)
	local roomPlayer = self.roomPlayers[seatIdx]
	if isQuick then
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
		local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")
		Node_ReplayBtn:setVisible(false)
		return
	end

	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	self.rootNode:reorderChild(playerInfoNode, 200)
	local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")
	Node_ReplayBtn:setVisible(true)
	-- 隐藏所有的按钮
	for i=1,5 do
		local node1 = gt.seekNodeByName(Node_ReplayBtn,string.format("Imgml%d",i))
		node1:setVisible(false)

		local node2 = gt.seekNodeByName(Node_ReplayBtn,string.format("Imgml%d",i*10+1))
		node2:setVisible(false)

	end
	gt.log("ffffsaa===" .. seatIdx)
	local isHuFlag = false
	for i=1,5 do
		local node1 = gt.seekNodeByName(Node_ReplayBtn,"Imgml"..i)
		local node2 = gt.seekNodeByName(Node_ReplayBtn,string.format("Imgml%d",i*10+1))
		node2:setVisible(true)
		
		for _,v in ipairs(decisionList) do
			gt.log("---ff-f-iiiiiii-" .. v)
			if v == i then
				if i == 4 then
					gt.log("---000000--")
					isHuFlag = true
				end
				node1:setVisible(true)
				node2:setVisible(false)
			end
		end
	end
	if isHuFlag then
		roomPlayer.isHuType = true
	else
		roomPlayer.isHuType = false
	end
end

-- start --
--------------------------------
-- @class function
-- @description 用户选择决策
-- @param seatIdx 座位索引
-- @param decisionList 决策的类型
-- end --
function PlayManager_Base:decisionResult(seatIdx,decisionIndex,isQuick)
	if isQuick then
		local roomPlayer = self.roomPlayers[seatIdx]
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
		local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")
		Node_ReplayBtn:setVisible(false)
		return
	end

	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	self.rootNode:reorderChild(playerInfoNode, 200)
	local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")

	local node
	for i=1,5 do
		local node1 = gt.seekNodeByName(Node_ReplayBtn,"Imgml"..i)
		if i == decisionIndex then
			node = node1
			break
		end
	end

	--添加手势测试
	local replayGesture = ccui.ImageView:create()
    replayGesture:loadTexture("sd/images/otherImages/replayGesture.png")
    replayGesture:setPosition(cc.p(node:getPositionX(),node:getPositionY()-25) )
    Node_ReplayBtn:addChild(replayGesture,300)

    local  sc2 = cc.ScaleBy:create(0.3,0.65)
    local  sc3 = cc.EaseInOut:create(sc2, 0.3)
    local  sc2_back = sc3:reverse()
    local function stopAction()
        replayGesture:stopAllActions()
        replayGesture:removeFromParent()
        Node_ReplayBtn:setVisible(false)
        for i = 1, self.playerNum do
        	local roomPlayer = self.roomPlayers[i]
        	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
			local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")
			dump(roomPlayer)
			--Node_ReplayBtn:setVisible(false)
        	if roomPlayer.displayIdx == seatIdx then
        		gt.log("yyyyyy--mmmm--")
				Node_ReplayBtn:setVisible(false)
				roomPlayer.isHuType = false
			else
				if not roomPlayer.isHuType then
					gt.log("yyyyyy--uuuu--")
					Node_ReplayBtn:setVisible(false)
				end
        	end
        	
    	end
    end

    local callfunc = cc.CallFunc:create(stopAction)
    replayGesture:runAction( cc.Sequence:create(sc3, callfunc))
end


-- start --
--------------------------------
-- @class function
-- @description 添加已出牌
-- @param seatIdx 座位号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --
function PlayManager_Base:outMjTile(roomPlayer, mjColor, mjNumber)
	-- 添加到已出牌
	-- local roomPlayer = self.roomPlayers[seatIdx]

	local mjTileName = string.format(self.pdsdd_img, roomPlayer.displayIdx, mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.outMjTiles, mjTile)

	-- 缩小玩家已出牌
	if roomPlayer.isOneself then
		mjTileSpr:setScale(0.66)
	end

    local tilesIn1Line = (self.playerNum == 2) and 18 or 10

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

-- start --
--------------------------------
-- @class function
-- @description 碰牌
-- @param seatIdx 座位编号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --
function PlayManager_Base:addMjTilePung(seatIdx, cardList)
	gt.log("function is addMjTilePung----------------")
	local roomPlayer = self.roomPlayers[seatIdx]

	local pungData = {}
	pungData.mjColor = cardList[1][1]
	pungData.mjNumber = cardList[1][2]
	table.insert(roomPlayer.mjTilePungs, pungData)

	pungData.groupNode = self:pungBarReorderMjTiles(roomPlayer, cardList[1][1], cardList[1][2], false, false, cardList)
end

-- 飞
function PlayManager_Base:addMjFei( seatIdx, m_think )
	dump(m_think)
	local feiData = {}
	feiData.mjColor = m_think[2][1]
	feiData.mjNumber = m_think[2][2]

	local feiGroup = {}
	table.insert(feiGroup,{m_think[2][1], m_think[2][2]})
	table.insert(feiGroup,{m_think[1][1], m_think[1][2]})
	table.insert(feiGroup,{m_think[3][1], m_think[3][2]})

	feiData.feiGroup = feiGroup

	-- 飞牌
	local roomPlayer = self.roomPlayers[seatIdx]
	table.insert(roomPlayer.mjTileFeis, feiData)

	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 显示飞牌
	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	local groupNode = cc.Node:create()
	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	self.playMjLayer:addChild(groupNode)

	for i = 1, 3 do
		local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, tonumber(feiGroup[i][1]), tonumber(feiGroup[i][2]))
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[i])
		mjTileSpr:setTag(i)
		if i == 2 then
			mjTileSpr:setColor(cc.c3b(255,255,100))
		end
		groupNode:addChild(mjTileSpr)
	end

	feiData.groupNode = groupNode

	-- 飞牌动画
	self:showDecisionAnimation(seatIdx, gt.DecisionType.FEI)
	-- 移除上家打出的牌
	self:removePrePlayerOutMjTile( m_think[2][1], m_think[2][1])
	for idx=1,2 do
		local num = #roomPlayer.holdMjTiles
		for i=num,1,-1 do
			if roomPlayer.holdMjTiles[i].mjColor == m_think[idx][1] and roomPlayer.holdMjTiles[i].mjNumber == m_think[idx][2] then
				gt.log("mjTile.mjColor:"..roomPlayer.holdMjTiles[i].mjColor)
				gt.log("mjTile.mjNumber:"..roomPlayer.holdMjTiles[i].mjNumber)
				roomPlayer.holdMjTiles[i].mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles,i)
				break
			end
		end
	end

	mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
	mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

	-- 重新排序现持有牌
	self:sortHoldMjTiles( roomPlayer )
end

-- 飞变提
function PlayManager_Base:changeFeiToTi( seatIdx, mThink )
	dump(mThink)
	local roomPlayer = self.roomPlayers[seatIdx]
	local  mjColor = mThink[2][1]
	local  mjNumber = mThink[2][2]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos

	for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
			mjTile.mjTileSpr:removeFromParent()
			table.remove(roomPlayer.holdMjTiles, i)
			break
		end
	end

	local mjTilePos = mjTilesReferPos.holdStart

	local color = mThink[1][1]
	local number = mThink[1][2]
	gt.log("提牌"..color..number)
	local mjTile = self:addMjTile(roomPlayer,color, number)
	mjTile.mjTileSpr:setPosition(mjTilePos)
	self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))

	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	-- 删除飞牌
	for i, pungData in ipairs(roomPlayer.mjTileFeis) do
		if pungData.mjColor == mjColor and pungData.mjNumber == mjNumber then
			-- 从飞牌列表中删除
			--pungData.groupNode:removeFromParent()
			local title = pungData.groupNode:getChildByTag(2)
			local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, tonumber(mjColor), tonumber(mjNumber))
			gt.log("mjTileName:"..mjTileName)
			title:setSpriteFrame(mjTileName)
			title:setColor(cc.c3b(255,255,255))

			table.remove(roomPlayer.mjTileFeis, i)
			table.insert(roomPlayer.mjTilePungs, pungData)
			break
		end
	end

	self:showDecisionAnimation(seatIdx, gt.DecisionType.TI)

	self:sortHoldMjTiles( roomPlayer )
end
-- 挑
function PlayManager_Base:changeTiao( seatIdx, mThink )
	local roomPlayer = self.roomPlayers[seatIdx]
	local  mjColor = mThink[2][1]
	local  mjNumber = mThink[2][2]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- if seatIdx == self.playerSeatIdx then
		for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
			if mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
				mjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles, i)
				break
			end
		end

		local mjTilePos = mjTilesReferPos.holdStart

		local color = mThink[1][1]
		local number = mThink[1][2]
		local mjTile = self:addMjTile(roomPlayer, color, number)
		mjTile.mjTileSpr:setPosition(mjTilePos)
		self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
	-- end

	-- 删除挑牌
	gt.dump(roomPlayer.mjTileBrightBars)
	gt.dump(roomPlayer.mjTileDarkBars)
	for i,BarData in ipairs(roomPlayer.mjTileBrightBars) do
		if tonumber(BarData.mjColor) == tonumber(mjColor) and tonumber(BarData.mjNumber) == tonumber(mjNumber) then
				local title = BarData.groupNode:getChildByTag(4)
				local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, tonumber(BarData.mjColor), tonumber(BarData.mjNumber))
				gt.log(mjTileName)
				title:setSpriteFrame(mjTileName)
				title:setColor(cc.c3b(255,255,255))
    end
	end
	for i,BarData in ipairs(roomPlayer.mjTileDarkBars) do
		if tonumber(BarData.mjColor) == tonumber(mjColor) and tonumber(BarData.mjNumber) == tonumber(mjNumber) then
				local title = BarData.groupNode:getChildByTag(4)
				local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, tonumber(BarData.mjColor), tonumber(BarData.mjNumber))
				gt.log(mjTileName)
				title:setSpriteFrame(mjTileName)
				title:setColor(cc.c3b(255,255,255))
    end
	end
	self:showDecisionAnimation(seatIdx, gt.DecisionType.TIAO)
	self:sortHoldMjTiles( roomPlayer )
end
function PlayManager_Base:showPiaoImage( mThink )
	gt.dump(mThink)
	for i=1,4 do
		local roomPlayer = self.roomPlayers[i]
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
		local Spr_piao = gt.seekNodeByName(playerInfoNode,"Spr_piao")
		if mThink[i][1] == 2 then
			Spr_piao:setVisible(true)
		else
			Spr_piao:setVisible(false)
		end
	end
end
function PlayManager_Base:showPiaoNumImage( mThink )
	gt.dump(mThink)
	for i=1,4 do
		local roomPlayer = self.roomPlayers[i]
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
		local Spr_piao = gt.seekNodeByName(playerInfoNode,"Spr_piao")
		if mThink[i][1] > 0 then
			Spr_piao:setVisible(true)
			local string = "x"..mThink[i][1]
			local label = gt.createTTFLabel(string, 28)
	    	label:setPositionX(20)
	    	Spr_piao:addChild(label)
		else
			Spr_piao:setVisible(false)
		end
	end
end
function PlayManager_Base:hidePiaoImage( )
	for i=1,4 do
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local Spr_piao = gt.seekNodeByName(playerInfoNode,"Spr_piao")
		Spr_piao:setVisible(false)
	end
end


function PlayManager_Base:addFanFanJinCard( m_FanPiGu )
	local h = 580
	if display.autoscale == "FIXED_HEIGHT" then
		h = 720
	end
	self.WanNengPaiCarTable = {}
	for i, v in ipairs(m_FanPiGu) do
		if v[1] ~= 0 and v[2] ~= 0 then
			local mjTileName = string.format(gt.MJSprFrameOut, 4, v[1], v[2])
			local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
			if i == 2 then
				mjTileSpr:setPosition( cc.p(55 * i, h) )
				
			elseif i == 3 then
				mjTileSpr:setPosition( cc.p(55 * i, h) )
				mjTileSpr:setColor(cc.c3b(255,255,100))
				table.insert( self.WanNengPaiCarTable, v )
			else
				mjTileSpr:setPosition( cc.p(55 * i, h) )
				mjTileSpr:setColor(cc.c3b(255,255,100))
				table.insert( self.WanNengPaiCarTable, v )
			end
			
			self.playMjLayer:addChild(mjTileSpr)
		end
	end

	for _, roomPlayer in ipairs(self.roomPlayers) do
		local num = #roomPlayer.holdMjTiles
		for i=num,1,-1 do
			for j,wan in ipairs(self.WanNengPaiCarTable) do
				if roomPlayer.holdMjTiles[i].mjColor == wan[1] and roomPlayer.holdMjTiles[i].mjNumber == wan[2] then
					roomPlayer.holdMjTiles[i].mjTileSpr:setColor(cc.c3b(255,255,100))
					break
				end
			end
		end
		self:sortHoldMjTiles(roomPlayer)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 杠牌
-- @param seatIdx 座位编号
-- @param mjColor 花色
-- @param mjNumber 编号
-- @param isBrightBar 明杠或者暗杠
-- end --
function PlayManager_Base:addMjTileBar(seatIdx, cardList, isBrightBar)
	gt.log("function is addMjTileBar-------------------")
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 加入到列表中
	local barData = {}
	barData.mjColor = cardList[1][1]
	barData.mjNumber = cardList[1][2]
	if isBrightBar then
		-- 明杠
		table.insert(roomPlayer.mjTileBrightBars, barData)
	else
		-- 暗杠
		table.insert(roomPlayer.mjTileDarkBars, barData)
	end

	barData.groupNode = self:pungBarReorderMjTiles(roomPlayer, cardList[1][1], cardList[1][2], true, isBrightBar, cardList)
end


function PlayManager_Base:getPlayerMjTilesReferPos(displayIdx)
	local mjTilesReferPos = {}

	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	local mjTilesReferNode = gt.seekNodeByName(playNode, "Node_playerMjTiles_" .. displayIdx)

	-- 持有牌数据
	local mjTileHoldSprF = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_1")
	local mjTileHoldSprS = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_2")
	mjTilesReferPos.holdStart = cc.p(mjTileHoldSprF:getPosition())
	mjTilesReferPos.holdSpace = cc.pSub(cc.p(mjTileHoldSprS:getPosition()), cc.p(mjTileHoldSprF:getPosition()))

	-- 摸牌偏移
	local drawSpaces = {{x = -16,	y = 0},
						{x = 0,		y = -16},
						{x = 16,	y = 0},
						{x = 32,	y = 0}}
	mjTilesReferPos.drawSpace = drawSpaces[displayIdx]

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
	if displayIdx == 1 or displayIdx == self.playerNum - 1 then
		mjTilesReferPos.groupSpace = cc.p(0, groupSize.height + 8)
		if displayIdx == self.playerNum - 1 then
			mjTilesReferPos.groupSpace.y = -mjTilesReferPos.groupSpace.y
		end
	else
		mjTilesReferPos.groupSpace = cc.p(groupSize.width + 8, 0)
		if displayIdx == 2 then
			mjTilesReferPos.groupSpace.x = -mjTilesReferPos.groupSpace.x
		end
	end

	-- 当前出牌展示位置
	local showMjTileNode = gt.seekNodeByName(mjTilesReferNode, "Node_showMjTile")
	mjTilesReferPos.showMjTilePos = cc.p(showMjTileNode:getPosition())

	return mjTilesReferPos
end

-- start --
--------------------------------
-- @class function
-- @description 玩家麻将牌根据花色，编号重新排序
-- end --
function PlayManager_Base:sortHoldMjTiles(roomPlayer)
	-- local roomPlayer = self.roomPlayers[seatIdx]

	-- 玩家持有牌不能看,不用排序
	if not roomPlayer.isHidden then
		-- 按照花色分类
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

		local dingqueTable = {}
		for i = #transMjTiles, 1, -1 do
			local mj = transMjTiles[i]
			for j,wan in ipairs(self.WanNengPaiCarTable) do
				if mj.mjColor == wan[1] and mj.mjNumber == wan[2] then
					table.insert(dingqueTable,1,mj)
					table.remove(transMjTiles,i)
				end
			end
		end

		for k,v in pairs(dingqueTable) do
			table.insert(transMjTiles, 1, v)
		end
	
		roomPlayer.holdMjTiles = transMjTiles
	end

	-- 更新摆放位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		-- dump(mjTilePos)
		mjTile.mjTileSpr:setPosition(mjTilePos)
		self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
		mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
	end
end

function PlayManager_Base:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, mjTilesCount, cancleSort)
	gt.log("function = removeHoldMjTiles")
	local transMjTiles = {}
	local count = 0
	gt.log("roomPlayer.holdMjTiles = ")
	gt.dump(roomPlayer.holdMjTiles)
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if roomPlayer.isHidden then
			if count < mjTilesCount then
				mjTile.mjTileSpr:removeFromParent()
				count = count + 1
			else
				table.insert(transMjTiles, mjTile)
			end
		else
			if count < mjTilesCount and mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
				mjTile.mjTileSpr:removeFromParent()
				count = count + 1
			else
				-- 保存其它牌
				table.insert(transMjTiles, mjTile)
			end
		end
	end
	roomPlayer.holdMjTiles = transMjTiles
	
	if not cancleSort then
		self:sortHoldMjTiles(roomPlayer)
	end
end

function PlayManager_Base:replaceThreeCardData(holdMjTiles,replaceThreeCard,replaceThreeCard_new)
	for j = 1 , 3  do
		for i = 1, #holdMjTiles do
			if replaceThreeCard[j][1] and tonumber(holdMjTiles[i][1]) == tonumber(replaceThreeCard[j][1]) and replaceThreeCard[j][2] and tonumber(holdMjTiles[i][2]) == replaceThreeCard[j][2] then
				table.remove(holdMjTiles,i)
				--table.insert(holdMjTiles,replaceThreeCard_new[i])
				break
			end
			
		end
	end
	for i = 1, 3 do
		table.insert(holdMjTiles,replaceThreeCard_new[i])
	end
	return holdMjTiles
end

--换三张有动作
function PlayManager_Base:replaceThreeCard(seatIdx,replaceThreeCard,replaceThreeCard_new,isQuick)
	gt.log("function = replaceThreeCard")
	gt.log("开始换三张 。。。。。。。。。。 " .. seatIdx)
	dump(replaceThreeCard)
	gt.log("开始换三张 。。。。。tttt。。。。。 ")
	dump(replaceThreeCard_new)
	local roomPlayer = self.roomPlayers[seatIdx]

	self.ChooseTable = {}

	for i = 1, #replaceThreeCard do
		self["num" .. i] = 0
		for j = 1, 3 do
			if replaceThreeCard[i][1] == replaceThreeCard[j][1] and replaceThreeCard[i][2] == replaceThreeCard[j][2] then
				self["num" .. i] = self["num" .. i] + 1
			end
		end
	end

	for i = 1, 3 do
		self["index" .. i] = 1
		table.insert(replaceThreeCard[i], self["num" .. i])
	end

	local index = 0
	for j = 1 , 3  do
		for i,v in pairs(roomPlayer.holdMjTiles) do
	
			if  self:isChooseTable(self.ChooseTable, v.mjColor, v.mjNumber) and tonumber(v.mjColor) == tonumber(replaceThreeCard[j][1]) and tonumber(v.mjNumber) == replaceThreeCard[j][2] then
				
				table.insert(self.ChooseTable,{v.mjColor, v.mjNumber, replaceThreeCard[j][3]})
				
				local mjTilePos = cc.p(v.mjTileSpr:getPosition())
				local mjPos = cc.p(mjTilePos.x, mjTilePos.y)
				local moveAction = nil
				
				if roomPlayer.displayIdx == 4 then
					moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 120))
				elseif roomPlayer.displayIdx ==  3 then
					moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x + 80, mjTilePos.y))
				elseif roomPlayer.displayIdx == 2 then			
					moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 80))
				elseif roomPlayer.displayIdx == 1 then
					moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x - 80, mjTilePos.y))
				end

				local function moveCallBack()
					index = index + 1
					local mjTileSpr = nil
					if roomPlayer.displayIdx == 4 then
						mjTileSpr = cc.Sprite:createWithSpriteFrameName(string.format(gt.MJSprFrame, 4, replaceThreeCard_new[index][1], replaceThreeCard_new[index][2]))
					else
						
						mjTileSpr = cc.Sprite:createWithSpriteFrameName(string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, replaceThreeCard_new[index][1], replaceThreeCard_new[index][2]))
					end

					self.playMjLayer:addChild(mjTileSpr)
					mjTileSpr:setPosition(mjTilePos.x, mjTilePos.y)
					mjTileSpr:setZOrder(v.mjTileSpr:getZOrder())
					v.mjTileSpr:setVisible(false)
					self:removeHoldMjTiles(roomPlayer, v.mjColor, v.mjNumber, 1, true)

					local mjTile = {}
					mjTile.mjTileSpr = mjTileSpr
					mjTile.mjColor = replaceThreeCard_new[index][1]
					mjTile.mjNumber = replaceThreeCard_new[index][2]
					table.insert(roomPlayer.holdMjTiles, mjTile)
					

					local function  moveToCallBack()
						self:sortHoldMjTiles(roomPlayer)
					end
					
					mjTileSpr:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.MoveTo:create(0.25, mjPos), cc.CallFunc:create(moveToCallBack)))
					
				end
				v.mjTileSpr:runAction(cc.Sequence:create(moveAction,cc.DelayTime:create(1), cc.CallFunc:create(moveCallBack)))
				
			end
			
		end
	end
end


function PlayManager_Base:isChooseTable(ChooseTable, mjColor, mjNumber)
	for i = 1, #self.ChooseTable do
		if #self.ChooseTable[i] > 0 and self.ChooseTable[i][1] == mjColor and self.ChooseTable[i][2] == mjNumber then
			if self.ChooseTable[i][3] > self["index" .. i] then
				self["index" .. i] = self["index" .. i] + 1
				return true
			else
				return false
				
			end
		end
	end
	return true
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
function PlayManager_Base:pungBarReorderMjTiles(roomPlayer, mjColor, mjNumber, isBar, isBrightBar, cardList)
	-- local roomPlayer = self.roomPlayers[seatIdx]
	gt.log("function is pungBarReorderMjTiles")
	gt.dump(cardList)
	local groupNode = nil
	local isEat = false
	if type(roomPlayer) == "number" then
		roomPlayer = self.roomPlayers[roomPlayer]
		isEat = true
	end

	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 显示碰杠牌
	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	groupNode = cc.Node:create()
	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	self.playMjLayer:addChild(groupNode)
	local mjTilesCount = 3
	if isBar then
		mjTilesCount = 4
	end
	if isEat == true then
		for i = 1, mjTilesCount do
			local mjTileName = string.format(self.pdsdd_img, roomPlayer.displayIdx, mjNumber[i][3], mjNumber[i][1])
			local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
			mjTileSpr:setPosition(groupMjTilesPos[i])
			groupNode:addChild(mjTileSpr)
		end
		mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
		mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

		-- 更新持有牌
		self:removeHoldMjTiles(roomPlayer, mjNumber[1][3], mjNumber[1][1], 1)
		self:removeHoldMjTiles(roomPlayer, mjNumber[3][3], mjNumber[3][1], 1)
	else
		for i = 1, mjTilesCount do
			local mjTileName = string.format(self.pdsdd_img, roomPlayer.displayIdx, cardList[i][1], cardList[i][2])
			if isBar and not isBrightBar and i <= 3 then
				-- 暗杠前三张牌扣着
				if i == 1 and self.playType == 204 then
					mjTileName = string.format(self.pdsdd_img, roomPlayer.displayIdx, cardList[i][1], cardList[i][2])
				else
					mjTileName = string.format(self.tdbgsd_img, roomPlayer.displayIdx)
				end
			end
			local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
            mjTileSpr.cardData = cardList[i]
			mjTileSpr:setPosition(groupMjTilesPos[i])
            mjTileSpr:setTag(i)
			groupNode:addChild(mjTileSpr)
		end
		mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
		mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

		-- 更新持有牌
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
		-- self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, mjTilesCount)
		local num = #cardList
		local removeNum = 0
		for i=1,num do
			for idx, mjTile in ipairs(roomPlayer.holdMjTiles) do
				if removeNum < mjTilesCount and mjTile.mjColor == cardList[i][1] and mjTile.mjNumber == cardList[i][2] then
					removeNum = removeNum + 1
					mjTile.mjTileSpr:removeFromParent()
					table.remove( roomPlayer.holdMjTiles, idx )
					break
				end
			end
		end

		self:sortHoldMjTiles(roomPlayer)
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
function PlayManager_Base:changePungToBrightBar(seatIdx, mjColor, mjNumber, cardList)
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 从持有牌中移除
	self:removeHoldMjTiles(roomPlayer, cardList[4][1], cardList[4][2], 1)

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

	-- 添加到明杠列表
	if brightBarData then
		-- 加入杠牌第4个牌
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
		local mjTileName = string.format(self.pdsdd_img, roomPlayer.displayIdx, cardList[4][1], cardList[4][2])
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[4])
    mjTileSpr:setTag(4)
		brightBarData.groupNode:addChild(mjTileSpr)
		table.insert(roomPlayer.mjTileBrightBars, brightBarData)
	end
end


-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlayManager_Base:removePrePlayerOutMjTile(mjColor, mjNumber)
	-- 移除上家打出的牌
	if self.prePlaySeatIdx then
		local roomPlayer = self.roomPlayers[self.prePlaySeatIdx]
		local endIdx = #roomPlayer.outMjTiles
		if endIdx > 0 then
			gt.log("====-----5555----" .. endIdx)
			local outMjTile = roomPlayer.outMjTiles[endIdx]
			gt.log("mjColor = "..tonumber(mjColor).."mjNumber = "..tonumber(mjNumber).."endIdx = "..endIdx)
			gt.dump(roomPlayer.outMjTiles)
			if tonumber(roomPlayer.outMjTiles[endIdx].mjColor) == tonumber(mjColor) and tonumber(roomPlayer.outMjTiles[endIdx].mjNumber) ==  tonumber(mjNumber) then
				gt.log("进行删除操作")
				outMjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.outMjTiles, endIdx)
				-- 隐藏出牌标识箭头
				self.outMjtileSignNode:setVisible(false)
			end
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家接炮胡，自摸胡，明杠，暗杠，碰动画显示
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlayManager_Base:showDecisionAnimation(seatIdx, decisionType)
	gt.log("44444444444pppp")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("images/changshamjbtn.plist")
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 四川麻将  杠就是刮风下雨
	if decisionType == gt.DecisionType.BRIGHT_BAR or 
	   decisionType == gt.DecisionType.BRIGHT_BU or decisionType == gt.DecisionType.DARK_BAR or 
	       decisionType == gt.DecisionType.DARK_BU then
	   		local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_2.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, 1000)
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

		gt.soundManager:PlaySpeakSound(roomPlayer.sex, "gang", roomPlayer)

	elseif decisionType == gt.DecisionType.TAKE_CANNON_WIN or
		   decisionType == gt.DecisionType.SELF_DRAWN_WIN then
	   	-- 胡牌动画 现在只有一个胡的标志
	   	gt.log("==================444========66=7=87=89==")
	   	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_1.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, 1000)
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
		if decisionType == gt.DecisionType.TAKE_CANNON_WIN then
			gt.soundManager:PlaySpeakSound(roomPlayer.sex, "hu", roomPlayer)
		else
			gt.soundManager:PlaySpeakSound(roomPlayer.sex, "zimo", roomPlayer)
		end
	elseif decisionType == gt.DecisionType.FEI  then
		--fei
		local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("playScene81.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, 1000)
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
		gt.soundManager:PlaySpeakSound(roomPlayer.sex, "fei", roomPlayer)
	elseif decisionType == gt.DecisionType.TI  then
		--fei
		local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("playScene82.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, 1000)
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
		gt.soundManager:PlaySpeakSound(roomPlayer.sex, "ti", roomPlayer)
	elseif decisionType == gt.DecisionType.TIAO then
	   	-- 挑
	   	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_10.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, gt.PlayZOrder.DECISION_SHOW)
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
	else
		--其他  碰 四川麻将这里就只有碰了
	   	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName("decision_sign_cs_3.png")
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, 1000)
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
-- @description 展示杠两张牌
-- end --
function PlayManager_Base:showBarTwoCardAnimation(seatIdx,cardList,isQuick)
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
	self.rootNode:addChild(image_bg,gt.PlayZOrder.HAIDILAOYUE)
	image_bg:setScale(0)
	-- 设置坐标位置
	local  m_curPos_x = 1
	local  m_curPos_y = 1
	if roomPlayer.displayIdx == 1 or roomPlayer.displayIdx == 3 then
		m_curPos_x = roomPlayer.mjTilesReferPos.holdStart.x
		m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
	elseif roomPlayer.displayIdx == 2 or roomPlayer.displayIdx == 4 then
		m_curPos_x = roomPlayer.mjTilesReferPos.showMjTilePos.x
		m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
	end

	-- image_bg:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	image_bg:setPosition(cc.p(m_curPos_x,m_curPos_y))

	-- 添加两个麻将
	gt.log("添加两个麻将")
	dump(cardList)
	for _,v in pairs(cardList) do
		gt.log("88888888888")
		gt.log(v[1])
		gt.log(v[2])
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

	if isQuick then
		-- 快进快退
		self:discardsOneCard(seatIdx,cardList[1][1], cardList[1][2])
		self:discardsOneCard(seatIdx,cardList[2][1], cardList[2][2])
		image_bg:removeFromParent()
	else
		local seqAction = cc.Sequence:create(easeBackAction, present_delayTime, fadeOutAction, callFunc_dontPresent,
			callFunc_present_first, delayTime_f_s, callFunc_present_second,callFunc_remove)
		image_bg:runAction(seqAction)
	end
end

function PlayManager_Base:discardsOneCard(seatIdx,mjColor,mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart

	-- 显示出的牌
	self:outMjTile(roomPlayer, mjColor, mjNumber)
	-- 显示出的牌箭头标识
	self:showOutMjtileSign(roomPlayer)

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
function PlayManager_Base:showStartDecisionAnimation(seatIdx, decisionType, showCard)
	-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
	local decisionSuffixs = {1, 4, 2, 2, 3}
	local decisionSfx = {"queyise", "banbanhu", "sixi", "liuliushun"}
	-- 显示决策标识
	local roomPlayer = self.roomPlayers[seatIdx]
	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("tile_cs_%s.png", decisionSfx[decisionType]))
	decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	self.rootNode:addChild(decisionSignSpr, gt.PlayZOrder.DECISION_SHOW)
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
	local demoSpr = cc.Sprite:createWithSpriteFrameName(string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, 1, 1))
	local tileWidthX = 0
	local tileWidthY = 0
	if roomPlayer.displayIdx == 1 then
		tileWidthX = 0
		tileWidthY = mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displayIdx == 2 then
		tileWidthX = -demoSpr:getContentSize().width
		tileWidthY = 0
	elseif roomPlayer.displayIdx == 3 then
		tileWidthX = 0
		tileWidthY = -mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displayIdx == 4 then
		tileWidthX = demoSpr:getContentSize().width
		tileWidthY = 0
	end

	-- 服务器返回消息
	local totalWidthX = (#showCard)*tileWidthX
	local totalWidthY = (#showCard)*tileWidthY

	for i,v in ipairs(showCard) do
		local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, v[1], v[2])
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

	-- 播放音效,没有资源,暂时用暗杠来代替
	-- dj revise
	gt.soundManager:PlaySpeakSound(roomPlayer.sex, decisionSfx[decisionType])

end

-- start --
--------------------------------
-- @class function
-- @description 狼起牌
-- @param seatIdx 座位编号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --
function PlayManager_Base:addMjTileLang(seatIdx, cardList)
	local roomPlayer = self.roomPlayers[seatIdx]

	for i = 2, #cardList do
		local pungData = {}
		pungData.mjColor = cardList[i][1]
		pungData.mjNumber = cardList[i][2]
		table.insert(roomPlayer.langMjTiles, pungData)
	end
	
	self:langReorderMjTiles(roomPlayer)
	--pungData.groupNode = self:langReorderMjTiles(roomPlayer, cardList[1][1], cardList[1][2], false, false, cardList)
end

-- start --
--------------------------------
-- @class function
-- @description 狼起重新排序麻将牌，显示狼起
-- @param seatIdx
-- @param mjColor
-- @param mjNumber
-- @param isBar
-- @param isBrightBar
-- @return
-- end --
function PlayManager_Base:langReorderMjTiles(roomPlayer)
		--local roomPlayer = self.roomPlayers[seatIdx]
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		-- 显示碰杠牌
		local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
		local groupNode = cc.Node:create()
		groupNode:setPosition(mjTilesReferPos.groupStartPos)
		self.playMjLayer:addChild(groupNode)
		
		local mjTileName = string.format("p%ds1_1.png", roomPlayer.displayIdx)
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)

		local mjTileName = nil
		local x = groupMjTilesPos[1].x
		local y = groupMjTilesPos[1].y
		if roomPlayer.displayIdx == 1 then
			y = groupMjTilesPos[3].y
		end
	
		gt.log("===d==f=d===fd==f=d=f==f==f==" .. #roomPlayer.langMjTiles)
		gt.dump(roomPlayer.langMjTiles)

		for i, mjTile in ipairs(roomPlayer.langMjTiles) do
			local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, roomPlayer.langMjTiles[i].mjColor, roomPlayer.langMjTiles[i].mjNumber)
			local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
			mjTileSpr:setPosition(cc.p(x, y))
			mjTileSpr:setColor(cc.c3b(255,255,100))
			groupNode:addChild(mjTileSpr)

			if roomPlayer.displayIdx == 4 then
				x = x + mjTileSpr:getContentSize().width
			elseif roomPlayer.displayIdx == 3 then
				y = y - mjTileSpr:getContentSize().height * 0.7
			elseif roomPlayer.displayIdx == 2 then
				x = x - mjTileSpr:getContentSize().width
			elseif roomPlayer.displayIdx == 1 then
				y = y + mjTileSpr:getContentSize().height * 0.7
				mjTileSpr:setZOrder(500 - i*10)
			end
		end

 		if roomPlayer.displayIdx == 4 then
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, cc.p(#roomPlayer.langMjTiles * mjTileSpr:getContentSize().width + 10, 0))
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, cc.p(#roomPlayer.langMjTiles * mjTileSpr:getContentSize().width + 10, 0))
		elseif roomPlayer.displayIdx == 3 then
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, cc.p(0, -#roomPlayer.langMjTiles * mjTileSpr:getContentSize().height * 0.9))
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, cc.p(0, -#roomPlayer.langMjTiles * mjTileSpr:getContentSize().height * 0.7))
		elseif roomPlayer.displayIdx == 2 then
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, cc.p(-#roomPlayer.langMjTiles * mjTileSpr:getContentSize().width - 10, 0))
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, cc.p(-#roomPlayer.langMjTiles * mjTileSpr:getContentSize().width, 0))
		elseif roomPlayer.displayIdx == 1 then
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, cc.p(0,#roomPlayer.langMjTiles * mjTileSpr:getContentSize().height * 0.9))
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, cc.p(0, #roomPlayer.langMjTiles * mjTileSpr:getContentSize().height * 0.75))
		end

		-- 更新持有牌显示位置
	
	
	if roomPlayer.seatIdx == self.playerSeatIdx then
		self.isLangDecision = false
		roomPlayer.isLangSelectedState = true
	
		-- for i, langTile in ipairs(roomPlayer.langMjTiles) do
		-- 	for j, mjTile in ipairs(roomPlayer.holdMjTiles) do
		-- 		if roomPlayer.langMjTiles[i].mjNumber == mjTile.mjNumber and roomPlayer.langMjTiles[i].mjColor == mjTile.mjColor then
		-- 			mjTile.mjTileSpr:removeFromParent()
		-- 			table.remove(roomPlayer.holdMjTiles, j)
		-- 			break
		-- 		end
		-- 	end
		-- end
		-- 重新排序现持有牌
		--self:sortPlayerMjTiles()

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
-- @description 显示指示出牌标识箭头动画
-- @param seatIdx 座次
-- end --
function PlayManager_Base:showOutMjtileSign(roomPlayer)
	-- local roomPlayer = self.roomPlayers[seatIdx]
	local endIdx = #roomPlayer.outMjTiles
	local outMjTile = roomPlayer.outMjTiles[endIdx]
	self.outMjtileSignNode:setVisible(true)
	self.outMjtileSignNode:setPosition(outMjTile.mjTileSpr:getPosition())
end

-- start --
--------------------------------
-- @class function
-- @description 显示出牌动画
-- @param seatIdx 座次
-- end --
function PlayManager_Base:showOutMjTileAnimation(roomPlayer, mjColor, mjNumber, cbFunc)
	local rotateAngle = {-90, 180, 90, 0}

	local mjTileName = nil
	if self.playerNum == 3 then
		mjTileName = string.format(gt.SR_SelfMJSprFrameOut, mjColor, mjNumber)
	elseif self.playerNum == 4 then
		mjTileName = string.format(gt.SelfMJSprFrameOut, mjColor, mjNumber)
	elseif self.playerNum == 2 then
		mjTileName = string.format(gt.SelfMJSprFrameOut, mjColor, mjNumber)
	end
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.rootNode:addChild(mjTileSpr, 98)

	-- 出牌位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
	mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.drawSpace)
	mjTileSpr:setPosition(mjTilePos)
	mjTileSpr:setRotation(rotateAngle[roomPlayer.displayIdx])
	local moveToAc_1 = cc.MoveTo:create(0.3, roomPlayer.mjTilesReferPos.showMjTilePos)
	local rotateToAc_1 = cc.RotateTo:create(0.15, 0)

	local delayTime = cc.DelayTime:create(0.3)

	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	local mjTilesCount = #roomPlayer.outMjTiles + 1
	local lineCount = math.ceil(mjTilesCount / 10) - 1
	local lineIdx = mjTilesCount - lineCount * 10 - 1
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))

	local moveToAc_2 = cc.MoveTo:create(0.3, mjTilePos)
	local rotateToAc_2 = cc.RotateTo:create(0.15, rotateAngle[roomPlayer.displayIdx])
	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()

		cbFunc()
	end)
	mjTileSpr:runAction(cc.Sequence:create(cc.Spawn:create(moveToAc_1, rotateToAc_1),
										delayTime,
										cc.Spawn:create(moveToAc_2, rotateToAc_2),
										callFunc));
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家定缺
-- @param seatIdx 座次
-- end --
function PlayManager_Base:showDingQueWithSeatIndex( seatIdx, mjColor)
	gt.log("显示玩家定缺")
	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	local Sp_dingque = gt.seekNodeByName(playerInfoNode,"Sp_dingque")
	Sp_dingque:setVisible(true)
	local imgName = "playScene46.png"
	if mjColor == 1 then
		imgName = "playScene46.png"
	elseif mjColor == 2 then
		imgName = "playScene44.png"
	elseif mjColor == 3 then
		imgName = "playScene42.png"
	end
	Sp_dingque:setSpriteFrame(imgName)
end


--除去抢杠胡的牌
function PlayManager_Base:onRecUserRemoveBarCard(seatIdx,m_color,m_number)
	gt.log("function = onRecUserRemoveBarCard")
	if self.qianGangSeatIdx then
		local roomPlayer = self.roomPlayers[self.qianGangSeatIdx]
		dump(roomPlayer.holdMjTiles)
		for k,v in pairs(roomPlayer.holdMjTiles) do

			if m_color == v.mjColor and m_number == v.mjNumber then
				local mjTile = roomPlayer.holdMjTiles[k]
				if mjTile then
					mjTile.mjTileSpr:removeFromParent()
					table.remove(roomPlayer.holdMjTiles, k)
				end
				self:sortHoldMjTiles(roomPlayer)
				break
			end
		end
	end
end

function PlayManager_Base:dismissRoom()
	if self.dismissTag and gt.isGM == 1 then
		self.dismissTag:setVisible(true)
	else
		self.dismissTag:setVisible(false)
	end
end
-- start --
--------------------------------
-- @class function
-- @description 显示玩家胡牌的标志和胡的牌 
-- @param seatIdx 座次
-- @param winType 自摸还是接炮
-- end --
function PlayManager_Base:showPalyerWinCard( seatIdx, mjColor, mjNumber,winType, isQuick, isQiangG, isGangHua)
	gt.log("================================================11===")
	gt.log("luxiang hupai seatIdx is  ... " .. seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 添加胡牌标志
	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	hutypeNode:setVisible(true)
	self.rootNode:reorderChild(hutypeNode, 800)

	gt.log("luxiang hupai displayIdx is  ... " .. roomPlayer.displayIdx)

	local huType = gt.seekNodeByName(hutypeNode, "huType" .. roomPlayer.displayIdx)
	huType:setContentSize(cc.size(62,53))
	huType:setVisible(true)

	--winType   接炮胡
	if winType then
		if not isQiangG then
			-- 移除上家打出的牌
			self:removePrePlayerOutMjTile(mjColor, mjNumber)
		end
		huType:loadTexture("playScene_hu.png",1)
		huType:setContentSize(cc.size(71,38))
	else
		--点杠胡
		if isGangHua then
			huType:loadTexture("playScene_hu.png",1)
			huType:setContentSize(cc.size(71,38))
		else --自摸胡
			huType:loadTexture("playScene_zimo.png",1)
			huType:setContentSize(cc.size(71,38))
		end
	end

	if winType then
		-- 添加牌放在末尾
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local mjTilePos = mjTilesReferPos.holdStart
		mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
		mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.drawSpace)

		local mjTile = self:addMjTile(roomPlayer, mjColor, mjNumber)
		mjTile.mjTileSpr:setPosition(mjTilePos)
		self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
	else
		-- 把胡的牌亮出来
		for i,mjTile in ipairs(roomPlayer.holdMjTiles) do
			if mjTile.mjColor == color and mjTile.mjNumber == number then
				mjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles, i)
				self:sortHoldMjTiles(roomPlayer)

				-- 添加牌放在末尾
				local mjTilesReferPos = roomPlayer.mjTilesReferPos
				local mjTilePos = mjTilesReferPos.holdStart
				mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
				mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))

				gt.log("isboolBreak == true"..mjTilePos.x..mjTilePos.y.."胡牌"..color..number)
				local mjTile = self:addMjTileToPlayer(color, number)
				mjTile.mjTileSpr:setPosition(mjTilePos)
				self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
				break
			end
		end
	end
end

