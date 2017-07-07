--create by shz 
local gt = cc.exports.gt
local RecruitIcon = class("RecruitIcon",function() return cc.Node:create() end)

function RecruitIcon.isOpen()
	if cc.FileUtils:getInstance():isFileExist("TB_tuiguang.csb") and 
		cc.FileUtils:getInstance():isFileExist("images/ActivityRecruitRes.png") 
		then
		return true
	end

	return false
end

function RecruitIcon:ctor()
	self.csbfile = "TB_tuiguang.csb"
	self.csbNode = cc.CSLoader:createNode(self.csbfile)
	self.csbNode:setPosition(cc.p(0,0))
	self:addChild(self.csbNode)

	self:loadControls()
end

function RecruitIcon:loadControls( ... )
	-- local action = cc.CSLoader:createTimeline(self.csbfile)
	-- action:gotoFrameAndPlay(0, 44,false)
	self:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create( function( )
		local action = cc.CSLoader:createTimeline(self.csbfile)
		action:gotoFrameAndPlay(0, 44,false)
		self.csbNode:runAction(action)
		
	end))))

	local btn = gt.seekNodeByName(self.csbNode, "Button_1")
 
	local function openFunc( ... )
		local ActivityRecruitDialog = require("app/views/Activities/ActivityRecruitDialog")
		if ActivityRecruitDialog.isOpen() then
			ActivityRecruitDialog:create():show()
		end		
	end
	gt.addBtnPressedListener(btn, openFunc)
end


return RecruitIcon