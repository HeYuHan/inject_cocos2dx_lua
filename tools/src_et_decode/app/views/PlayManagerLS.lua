
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerLS = gt.PlayManager_Base:new()
gt.PlayManagerLS = PlayManagerLS

function PlayManagerLS:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 4)

    self.m_playtype = paramTbl.m_playtype

	return o
end


--除去抢杠胡的牌
function PlayManagerLS:onRecUserRemoveBarCard(seatIdx,m_color,m_number)
	gt.log("function = onRecUserRemoveBarCard=======")
	if self.qianGangSeatIdx then
		local roomPlayer = self.roomPlayers[self.qianGangSeatIdx]
		dump(roomPlayer.holdMjTiles)

        local _foundTargrt = false
		for k,v in pairs(roomPlayer.holdMjTiles) do

			if m_color == v.mjColor and m_number == v.mjNumber then
				local mjTile = roomPlayer.holdMjTiles[k]
				if mjTile then
					mjTile.mjTileSpr:removeFromParent()
					table.remove(roomPlayer.holdMjTiles, k)
                    _foundTargrt = true
				end
				self:sortHoldMjTiles(roomPlayer)
				break
			end
		end

        -- 没有在手牌中找到对应的牌, 并且有幺鸡任用玩法
        if (not _foundTargrt) and table.contains(self.m_playtype, 161)  then
            -- 查找玩家手里碰牌是否有目标花色的碰牌
            local _foundPung = false
            for _, _pung in ipairs(roomPlayer.mjTilePungs) do
                if m_color == _pung.mjColor and m_number == _pung.mjNumber then
                    local mjTileName = string.format(gt.MJSprFrameOut, roomPlayer.displayIdx, 3, 1)

                    for __, _node in ipairs(_pung.groupNode:getChildren()) do
                        if not (_node.cardData[1] == 3 and _node.cardData[2] == 1) then
                            _node:setSpriteFrame(mjTileName)
                            _foundPung = true
                            break
                        end
                    end
                    break
                end
            end

            -- 删除手中一张幺鸡牌
            if _foundPung then
                for k,v in pairs(roomPlayer.holdMjTiles) do
                    if 3 == v.mjColor and 1 == v.mjNumber then
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
	end
end
