
local gt = cc.exports.gt

local NewyearActivity = class("NewyearActivity", function()
	return gt.createMaskLayer()
end)

function NewyearActivity:ctor(uid)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("NewyearActivity.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	csbNode:setScale(0.8)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScaleX(0.7)
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 返回按钮
	local Btn_close = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(Btn_close, function()
		-- 移除界面,返回主界面
		self:removeFromParent()
		-- gt.NYwebView:setVisible(false)
		-- self:setVisible(false)
		-- self:setZOrder(self:getParent():getZOrder()-1)
	end)
	--web底框
	self.Text_webView = gt.seekNodeByName(self.rootNode, "Text_webView")
	self:GetWebUrl()
end

--调webView
function NewyearActivity:GetWebUrl()
	local NewyearServer = "http://114.55.84.16:9898/shopping"
	if not gt.debugMode then
		NewyearServer = "https://vip.xianlaihy.com"
	end
	local serverCode = "sichuan_db"
	local inviter = gt.playerData.uid
	local scrit = "3c6e0b8a9c15224a8228b9a98ca1531d"
	local sign = cc.UtilityExtension:generateMD5(serverCode..inviter, string.len(serverCode..inviter))
	local url = NewyearServer.."/xcyy/toXcyy?serverCode="..serverCode.."&inviter="..inviter.."&sign="..sign
	local scrollX = self.Text_webView:getContentSize().width/2
	local scrollY = self.Text_webView:getContentSize().height/2
    gt.NYwebView = ccexp.WebView:create()
    gt.NYwebView:setPosition(scrollX,scrollY)
    gt.NYwebView:setContentSize(self.Text_webView:getContentSize())

    gt.log("个人请求", url)
    gt.NYwebView:loadURL(url)
    gt.NYwebView:setScalesPageToFit(false)

    gt.NYwebView:setOnShouldStartLoading(function(sender, url)
        return true
    end)
    gt.NYwebView:setOnDidFinishLoading(function(sender, url)
    end)
    gt.NYwebView:setOnDidFailLoading(function(sender, url)
    end)
    self.Text_webView:addChild(gt.NYwebView)	
    -- return self.NYwebView
end

return NewyearActivity

