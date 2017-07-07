

local gt = cc.exports.gt

local mt =
{
	implement =
	{
		init = nil,
		login = nil,
		logout = nil,
		messageHandler = nil,
		channelID = "",
		payWay = "IOS",
		platformID = "AppStore",
		infoList = {}
	}
}


--mt.implement.infoList = infoList
-- start --
--------------------------------
-- @class function init
-- @description 登录
-- end --
local function init()
	gt.log("AppStore init")

	gt.serverCode = "sichuan_db"
	--后台验证url	
	-- gt.payUrl =  "http://114.55.84.16:9898/payment-center/core/ios/notifyIOS.json"
	gt.payUrl =  "http://payment-center.xianlaigame.com/payment-center/core/ios/notifyIOS.json"
	-- gt.payUrl =  "http://test-payment.ixianlai.com/payment-center/core/ios/notifyIOS.json"
	-- gt.payUrl =  "http://test-payment.xlsxmj.com/payment-center/core/ios/notifyIOS.json"--appstore

	--限购查询url
	-- gt.checkLimitUrl = "http://114.55.84.16:9898/payment-center/core/ios/checkPayStatus.json"
	gt.checkLimitUrl = "http://payment-center.xianlaigame.com/payment-center/core/ios/checkPayStatus.json"
	-- gt.checkLimitUrl = "http://test-payment.ixianlai.com/payment-center/core/ios/checkPayStatus.json"
	-- gt.checkLimitUrl = "http://test-payment.xlsxmj.com/payment-center/core/ios/checkPayStatus.json" --appstore
	gt.chargeURL = ""  --充值验证

end
mt.implement.init = init

-- start --
--------------------------------
-- @class function pay
-- @description 支付
-- end --
local function pay(price, orderId, itemId)
	gt.log("App store pay")
	local luaBridge = require("cocos/cocos2d/luaoc")
	luaBridge.callStaticMethod("AppController", "postMessage", {event = "PAY", productId = tostring(itemId)})
	-- ApiBridge:postMessageToSdk(json.encode({ event = "PAY" ,_price = price ,_orderId = orderId ,_itemId = itemId}))
end
mt.implement.pay = pay

-- start --
--------------------------------
-- @class function messageHandler
-- @description 消息处理
-- end --
-- local function messageHandler(messageTable)
-- 	gt.log("AppStore messageHandler")
-- 	if ("PAY_SUCCESS" == messageTable.event) then
-- 		Charge.closeMaskLayer()
-- 		gt.log("Channel AppStore: PAY_SUCCESS!!!")
-- 		-- MessageControl:getInstance():dispatchMessage(NotificationType.NOTIFICATION_APPSTORE_PAY_IS_SUCCESS, messageTable)
-- 	elseif ("PURCHASE_CANCEL" == messageTable.event) then
-- 		Charge.closeMaskLayer()
-- 	elseif ("PURCHASE_DISABLE" == messageTable.event) then
-- 		-- Message.createMessageBox(MessageType.MESSAGE_PAY_APPSTORE_DISABLE)
-- 	end
-- end

-- mt.implement.messageHandler = messageHandler

return mt.implement