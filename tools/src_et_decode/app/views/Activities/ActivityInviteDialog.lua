local gt = cc.exports.gt

local ActivityInviteDialog = class("ActivityInviteDialog",function() 
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

function ActivityInviteDialog.isOpen()
	if cc.FileUtils:getInstance():isFileExist("ActivityInvite.csb") and 
		cc.FileUtils:getInstance():isFileExist("images/ActivityInvite.png") 
		then
		return true
	end

	return false
end

function ActivityInviteDialog:ctor( infoTbl )
	self.infoTbl = infoTbl
	local csbfile = "ActivityInvite.csb"
	local csbNode = cc.CSLoader:createNode(csbfile)
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	-- 头像下载管理器
  	local playerHeadMgr = require("app/PlayerHeadManager"):create()
   	csbNode:addChild(playerHeadMgr)
   	self.playerHeadMgr = playerHeadMgr	

	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end

	self.root = gt.seekNodeByName(csbNode, "back")
	self:loadControls()
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	-- 服务器返回 用户 send invite id 后的消息
	gt.socketClient:registerMsgListener(gt.GC_ACTIVITY_REPLY_INVITE , self, self.onRecvInviteIDReply)
end

function ActivityInviteDialog:onRecvInviteIDReply( msgTbl )
	gt.dump(msgTbl)
	local messageTable = {
		[0] = "提交成功，快去跟好友一起玩吧！",
		[1] = "请输入正确的ID号！",
		[2] = "新用户和15天未登录的用户才可被邀请哦！",
		[3] = "您已经填写过邀请人了哦！",
		[4] = "不能邀请自己哦！",
		[5] = "该用户邀请人数已达上限！"
	}
	self.isSendingInviteID = false
	require("app/views/NoticeTips"):create("提示", messageTable[msgTbl.m_errorCode], nil, nil, true)
end

function ActivityInviteDialog:loadControls(  )
	self.inviteIDBox = gt.seekNodeByName(self.root, "InviteID")
	self.headerNode  = gt.seekNodeByName(self.root, "headerNode")

	------------------test code-----------------------------
	-- for i=1,5 do
	-- 	local aHeader = gt.seekNodeByName(self.headerNode , "header_"..i)
	-- 	local aUserID = gt.seekNodeByName(aHeader , "userID")
		
	-- 	aUserID:setString("sunhaozhi...")
		
	
	-- end
	------------------test code-----------------------------


	local sendBtn = gt.seekNodeByName(self.root, "Btn_send")
	local function sendFunc()
		gt.log("sendmessage ========================= ")
		if self.isSendingInviteID then
			return
		end
		local inviteid = self.inviteIDBox:getString()
		self:checkInviteAction( inviteid )
	end
	gt.addBtnPressedListener(sendBtn, sendFunc)

	local closeBtn = gt.seekNodeByName(self.root, "Btn_close")
	local function closeFunc()
		self:hide()
	end
	gt.addBtnPressedListener(closeBtn, closeFunc)

	local raffleBtn = gt.seekNodeByName(self.root, "Btn_raffle")
	local function raffleFunc(  )
		gt.log("=======================raffleFunc  ")
		
		if not gt.isSendActivities then
			gt.isSendActivities = true
			local MainScene = require("app/views/MainScene")
			MainScene:sendGetActivities()
			-- self:sendGetActivities()
		end
	end
	gt.addBtnPressedListener(raffleBtn, raffleFunc)

	local _csbFile = "ActivityInviteBtnAct_1.csb"
	local actcsbNode = cc.CSLoader:createNode(_csbFile)
	local actionLine = cc.CSLoader:createTimeline(_csbFile)
   	actionLine:gotoFrameAndPlay(0, 72,true)
   	actcsbNode:runAction(actionLine)
   	actcsbNode:setPosition(cc.p(99,99))
   	raffleBtn:addChild(actcsbNode)
	self.raffleNumText = gt.seekNodeByName(raffleBtn, "remainNum")
	gt.inviteRaffleNumText = self.raffleNumText
	-- init data 
	-- 抽奖次数
	gt.log("self.infoTbl ================ "..self.infoTbl.m_drawChance)
	local remainNum = self.infoTbl.m_drawChance or 0
	gt.raffleChanceNum = remainNum
	self:setRemainRaffleNum( remainNum )

	-- 用户头像
	local invitedUsers = self.infoTbl.m_invitedUsers or {{"haosdsdaddssadada"},{"sdad9887r3hwih"}}
	for i=1,5 do
		local aHeader = gt.seekNodeByName(self.headerNode , "header_"..i)
		local aUserID = gt.seekNodeByName(aHeader , "userID")
		local aUserInfo = invitedUsers[i]
		if not aUserInfo then
			aHeader:setVisible(false)
		else
			local showName = gt.checkName(aUserInfo[2],5)
			aUserID:setString(showName.."...")
			-- aUserInfo[3] = "http://imgsrc.baidu.com/forum/pic/item/8806dd54564e9258ba2506bd9882d158ccbf4e71.jpg"
			local face = string.sub(aUserInfo[3], 1, string.lastString(aUserInfo[3], "/")) .. "96"
			self.playerHeadMgr:attach(aHeader, aUserInfo[1], face)
		end

		-- gt.log("i ========= "..i.."  aHeader ============ "..aUserInfo.m_headImageUrl.."  userId = "..aUserInfo.m_userId)
		-- aUserID:setString(aUserInfo.m_userId)
	end
end

function ActivityInviteDialog:checkInviteAction( inviteid )
	-- 判断 inviteid 是否存在
	if not inviteid or inviteid == "" then
		require("app/views/NoticeTips"):create("提示", "邀请人ID不能为空！", nil, nil, true)
		return
	end

	-- 判断 inviteid 是不是纯数字
	inviteid = tonumber(inviteid)
	if not inviteid then
		require("app/views/NoticeTips"):create("提示", "请输入正确的邀请人ID格式！", nil, nil, true)
		return
	end

	-- require("app/views/NoticeTips"):create("提示", "invite 客户端 认为合法 请求 request", nil, nil, true)
	-- invite 客户端 认为合法 请求 request 
	gt.log("==================== checkInviteAction ")
	local msgTbl = {}
	msgTbl.m_inviter = inviteid
	msgTbl.m_userId = tonumber(gt.m_id)
	msgTbl.m_msgId = gt.CG_ACTIVITY_REQUEST_INVITE
	gt.socketClient:sendMessage( msgTbl )
	self.isSendingInviteID = true
end

function ActivityInviteDialog:onNodeEvent(eventName)
	if "enter" == eventName then
		
	elseif "exit" == eventName then
		gt.inviteRaffleNumText = nil
		gt.isSendInviteActivities = false
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end


function ActivityInviteDialog:setRemainRaffleNum( num )
	num = num or 1
	self.raffleNumText:setString(num)
end

function ActivityInviteDialog:show( parent , zOrder )
	parent = parent or cc.Director:getInstance():getRunningScene()
	zOrder = zOrder or 60 -- notice tip 的 层级是 67 ，要比67 小
	parent:addChild(self,zOrder)
end

function ActivityInviteDialog:hide(  )
	self:removeFromParent()
end

return ActivityInviteDialog