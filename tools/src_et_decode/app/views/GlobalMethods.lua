
--存放全局函数

local function checkVersion(_bai, _shi, _ge)
	local ok, appVersion = nil
	if gt.isIOSPlatform() then
		local luaBridge = require("cocos/cocos2d/luaoc")
		ok, appVersion = luaBridge.callStaticMethod("AppController", "getVersionName")
	elseif gt.isAndroidPlatform() then
		local luaBridge = require("cocos/cocos2d/luaj")
		ok, appVersion = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	else
		appVersion = "1.0.1"
	end
	local versionNumber = string.split(appVersion, '.')
	gt.log("versionNumber = "..appVersion)
	gt.dump(versionNumber)
	if tonumber(versionNumber[1]) > _bai
		or tonumber(versionNumber[2]) > _shi
		or tonumber(versionNumber[3]) > _ge then
		gt.log("checkVersion true")
		return true
	end
	gt.log("checkVersion false")
	return false
end
gt.checkVersion = checkVersion

local function LastVersionNum()
	local ok, appVersion = nil
	if gt.isIOSPlatform() then
		local luaBridge = require("cocos/cocos2d/luaoc")
		ok, appVersion = luaBridge.callStaticMethod("AppController", "getVersionName")
	elseif gt.isAndroidPlatform() then
		local luaBridge = require("cocos/cocos2d/luaj")
		ok, appVersion = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	else
		appVersion = "1.0.1"
	end
	local versionNumber = string.split(appVersion, '.')
	return tonumber(versionNumber[3])
end
gt.LastVersionNum = LastVersionNum

local function isUseNewMusic( )
	if gt.LastVersionNum() < 4 then
		return false
	end

	return true;
end
gt.isUseNewMusic = isUseNewMusic

local function isCopyText()
	-- local ok, appVersion = nil
	-- if gt.isIOSPlatform() then
	-- 	local luaBridge = require("cocos/cocos2d/luaoc")
	-- 	ok, appVersion = luaBridge.callStaticMethod("AppController", "getVersionName")
	-- elseif gt.isAndroidPlatform() then
	-- 	local luaBridge = require("cocos/cocos2d/luaj")
	-- 	ok, appVersion = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	-- else
	-- 	appVersion = 101
	-- end

	-- local lastnum = string.sub(appVersion,-1)
	if gt.isIOSPlatform() then
		if gt.LastVersionNum() < 4 then
			return false
		else
			return true
		end
	elseif gt.isAndroidPlatform() then
		if gt.LastVersionNum() < 5 then
			return false
		else
			return true
		end
	elseif cc.PLATFORM_OS_MAC == gt.targetPlatform then
        return true
	else
		return false
	end
end
gt.isCopyText = isCopyText

local function CopyText(labString)
	if not labString or string.len(labString)==0 then return end
	if gt.isCopyText() then
		gt.log("labString = "..labString)
		if gt.isIOSPlatform() or (cc.PLATFORM_OS_MAC == gt.targetPlatform) then
			local luaBridge = require("cocos/cocos2d/luaoc")
			luaBridge.callStaticMethod("AppController", "copyStr",{copystr = labString})
		elseif gt.isAndroidPlatform() then
			local luaBridge = require("cocos/cocos2d/luaj")
			luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "copyStr",{labString})
		end
	end
end
gt.CopyText = CopyText

local function getCopyStr()
	gt.log("function is getCopyStr")
	local ok, ret
	if gt.isCopyText() then
		if gt.isIOSPlatform() or (cc.PLATFORM_OS_MAC == gt.targetPlatform) then
			local luaBridge = require("cocos/cocos2d/luaoc")
			ok, ret = luaBridge.callStaticMethod("AppController", "getCopyStr")
		elseif gt.isAndroidPlatform() then
			local luaBridge = require("cocos/cocos2d/luaj")
			ok, ret = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getClipText", nil, "()Ljava/lang/String;")
		else
			ret = ""
		end
	end
	local labString = ret
	if labString == nil or string.len(labString) == 0 then
		labString = ""
	end
	if string.len(labString) > 0 then
		gt.log("labString = "..labString)
	end
	return labString
end
gt.getCopyStr = getCopyStr

--获取跳转至游戏的url链接
local function getRoomIDUrl()
	local ok
	local ret = ""
	if gt.checkVersion(1, 0, 9) then
		if gt.isIOSPlatform() then
			local luaBridge = require("cocos/cocos2d/luaoc")
			ok, ret = luaBridge.callStaticMethod("AppController", "getRoomIDUrl")	
		-- elseif gt.isAndroidPlatform() then
		-- 	local luaBridge = require("cocos/cocos2d/luaj")
		-- 	ok, ret = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getRoomIDUrl", nil, "()Ljava/lang/String;")
		else
			ret = ""
		end
		if ret == nil or string.len(ret) == 0 then
			ret = ""
		end
		gt.log("getRoomIDUrl = "..ret)
	else
		ret = ""
	end
	return ret
end
gt.getRoomIDUrl = getRoomIDUrl

-- 牌桌内游戏延迟数颜色变化
local function InitCurrtimeColor(timelabel,timeNum)
	if timeNum >= 300 then
		timelabel:setColor(cc.c3b(255,0,0))
	elseif timeNum < 300 and timeNum >= 200 then
		timelabel:setColor(cc.c3b(255,85,0))
	elseif timeNum < 200 and timeNum >= 100 then
		timelabel:setColor(cc.c3b(255,170,0))
	elseif timeNum < 100 then
		timelabel:setColor(cc.c3b(255,255,0))
	end
end
gt.InitCurrtimeColor = InitCurrtimeColor

-- 字符串超长处理
local function checkName( str , long )
	local retStr = ""
	local num = 0
	local lenInByte = #str
	local x = 1
	local longth = long or 4
	for i=1,lenInByte do
		i = x
	    local curByte = string.byte(str, x)
	    local byteCount = 1;
	    if curByte>0 and curByte<=127 then
	        byteCount = 1
	    elseif curByte>127 and curByte<240 then
	        byteCount = 3
	    elseif curByte>=240 and curByte<=247 then
	        byteCount = 4
	    end
	    local curStr = string.sub(str, i, i+byteCount-1)
	    retStr = retStr .. curStr
	    x = x + byteCount
	    if x >= lenInByte then
	    	return retStr
	    end
	    num = num + 1
	    if num >= longth then
	    	return retStr
	    end
    end
    return retStr
end
gt.checkName = checkName

local function PalyTypeText(TypeState,TypeTable, BaseScore)
	gt.log("function is PalyTypeText"..TypeState)
	local TypeStr = ""
	if TypeState and TypeState == 101 then
		TypeStr = "血战到底"
	elseif TypeState and TypeState == 102 then
		TypeStr = "血流成河"
	elseif TypeState and TypeState == 103 then
		TypeStr = "三人两房血战"
	elseif TypeState and TypeState == 104 then
		TypeStr = "倒倒胡"
	elseif TypeState and TypeState == 105 then
		TypeStr = "四人两房"
	elseif TypeState and TypeState == 106 then
		TypeStr = "德阳麻将"
	elseif TypeState and TypeState == 107 then
		TypeStr = "三人三房麻将"
	elseif TypeState and TypeState == 108 then
		TypeStr = "绵阳麻将"
	elseif TypeState and TypeState == 109 then
		TypeStr = "宜宾麻将"
	elseif TypeState and TypeState == 110 then
		TypeStr = "万州麻将"
	elseif TypeState and TypeState == 111 then
		TypeStr = "泸州麻将"
		gt.log("TypeState = "..111)
	elseif TypeState and TypeState == 112 then
		TypeStr = "乐山麻将"
		gt.log("TypeState = "..112)
	elseif TypeState and TypeState == 115 or TypeState == 117 then
		TypeStr = "自贡麻将"
	elseif TypeState and TypeState == 113 then
		TypeStr = "南充麻将"
	elseif TypeState and TypeState == 114 then
		TypeStr = "广安麻将"
	elseif TypeState and TypeState == 116 then
		TypeStr = "雅安麻将"
	elseif TypeState and TypeState == 118 or TypeState == 119 then
		TypeStr = "内江麻将"
	elseif TypeState and TypeState == 120 then
		TypeStr = "二人麻将"
	end
	local tableStr = ""


	for i=1,#TypeTable do
	
		if TypeTable[i] == 20 then
			tableStr = tableStr .. "换三张 "
		elseif TypeTable[i] == 22 then
			tableStr = tableStr .. "自摸加底 "
		elseif TypeTable[i] == 23 then
			tableStr = tableStr .. "自摸加番 "
		elseif TypeTable[i] == 24 then
			tableStr = tableStr .. "2番 "
		elseif TypeTable[i] == 25 then
            tableStr = tableStr .. "3番 "
		elseif TypeTable[i] == 26 then
            if TypeState == 111 then
                tableStr = tableStr .. "20颗 "
            else
                tableStr = tableStr .. "4番 "
            end
		elseif TypeTable[i] == 27 then
			tableStr = tableStr .. "幺九将对 "
		elseif TypeTable[i] == 28 then
			tableStr = tableStr .. "门清中张 "
		elseif TypeTable[i] == 29 then
			tableStr = tableStr .. "点杠花(点炮) "
		elseif TypeTable[i] == 30 then
			tableStr = tableStr .. "点杠花(自摸) "
		elseif TypeTable[i] == 31 then
			tableStr = tableStr .. "1拖1 "
		elseif TypeTable[i] == 32 then
			tableStr = tableStr .. "1拖2 "
		elseif TypeTable[i] == 33 then
			tableStr = tableStr .. "3拖5 "
		elseif TypeTable[i] == 34 then
			tableStr = tableStr .. "天地胡 "
		elseif TypeTable[i] == 1 then
			tableStr = tableStr .. "自摸胡 "
		elseif TypeTable[i] == 2 then
			tableStr = tableStr .. "点炮胡(可抢杠) "
		elseif TypeTable[i] == 5 then
			tableStr = tableStr .. "可胡七对 "
		elseif TypeTable[i] == 35 then
                tableStr = tableStr .. "7张 "
		elseif TypeTable[i] == 36 then
			tableStr = tableStr .. "10张 "
		elseif TypeTable[i] == 37 then
                tableStr = tableStr .. "13张 "
		elseif TypeTable[i] == 38 then
			tableStr = tableStr .. "卡二条 "
		elseif TypeTable[i] == 39 then
			gt.log("=====bbb===" .. TypeState)
			if TypeState == 115 then
				tableStr = tableStr .. "平胡可接炮 "
            elseif TypeState == 120 then
				tableStr = tableStr .. "两分起胡 "
			else
				tableStr = tableStr .. "点炮可平胡 "
			end
		elseif TypeTable[i] == 40 then
			tableStr = tableStr .. "对对胡两番 "
		elseif TypeTable[i] == 41 then
			tableStr = tableStr .. "夹心五 "
		elseif TypeTable[i] == 101 then
            if TypeState == 111 then
                tableStr = tableStr .. "40颗 "
            else
                tableStr = tableStr .. "5番 "
            end
		elseif TypeTable[i] == 102 then
            if TypeState == 111 then
                tableStr = tableStr .. "80颗(5分起胡) "
            else
                tableStr = tableStr .. "6番 "
            end
		elseif TypeTable[i] == 103 then
			tableStr = tableStr .. "点炮胡 "
		elseif TypeTable[i] == 104 then
            if table.contains({118, 119}, TypeState) then -- 内江玩法
                tableStr = tableStr .. "飘 "
            else
                tableStr = tableStr .. "可飘 "
            end
		elseif TypeTable[i] == 150 then
			tableStr = tableStr .. "两家不躺 "
		elseif TypeTable[i] == 151 then
			if TypeState == 110 then
				tableStr = tableStr .. "报叫必胡 "
			elseif TypeState == 116 then
				tableStr = tableStr .. "廊起必胡 "
			else
				tableStr = tableStr .. "有躺必胡 "
			end
		elseif TypeTable[i] == 160 then
			tableStr = tableStr .. "血战到底 "
		elseif TypeTable[i] == 161 then
			if TypeState == 112 then
				tableStr = tableStr .. "幺鸡任用 "
			else
				tableStr = tableStr .. "幺鸡代 "
			end
		elseif TypeTable[i] == 171 then
			tableStr = tableStr .. "4鬼 "
		elseif TypeTable[i] == 172 then
			tableStr = tableStr .. "8鬼 "
		elseif TypeTable[i] == 173 then
			tableStr = tableStr .. "12鬼 "
		elseif TypeTable[i] == 47 then
			tableStr = tableStr .. "门清 "
		elseif TypeTable[i] == 48 then
			tableStr = tableStr .. "中张 "
		elseif TypeTable[i] == 49 then
			tableStr = tableStr .. "四幺鸡 "
		elseif TypeTable[i] == 50 then
			tableStr = tableStr .. "软碰可杠 "
		elseif TypeTable[i] == 0 then
			if TypeState == 112 or TypeState == 115 or TypeState == 116 or TypeState == 117 or
            TypeState == 118 or TypeState == 119 then
				tableStr = tableStr .. "自摸不加 "
			end
		elseif TypeTable[i] == 105 then
			tableStr = tableStr .. "不能飘 "
		elseif TypeTable[i] == 106 then
			tableStr = tableStr .. "飘3个 "
		elseif TypeTable[i] == 107 then
			tableStr = tableStr .. "飘4个 "
		elseif TypeTable[i] == 108 then
			tableStr = tableStr .. "飘5个 "
		elseif TypeTable[i] == 52 then
			if TypeState == 118 or TypeState == 119 then
                tableStr = tableStr .. "报叫 "
            else
                tableStr = tableStr .. "摆牌 "
            end
		elseif TypeTable[i] == 201 then
			tableStr = tableStr .. "幺九 "
		elseif TypeTable[i] == 202 then
			tableStr = tableStr .. "将对 "
		elseif TypeTable[i] == 203 then
			tableStr = tableStr .. "中发白 "
		elseif TypeTable[i] == 177 then
			tableStr = tableStr .. "字牌火箭 "
		elseif TypeTable[i] == 178 then
			tableStr = tableStr .. "大三元翻倍 "
		elseif TypeTable[i] == 179 then
			tableStr = tableStr .. "门大叠加 "
		elseif TypeTable[i] == 180 then
			tableStr = tableStr .. "定缺 "
		elseif TypeTable[i] == 181 then
			tableStr = tableStr .. "过手加颗可胡 "
		elseif TypeTable[i] == 182 then
			tableStr = tableStr .. "字牌飞机  "
		elseif TypeTable[i] == 183 then
			tableStr = tableStr .. "十八学士 "
		elseif TypeTable[i] == 184 then
            if table.contains({118, 119}, TypeState) then -- 内江玩法
                tableStr = tableStr .. "呼叫转移 "
            else
                tableStr = tableStr .. "转雨 "
            end
		elseif TypeTable[i] == 185 then
			tableStr = tableStr .. "查叫退税 "
		elseif TypeTable[i] == 186 then
			tableStr = tableStr .. "过水加番可胡 "
		elseif TypeTable[i] == 187 then
			tableStr = tableStr .. "关死 "
		elseif TypeTable[i] == 188 then
			tableStr = tableStr .. "4番(极品10分) "
		elseif TypeTable[i] == 189 then
			tableStr = tableStr .. "4番(极品16分) "
		elseif TypeTable[i] == 51 then
			tableStr = tableStr .. "点杠花(一人自摸) "
		elseif TypeTable[i] == 190 then
			tableStr = tableStr .. "缺门 "
		elseif TypeTable[i] == 191 then
			tableStr = tableStr .. "巴倒烫 "
		elseif TypeTable[i] == 192 then
			tableStr = tableStr .. "一般高 "
		elseif TypeTable[i] == 193 then
			tableStr = tableStr .. "豹子 "
		elseif TypeTable[i] == 162 then
			tableStr = tableStr .. "碰后可杠 "
		elseif TypeTable[i] == 204 then
			tableStr = tableStr .. "幺九将对3番 "
		elseif TypeTable[i] == 211 then
			tableStr = tableStr .. "无鬼1番 "
		elseif TypeTable[i] == 212 then
			tableStr = tableStr .. "无鬼2番 "
		elseif TypeTable[i] == 213 then
			tableStr = tableStr .. "无鬼3番 "
		elseif TypeTable[i] == 214 then
			tableStr = tableStr .. "杠上炮1番 "
		elseif TypeTable[i] == 215 then
			tableStr = tableStr .. "杠上炮2番 "
		elseif TypeTable[i] == 216 then
			tableStr = tableStr .. "杠上炮3番 "
		elseif TypeTable[i] == 217 then
			tableStr = tableStr .. "抢杠1番 "
		elseif TypeTable[i] == 218 then
			tableStr = tableStr .. "抢杠2番 "
		elseif TypeTable[i] == 219 then
			tableStr = tableStr .. "抢杠3番 "
        -- else -- 调试用
		-- 	tableStr = tableStr .. "未知" .. TypeTable[i] .. " "
		end
	end

    if BaseScore then
        tableStr = tableStr .. string.format("%d分", BaseScore)
    end

	return TypeStr,tableStr
end
gt.PalyTypeText = PalyTypeText

local function updateNewApp( )
	--打开系统的浏览器
	if gt.isIOSPlatform() then
		local luaBridge = require("cocos/cocos2d/luaoc")
		local ok = luaBridge.callStaticMethod("AppController", "openWebURL", {webURL = gt.shareWeb})
	elseif gt.isAndroidPlatform() then
		local luaBridge = require("cocos/cocos2d/luaj")
		local ok = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL", {gt.shareWeb}, "(Ljava/lang/String;)V")
	end
end
gt.updateNewApp = updateNewApp

local function getBundleID()
	if not gt.gameBundleId then
		if gt.isIOSPlatform() and gt.checkVersion(1, 0, 4) then
			local luaBridge = require("cocos/cocos2d/luaoc")
			local ok, bundleId = luaBridge.callStaticMethod("AppController", "getBundleID")

			gt.gameBundleId = bundleId
	    end
	end

	-- gt.gameBundleId = "com.xianlai.mahjonghntwo"

	return gt.gameBundleId
end
gt.getBundleID = getBundleID

local function getRechargeConfig()
	gt.log("function is getRechargeConfig")
	local rechargeConfig = {}

	if gt.checkVersion(1, 0, 4) then
		local luaBridge = require("cocos/cocos2d/luaoc")
		local ok, ret = luaBridge.callStaticMethod("AppController", "getBundleID")
		if ret == "com.game.xiongmao" then
			rechargeConfig = require("app/views/Purchase/Recharge")
		elseif ret == "com.sichuan.majiangxmjh" then
			rechargeConfig = require("app/views/Purchase/Recharge_1090515")
		elseif ret == "com.game.sichuan" then
			rechargeConfig = require("app/views/Purchase/Recharge_10100615")
		end
	end

	return rechargeConfig

end
gt.getRechargeConfig = getRechargeConfig

local function checkIAPState()
	if gt.checkVersion(1, 0, 4) and gt.isIOSPlatform() then
		gt.isOpenIAP = true
	else
		gt.isOpenIAP = false
	end

	return gt.isOpenIAP
end
gt.checkIAPState = checkIAPState

-- 带子结点控件点击事件（子结点同时缩放）
local function addTouchEventListener(btn, listener, sfxType, scale)
	if not btn or not listener then
		return
	end

	if not scale then
		scale = -0.1
	end

	local oriScale = btn:getScale()

	btn:addTouchEventListener(function(uiwidget, eventType)
		if eventType == 0 then
			btn:runAction(cc.ScaleTo:create(0.05, oriScale+scale))
			return true
		end

		if eventType == 2 then
			btn:runAction(cc.ScaleTo:create(0.05, oriScale))
			listener(uiwidget)
		end

		if eventType == 3 then
			btn:runAction(cc.ScaleTo:create(0.05, oriScale))
		end
	end)

end

gt.addTouchEventListener = addTouchEventListener
local function ActionNewChild(node, type, param)
	local action = {}
	local callBack = param.callBack
	local delay = param.delay == nil and 0.2 or param.delay
	--------------------------------------------------------
	if type == gt.Action_Type.Fade_in then
		action[#action + 1] = cc.FadeIn:create(delay)
	elseif type == gt.Action_Type.Fade_out then
		action[#action + 1] = cc.FadeOut:create(delay)
	elseif type == gt.Action_Type.Move_left_in then
		local action = cc.FadeIn:create(delay)
		local actionease = cc.EaseIn:create(cc.Moveto:create(delay,cc.p(param.targetX,param.targetY)),5.0)
		action[#action + 1] = cc.Spawn:create(action, actionease)
		--node:setPosition(param.startX, param.startY)
	elseif type == gt.Action_Type.Move_left_out then
		local action = cc.FadeOut:create(delay)
		local actionease = cc.EaseOut:create(cc.Moveto:create(delay,cc.p(param.targetX,param.targetY)),5.0)
		action[#action + 1] = cc.Spawn:create(action, actionease)
		--node:setPosition(param.startX, param.startY)
	elseif type == gt.Action_Type.Move_right_in then

	elseif type == gt.Action_Type.Move_right_out then

	elseif type == gt.Action_Type.Move_top_in then

	elseif type == gt.Action_Type.Move_top_out then

	elseif type == gt.Action_Type.Move_bottom_in then

	elseif type == gt.Action_Type.Move_bottom_out then

	elseif type == gt.Action_Type.Move_scale_in then
		node:setScale(0.01)
		local action1 = cc.FadeIn:create(delay)
		local actionease = cc.EaseBackOut:create(cc.ScaleTo:create(delay,1,1))
		action[#action + 1] = cc.Spawn:create(action1, actionease)
	elseif type == gt.Action_Type.Move_scale_out then
		local action1 = cc.FadeOut:create(delay)
		local actionease = cc.EaseBackIn:create(cc.ScaleTo:create(delay,0.01,0.01))
		action[#action + 1] = cc.Spawn:create(actionease)
	else
		return
	end
	if param.callBack then
		action[#action + 1] = cc.CallFunc:create(function()
			param.callBack()
		end)
	end
	node:runAction(cc.Sequence:create(action))
end
gt.ActionNewChild = ActionNewChild

local function _groupNode(group, name, child) -- 聚合序列节点为数组
    local _pre, _num = string.match(name, "(.+)(%d+)$")
    if not _pre then
        return
    end

    if string.sub(_pre, -1) == "_" then
        _pre = string.sub(_pre, 1, #_pre-1)
    end

    if not group[_pre] then
        group[_pre] = {}
    end

    group[_pre][_num] = child
end

-- 绑定csb中符合bind规则的节点到attachedTo上，便于访问节点
local function loadCSB(csbName, attachedTo)
	local csbNode = cc.CSLoader:createNode(csbName)

  if not attachedTo then
    attachedTo = csbNode
  end

  gt.bindNodeByName(csbNode, attachedTo)

  return csbNode
end
gt.loadCSB = loadCSB

local function bindNodeByName(node, attachedTo)
  local matchTable = {spr_=true, nod_=true, btn_=true, chk_=true,
                      img_=true, lbl_=true, prg_=true, lst_=true,
                      pnl_=true, scr_=true}

  for _, child in ipairs(node:getChildren()) do
    local nodeName = child:getName()
    local nodeNameSub = string.sub(nodeName, 0, 4)

    if matchTable[nodeNameSub] then
      attachedTo[nodeName] = child
    end

    bindNodeByName(child, attachedTo)
  end
end
gt.bindNodeByName = bindNodeByName

gt.runCSBAction = function(node, csbName, isLoopAction)
    local _action = cc.CSLoader:createTimeline(csbName)
    _action:gotoFrameAndPlay(0, isLoopAction)
    node:runAction(_action)
end

gt.runCSBActionOnce = function(node, csbName)
    local _action = cc.CSLoader:createTimeline(csbName)
    _action:gotoFrameAndPlay(0, false)
    node:runAction(_action)

    local time = _action:getDuration()/60
    local _a = cc.Sequence:create(cc.DelayTime:create(time), cc.RemoveSelf:create())
    node:runAction(_a)
end

-- 可以统一给node的list调用函数
-- 示例gt.NodeArray(node1, node2, node3):setVisible(false):setScale(1)
local function NodeArray(...)
    local na = {}
    local mt = {}
    setmetatable(na, mt)

    mt.__index = function(t, method)
        -- key在map中直接返回
        if t.map[method] then
            return t.map[method]
        end

        -- key不在map中当成一次函数调用
        local function _call(_na, ...)
            for _, node in ipairs(_na.data) do
                node[method](node, ...)
            end

            return _na
        end
        return _call
    end

    na.data = {...}
    na.map = {} -- 配合findNodeArray使用

    na.dump = function(_na)
        local _dumpArray = {data={}, map=_na.map}

        for _, _node in ipairs(_na.data) do
            table.insert(_dumpArray.data, _node:getName() .. " " .. tostring(_node))
        end

        dump(_dumpArray)

        return _na
    end

    return na
end
gt.NodeArray = NodeArray

-- 返回一个NodeArray实例
local function findNodeArray(rootNode, ...)
    local _list = gt.NodeArray()
    local _matchTable = {}
    local _parentMatchTable = {}

    local function _addKey2MatchTable(t, key, value)
        if string.find(key, "#") then -- 该子项为一个序列
            local _keyPrefix, _startStr, _endStr = string.match(key, "(.+)#(.+)#(.+)")

            for j=tonumber(_startStr), tonumber(_endStr) do
                local _originT = t[_keyPrefix .. j] or {}
                for k,v in pairs(_originT) do value[k] = v end
                t[_keyPrefix .. j] = value
            end
        else
            t[key] = value
        end
    end

    local function _parseParam(...)
        for _, key in ipairs({...}) do
            if type(key) == "table" then
                local _childMatchTable = {}
                for i=2, table.maxn(key) do
                    _addKey2MatchTable(_childMatchTable, key[i], true)
                end

                _addKey2MatchTable(_parentMatchTable, key[1], _childMatchTable)
            else
                _addKey2MatchTable(_matchTable, key, true)
            end
        end
    end

    local function _findNodes(_rootNode, parentNode, parentMatch)
        if _parentMatchTable[_rootNode:getName()] then -- 该节点在父节点列表
            parentNode = _rootNode
            parentMatch = _parentMatchTable[_rootNode:getName()]
        end

        for _, _child in ipairs(_rootNode:getChildren()) do
            local _nodeName = _child:getName()

            if parentNode then
                if parentMatch[_nodeName] then
                    parentNode[_nodeName] = _child
                    table.insert(_list.data, _child)
                    _groupNode(parentNode, _nodeName, _child)
                end
            else
                if _matchTable[_nodeName] then
                    table.insert(_list.data, _child)
                    _list.map[_nodeName] = _child
                    _groupNode(_list.map, _nodeName, _child)
                end
                if _parentMatchTable[_nodeName] then
                    _list.map[_nodeName] = _child
                    _groupNode(_list.map, _nodeName, _child)
                end
            end

            _findNodes(_child, parentNode, parentMatch)
        end
    end

    -- TODO 统计下未找到的key，并在debug模式下打印出来
    _parseParam(...)
    _findNodes(rootNode)

    return _list
end
gt.findNodeArray = findNodeArray

-- Lua extends
table.contains = function(tbl, element)
    assert(type(tbl) == "table", "First param must be a table")

    for _, el in pairs(tbl) do
        if el == element then
            return true
        end
    end

    return false
end

-- check a string is 微信号 or not
-- 微信号规则： 微信帐号支持6-20个字母、数字、下划线和减号，必须以字母开头。
local function checkWXNumberStatus( checkStr )
	if not checkStr then
		return false
	end
	checkStr = tostring(checkStr)
	local length = #checkStr

	-- check code is 字母、数字、下划线和减号 or not 
	local function checkCodeLegal( aCode , mustLetter )
		-- 必须为字母
		local asciiValue = string.byte(aCode)
		if mustLetter then
			if (asciiValue >= string.byte("A") and asciiValue <= string.byte("Z")) or
				(asciiValue >= string.byte("a") and asciiValue <= string.byte("z")) then
				return true
			else
				return false
			end
		else
			if (asciiValue >= string.byte("A") and asciiValue <= string.byte("Z")) or
				(asciiValue >= string.byte("a") and asciiValue <= string.byte("z")) or
				tonumber(aCode) or (aCode == "_") or (aCode == "-") then
				return true
			else
				return false
			end
		end
	end

	if length >= 6 and length <= 20 then
		-- check is a phone number or not 
		if length == 11 and tonumber(checkStr) then
			gt.log(" --------- 合法的手机号 ")
			return true
		end

		-- check is 微信号 or not  
		-- 字母开头
		for i=1,length do
			local achar = string.sub(checkStr,i,i) --首字符必须为字母
			if not checkCodeLegal(achar,i == 1) then
				return false
			end
		end
		return true
	else
		return false
	end
end
gt.checkWXNumberStatus = checkWXNumberStatus

--浮动文本(可做提示，不弹二级弹窗)
local function floatText(content)
	gt.golbalZOrder = 10000
	if string.len(gt.fontNormal) == 0 then
		gt.fontNormal = "res/fonts/DFYuanW7-GB2312.ttf"
	end
	if not content or content == "" then
		return
	end

	local offsetY = 20
	local rootNode = cc.Node:create()
	rootNode:setPosition(cc.p(gt.winCenter.x, gt.winCenter.y - offsetY))

	local bg = cc.Scale9Sprite:create("res/sd/images/otherImages/float_text_bg.png")
	local capInsets = cc.size(200, 5)
	local textWidth = bg:getContentSize().width - capInsets.width * 2
	bg:setScale9Enabled(true)
	bg:setCapInsets(cc.rect(capInsets.width, capInsets.height, bg:getContentSize().width - capInsets.width, bg:getContentSize().height - capInsets.height))
	bg:setAnchorPoint(cc.p(0.5, 0.5))
	bg:setGlobalZOrder(gt.golbalZOrder)
	gt.golbalZOrder = gt.golbalZOrder + 1
	rootNode:addChild(bg)

	local ttfConfig = {}
	ttfConfig.fontFilePath = gt.fontNormal
	ttfConfig.fontSize = 38
	local ttfLabel = cc.Label:createWithSystemFont( content, gt.fontNormal, 38)
	ttfLabel:setGlobalZOrder(gt.golbalZOrder)
	gt.golbalZOrder = gt.golbalZOrder + 1
	ttfLabel:setTextColor(cc.YELLOW)
	ttfLabel:setAnchorPoint(cc.p(0.5, 0.5))
	rootNode:addChild(ttfLabel)

	if ttfLabel:getContentSize().width > textWidth then
		bg:setContentSize(cc.size(bg:getContentSize().width + (ttfLabel:getContentSize().width - textWidth), bg:getContentSize().height))
	end
	
	local action = cc.Sequence:create(
		cc.MoveBy:create(0.8, cc.p(0, 120)),
		cc.CallFunc:create(function()
			rootNode:removeFromParent(true)
		end)
	)
	cc.Director:getInstance():getRunningScene():addChild(rootNode)
	rootNode:runAction(action)
end
gt.floatText = floatText

-- 格式化金币格式
local function formatCoinNumber( num , boundaryNum , unitNum )
	if not num then return 0 end

	boundaryNum = boundaryNum or 1000000

	if num < boundaryNum then return num end
	-- if tempUnitNum > boundaryNum or num then return num end
	local unitNumConf = {
		"十",
		"百",
		"千",
		"万",
		"十万",
		"百万",
	}
	unitNum = unitNum or 4
	
	local tempUnitNum = math.pow(10,unitNum)
	
	num = num / tempUnitNum

	if num >= 1000 then
		num = math.floor(num)
	elseif num >= 100 then
		num = string.format("%0.1f", num)
		gt.log("num ============"..num)
	end
	num = num .. (unitNumConf[unitNum] or "")

	return num
end
gt.formatCoinNumber = formatCoinNumber

local function dadianDataAdd(logId, windowId, actionId)
    gt.dadianData = gt.dadianData or {}
    local gameId = "15001"
    local time = os.date("%Y-%m-%d %H:%M:%S")

    local _t = {logId, time, gameId, gt.playerData.uid, windowId, actionId}
    dump(_t)
    table.insert(gt.dadianData, table.concat(_t, "|"))
    dump(gt.dadianData)
end
gt.dadianDataAdd = dadianDataAdd

local function dadianDataSend()
    if not gt.dadianData or #gt.dadianData == 0 then return end

    local url = "http://120.76.194.200:7480/xlhy-activity/shareLog/saveLog"
    if not gt.debugMode then
        url = "https://active.xianlaigame.com/xlhy-activity/shareLog/saveLog"
    end

    require("json")
    local sendData = json.encode(gt.dadianData)
    sendData = string.format("logData=%s", sendData)
    dump(url)
    dump(sendData)

    local xhr = cc.XMLHttpRequest:new()
    xhr:open("POST", url)

    local function onResp()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            gt.log("发送打点数据成功")
			dump(xhr.response)
        elseif xhr.readyState == 1 and xhr.status == 0 then
            gt.log("发送打点数据失败")
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onResp)
	xhr:send(sendData)

    gt.dadianData = nil
end
gt.dadianDataSend = dadianDataSend
