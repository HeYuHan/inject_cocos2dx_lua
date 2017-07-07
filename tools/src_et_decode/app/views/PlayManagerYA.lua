
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerYA = gt.PlayManager_Base:new()
gt.PlayManagerYA = PlayManagerYA

function PlayManagerYA:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 4)
	return o
end

-- 移除廊起的牌
function PlayManagerYA:removePrePlayerLangMjTile(seatIdx, langMjTiles)
	gt.log("function = removePrePlayerLangMjTile")
	gt.dump(langMjTiles)
	local roomPlayer = self.roomPlayers[seatIdx]

	for i = 2, #langMjTiles do
        local mjTile = langMjTiles[i]
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
