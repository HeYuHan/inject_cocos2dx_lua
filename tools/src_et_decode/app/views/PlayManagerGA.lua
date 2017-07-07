local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerGA = gt.PlayManager_Base:new()
gt.PlayManagerGA = PlayManagerGA

function PlayManagerGA:new(rootNode, paramTbl,o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self:ctor(rootNode, paramTbl, 4)
    return o
end
