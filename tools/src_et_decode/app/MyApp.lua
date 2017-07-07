

require("app/UtilityTools")
require("app/localizations/LocationUtil")

local gt = cc.exports.gt

local MyApp = class("MyApp", cc.load("mvc").AppBase)

function MyApp:ctor()
	gt.setRandomSeed()

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	local customListenerBg = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND_EVENT",
								handler(self, self.onEnterBackground))
	eventDispatcher:addEventListenerWithFixedPriority(customListenerBg, 1)
	local customListenerFg = cc.EventListenerCustom:create("APP_ENTER_FOREGROUND_EVENT",
								handler(self, self.onEnterForeground))
	eventDispatcher:addEventListenerWithFixedPriority(customListenerFg, 1)

	-- 音效引擎
	gt.soundEngine = require("app/Sound"):create()

	cc.Device:setKeepScreenOn(true)

	if gt.debugMode then
		cc.Director:getInstance():setDisplayStats(false)--显示FPS帧数
	end
end

function MyApp:run()
	local loginScene = require("app/views/LogoScene"):create()
	cc.Director:getInstance():replaceScene(loginScene)

	-- if gt.localVersion then
	-- 	local loginScene = require("app/views/LoginScene"):create()
	-- 	cc.Director:getInstance():replaceScene(loginScene)
	-- else
	-- 	local updateScene = require("app/views/UpdateScene"):create()
	-- 	cc.Director:getInstance():runWithScene(updateScene)
	-- end

	-- -- 30s启动Lua垃圾回收器
	-- gt.scheduler:scheduleScriptFunc(function(delta)
	-- 	local preMem = collectgarbage("count")
	-- 	-- 调用lua垃圾回收器
	-- 	for i = 1, 3 do
	-- 		collectgarbage("collect")
	-- 	end
	-- 	local curMem = collectgarbage("count")
	-- 	gt.log(string.format("Collect lua memory:[%d] cur cost memory:[%d]", (curMem - preMem), curMem))
	-- 	local luaMemLimit = 30720
	-- 	if curMem > luaMemLimit then
	-- 		gt.log("Lua memory limit exceeded!")
	-- 	end
	-- end, 30, false)
end

function MyApp:onEnterBackground()
	gt.soundEngine:pauseAllSound()
end

function MyApp:onEnterForeground()
	gt.soundEngine:resumeAllSound()

	-- 发送心跳，判断链接是否已经断开
	if gt.socketClient then
		gt.socketClient:sendHeartbeat(true)
	end
end

return MyApp
