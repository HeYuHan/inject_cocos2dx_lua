
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerSR = gt.PlayManager_Base:new()
gt.PlayManagerSR = PlayManagerSR

function PlayManagerSR:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 3)
	return o
end

function PlayManagerSR:initUI(msgTbl)
	-- 隐藏玩家麻将参考位置
	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	playNode:setVisible(false)

	-- 房间号
	local roomIDLabel = gt.seekNodeByName(self.rootNode, "Label_roomID")
	roomIDLabel:setString("房间号 " .. gt.getLocationString("LTKey_0013", self.roomID))
	

	local Lab_Play = gt.seekNodeByName(self.rootNode, "Lab_Play")

		-- 番数提示
	local str1 = ""
	local str2 = ""
	local str3 = ""
	local str4 = ""
	local str5 = ""
	local str6 = ""
	local str7 = ""
	local str8 = ""
	local str9 = ""
	
	for i = 1, #msgTbl.m_playtype do
		if msgTbl.m_playtype[i] == 24 then
			str1 = "二番封顶  "
		elseif msgTbl.m_playtype[i] == 25 then
			str1 = "三番封顶  "
		elseif msgTbl.m_playtype[i] == 26 then
			str1 = "四番封顶  "
		elseif msgTbl.m_playtype[i] == 27 then
			str3 = "幺九将对  "
		elseif msgTbl.m_playtype[i] == 22 then
			str2 = "自摸加底  "
		elseif msgTbl.m_playtype[i] == 23 then
			str2 = "自摸加番  "
		elseif msgTbl.m_playtype[i] == 28 then
			str5 = "门清中张  "
		elseif msgTbl.m_playtype[i] == 29 then
			str4 = "点杠花(点炮)  "
		elseif msgTbl.m_playtype[i] == 30 then
			str4 = "点杠花(自摸)  "
		elseif msgTbl.m_playtype[i] == 34 then
			str6 = "天地胡  "
		elseif msgTbl.m_playtype[i] == 39 then
			str7 = "点炮可平胡  "
		elseif msgTbl.m_playtype[i] == 40 then
			str8 = "对对胡两番  "
		elseif msgTbl.m_playtype[i] == 41 then
			str9 = "夹心五  "
		end
	end

	local str = str1 .. str2 .. str3 .. str4 .. str5 .. str6 .. str7 .. str8 .. str9
	Lab_Play:setString(str)

	if #msgTbl.m_playtype > 6 then
		Lab_Play:setFontSize(18)
	end
	

	local playType1 = gt.seekNodeByName(self.rootNode, "Spr_PlayTile")
	--1:血战：2血流

	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	hutypeNode:setVisible(false)
	for i=1,3 do
		local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
		hutypeSubNode:setVisible(false)
	end

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

	for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end
end


-- start --
--------------------------------
-- @class function
-- @description 设置座位编号标识
-- @param seatIdx 座位编号
-- end --
function PlayManagerSR:setTurnSeatSign(seatIdx)
	-- 显示轮到的玩家座位标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	-- 显示当先座位标识
	gt.log("=======00====" .. seatIdx)
	local displayIdx = (seatIdx + self.seatOffset - 1) % 3 + 1
	local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. displayIdx)
	turnPosSpr:setVisible(true)
	if self.preTurnSeatIdx and self.preTurnSeatIdx ~= displayIdx then
		gt.log("---========="  .. self.preTurnSeatIdx)
		-- 隐藏上次座位标识
		local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
		turnPosSpr:setVisible(false)
	end
	self.preTurnSeatIdx = displayIdx
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家开局胡牌动画,比如 1-缺一色 2-板板胡 3-大四喜 4-六六顺
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlayManagerSR:showStartDecisionAnimation(seatIdx, decisionType, showCard)
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
	local demoSpr = cc.Sprite:createWithSpriteFrameName(string.format(gt.SR_MJSprFrameOut, roomPlayer.displayIdx, 1, 1))
	local tileWidthX = 0
	local tileWidthY = 0
	if roomPlayer.displayIdx == 1 then
		tileWidthX = 0
		tileWidthY = mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displayIdx == 2 then
		tileWidthX = 0
		tileWidthY = -mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displayIdx == 3 then
		tileWidthX = demoSpr:getContentSize().width
		tileWidthY = 0
	end

	-- 服务器返回消息
	local totalWidthX = (#showCard)*tileWidthX
	local totalWidthY = (#showCard)*tileWidthY

	for i,v in ipairs(showCard) do
		local mjTileName = string.format(gt.SR_MJSprFrameOut, roomPlayer.displayIdx, v[1], v[2])
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

