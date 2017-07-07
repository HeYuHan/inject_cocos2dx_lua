
local gt = cc.exports.gt

local HelpScene = class("HelpScene", function()
	return gt.createMaskLayer()
end)

function HelpScene:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("HelpScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Image_bg"):setScaleY(1280/960)
		-- gt.seekNodeByName(csbNode, "Text_webView"):setPosition(cc.p(630,345))
		-- gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		-- 移除界面,返回主界面
		-- self:removeFromParent()
		gt._webView:setVisible(false)
		self:setVisible(false)
		self:setZOrder(self:getParent():getZOrder()-1)
	end)
	--web底框
	self.Text_webView = gt.seekNodeByName(self.rootNode, "Text_webView")

	self:onWebView()
end

--调webView
function HelpScene:onWebView()
	local url = "http://www.ixianlai.com/sichuan/help/20170615/"
	local scrollX = self.Text_webView:getPositionX()-60 - 10
	local scrollY = self.Text_webView:getPositionY()-65 + 25
	-- local scrollX = self.Text_webView:getPositionX()
	-- local scrollY = self.Text_webView:getPositionY()
    gt._webView = ccexp.WebView:create()
    gt._webView:setPosition(scrollX,scrollY)
    gt.log("scrollX======= "..scrollX .. "scrollY ============ "..scrollY)
    gt._webView:setContentSize(self.Text_webView:getContentSize())

    gt.log("个人请求", url)
    gt._webView:loadURL(url)
    gt._webView:setScalesPageToFit(false)

    gt._webView:setOnShouldStartLoading(function(sender, url)
        return true
    end)
    gt._webView:setOnDidFinishLoading(function(sender, url)
    end)
    gt._webView:setOnDidFailLoading(function(sender, url)
    end)
    self.Text_webView:addChild(gt._webView)	
    -- return self._webView
end

return HelpScene

