--
-- Author: liu yang
-- Date: 2017-02-08 15:36:34
--
local gt = cc.exports.gt
local RechargeConfig = gt.getRechargeConfig()

local RechargeLayer = class("RechargeLayer", function()
	return gt.createMaskLayer()
end)

function RechargeLayer:ctor()
	self.itemCount = 3
	self.itemsLimitState = {}
	self:checkItemLimitState()
end

--检测商品限购状态
function RechargeLayer:checkItemLimitState()
	
	gt.showLoadingTips("正在请求充值列表")

    local xhr = cc.XMLHttpRequest:new()
    -- mt.xhr:retain()
    xhr.timeout = 10 -- 设置超时时间

    local productIdList = RechargeConfig[1]["AppStore"] .. ":" .. RechargeConfig[2]["AppStore"] .. ":" .. RechargeConfig[3]["AppStore"]
	local checkUrl = string.format("%s?serverCode=%s&userId=%s&productNumbers=%s&payWay=%s", gt.checkLimitUrl, gt.serverCode, gt.playerData.uid, productIdList, gt.sdkBridge.payWay)
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xhr:open("POST", checkUrl)
    xhr:registerScriptHandler(handler(self, self.initLayer))
    xhr:send()

    self.xhr = xhr
    self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.erripserverhandler), 8, false)
end

function RechargeLayer:erripserverhandler(delta)
	gt.log("function is erripserverhandler")
	self.xhr:unregisterScriptHandler()
	if self.scheduleHandler then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		self.scheduleHandler = nil
	end
	gt.removeLoadingTips()
	self:closeLayer()
	require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
end

function RechargeLayer:initLayer()
	gt.log("--------init layer:")
	gt.removeLoadingTips()
	if self.scheduleHandler then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		self.scheduleHandler = nil
	end
	-- self.xhr:unregisterScriptHandler()
	if self.xhr.readyState == 4 and (self.xhr.status >= 200 and self.xhr.status < 207) then
		gt.log("self.xhr.readyState = "..self.xhr.readyState)
		require("json")
		local response = json.decode(self.xhr.response)
		dump(response, "----验证结果")
		if response.code == 0 then
			dump(response.data, "---------require succeed")
			local data = response.data
			for j = 1, self.itemCount do
				local tmpPId = RechargeConfig[j]["AppStore"]
				if data[tmpPId] then
					gt.log("--------state, index:" .. data[tmpPId] .. "," .. j)
					self.itemsLimitState[j] = data[tmpPId]
				end
			end

			self:checkRequestComplete()
		elseif response.code == "-1" then
			self:checkItemLimitState()
		end
		
	elseif self.xhr.readyState == 1 and self.xhr.status == 0 then
		gt.log("self.xhr.status = "..self.xhr.status)
		self:checkItemLimitState()
	end
end

--检测请求是否完成
function RechargeLayer:checkRequestComplete()
	local checkComplete = true
	for i = 1, self.itemCount do
		if not self.itemsLimitState[i] then
			checkComplete = false
			break
		end
	end

	gt.log("-------checkRequestComplete:" .. tostring(checkComplete))
	if checkComplete then
		if not self.isInitComplete then
			self.rootNode = gt.createCSNode("RechargeShop.csb")
			self.rootNode:setAnchorPoint(0.5,0.5)
			self.rootNode:setPosition(gt.winCenter)
			self:addChild(self.rootNode)
			--遍历微信号码数组
			local TabNum = tonumber(gt.playerData.uid)% #gt.NameTab + 1
			local WxName = ""
			if TabNum>0 and TabNum<=#gt.NameTab then
				WxName = gt.NameTab[TabNum]
			else
				WxName = "xmscmj666【公众号】"
			end
			local Button_Copy =  gt.seekNodeByName(self.rootNode,"Button_Copy")
			gt.addBtnPressedListener(Button_Copy, function()
				if string.len(WxName)>0 and string.find(WxName,"【") then
					WxName = string.sub(WxName,1,string.find(WxName,"【")-1)
				end
				gt.CopyText(WxName)
			end)
			if gt.isInReview then
				gt.seekNodeByName(self.rootNode,"shopTips"):setString("小提示：成功购买后房卡直接充值到游戏中")
				Button_Copy:setVisible(false)
			else
				gt.seekNodeByName(self.rootNode,"shopTips"):setString("游戏代理招募:"..WxName)
			end

			if display.autoscale == "FIXED_HEIGHT" then
				self.rootNode:setScale(0.75)
			end

			self.curSelItem = 1

			self.isInitComplete = true

			self:initBaseInfo()

			self:registerButtonsEvent()
		end
		
		for i = 1, self.itemCount do
			gt.log("-----------i:"..i)
			local tmpItem = self.itemList[i]

			if self.itemsLimitState[i] == "purchasable" then
				tmpItem.limitIcon:setVisible(false)
				self:enableBuyBtn()
			else
				tmpItem.limitIcon:setVisible(true)
				self:disableBuyBtn()
			end
		end
	
		self:selectItem(self.curSelItem)

		
	end
end

function RechargeLayer:initBaseInfo()
	self.itemList = {}
	for i = 1, self.itemCount do
		local tmpItem = gt.seekNodeByName(self.rootNode, "item" .. i)
		local tmpItemTitle = tmpItem:getChildByName("item" .. i .. "Title")
		local tmpItemCost = tmpItem:getChildByName("item" .. i .. "Cost")
		local tmpItemSel = tmpItem:getChildByName("item" .. i .. "Sel")
		local tmpItemLimit = gt.seekNodeByName(tmpItem, "item" .. i .. "Limited")


		local tmpItemConfig = RechargeConfig[i]

		tmpItemSel:setVisible(false)
		tmpItemLimit:setVisible(false)
		tmpItemTitle:setString(tmpItemConfig["Title"])
		tmpItemCost:setString(tmpItemConfig["CostValue"])

		local tmpItemInfo = {}
		tmpItemInfo.SelIcon = tmpItemSel
		tmpItemInfo.limitIcon = tmpItemLimit
		self.itemList[i] = tmpItemInfo

		gt.addTouchEventListener(tmpItem, function()
			self:selectItem(i)
		end, nil, 0)
	end

end

function RechargeLayer:registerButtonsEvent()
	self.closeBtn = gt.seekNodeByName(self.rootNode, "closeBtn")
	gt.addBtnPressedListener(self.closeBtn, function()
		self:closeLayer()
	end)

	self.buyBtn = gt.seekNodeByName(self.rootNode, "buyBtn")
	gt.addBtnPressedListener(self.buyBtn, function()
		self:buy()
	end)
end

function RechargeLayer:selectItem(index)
	self.curSelItem = index
	for i = 1, self.itemCount do
		local tmpItem = self.itemList[i]
		if tmpItem and i == self.curSelItem then
			tmpItem.SelIcon:setVisible(true)
			if self.itemsLimitState[i] == "purchasable" then
				tmpItem.limitIcon:setVisible(false)
				self:enableBuyBtn()
			else
				tmpItem.limitIcon:setVisible(true)
				self:disableBuyBtn()
			end
		else
			tmpItem.SelIcon:setVisible(false)
		end
	end

	local curItemConfig = RechargeConfig[self.curSelItem]
	local itemDes = gt.seekNodeByName(self.rootNode, "itemDes")
	itemDes:setString(curItemConfig["Description"])

	local itemCost = gt.seekNodeByName(self.rootNode, "itemCostValue")
	itemCost:setString(curItemConfig["CostValue"])
end

function RechargeLayer:disableBuyBtn()
	if not self.buyBtn then
		self.buyBtn = gt.seekNodeByName(self.rootNode, "buyBtn")
	end

	self.buyBtn:setTouchEnabled(false)
	self.buyBtn:setBright(false)
end

function RechargeLayer:enableBuyBtn()
	if not self.buyBtn then
		self.buyBtn = gt.seekNodeByName(self.rootNode, "buyBtn")
	end

	self.buyBtn:setTouchEnabled(true)
	self.buyBtn:setBright(true)
end

function RechargeLayer:refreshShopState()
	self:checkItemLimitState()
end

function RechargeLayer:closeLayer()
	gt.removeTargetEventListenerByType(self, gt.EventType.PURCHASE_SUCCESS)

	self:removeAllChildren()
	self:removeFromParent()
end

function RechargeLayer:buy()
	gt.registerEventListener(gt.EventType.PURCHASE_SUCCESS, self, self.refreshShopState)
	gt.log("----buy item:" .. self.curSelItem)
	Charge.buy(self.curSelItem)
end

return RechargeLayer