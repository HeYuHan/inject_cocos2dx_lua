cc.FileUtils:getInstance():setPopupNotify(false)

local writePath = cc.FileUtils:getInstance():getWritablePath()
local resSearchPaths = {
	writePath,
	writePath .. "src_et/",
	writePath .. "src/",
	writePath .. "res/sd/",
	writePath .. "res/",
	"src_et/",
	"src/",
	"res/sd/",
	"res/"
}
cc.FileUtils:getInstance():setSearchPaths(resSearchPaths)

require "config"
require "cocos.init"

local function main()
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

function __G__TRACKBACK__(errorMsg)
	print("BUGLY-----LUA ERROR:"..tostring(errorMsg).."\n")
	print(debug.traceback(""))

	local message = errorMsg
	 if buglyReportLuaException and not gt.debugMode then
   		buglyReportLuaException(tostring(message), debug.traceback())
   	end
end