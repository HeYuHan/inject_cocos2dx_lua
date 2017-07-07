
local gt = cc.exports.gt

local zanHelpScene = class("zanHelpScene", function()
	return gt.createMaskLayer()
end)

function zanHelpScene:ctor()

	local csbNode = cc.CSLoader:createNode("ZanHelpScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Image_bg"):setScaleY(1280/960)
		-- gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		-- 移除界面,返回主界面
		self:removeFromParent()
	end)

	local runningScene = cc.Director:getInstance():getRunningScene()
	if runningScene then
		runningScene:addChild(self, gt.CommonZOrder.NOTICE_TIPS)
	end
end

return zanHelpScene

