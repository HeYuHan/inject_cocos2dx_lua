
local gt = cc.exports.gt

gt.name_s = "d8dbfeeaf12"
gt.name_e = "25f1fd508b1"
gt.chu_wan = 5
gt.zhong_wan = 6
gt.gao_wan = 7
gt.gu_wan = 8

gt.loginGaoFang = "scxm.xianlaiyx.com"

local ipStrategy = {}

ipStrategy.state = {

	IPSERVER = 1,

	IPCDN = 2,

	IPGAOFANG = 3,

	ERROR = 4

}

ipStrategy.ip = ""
ipStrategy.port = ""
ipStrategy.loginStateType = 0

function ipStrategy:getIpByIpServer()

	gt.log("get ip 1 ........ ")
	gt.showLoadingTips(gt.getLocationString("LTKey_0054_6"))

	local servername = "sichuan"
	local srcSign = string.format("%s%s", gt.unionid, servername)
	local sign = cc.UtilityExtension:generateMD5(srcSign, string.len(srcSign))
	local xhr = cc.XMLHttpRequest:new()
	self.xhr_un = xhr
	xhr.timeout = 3

	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.erripserverhandler), 3, false)

	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local refreshTokenURL = string.format("http://secureapisichuan.ixianlai.com/security/server/getIPbyZoneUid")
	xhr:open("POST", refreshTokenURL)
	local function onResp()
		if self.scheduleHandler then
			gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
			self.scheduleHandler = nil
		end
		gt.log("xhr.readyState = " .. xhr.readyState .. ", xhr.status = " .. xhr.status.."get ip 1")
		gt.log("xhr.statusText = " .. xhr.statusText)
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			dump(response)
			require("json")
			local respJson = json.decode(response)
			if respJson.errorCode == 0 then 
				ipStrategy.ip = respJson.ip -- 记录ip策略获取的ip
				ipStrategy.loginStateType = ipStrategy.state.IPCDN
				self:connectSocket()
			else
				-- 没有返回ip 走cdn
				gt.removeLoadingTips()
				ipStrategy.loginStateType = ipStrategy.state.ERROR
				self:getIpGaoFang()
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 请求失败  
			gt.removeLoadingTips()
			ipStrategy.loginStateType = ipStrategy.state.ERROR
			self:getIpGaoFang()
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send(string.format("uuid=%s&servername=%s&sign=%s", gt.unionid, servername, sign))

end

function ipStrategy:erripserverhandler(delta)
	gt.log("function is erripserverhandler")
	self.xhr_un:unregisterScriptHandler()
	-- 请求失败  
	gt.removeLoadingTips()
	ipStrategy.loginStateType = ipStrategy.state.ERROR
	self:getIpGaoFang()
	if self.scheduleHandler then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		self.scheduleHandler = nil
	end
end

function ipStrategy:getCdnIp()

	gt.log("get ip 2 ........ ")
	gt.showLoadingTips(gt.getLocationString("LTKey_0054_6"))

	local playCount = tonumber(self:getPlayCount())
	if playCount ~= nil then
		gt.log("playCount:"..playCount)
		local filename = nil
		local num = 0
		if playCount < 21 then
			num = gt.chu_wan
		elseif playCount < 51 then
			num = gt.zhong_wan
		elseif playCount < 101 then
			num = gt.gao_wan
		else
			num = gt.gu_wan
		end
		if num > 0 and num < 9 then
			filename = self:getFileByNum(num)
			if filename then
				self:getYoYoFile(filename)
			end
		end
	end
end

function ipStrategy:getPlayCount()
	local playCount = cc.UserDefault:getInstance():getStringForKey("yoyo_name")
	if playCount ~= "" then
		local s = string.find(playCount, gt.name_s)
		local e = string.find(playCount, gt.name_e)
		if s and e then
			return string.sub(playCount, s + string.len(gt.name_s), e - 1)
		end
	end
	return 0
end

function ipStrategy:savePlayCount(count)
	local name = gt.name_s .. count .. gt.name_e
	cc.UserDefault:getInstance():setStringForKey("yoyo_name", name)
end

function ipStrategy:getAscii(uuid)
	gt.log("uuid:"..uuid)
	if not uuid then
		return 1
	end
	local ascii = string.byte(string.sub(uuid, #uuid - 1))
	return (ascii % 4) + 1
end

function ipStrategy:getFileByNum(num)
	local filename = "s_1_3_1_4_" .. num .. "_2_4_3"
	local md5 = cc.UtilityExtension:generateMD5(filename, string.len(filename))
	gt.log("filename:"..filename)
	gt.log("num:"..num)
	gt.log("md5:"..md5)
	return "http://allgame.ixianlai.com/sichuan_" .. md5 .. "_" .. num .. "_.txt"
end

function ipStrategy:getYoYoFile(filename)

	local xhr = cc.XMLHttpRequest:new()
	xhr.timeout = 5
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local refreshTokenURL = filename
	xhr:open("GET", refreshTokenURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			dump(xhr.response)
			local data = tostring(xhr.response)
	        if data then
				local ipTab = string.split(data, ".")
				if #ipTab == 4 then -- 正确的ip地址
					ipStrategy.ip = data 
					ipStrategy.loginStateType = ipStrategy.state.IPCDN
					self:connectSocket()
				else
					gt.removeLoadingTips()
					ipStrategy.loginStateType = ipStrategy.state.ERROR
					self:getIpGaoFang()
				end
	        end

		elseif xhr.readyState == 1 and xhr.status == 0 then
			gt.log("oss策略失败")
			-- 请求失败  走高仿
			gt.removeLoadingTips()
			ipStrategy.loginStateType = ipStrategy.state.ERROR
			self:getIpGaoFang()
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()

end

function ipStrategy:getIpGaoFang()
	
	gt.log("get ip 3 ........ ")
	gt.showLoadingTips(gt.getLocationString("LTKey_0054_6"))
	ipStrategy.ip = gt.loginGaoFang 
	ipStrategy.loginStateType = ipStrategy.state.IPGAOFANG
	self:connectSocket()

end

function ipStrategy:connectSocket()

	gt.log("connectSocket ..... ")
	gt.socketClient:close()
	local errorCode = gt.socketClient:connect(ipStrategy.ip, ipStrategy.port, true)
	if errorCode == true then
		if ipStrategy.ip ~= gt.loginGaoFang then
			--保存本地
			cc.UserDefault:getInstance():setStringForKey("LoginSuccessIp", ipStrategy.ip)
			gt.log("写入gt.LoginSuccessIp = "..ipStrategy.ip)
		end
		--  连接成功
		gt.socketClient:SendRelogin()
	else
		-- 连接失败
		-- gt.removeLoadingTips()
		if ipStrategy.loginStateType == ipStrategy.state.IPSERVER then
			-- 走cdn
			self:getCdnIp()

		elseif ipStrategy.loginStateType == ipStrategy.state.IPCDN then
			-- 走高仿
			self:getIpGaoFang()

		elseif ipStrategy.loginStateType == ipStrategy.state.IPGAOFANG then
			-- 直接弹框吧 没办法了
			
			-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0054_5"), function ()
				
			-- 	gt.socketClient.netWorkChangeFlag = true
			-- 	gt.socketClient.isReconnectFlag = false
			-- 	gt.socketClient:reloginServer()

			-- end, nil, true)
			-- return
		end
	end

end


-----------------------------ip策略域名解析失败----------------------------

function ipStrategy:getIpByIpServerError()

	gt.showLoadingTips(gt.getLocationString("LTKey_0054_6"))

	local servername = "sichuan"
	local srcSign = string.format("%s%s", gt.unionid, servername)
	local sign = cc.UtilityExtension:generateMD5(srcSign, string.len(srcSign))
	local xhr = cc.XMLHttpRequest:new()
	xhr.timeout = 5
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local refreshTokenURL = string.format("http://218.11.1.112/security/server/getIPbyZoneUid")
	xhr:open("POST", refreshTokenURL)
	local function onResp()
		gt.log("xhr.readyState = " .. xhr.readyState .. ", xhr.status = " .. xhr.status)
		gt.log("xhr.statusText = " .. xhr.statusText)
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			dump(response)
			require("json")
			local respJson = json.decode(response)
			if respJson.errorCode == 0 then 
				ipStrategy.ip = respJson.ip -- 记录ip策略获取的ip
				ipStrategy.loginStateType = ipStrategy.state.IPSERVER
				self:connectSocket()
			else
				-- 没有返回ip 走cdn
				gt.removeLoadingTips()
				ipStrategy.loginStateType = ipStrategy.state.ERROR
				self:getIpGaoFang()
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 请求失败  走cdn
			gt.removeLoadingTips()
			ipStrategy.loginStateType = ipStrategy.state.ERROR
			self:getIpGaoFang()
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send(string.format("uuid=%s&servername=%s&sign=%s", gt.unionid, servername, sign))

end

return ipStrategy