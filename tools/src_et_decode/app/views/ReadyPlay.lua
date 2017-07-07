
local gt = cc.exports.gt

local ReadyPlay = class("ReadyPlay")

function ReadyPlay:ctor(csbNode, paramTbl)
	self.isRoomCreater = false
	if paramTbl.playerSeatPos == 0 then
		-- 0位置是房主
		self.isRoomCreater = true
	end

	-- 房间号
	self.roomID = paramTbl.roomID

	-- 准备节点（子节点：邀请好友，解散房间，返回大厅）
	local readyPlayNode = gt.seekNodeByName(csbNode, "Node_readyPlay")

	-- 邀请好友
	local inviteFriendBtn = gt.seekNodeByName(readyPlayNode, "Btn_inviteFriend")
	gt.addBtnPressedListener(inviteFriendBtn, function()
		local TypeStr,tableStr = gt.PalyTypeText(paramTbl.m_state,paramTbl.playtypebranch)
		local description = string.format("房号:[%d],%d局,%s",self.roomID,paramTbl.roundMaxCount,tableStr)
		local title = "熊猫麻将".."<"..TypeStr..">"

		gt.RealshareRoomIdUrl = gt.shareRoomIdUrl.."?roomId="..self.roomID
		gt.log("gt.RealshareRoomIdUrl = "..gt.RealshareRoomIdUrl)
		if gt.checkVersion(1, 0, 9) then
			if gt.isIOSPlatform() then
				local luaoc = require("cocos/cocos2d/luaoc")
				local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
					{url = gt.RealshareRoomIdUrl, title = title, description = description})
			elseif gt.isAndroidPlatform() then
				local luaj = require("cocos/cocos2d/luaj")
				local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
					{gt.RealshareRoomIdUrl, title, description},
					"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
			end
		else
			--tips:更新包之后改url
			if gt.isIOSPlatform() then
				local luaoc = require("cocos/cocos2d/luaoc")
				local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
					{url = gt.shareiosWeb, title = title, description = description})
			elseif gt.isAndroidPlatform() then
				local luaj = require("cocos/cocos2d/luaj")
				local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
					{gt.shareWeb, title, description},
					"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
			end
		end
	end)

	if gt.isInReview then
		inviteFriendBtn:setVisible(false)
	else
		inviteFriendBtn:setVisible(true)
	end

	-- 返回大厅
	local backSalaBtn = gt.seekNodeByName(readyPlayNode, "Btn_outRoom")
	gt.addBtnPressedListener(backSalaBtn, function()
		-- 返回大厅提示
		local tipsContentKey = "LTKey_0019"
		if self.isRoomCreater then
			tipsContentKey = "LTKey_0010"
		end
		if paramTbl.m_state == 1102 then
			tipsContentKey = "LTKey_0019"
		end
		require("app/views/NoticeTips"):create(
			gt.getLocationString("LTKey_0009"),
			gt.getLocationString(tipsContentKey),
			function()
				gt.showLoadingTips(gt.getLocationString("LTKey_0016"))

				local msgToSend = {}
				msgToSend.m_msgId = gt.CG_QUIT_ROOM
				msgToSend.m_pos = paramTbl.playerSeatPos
				gt.socketClient:sendMessage(msgToSend)
				gt.dump(msgToSend)
			end)
	end)
	gt.socketClient:registerMsgListener(gt.GC_QUIT_ROOM, self, self.onRcvQuitRoom)

	-- 解散房间
	local dimissRoomBtn = gt.seekNodeByName(readyPlayNode, "Btn_dimissRoom")

	local ls_12 = gt.getLocationString("LTKey_0012")
	if gt.isIOSPlatform() and gt.isInReview then
		ls_12 = gt.getLocationString("LTKey_0012_1")
	end

	gt.addBtnPressedListener(dimissRoomBtn, function()
		require("app/views/NoticeTips"):create(
			gt.getLocationString("LTKey_0011"),
			ls_12,
			function()
				local msgToSend = {}
				msgToSend.m_msgId = gt.CG_DISMISS_ROOM
				msgToSend.m_pos = paramTbl.playerSeatPos
				gt.socketClient:sendMessage(msgToSend)
				gt.CopyText(" ")
			end)
	end)
	gt.socketClient:registerMsgListener(gt.GC_DISMISS_ROOM, self, self.onRcvDismissRoom)

	if paramTbl.m_state == 1102 then
		dimissRoomBtn:setVisible(false)
		inviteFriendBtn:setVisible(false)
	end

	-- 隐藏非房主无法操作的按钮
	if not self.isRoomCreater then
		dimissRoomBtn:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 返回大厅
-- end --
function ReadyPlay:onRcvQuitRoom(msgTbl)
	gt.dump(msgTbl)
	gt.removeLoadingTips()

	if msgTbl.m_errorCode == 0 then
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE, self.isRoomCreater, self.roomID)
	else
		-- 提示返回大厅失败
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0045"), nil, nil, true)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 房间创建者解散房间
-- end --
function ReadyPlay:onRcvDismissRoom(msgTbl)

	gt.log("进入消息id27的回调函数")
	dump(msgTbl)

	if msgTbl.m_errorCode == 1 then
		-- 游戏未开始解散成功
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE)
	else
		-- 游戏中玩家申请解散房间
		gt.dispatchEvent(gt.EventType.APPLY_DIMISS_ROOM, msgTbl)
	end
end

return ReadyPlay


