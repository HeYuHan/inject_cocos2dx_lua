
local gt = cc.exports.gt
require("app/views/ShieldWord")

local ChatPanel = class("ChatPanel", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function ChatPanel:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("ChatPanel.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end
	-- 固定短语
	local fixMsgNode = gt.seekNodeByName(csbNode, "Node_fixMsg")
	local fixMsgListVw = gt.seekNodeByName(fixMsgNode, "ListVw_fixMsg")
	for i = 1, 10 do
		local fixMsgCell = cc.CSLoader:createNode("FixMsgCell.csb")
		local bgSpr = gt.seekNodeByName(fixMsgCell, "Spr_bg")

		-- local fixMsgLabel = gt.createTTFLabel(gt.getLocationString("LTKey_0028_" .. i), 32)
		-- fixMsgLabel:setAnchorPoint(0, 0.5)
		-- fixMsgLabel:setColor(cc.c3b(107,64,47))
		-- fixMsgLabel:setPosition(cc.p(10,25))
		-- fixMsgCell:addChild(fixMsgLabel)

		local fixlabel = gt.seekNodeByName(bgSpr, "Label_fixMsg")
		-- fixlabel:setVisible(false)
		fixlabel:setString(gt.getLocationString("LTKey_0028_" .. i))
		local fixMsgItem = ccui.Widget:create()
		fixMsgItem:setTag(i)
		fixMsgItem:setTouchEnabled(true)
		fixMsgItem:setContentSize(cc.size(730,50))
		fixMsgItem:addChild(fixMsgCell)
		fixMsgItem:addClickEventListener(handler(self, self.fixMsgClickEvent))
		fixMsgListVw:pushBackCustomItem(fixMsgItem)
	end

	-- 焦点在边框框上
	local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
            self:runAction(cc.MoveBy:create(0.225,cc.p(0, 300)))
            self.textFileKeyWordVisible = true
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            self:runAction(cc.MoveBy:create(0.175, cc.p(0, -300)))
            -- self.textFileKeyWordVisible = false
        end
    end

	local inputMsgTxtField = gt.seekNodeByName(fixMsgNode, "TxtField_inputMsg")
	inputMsgTxtField:addEventListener(textFieldEvent)
	inputMsgTxtField:setTouchEnabled(true)
	self.inputMsgTxtField = inputMsgTxtField

	local sendBtn = gt.seekNodeByName(fixMsgNode, "Btn_send")
	gt.addBtnPressedListener(sendBtn, function()
		local inputMsgTxtField = gt.seekNodeByName(fixMsgNode, "TxtField_inputMsg")
		local inputString = inputMsgTxtField:getString()
		if string.len(inputString) > 0 then
			if string.len(inputString) > 60 then
				require("app/views/NoticeTips"):create("提示", "发送文字不得超过20字", nil, nil, true)
				return
			end

			if gt.CheckShieldWord(inputString) then
				
			else
				self:sendChatMsg(gt.ChatType.INPUT_MSG, 0, inputString)
			end
			
		end
	end)

	-- 表情符号
	local emojiNode = gt.seekNodeByName(csbNode, "Node_emoji")
	emojiNode:setVisible(false)
	local emojiScrollVw = gt.seekNodeByName(emojiNode, "ScrollVw_emoji")
	local emojiNameArray = {
		"E056.png", "E057.png", "E058.png", "E059.png", "E105.png", "E106.png",
		"E107.png", "E108.png", "E401.png", "E402.png", "E403.png", "E404.png",
		"E405.png", "E406.png", "E407.png", "E408.png", "E409.png", "E40A.png",
		"E40B.png", "E40C.png", "E40D.png", "E40E.png", "E40F.png", "E410.png",
		"E411.png", "E412.png", "E413.png", "E414.png", "E415.png", "E416.png",
		"E417.png", "E418.png", "E02B.png", "E04F.png", "E052.png", "E52D.png",
		"E52E.png", "E053.png", "E051.png", "E52B.png", "E420.png", "E421.png",
		"E00E.png", "E41D.png", "E41F.png", "E428.png", "E043.png", "E252.png"
	}
	local emojiSpr = gt.seekNodeByName(emojiScrollVw, "Spr_emoji")
	emojiScrollVw:removeAllChildren()
	local emojiStartPos = cc.p(emojiSpr:getPosition())
	local emojiPos = emojiStartPos
	for i, v in ipairs(emojiNameArray) do
		local emojiSpr = cc.Sprite:createWithSpriteFrameName(v)
		local emojiSize = emojiSpr:getContentSize()
		emojiSpr:setPosition(emojiSize.width * 0.5, emojiSize.height * 0.5)
		local emojiWidget = ccui.Widget:create()
		emojiWidget:setTouchEnabled(true)
		emojiWidget:setTag(i)
		emojiWidget:setName(v)
		emojiWidget:setContentSize(emojiSize)
		emojiWidget:addChild(emojiSpr)
		emojiScrollVw:addChild(emojiWidget)
		emojiWidget:setPosition(emojiPos)
		emojiWidget:addClickEventListener(handler(self, self.emojiClickEvent))

		local row = math.floor(i / 8)
		local col = i % 8
		emojiPos = cc.pAdd(emojiStartPos, cc.p(col * (emojiSize.width + 7), -row * (emojiSize.height + 5)))
	end

	local msgTabBtn = gt.seekNodeByName(csbNode, "Btn_msgTab")
	msgTabBtn:setTag(1)
	msgTabBtn:addClickEventListener(handler(self, self.switchChatTab))

	local emojiTabBtn = gt.seekNodeByName(csbNode, "Btn_emojiTab")
	emojiTabBtn:setTag(2)
	emojiTabBtn:addClickEventListener(handler(self, self.switchChatTab))
	
	self.chatTabBtns = {{msgTabBtn, fixMsgNode}, {emojiTabBtn, emojiNode}}

	self.Btn_msgTab_normal = gt.seekNodeByName(csbNode,"Btn_msgTab_normal")
	self.Btn_msgTab_select = gt.seekNodeByName(csbNode,"Btn_msgTab_select")

	self.Btn_emojiTab_normal = gt.seekNodeByName(csbNode,"Btn_emojiTab_normal")
	self.Btn_emojiTab_select = gt.seekNodeByName(csbNode,"Btn_emojiTab_select")

	self.header_bg = gt.seekNodeByName(csbNode,"headerbg")

	self:switchChatTab(msgTabBtn)

	self.removePar = false
	self.textFileKeyWordVisible = false
end

function ChatPanel:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function ChatPanel:onTouchBegan(touch, event)
	return true
end

function ChatPanel:onTouchEnded(touch, event)
	
	gt.log("11111111111")
	if self.textFileKeyWordVisible and not self.removePar then
		self.removePar = true
		gt.log("22222222222")
		return
	end
	gt.log("33333333333")
	self:removeFromParent()
end

function ChatPanel:switchChatTab(sender)
	local tabTag = sender:getTag()
	for i, tabData in ipairs(self.chatTabBtns) do
		if i == tabTag then
			tabData[1]:setBrightStyle(ccui.BrightStyle.highlight)
			tabData[2]:setVisible(true)

			self.Btn_msgTab_normal:setVisible(true)
			self.Btn_msgTab_select:setVisible(false)

			self.Btn_emojiTab_normal:setVisible(false)
			self.Btn_emojiTab_select:setVisible(true)

			self.header_bg:setSpriteFrame("chat_text_back.png")

		else
			tabData[1]:setBrightStyle(ccui.BrightStyle.normal)
			tabData[2]:setVisible(false)

			self.Btn_msgTab_normal:setVisible(false)
			self.Btn_msgTab_select:setVisible(true)

			self.Btn_emojiTab_normal:setVisible(true)
			self.Btn_emojiTab_select:setVisible(false)
			self.header_bg:setSpriteFrame("chat_emoji_back.png")

		end
	end
	local fixMsgNode = gt.seekNodeByName(csbNode, "Node_fixMsg")
	local emojiNode = gt.seekNodeByName(csbNode, "Node_emoji")
end

function ChatPanel:fixMsgClickEvent(sender, eventType)
	self:sendChatMsg(gt.ChatType.FIX_MSG, sender:getTag())
end

function ChatPanel:emojiClickEvent(sender)
	self:sendChatMsg(gt.ChatType.EMOJI, 0, sender:getName())
end

function ChatPanel:sendChatMsg(chatType, chatIdx, chatString)


	chatIdx = chatIdx or 1
	chatString = chatString or ""

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_CHAT_MSG
	msgToSend.m_type = chatType
	msgToSend.m_id = chatIdx
	msgToSend.m_msg = chatString
	gt.socketClient:sendMessage(msgToSend)

	cc.Director:getInstance():getOpenGLView():setIMEKeyboardState(false)
	
	self:removeFromParent()

end

return ChatPanel


