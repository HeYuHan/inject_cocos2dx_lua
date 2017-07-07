
local gt = cc.exports.gt

local wxTipsLayer = class("wxTipsLayer", function()
	return gt.createMaskLayer()
end)

function wxTipsLayer:ctor(tipsText)

	local csbNode = cc.CSLoader:createNode("weixinTipsLayer.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end
	local PageView_wx = gt.seekNodeByName(csbNode, "PageView_wx")
	PageView_wx:setTouchEnabled(true)
	PageView_wx:setIndicatorEnabled(true)
	PageView_wx:setIndicatorPosition(cc.p(485,0))
	PageView_wx:setIndicatorSelectedIndexColor(cc.c3b(255,165,0))
	-- PageView_wx:setIndicatorSpaceBetweenIndexNodes(10)
	
	for i=1,4 do
    	---创建layout，内容添加到layout
        local layout=ccui.Layout:create()
        layout:setContentSize(PageView_wx:getContentSize())
        local frameName = string.format("weixin_%d.png", i)
        local Tips = cc.Sprite:createWithSpriteFrameName(frameName)
        Tips:setContentSize(layout:getContentSize())
        Tips:setPosition(cc.p(layout:getContentSize().width*0.5,layout:getContentSize().height*0.5))
        if i == 1 then
        	local button = ccui.Button:create()
			button:loadTextures("PopupScene35.png","PopupScene35.png","PopupScene35.png",ccui.TextureResType.plistType)
			button:setPosition(cc.p(780,465))
			button:setTouchEnabled(true)
			gt.addBtnPressedListener(button, function()
				if gt.isIOSPlatform() and gt.isUseNewMusic() then
					local luaBridge = require("cocos/cocos2d/luaoc")
					luaBridge.callStaticMethod("AppController", "copyStr",{copystr = "熊猫麻将"})
				elseif gt.isAndroidPlatform() and gt.isUseNewMusic() then
					local luaBridge = require("cocos/cocos2d/luaj")
					luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "copyStr",{"熊猫麻将"})
				end
			end)
			Tips:addChild(button)
		end
        layout:addChild(Tips)
        PageView_wx:insertPage(layout,i-1)
    end

	local function pageviewAct()
		gt.log("PageView_wx:getCurrentPageIndex() = "..PageView_wx:getCurrentPageIndex())
		if PageView_wx:getCurrentPageIndex() < 3 then
			PageView_wx:scrollToPage(PageView_wx:getCurrentPageIndex()+1)
		elseif PageView_wx:getCurrentPageIndex() == 3 then
			--向前滑动
			PageView_wx:scrollToPage(0)
		end
	end
	local callFunc1 = cc.CallFunc:create(function(sender)
		pageviewAct()
	end)
	local delayTime = cc.DelayTime:create(5)
	local seqAction = cc.Sequence:create(callFunc1,delayTime)
	self:runAction(cc.RepeatForever:create(seqAction))


	local okBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(okBtn, function()
		self:removeFromParent()
	end)

	local runningScene = cc.Director:getInstance():getRunningScene()
	if runningScene then
		runningScene:addChild(self, gt.CommonZOrder.NOTICE_TIPS)
	end
end

return wxTipsLayer

