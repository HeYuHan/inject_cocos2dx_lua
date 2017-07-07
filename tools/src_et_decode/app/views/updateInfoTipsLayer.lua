--
-- Author: zhupengfei
-- Date: 2016-08-31 15:34:40
--

local gt = cc.exports.gt

local updateInfoTipsLayer = class("updateInfoTipsLayer", function()
	return gt.createMaskLayer()
end)

function updateInfoTipsLayer:ctor(uid)

	local csbNode = cc.CSLoader:createNode("UpdataScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)
	self.rootNode = csbNode
	
	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		-- 移除界面,返回主界面
		self:removeFromParent()
	end)

	-- self:onWebView()
end

--调webView
function updateInfoTipsLayer:onWebView()
	local url = "http://www.ixianlai.com/sichuan/notice/20161206"
	local item = gt.seekNodeByName(self.rootNode, "Text_webView")
	local scrollX = item:getPositionX()-40
	local scrollY = item:getPositionY()-40
    self._webView = ccexp.WebView:create()
    self._webView:setPosition(scrollX,scrollY)
    self._webView:setContentSize(item:getContentSize())

    gt.log("个人请求", url)
    self._webView:loadURL(url)
    self._webView:setScalesPageToFit(false)

    self._webView:setOnShouldStartLoading(function(sender, url)
        return true
    end)
    self._webView:setOnDidFinishLoading(function(sender, url)
    end)
    self._webView:setOnDidFailLoading(function(sender, url)
    end)
    item:addChild(self._webView)	
    -- return self._webView
end

return updateInfoTipsLayer

