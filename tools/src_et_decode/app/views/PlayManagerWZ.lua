
local gt = cc.exports.gt

require("app/views/PlayManager_Base")

local PlayManagerWZ = gt.PlayManager_Base:new()
gt.PlayManagerWZ = PlayManagerWZ

function PlayManagerWZ:new(rootNode, paramTbl, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:ctor(rootNode, paramTbl, 4)
	return o
end