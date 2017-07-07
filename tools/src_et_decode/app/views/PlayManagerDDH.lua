
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerDDH = gt.PlayManager_Base:new()
gt.PlayManagerDDH = PlayManagerDDH

function PlayManagerDDH:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 4)
	return o
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家接炮胡，自摸胡，明杠，暗杠，碰动画显示
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlayManagerDDH:showDecisionAnimation(seatIdx, decisionType)

	local roomPlayer = self.roomPlayers[seatIdx]
	-- 四川麻将  杠就是刮风下雨
	if decisionType == gt.DecisionType.BRIGHT_BAR or 
	   decisionType == gt.DecisionType.BRIGHT_BU then
	   	-- 刮风
	   	local Node_DecisionAnimate = gt.seekNodeByName(self.rootNode,"Node_DecisionAnimate")
		local node_animate = gt.seekNodeByName(Node_DecisionAnimate,"node_animate_" .. roomPlayer.displayIdx)
		local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/BrightBar.csb")
		self.brightBarAnimateNode = brightBarAnimateNode
		self.brightBarAnimate = brightBarAnimate
		brightBarAnimateNode:setPosition(cc.p(node_animate:getPositionX(),node_animate:getPositionY()))
		self.rootNode:addChild(brightBarAnimateNode, 1000)
	
		self.brightBarAnimate:play("run", false)
		gt.soundManager:PlaySpeakSound(roomPlayer.sex, "gang", roomPlayer)

	elseif decisionType == gt.DecisionType.DARK_BAR or 
	       decisionType == gt.DecisionType.DARK_BU then
	   	-- 下雨
		local Node_DecisionAnimate = gt.seekNodeByName(self.rootNode,"Node_DecisionAnimate")
		local node_animate = gt.seekNodeByName(Node_DecisionAnimate,"node_animate_" .. roomPlayer.displayIdx)
		local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/DarkBar.csb")
		self.brightBarAnimateNode = brightBarAnimateNode
		self.brightBarAnimate = brightBarAnimate
		brightBarAnimateNode:setPosition(cc.p(node_animate:getPositionX(),node_animate:getPositionY()))
		self.rootNode:addChild(brightBarAnimateNode, 1000)
		self.brightBarAnimate:play("run", false)
		gt.soundManager:PlaySpeakSound(roomPlayer.sex, "gang", roomPlayer)

	elseif decisionType == gt.DecisionType.TAKE_CANNON_WIN or
		   decisionType == gt.DecisionType.SELF_DRAWN_WIN then
	   	-- 胡牌动画 现在只有一个胡的标志
	   	
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


