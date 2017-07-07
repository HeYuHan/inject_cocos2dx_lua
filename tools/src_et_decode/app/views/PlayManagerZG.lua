local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerZG = gt.PlayManager_Base:new()
gt.PlayManagerZG = PlayManagerZG

function PlayManagerZG:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 3)

	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setRotation(0)

	return o
end


--color表玩家位置，number代表选择，0不报叫，1报叫
function PlayManagerZG:setBaoJiaoTile(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	local spr_baojiao = gt.seekNodeByName(playerInfoNode, "Spr_baojiao")
	if mjNumber == 1 then 
		spr_baojiao:setVisible(true)
	else
		spr_baojiao:setVisible(false)
	end
end

function PlayManagerZG:getDisplaySeatIdx(pos)
    local _displaySeatMap = {
        [0]=3, [1]=1, [2]=2
    }
    return _displaySeatMap[(pos - self.playerSeatIdx) % self.playerNum]
end

function PlayManagerZG:setTurnSeatSign(seatIdx)
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
