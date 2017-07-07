local gt = cc.exports.gt
local SEND_WX_KEY = "send_wx_key"
local isShowSendPhoneNum = true
local ActivityRecruitDialog = class("ActivityRecruitDialog",function() 
		local maskLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 180), gt.winSize.width, gt.winSize.height)
		local function onTouchBegan(touch, event)
			return true
		end
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = maskLayer:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, maskLayer)
		return maskLayer
	end)

function ActivityRecruitDialog.isOpen()
	if cc.FileUtils:getInstance():isFileExist("ActivityRecruit.csb") and 
		cc.FileUtils:getInstance():isFileExist("images/ActivityRecruitRes.png") 
		then
		return true
	end

	return false
end
--init dialog
function ActivityRecruitDialog:ctor(  )
	local csbNode, action = gt.createCSAnimation("res/ActivityRecruit.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	self.root = gt.seekNodeByName(csbNode, "root")
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end

	self:loadControl()
end

-- load controls
function ActivityRecruitDialog:loadControl( ... )
	self.userWXText  = gt.seekNodeByName(self.root, "userWX")
	self.guangfangWX = gt.seekNodeByName(self.root, "guanfangWX")
	self.closeBtn  	 = gt.seekNodeByName(self.root, "btn_close")	
	self.copyBtn	 = gt.seekNodeByName(self.root, "btn_copy")	
	self.sendBtn	 = gt.seekNodeByName(self.root, "btn_send")
	self.userWXBack  = gt.seekNodeByName(self.root, "edtBack")
	self.icon        = gt.seekNodeByName(self.root, "icon")
	self.editText	 = gt.seekNodeByName(self.root, "editText")


	self.userWXText:setLocalZOrder(10)  
	self.guangfangWX:setLocalZOrder(10) 
	self.closeBtn:setLocalZOrder(10)   	 	
	self.copyBtn:setLocalZOrder(10) 	
	self.sendBtn:setLocalZOrder(10) 

	local userId = gt.playerData.uid or 1
	local TabNum = tonumber(gt.playerData.uid)% #gt.NameTab + 1
	if TabNum then
		if TabNum>0 and TabNum<=#gt.NameTab then
			self.guangfangWX:setString(gt.NameTab[TabNum])
		else
			self.guangfangWX:setString("xmscmj666【公众号】")
		end
	else
		self.guangfangWX:setString("xmscmj666【公众号】")
	end

	self:initPages()

	self:initEvents()
end

function ActivityRecruitDialog:initPages( ... )
	-- -- pageView:setDelegate()
	-- -- local function handler( sender , eventType )
	-- -- 	gt.log("eventType================= ",eventType)
	-- -- end
	-- -- pageView:addEventListener(handler)
	-- local scaleNum = 0.6 -- 此参数是为了 调整 pageview 的  底部点的 大小
	-- local contentSize = pageView:getContentSize()
	-- contentSize = cc.size(contentSize.width/scaleNum,contentSize.height/scaleNum)
	-- pageView:setContentSize(contentSize)
	-- pageView:setScale(scaleNum)

	-- pageView:setIndicatorEnabled(true)
	-- pageView:setIndicatorPosition(cc.p(contentSize.width/2,8))
	-- pageView:setIndicatorSpaceBetweenIndexNodes(16)
	-- pageView:setIndicatorSelectedIndexColor(cc.c3b(255,165,0))

	-- local pagePointsNode = gt.seekNodeByName(self.root, "Node_1")
	-- pagePointsNode:setVisible(false)
	
	-- local pagesNum = 5
	-- for i=1,pagesNum do
 --        local layout=ccui.Layout:create()
 --        layout:setContentSize(contentSize)
 --       	local sp = cc.Sprite:createWithSpriteFrameName("page_".. i ..".png")
 --       	sp:setPosition(cc.p(contentSize.width/2,contentSize.height/2))
 --       	sp:setScale(1/scaleNum)
 --       	layout:addChild(sp)
 --        pageView:addPage(layout)---一个layout 为一个 page内容

 --        local maskLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 180), contentSize.width, 30)
	-- 	maskLayer:setPosition(cc.p(0,0))
	-- 	sp:addChild(maskLayer)
 --    end

    local pageView = require("app/views/XLPageView"):create(cc.size(964,465))
	local scaleNum = 0.6 -- 此参数是为了 调整 pageview 的  底部点的 大
	pageView:setTouchEnabled(true) 
	pageView:setPointOnAndOffTexture( "page_now.png" , "page_grey.png" , true)
	
	pageView:setPVInnerContainerSize(cc.size(964*2,465))
	pageView:setPVDirection(ccui.ScrollViewDir.horizontal )

	pageView:setPosition(cc.p(21.5 + 964/2,98 + 465/2) )


	if not isShowSendPhoneNum then
		pageView:setPosition(cc.p(21.5 + 964/2,50 + 465/2) )
		self.userWXBack:setVisible(false)
		self.userWXText:setVisible(false)
		self.sendBtn:setVisible(false)

		self.guangfangWX:setPositionY(self.guangfangWX:getPositionY() - 24)
		self.copyBtn:setPositionY(self.copyBtn:getPositionY() - 24)
		self.icon:setPositionY(self.icon:getPositionY() - 24)      
		self.editText:setPositionY(self.editText:getPositionY() - 24)
	end
	pageView:setBetweenPagePointsDis( 40 )
	pageView:setPointNodePos(cc.p(0,15))
	-- pageView:setPointScale(1)
	pageView:show(self.root,3)
	local contentSize = pageView:getPVContentSize()
	local pagesNum = 2
	for i=1,pagesNum do
       	local sp = cc.Sprite:createWithSpriteFrameName("page_".. i ..".png")
       	-- sp:setPosition(cc.p(contentSize.width/2,contentSize.height/2))
        pageView:addPage(sp)

        local maskLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 180), contentSize.width, 30)
		maskLayer:setPosition(cc.p(0,0))
		sp:addChild(maskLayer)
    end
    pageView:openLoopScroll(5)
end

--init events
function ActivityRecruitDialog:initEvents( ... )
	local function closefunc( )
		self:hide()
	end
	gt.addBtnPressedListener(self.closeBtn, closefunc)

	local function copyfunc()

		if gt.isCopyText() then
			local guangfangWXText = self.guangfangWX:getString()

			if string.len(guangfangWXText)>0 and string.find(guangfangWXText,"【") then
				guangfangWXText = string.sub(guangfangWXText,1,string.find(guangfangWXText,"【")-1)
			end
			gt.CopyText(guangfangWXText)
			require("app/views/NoticeTips"):create("提示", "复制官方微信号成功！", nil, nil, true)
		else
			require("app/views/NoticeTips"):create("提示", "当前客户端版本不支持复制，请更新版本。", nil, nil, true)
		end
	end
	gt.addBtnPressedListener(self.copyBtn, copyfunc)

	local function sendfunc( ... )
		--判断是否为微信号
		local wxText = self.userWXText:getString()
		if gt.checkWXNumberStatus(wxText) then
			self:requestWXNumber( wxText )
		else
			require("app/views/NoticeTips"):create("提示", "请输入正确格式的微信号或手机号！", nil, nil, true)
		end
	end
	gt.addBtnPressedListener(self.sendBtn, sendfunc)

	self:registerScriptHandler(handler(self, self.onNodeEvent))
end

function ActivityRecruitDialog:requestWXNumber( wxstr )
	if self:isSendAlready() then
		require("app/views/NoticeTips"):create("提示", "亲，同一用户不能重复发送哦!\n同时感谢您对此次活动的支持！", nil, nil, true)
		return
	end

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	local serverKey = "bf4ad120872a37a012575028f8d78e71"
	local userId = gt.playerData.uid or 1	
	
	local urlStr = "https://active.xianlaigame.com/xlhy-activity/agentRecruit/submit?serverCode=sichuan_db&userId=".. userId.."&userMobile="..wxstr.."&serverKey="..serverKey
	if gt.debugMode then
		urlStr = "http://172.16.70.25:7780/xlhy-activity/agentRecruit/submit?serverCode=sichuan_db&userId=".. userId.."&userMobile="..wxstr.."&serverKey="..serverKey
	end

	xhr:open("GET", urlStr)
	local function onReadyStateChanged()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			gt.log(xhr.response)
			-- local responseData = xhr.response
			require("json")
			local respJson = json.decode(xhr.response)
			gt.dump(respJson)
			if respJson["status"] == "1" then
				require("app/views/NoticeTips"):create("提示", "提交成功！稍后我们会与您联系！", nil, nil, true)
				cc.UserDefault:getInstance():setBoolForKey( SEND_WX_KEY .. userId,true)
			else
				require("app/views/NoticeTips"):create("提示", "发送失败，请重新发送！", nil, nil, true)
			end
		else
			require("app/views/NoticeTips"):create("提示", "发送失败，请重新发送！", nil, nil, true)
			gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
		end
		xhr:unregisterScriptHandler()
		self.xhr = nil
	end
	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()

	self.xhr = xhr
end

function ActivityRecruitDialog:isSendAlready( ... )
	local userId = gt.playerData.uid or 1
	local isSended = cc.UserDefault:getInstance():getBoolForKey( SEND_WX_KEY .. userId ,false)
	return isSended
end

function ActivityRecruitDialog:onNodeEvent(eventName)
	if "enter" == eventName then
		-- local listener = cc.EventListenerTouchOneByOne:create()
		-- listener:setSwallowTouches(true)
		-- listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		-- local eventDispatcher = self:getEventDispatcher()
		-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)

		if self.xhr then
			self.xhr:unregisterScriptHandler()
			self.xhr = nil
		end
	end
end

function ActivityRecruitDialog:show( parent , zorder )
	parent = parent or cc.Director:getInstance():getRunningScene()
	zorder = zorder or 60 -- notice tip 的 层级是 67 ，要比67 小
	parent:addChild(self,zorder)
end

function ActivityRecruitDialog:hide( ... )
	self:removeFromParent(true)
end

return ActivityRecruitDialog




