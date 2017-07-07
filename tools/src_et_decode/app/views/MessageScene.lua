
local gt = cc.exports.gt

local MessageScene = class("MessageScene", function()
	return gt.createMaskLayer()
end)

function MessageScene:ctor(uid)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("MessageScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Sprite_bg"):setScaleY(1280/960)
		-- gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)
	self.csbNode = csbNode
	self:requestAgreement()

	-- 返回按钮
	local backBtn = gt.seekNodeByName(self.csbNode , "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		-- 移除界面,返回主界面
		self:removeFromParent()
	end)
end

function MessageScene:requestAgreement()
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr:open("GET", "http://www.ixianlai.com/client/mj_sc_update/messagenotice.txt")
	local function onReadyStateChanged()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			-- gt.log(xhr.response)
		else
			gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
		end
		xhr:unregisterScriptHandler()
		self.xhr = nil

		local agreementScrollVw = gt.seekNodeByName(self.csbNode , "ScrollVw_agreement")
		local scrollVwSize = agreementScrollVw:getContentSize()
		local agreementLabel = nil
		if gt.isInReview then
			agreementLabel = gt.createTTFLabel("亲爱的玩家  \n\n  祝您在游戏中玩的愉快", 30)
		else
			agreementLabel = gt.createTTFLabel(xhr.response, 30)
		end
		agreementLabel:setAnchorPoint(0.5, 1)
		agreementLabel:setColor(cc.c3b(255,213,156))
		gt.setTTFLabelStroke(agreementLabel, cc.c3b(0,0,0), 2)
		agreementLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
		agreementLabel:setWidth(scrollVwSize.width)
		local labelSize = agreementLabel:getContentSize()
		if labelSize.height < scrollVwSize.height then
			agreementLabel:setPosition(scrollVwSize.width * 0.5, scrollVwSize.height)
		else
			agreementLabel:setPosition(scrollVwSize.width * 0.5, labelSize.height)
		end
		agreementScrollVw:addChild(agreementLabel)
		agreementScrollVw:setInnerContainerSize(labelSize)
	end
	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()

	self.xhr = xhr
end

return MessageScene

