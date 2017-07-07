local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerNeiJiang = gt.PlayManager_Base:new()
gt.PlayManagerNeiJiang = PlayManagerNeiJiang

function PlayManagerNeiJiang:new(rootNode, paramTbl,o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self:ctor(rootNode, paramTbl, (paramTbl.roomState == 118) and 3 or 4)
    self:resetMjTileFrameNames()
    self:resetTurnPos()
    self:adjustUIfor3People()
    self:adjustUIfor7Pai(paramTbl)
    return o
end

--color表玩家位置，number代表选择，0不报叫，1报叫
function PlayManagerNeiJiang:setBaoJiaoTile(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	local spr_baojiao = gt.seekNodeByName(playerInfoNode, "Spr_baojiao")
	if mjNumber == 1 then
		spr_baojiao:setVisible(true)
	else
		spr_baojiao:setVisible(false)
	end
end

function PlayManagerNeiJiang:adjustUIfor7Pai(paramTbl)
    if not table.contains(paramTbl.m_playtype, 35) then return end

    local _holdOffsetTbl = {
        {0, 100},
        {-150, 0},
        {0, -100},
        {250, 0}
    }

    dump(_holdOffsetTbl)
    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerMjTiles_#1#4", "Spr_mjTileHold_1", "Spr_mjTileHold_2", "Panel_mjTileGroup"})
    _nodeList:dump()

    for i=1, 4 do
        local _n1 = _nodeList["Node_playerMjTiles_" .. i].Spr_mjTileHold_1
        local _n2 = _nodeList["Node_playerMjTiles_" .. i].Spr_mjTileHold_2
        local _n3 = _nodeList["Node_playerMjTiles_" .. i].Panel_mjTileGroup

        _n1:setPosition(cc.pAdd(cc.p(_n1:getPosition()), cc.p(unpack(_holdOffsetTbl[i]))))
        _n2:setPosition(cc.pAdd(cc.p(_n2:getPosition()), cc.p(unpack(_holdOffsetTbl[i]))))
        _n3:setPosition(cc.pAdd(cc.p(_n3:getPosition()), cc.p(unpack(_holdOffsetTbl[i]))))
    end

    local _nodeList = gt.findNodeArray(self.rootNode, {"Node_playerInfo_4", "Node_ReplayBtn"})
    _nodeList.Node_playerInfo_4:setPositionY(_nodeList.Node_playerInfo_4:getPositionY() - 100)
    _nodeList.Node_playerInfo_4.Node_ReplayBtn:setPositionY(_nodeList.Node_playerInfo_4.Node_ReplayBtn:getPositionY() + 100)
end

function PlayManagerNeiJiang:adjustUIfor3People()
    if self.playerNum ~= 3 then return end -- 仅仅重设内江三人

    local _nodeList = gt.findNodeArray(self.rootNode, "Node_playerInfo_2"):setVisible(false)
end

function PlayManagerNeiJiang:setBaoZi(num1, num2)
    gt.findNodeArray(self.rootNode, "Spr_baozi").Spr_baozi:setVisible((num1 ~= 0) and (num1 == num2))
end

function PlayManagerNeiJiang:roomAddPlayer(roomPlayer)
	-- 玩家自己
	roomPlayer.isOneself = false
	if roomPlayer.seatIdx == self.playerSeatIdx then
		roomPlayer.isOneself = true
	end
	-- 显示索引
	roomPlayer.displayIdx = self:getDisplaySeatIdx(roomPlayer.seatIdx)

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

function PlayManagerNeiJiang:getPlayerMjTilesReferPos(displayIdx)
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
	if displayIdx == 1 or displayIdx == 3 then
		mjTilesReferPos.groupSpace = cc.p(0, groupSize.height + 8)
		if displayIdx == 3 then
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

function PlayManagerNeiJiang:getDisplaySeatIdx(pos)
    local _displaySeatMap = {
        [3] = {[0]=4, [1]=1, [2]=3},
        [4] = {[0]=4, [1]=1, [2]=2, [3]=3}
    }
    return _displaySeatMap[self.playerNum][(pos - self.playerSeatIdx) % self.playerNum]
end

function PlayManagerNeiJiang:resetMjTileFrameNames()
    if self.playerNum ~= 3 then return end -- 仅仅重设内江三人

    self.pdbdd_img = gt.MJSprFrame
    self.tbgsd_img = "tbgs_%d.png"
    self.tdbgsd_img = "tdbgs_%d.png"
    self.pdsdd_img = gt.MJSprFrameOut
end

function PlayManagerNeiJiang:showPiaoImage( mThink )
	gt.dump(mThink)
	for i=1, self.playerNum do
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

function PlayManagerNeiJiang:resetTurnPos()
    local _nodeList = gt.findNodeArray(self.rootNode, "Spr_turnPosBg")

    _nodeList.Spr_turnPosBg:setRotation(0)
end

function PlayManagerNeiJiang:setTurnSeatSign(seatIdx)
    local displayIdx = self:getDisplaySeatIdx(seatIdx)
    seatIdx = displayIdx
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

function PlayManagerNeiJiang:hideInfo()
    gt.findNodeArray(self.rootNode, "Node_hutype", "huType#1#4"):setVisible(false)
end

function PlayManagerNeiJiang:cleanMjFormLayer()
	self.playMjLayer:removeAllChildren()

	self.outMjtileSignNode:setVisible(false)

    gt.findNodeArray(self.rootNode,
                     {"Node_hutype",           "huType#1#4"       },
                     {"Node_playerInfo_#1#4",  "Node_ReplayBtn"   },
                     {"Spr_turnPosBg",         "Spr_turnPos_#1#4" }
    ):setVisible(false)
end
