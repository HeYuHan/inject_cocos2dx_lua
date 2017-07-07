
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerZGSR = gt.PlayManager_Base:new()
gt.PlayManagerZGSR = PlayManagerZGSR

function PlayManagerZGSR:new(rootNode, paramTbl,o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 4)
	return o
end

--color表玩家位置，number代表选择，0不报叫，1报叫
function PlayManagerZGSR:setBaoJiaoTile(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	local spr_baojiao = gt.seekNodeByName(playerInfoNode, "Spr_baojiao")
	if mjNumber == 1 then 
		spr_baojiao:setVisible(true)
	else
		spr_baojiao:setVisible(false)
	end
end
