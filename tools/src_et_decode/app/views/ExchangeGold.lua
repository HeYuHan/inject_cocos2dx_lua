
local gt = cc.exports.gt

local ExchangeGold = class("ExchangeGold", function()
	return gt.createMaskLayer()
end)

function ExchangeGold:ctor(uid)

	local csbNode = cc.CSLoader:createNode("ExchangeGold.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Image_bg"):setScaleY(1280/960)
		gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		-- 移除界面,返回主界面
		self:setVisible(false)
		self:setZOrder(self:getParent():getZOrder()-1)
	end)

	local Btn_Exchange1 = gt.seekNodeByName(csbNode, "Btn_Exchange1")
	gt.addBtnPressedListener(Btn_Exchange1, function()
		-- 发送兑换金币
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_EXCHANGEGOLD
		msgToSend.m_card = gt.Exchange[1]
		gt.dump(msgToSend)
		gt.socketClient:sendMessage(msgToSend)
	end)

	local Btn_Exchange2 = gt.seekNodeByName(csbNode, "Btn_Exchange2")
	gt.addBtnPressedListener(Btn_Exchange2, function()
		-- 发送兑换金币
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_EXCHANGEGOLD
		msgToSend.m_card = gt.Exchange[3]
		gt.dump(msgToSend)
		gt.socketClient:sendMessage(msgToSend)
	end)

	local Btn_Exchange3 = gt.seekNodeByName(csbNode, "Btn_Exchange3")
	gt.addBtnPressedListener(Btn_Exchange3, function()
		-- 发送兑换金币
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_EXCHANGEGOLD
		msgToSend.m_card = gt.Exchange[5]
		gt.dump(msgToSend)
		gt.socketClient:sendMessage(msgToSend)
	end)
	gt.seekNodeByName(csbNode, "Text_Time"):setString(gt.GoldTime)

	for i=1,3 do
		local image = gt.seekNodeByName(csbNode, "Image_" .. i )
		gt.seekNodeByName(image, "Text_fk" ):setString( gt.Exchange[2*i-1] .. "张房卡")
		gt.seekNodeByName(image, "Text_jb" ):setString( gt.Exchange[2*i] .. "金币")
	end

	gt.socketClient:registerMsgListener(gt.GC_EXCHANGEGOLD, self, self.onRcvExchangeGold)
end

function ExchangeGold:onRcvExchangeGold(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_card > 0 then
		-- 兑换成功
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), msgTbl.m_card .. "张房卡兑换成功", nil, nil, true)
	elseif msgTbl.m_card == -1 then
		--todo
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "房卡兑换活动未开启", nil, nil, true)
	elseif msgTbl.m_card == -2 then
		--todo
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "金币不足", nil, nil, true)
	end
end

return ExchangeGold