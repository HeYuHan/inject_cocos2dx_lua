
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerXL = gt.PlayManager_Base:new()
gt.PlayManagerXL = PlayManagerXL

function PlayManagerXL:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	o:ctor(rootNode, paramTbl, 4)
	return o
end

function PlayManagerXL:hideInfo()
	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	hutypeNode:setVisible(false)
	for i=1,4 do
		local hutypeSubNode = gt.seekNodeByName(hutypeNode,"huType" .. i)
		hutypeSubNode:setVisible(false)

		--隐藏胡牌信息
		local Node_HuGroup = gt.seekNodeByName(self.rootNode, "Node_HuGroup_" .. i)

		for m = 1, 3 do
			local Img_kuang = gt.seekNodeByName(Node_HuGroup, "Img_kuang_" .. m)
			Img_kuang:setVisible(false)
		end

		for j = 1 , 24 do
			local Spr_mjTileHu = gt.seekNodeByName(Node_HuGroup, "Spr_mjTileHu_" .. j)
			Spr_mjTileHu:setVisible(false)
		end

	end
end

function PlayManagerXL:addTileTable(roomPlayer)
	-- 玩家已胡牌
	roomPlayer.huMjTiles = {}
end

-- 清理掉所有出的牌
function PlayManagerXL:cleanMjFormLayer()
	self.playMjLayer:removeAllChildren()

	self.outMjtileSignNode:setVisible(false)

	self:cleanMjHu()


	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end
end

function PlayManagerXL:cleanMjHu()
	--清理胡的牌
	for i = 1, 4 do

		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local Node_ReplayBtn = gt.seekNodeByName(playerInfoNode,"Node_ReplayBtn")
		Node_ReplayBtn:setVisible(false)

	--清理胡的牌
		local Node_HuGroup = gt.seekNodeByName(self.rootNode, "Node_HuGroup_" .. i)
		for m = 1, 3 do
			local Img_kuang = gt.seekNodeByName(Node_HuGroup, "Img_kuang_" .. m)
			Img_kuang:setVisible(false)
		end

		for j = 1, 24 do
			local Spr_mjTileHu = gt.seekNodeByName(Node_HuGroup, "Spr_mjTileHu_" .. j)
			if j < #self.roomPlayers[i]  then
				Spr_mjTileHu:setVisible(true)
			else
				Spr_mjTileHu:setVisible(false)
			end
		end
	end

end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家胡牌的标志和胡的牌 
-- @param seatIdx 座次
-- @param winType 自摸还是接炮
-- end --
function PlayManagerXL:showPalyerWinCard( seatIdx, mjColor, mjNumber,winType, isQuick, isQiangG, isGangHua)
	
	gt.log("luxiang hupai seatIdx is  ... " .. seatIdx)

	local roomPlayer = self.roomPlayers[seatIdx]

	
	--自摸
	if not winType then
		-- 自摸
		dump(roomPlayer.holdMjTiles)
		gt.log("自摸胡牌 ........... ")
		
		local lastMj = roomPlayer.holdMjTiles[#roomPlayer.holdMjTiles].mjTileSpr
		lastMj:removeFromParent()
		table.remove(roomPlayer.holdMjTiles, #roomPlayer.holdMjTiles)
	else --接炮
		if not isQiangG then
			self:removePrePlayerOutMjTile(mjColor, mjNumber)
		end
	end
	--if not isGangHua then
	self:addAlreadyHuMjTiles(seatIdx, mjColor, mjNumber, #roomPlayer.huMjTiles + 1)
	self:setHuTag(seatIdx)
end


-- start --
--------------------------------
-- @class function
-- @description 显示已胡牌
-- @param seatIdx 座位号
-- @param mjColor 麻将花色
-- @param mjNumber 麻将编号
-- end --
function PlayManagerXL:addAlreadyHuMjTiles(seatIdx, mjColor, mjNumber, index)

	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, mjColor, mjNumber))
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.huMjTiles, mjTile)

	-- 玩家已胡牌缩小
	if self.playerSeatIdx == seatIdx then
		mjTileSpr:setScale(0.66)
	end

	-- if isHide then
	--  	mjTileSpr:setVisible( false )
	-- end

	local Node_HuGroup = gt.seekNodeByName(self.rootNode, "Node_HuGroup_" .. roomPlayer.displayIdx)
	local Spr_mjTileHu = gt.seekNodeByName(Node_HuGroup, "Spr_mjTileHu_" .. index)
	Spr_mjTileHu:setSpriteFrame(string.format(gt.MJSprFrameOut,roomPlayer.displayIdx, mjColor, mjNumber))
	Spr_mjTileHu:setVisible(true)
end

function PlayManagerXL:setHuTag(seatIdx)
	local hutypeNode = gt.seekNodeByName(self.rootNode,"Node_hutype")
	self.rootNode:reorderChild(hutypeNode, 800)
	hutypeNode:setVisible(false)
	

	local roomPlayer = self.roomPlayers[seatIdx]

	local huType = gt.seekNodeByName(hutypeNode, "huType" .. roomPlayer.displayIdx)
	huType:setVisible(false)
	

	local Node_HuGroup = gt.seekNodeByName(self.rootNode, "Node_HuGroup_" .. roomPlayer.displayIdx)

  
	local function setKuang(tag)
		for i = 1, 3 do
			local Img_kuang = gt.seekNodeByName(Node_HuGroup, "Img_kuang_" .. i)
			Img_kuang:setVisible(false)
		
			if i == tag then
				
				Img_kuang:setVisible(true)
			end
		end
	end

	if #roomPlayer.huMjTiles == 1 or #roomPlayer.huMjTiles == 2 then
		setKuang(#roomPlayer.huMjTiles)
	elseif #roomPlayer.huMjTiles >= 3 then
		setKuang(3)
	end

end

