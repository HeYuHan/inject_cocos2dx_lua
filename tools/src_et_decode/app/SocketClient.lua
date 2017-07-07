-- Creator ArthurSong
-- Create Time 2016/1/29

local gt = cc.exports.gt

require("app/protocols/MessageInit")
require("socket")
local bit = require("app/libs/bit")
local loginStrategy = require("app/LoginIpStrategy")

local SocketClient = class("SocketClient")

function SocketClient:ctor()

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- 随机函数种子
	math.randomseed(os.time())
	
	-- 加载消息打包库
	local msgPackLib = require("app/libs/MessagePack")
	msgPackLib.set_number("integer")
	msgPackLib.set_string("string")
	msgPackLib.set_array("without_hole")
	self.msgPackLib = msgPackLib

	self:initSocketBuffer()

	-- 注册消息逻辑处理函数回调
	self.rcvMsgListeners = {}

	-- 收发消息超时
	self.timeDuration = 0

	-- 是否已经弹出网络错误提示
	self.isPopupNetErrorTips = false

	-- 登录到服务器标识
	self.isStartGame = false

	-- 断线重连开关heartbeat
	self.closeHeartBeat = true

	self.isReconnectFlag = false

	self.netWorkChangeFlag = false

	gt.resume_time = 8

	-- 发送心跳时间
	self.heartbeatCD = 4
	-- 心跳回复时间间隔
	-- 上一次时间间隔
	self.lastReplayInterval = 0
	-- 当前时间间隔
	self.curReplayInterval = 0

	-- 登录状态,有三次自动重连的机会
	-- self.loginReconnectNum = 0
	
	-- 用于消息头数据
	self.playerUUID = ""
	self.playerKeyOnGate = ""
	self.playerMsgOrder = 0

	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)

	-- local ok, appVersion = nil
	-- if gt.isIOSPlatform() then
	-- 	local luaoc = require("cocos/cocos2d/luaoc")
	-- 	ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
	-- elseif gt.isAndroidPlatform() then
	-- 	local luaj = require("cocos/cocos2d/luaj")
	-- 	ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	-- else
	-- 	appVersion = 102
	-- end

	-- local lastnum = string.sub(appVersion,-1)
	-- if tonumber(lastnum) > 2 then
	-- 	-- self.scheduleCheckNetWork = gt.scheduler:scheduleScriptFunc(handler(self, self.updateNetWork), 1, false)
	-- end
	
	gt.registerEventListener(gt.EventType.NETWORK_ERROR, self, self.networkErrorEvt)
end

function SocketClient:initSocketBuffer()
	-- 发送消息缓冲
	self.sendMsgCache = {}
	self.sendingBuffer = ""
	self.remainSendSize = 0
	
	-- 接收消息
	self.recvingBuffer = ""
	self.remainRecvSize = 12 --剩余多少数据没有接受完毕,2:头部字节数
	self.recvState = "Head"

end

-- start --
--------------------------------
-- @class function
-- @description 和指定的ip/port服务器建立socket链接
-- @param serverIp 服务器ip地址
-- @param serverPort 服务器端口号
-- @param isBlock 是否阻塞
-- @return socket链接创建是否成功
-- end --
function SocketClient:connect(serverIp, serverPort, isBlock)

	if not serverIp or not serverPort then
		return
	end

	self:initSocketBuffer()
	
	-- self.serverIp = serverIp
	self.serverPort = serverPort
	self.isBlock = isBlock

	gt.log("the ip is .." .. serverIp .. "the port is .. " .. serverPort)

	-- tcp 协议 socket
	local tcpConnection, errorInfo = self:getTcp(serverIp)
 	if not tcpConnection then
		gt.log(string.format("Connect failed when creating socket | %s", errorInfo))
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end
	self.tcpConnection = tcpConnection
	tcpConnection:setoption("tcp-nodelay", true)
	-- 和服务器建立tcp链接
	tcpConnection:settimeout(isBlock and 5 or 0)
	local connectCode, errorInfo = tcpConnection:connect(serverIp, serverPort)
	if connectCode == 1 then
		self.isConnectSucc = true
		self.isReconnectFlag = false
		gt.log("Socket connect success!")
	else
		gt.log(string.format("Socket %s Connect failed | %s", (isBlock and "Blocked" or ""), errorInfo))
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end
	self.curIpState = nil
	self.tcpConnection:settimeout(0)
	
	return true
end

function SocketClient:getTcp(host)
	local isipv6_only = false
	local addrinfo, err = socket.dns.getaddrinfo(host);
	if addrinfo ~= nil then
		for i,v in ipairs(addrinfo) do
			if v.family == "inet6" then
				isipv6_only = true;
				break
			end
		end
	end
	-- dump(socket.dns.getaddrinfo(host))
	print("isipv6_only", isipv6_only)
	if isipv6_only then
		return socket.tcp6()
	else
		return socket.tcp()
	end
end

function SocketClient:connectResume()
	
	if gt.debugIpGet then
		gt.showLoadingTips(gt.getLocationString("LTKey_0054_6"))
		self:close()
		loginStrategy.ip = gt.LoginServer.ip
		self:connect(gt.LoginServer.ip, gt.LoginServer.port, true)
		self:SendRelogin()
		return
	end

	-- 不用管当前是什么状态 什么scene  只要断掉都走重连
	if self.isReconnectFlag == false then
		
		gt.showLoadingTips(gt.getLocationString("LTKey_0054_6"))
		
		self.isReconnectFlag = true
		loginStrategy.port = gt.LoginServer.port

		--读取上次成功的本地IP
		gt.LoginSuccessIp = cc.UserDefault:getInstance():getStringForKey("LoginSuccessIp")
		if string.len(gt.LoginSuccessIp) ==  0 then
			gt.log("111111111111111")
			loginStrategy:getIpByIpServer()--为空走ip策略
		else
			gt.log("读取gt.LoginSuccessIp = "..gt.LoginSuccessIp.."the ip is ..101.201.245.46the port is .. 5031 ")

			self:close()
			loginStrategy.ip = gt.LoginSuccessIp

			local errorCode = gt.socketClient:connect(loginStrategy.ip, loginStrategy.port, true)
			if errorCode == true then
				self:SendRelogin()
				
			else
				gt.log("222222222222")
				loginStrategy:getIpByIpServer()
			end
		end

	end

end

-- start --
--------------------------------
-- @class function
-- @description 恢复链接
-- @param
-- @param
-- @param
-- @return
-- end --
function SocketClient:connectResumeBK()
	if self.isConnectSucc or not self.tcpConnection then
		-- 连接成功或者socket.tcp句柄创建失败
		return
	end

	local r, w, e = socket.select({self.tcpConnection}, {self.tcpConnection}, 0.02)
	if not w or e == "timeout" then
		gt.log("Socket select timeout")
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR)
		return false
	end
	local connectCode, errorInfo = self.tcpConnection:connect(self.serverIp, self.serverPort)
	if errorInfo ~= "already connected" then
		gt.log("Socket connect errorInfo: " .. errorInfo)
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR)
		return false
	end
	self.isConnectSucc = true
	-- 一旦重新连接上,则此ip又可作为下次连接的ip使用
	self.isReconnectFlag = false
	self.curIpState = nil
	return true
end

-- start --
--------------------------------
-- @class function
-- @description 关闭socket链接
-- end --
function SocketClient:close()
	if self.tcpConnection then
		self.tcpConnection:close()
	end
	self.tcpConnection = nil
	self.isConnectSucc = false
	self.sendMsgCache = {}

	self.isPopupNetErrorTips = false
end

-- start --
--------------------------------
-- @class function
-- @description 发送消息放入到缓冲,非真正的发送
-- @param msgTbl 消息体
-- end --
function SocketClient:sendMessage(msgTbl)
	--gt.dump(msgTbl)

	-- 打包成messagepack格式
	-- 打包消息实体
	local packMsgData    = self.msgPackLib.pack(msgTbl)
	local packMsgEntity  = string.char(1) .. packMsgData --1字节标志此消息为经过pack过的
	local msgEntityLen   = string.len(packMsgEntity)
	local msgEntityLenHi = string.char(math.floor(msgEntityLen / 256))
	local msgEntityLenLow= string.char(msgEntityLen % 256)
	
	-- 打包消息头
	local packMsgHead  = self.msgPackLib.pack(self:getMessageHead(packMsgData))
	local msgHeadLen   = string.len(packMsgHead)
	local msgHeadLenHi = string.char(math.floor(msgHeadLen / 256))
	local msgHeadLenLow= string.char(msgHeadLen % 256)
	
	local msgTotalLen   = msgHeadLen + 2 + msgEntityLen + 2	--需要各加两个字节的长度长
	local msgTotalLenHi = string.char(math.floor(msgTotalLen / 256))
	local msgTotalLenLow= string.char(msgTotalLen % 256)
	
	local curTime 	= os.time()
	local time 		= self:luaToCByInt(curTime)
	local msgId 	= self:luaToCByInt(msgTbl.m_msgId * ((curTime % 10000) + 1))
	
	local checksum 	= self:getCheckSum(time .. msgId .. msgHeadLenLow .. msgHeadLenHi .. packMsgHead .. msgEntityLenLow .. msgEntityLenHi .. packMsgEntity)

	local msgToSend = msgTotalLenLow .. msgTotalLenHi .. checksum .. time .. msgId .. msgHeadLenLow .. msgHeadLenHi .. packMsgHead .. msgEntityLenLow .. msgEntityLenHi .. packMsgEntity

	-- 放入到消息缓冲
	table.insert(self.sendMsgCache, msgToSend)
end


function SocketClient:getCheckSum(time)
	local crc = self:CRC(time, 8)
	return self:luaToCByShort(crc)
end

function SocketClient:luaToCByShort(value)
	return string.char(value % 256) .. string.char(math.floor(value / 256))
end

function SocketClient:luaToCByInt(value)
	local lowByte1 = string.char(((value / 256) / 256) / 256)
	local lowByte2 = string.char(((value / 256) / 256) % 256)
	local lowByte3 = string.char((value / 256) % 256)
	local lowByte4 = string.char(value % 256)
	return lowByte4 .. lowByte3 .. lowByte2 .. lowByte1
end

function SocketClient:CRC(data, length)
    local sum = 65535
    for i = 1, length do
        local d = string.byte(data, i)    -- get i-th element, like data[i] in C
        sum = self:ByteCRC(sum, d)
    end
    return sum
end

function SocketClient:ByteCRC(sum, data)
    -- sum = sum ~ data
    local sum = bit:_xor(sum, data)
    for i = 0, 3 do     -- lua for loop includes upper bound, so 7, not 8
        -- if ((sum & 1) == 0) then
        if (bit:_and(sum, 1) == 0) then
            sum = sum / 2
        else
            -- sum = (sum >> 1) ~ 0xA001  -- it is integer, no need for string func
            sum = bit:_xor((sum / 2), 0x70B1)
        end
    end
    return sum
end
-- start --
--------------------------------
-- @class function
-- @description 发送消息
-- @param msgTbl 消息表结构体
-- end --
function SocketClient:send()
	if not self.isConnectSucc or not self.tcpConnection then
		-- 链接未建立
		return false
	end

	if #self.sendMsgCache <= 0 then
		return true
	end
	
	local sendSize = 0
	local errorInfo = ""
	local sendSizeWhenError = 0
	if self.remainSendSize > 0 then --还有剩余的数据没有发送完毕，接着发送
		local totalSize = string.len(self.sendingBuffer)
		local beginPos = totalSize - self.remainSendSize + 1
		sendSize, errorInfo, sendSizeWhenError = self.tcpConnection:send(self.sendingBuffer, beginPos)
	else
		self.sendingBuffer = self.sendMsgCache[1]
		self.remainSendSize = string.len(self.sendingBuffer)
		sendSize, errorInfo, sendSizeWhenError = self.tcpConnection:send(self.sendingBuffer)
	end
	
	if errorInfo == nil then 
		self.remainSendSize = self.remainSendSize - sendSize
		if self.remainSendSize == 0 then  --说明已经发送完毕
			table.remove(self.sendMsgCache, 1)  --移除第一个
			self.sendingBuffer = ""
		end
	else
		if errorInfo == "timeout" then --由于是异步socket，并且timeout为0，luasocket则会立即返回不会继续等待socket可写事件
			if sendSizeWhenError ~= nil and sendSizeWhenError > 0 then
				self.remainSendSize = self.remainSendSize - sendSizeWhenError

				--gt.log("Send time out. Had sent size:" .. sendSizeWhenError)
			end
		else
			--gt.log("Send failed errorInfo:" .. errorInfo)
			return false
		end
	end
		
	return true
end

function SocketClient:receive()
	if not self.isConnectSucc or not self.tcpConnection then
		-- 链接未建立
		return
	end
	
	local messageQueue = {}
	self:receiveMessage(messageQueue)
	
	if #messageQueue <= 0 then
		return
	end

	gt.log("Recv meesage package:" .. #messageQueue)
	
	for i,v in ipairs(messageQueue) do
		self:dispatchMessage(v)
	end
end

function SocketClient:receiveMessage(messageQueue)
	if self.remainRecvSize <= 0 then
		return true
	end

	local recvContent,errorInfo,otherContent = self.tcpConnection:receive(self.remainRecvSize)
	if errorInfo ~= nil then
		if errorInfo == "timeout" then --由于timeout为0并且为异步socket，不能认为socket出错
			if otherContent ~= nil and #otherContent > 0 then
				self.recvingBuffer = self.recvingBuffer .. otherContent
				self.remainRecvSize = self.remainRecvSize - #otherContent

				gt.log("recv timeout, but had other content. size:" .. #otherContent)
			end
			
			return true
		else	--发生错误，这个点可以考虑重连了，不用等待heartbeat
			gt.log("Recv failed errorinfo:" .. errorInfo)

			-- self:reloginServer()
			return false
		end
	end
	
	local contentSize = #recvContent
	self.recvingBuffer = self.recvingBuffer .. recvContent
	self.remainRecvSize = self.remainRecvSize - contentSize

	gt.log("success recv size:" .. contentSize ..  "   remainRecvSize is:" .. self.remainRecvSize)
	
	if self.remainRecvSize > 0 then	--等待下次接收
		return true
	end
	
	if self.recvState == "Head" then
		self.remainRecvSize = string.byte(self.recvingBuffer, 2) * 256 + string.byte(self.recvingBuffer, 1)
		self.recvingBuffer = ""
		self.recvState = "Body"
		gt.log("Need recv body size:" .. self.remainRecvSize)
	elseif self.recvState == "Body" then
		local Data = string.sub(self.recvingBuffer, 2, -1) --跳过packet字节
		local messageData = self.msgPackLib.unpack(Data)	
		table.insert(messageQueue, messageData)

		self.remainRecvSize = 12  --下个包头
		self.recvingBuffer = ""
		self.recvState = "Head"
	end

	--继续接数据包
	--如果有大量网络包发送给客户端可能会有掉帧现象，但目前不需要考虑，解决方案可以1.设定总接收时间2.收完body包就不在继续接收了
	return self:receiveMessage(messageQueue)
end

-- start --
--------------------------------
-- @class function
-- @description 注册msgId消息回调
-- @param msgId 消息号
-- @param msgTarget
-- @param msgFunc 回调函数
-- end --
function SocketClient:registerMsgListener(msgId, msgTarget, msgFunc)
	-- if not msgTarget or not msgFunc then
	-- 	return
	-- end

	self.rcvMsgListeners[msgId] = {msgTarget, msgFunc}
end

-- start --
--------------------------------
-- @class function
-- @description 注销msgId消息回调
-- @param msgId 消息号
-- end --
function SocketClient:unregisterMsgListener(msgId)
	self.rcvMsgListeners[msgId] = nil
end

-- start --
--------------------------------
-- @class function
-- @description 分发消息
-- @param msgTbl 消息表结构
-- end --
function SocketClient:dispatchMessage(msgTbl)
	local rcvMsgListener = self.rcvMsgListeners[msgTbl.m_msgId]
	gt.log("dispatch message id = " .. tostring(msgTbl.m_msgId))
	if rcvMsgListener then
		rcvMsgListener[2](rcvMsgListener[1], msgTbl)
	else
		gt.log("Could not handle Message " .. tostring(msgTbl.m_msgId))
		return false
	end

	return true
end

function SocketClient:setIsStartGame(isStartGame)
	self.isStartGame = isStartGame

	-- self.loginReconnectNum = 0

	-- 心跳消息回复
	self:registerMsgListener(gt.GC_HEARTBEAT, self, self.onRcvHeartbeat)
end


function  SocketClient:setIsCloseHeartBeat( isCloseHeartBeat )
	-- body

	gt.resume_time = 8

	self.heartbeatCD = 4

	self.closeHeartBeat = isCloseHeartBeat
end

-- start --
--------------------------------
-- @class function
-- @description 向服务器发送心跳
-- @param isCheckNet 检测和服务器的网络连接
-- end --
function SocketClient:sendHeartbeat(isCheckNet)
	if not self.isStartGame then
		return
	end
	
	local timenow = gt.socket.gettime()
	if timenow ~= nil then
		gt.m_sec,gt.m_usec = math.modf(math.floor(timenow*1000)/1000)
		gt.m_usec = math.floor(gt.m_usec*1000)
	end
 	gt.log("gt.m_sec is ",gt.m_sec)
 	gt.log("gt.m_usec is ",gt.m_usec)

	local msgTbl = {}
	msgTbl.m_msgId = gt.CG_HEARTBEAT
	msgTbl.m_sec = gt.m_sec
	msgTbl.m_usec = gt.m_usec

	if not self.closeHeartBeat then
		self:sendMessage(msgTbl)
	end

	self.curReplayInterval = 0

	self.isCheckNet = isCheckNet
	if isCheckNet then
		-- 防止重复发送心跳,直接进入等待回复状态
		self.heartbeatCD = -1
	end
end

-- start --
--------------------------------
-- @class function
-- @description 服务器回复心跳
-- @param msgTbl
-- end --
function SocketClient:onRcvHeartbeat(msgTbl)
	if msgTbl.m_sec and msgTbl.m_usec then
		gt.log("msgTbl.m_sec is ",msgTbl.m_sec)
 		gt.log("msgTbl.m_usec is ",msgTbl.m_usec)
		gt.IsSendheartbeat = true
	end
	self.heartbeatCD = 4
	self.lastReplayInterval = self.curReplayInterval
end

-- start --
--------------------------------
-- @class function
-- @description 获取上一次心跳回复时间间隔用来判断网络信号强弱
-- @return 上一次心跳回复时间间隔
-- end --
function SocketClient:getLastReplayInterval()
	return self.lastReplayInterval
end

function SocketClient:updateNetWork( delta )
	
	-- 检测网络
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "getNetWorkType")
		gt.log("ret = "..ret)
		if ret == "deviceNetWork" then
			if self.netWorkChangeFlag == true then
				self.netWorkChangeFlag = false
				gt.removeLoadingTips()
				self:reloginServer()
				return
			end
		elseif ret == "deviceNONetWork" then
			-- 没有网络
			gt.showLoadingTips(gt.getLocationString("LTKey_0054_4"))
			self.netWorkChangeFlag = true
			self.isStartGame = false
			return
		end
	elseif gt.isAndroidPlatform() then
		
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "isNetworkAvailable", nil, "()Ljava/lang/String;")

		if ret == "networkAble" then
			if self.netWorkChangeFlag == true then
				self.netWorkChangeFlag = false
				gt.removeLoadingTips()
				self:reloginServer()
				return
			end
		elseif ret == "networkUnAble" then
			-- 没有网络
			gt.showLoadingTips(gt.getLocationString("LTKey_0054_4"))
			self.netWorkChangeFlag = true
			self.isStartGame = false
			return
		end

	end

end

function SocketClient:update(delta)

	self:send()
	self:receive()

	if self.isStartGame then
		if self.heartbeatCD >= 0 then
			-- 登录服务器后开始发送心跳消息
			self.heartbeatCD = self.heartbeatCD - delta
			if self.heartbeatCD < 0 then
				-- 发送心跳
				self:sendHeartbeat(true)
			end
		else
			-- 心跳回复时间间隔
			self.curReplayInterval = self.curReplayInterval + delta

			if self.isCheckNet and self.curReplayInterval > gt.resume_time then
				gt.resume_time = 8
				self.isCheckNet = false
				-- 心跳时间稍微长一些,等待重新登录消息返回
				self.heartbeatCD = 4
				-- 监测网络状况下,心跳回复超时发送重新登录消息
				gt.removeLoadingTips()
				self.netWorkChangeFlag = true
				-- self.isStartGame = false
				
				-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0054_5"), function ()
				
				self.isReconnectFlag = false
				self:reloginServer()

				-- end, nil, true)

			end
		end
	end
end

function SocketClient:reloginServer()
	
	gt.log("123...........")
	-- 链接关闭重连
	self.closeHeartBeat = true
	self:connectResume()
	
end

function SocketClient:SendRelogin( )
	-- body
	-- 发送重联消息
	local runningScene = display.getRunningScene()
	if runningScene then
		runningScene:reLogin()
	end
end

function SocketClient:networkErrorEvt(eventType, errorInfo)
	gt.log("networkErrorEvt errorInfo:" .. errorInfo)

	if self.isPopupNetErrorTips then
		return
	end

	if self.isStartGame then
		return
	end

	local tipInfoKey = "LTKey_0047"
	if errorInfo == "connection refused" then
		-- 连接被拒提示服务器维护中
		tipInfoKey = "LTKey_0002"
	end
	
	
	-- if self.loginReconnectNum < 3 and self.isStartGame == false then
	-- 	self.loginReconnectNum = self.loginReconnectNum + 1
	-- 	self:reloginServer()
	-- 	return
	-- end

	self.isPopupNetErrorTips = true
	require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString(tipInfoKey),
		function()
			self.isPopupNetErrorTips = false
			gt.removeLoadingTips()

			if errorInfo == "timeout" then
				-- 检测网络连接
				self:sendHeartbeat(true)
			end
		end, nil, true)
end


-- 进行一些必须的善后处理,更包的时候,再把清理定时器等拿到这个函数内
function SocketClient:clearSocket()
	
	-- 登录状态,有三次自动重连的机会
	-- self.loginReconnectNum = 0
end


function SocketClient:getMessageHead(messageEntity)
	-- 对包体产生随机数，以便生成md5
	local msgEntityLen = string.len(messageEntity)
	local beginPos = 0
	local endPos = 0
	
	if msgEntityLen > 0 then
		beginPos = math.random(msgEntityLen)
	end
	
	endPos = beginPos
	local remainLen = msgEntityLen - beginPos
	if remainLen > 0 then
		endPos = beginPos + math.random(math.min(128, remainLen))
	end
	
	local md5 = ""
	if beginPos > 0 and endPos >= beginPos then
		local stringMd5 = ""
		for i = beginPos, endPos, 1 do
			local tmp = tonumber(string.byte(messageEntity, i))
			stringMd5 = stringMd5 .. string.format("%02X", tmp)
		end
		md5 = cc.UtilityExtension:generateMD5(stringMd5, string.len(stringMd5))
	else
		beginPos = 0
		endPos   = 0
	end
	
	-- print("11111self.playerMsgOrder:",self.playerMsgOrder)
	self.playerMsgOrder = self.playerMsgOrder + 1
	-- print("2222self.playerMsgOrder:",self.playerMsgOrder)
	local msgHeadData = {}
	msgHeadData.m_msgId = gt.CG_VERIFY_HEAD
	msgHeadData.m_strUserId    = self.playerUUID
	msgHeadData.m_iMd5Begin    = beginPos
	msgHeadData.m_iMd5End      = endPos
	msgHeadData.m_strMd5       = md5
	msgHeadData.m_strVerifyKey = self.playerKeyOnGate
	msgHeadData.m_lMsgOrder    = self.playerMsgOrder
	-- print("2222msgHeadData.m_lMsgOrder :",msgHeadData.m_lMsgOrder)
	return msgHeadData
end

function SocketClient:setPlayerUUID(playerUUID)
	self.playerUUID = playerUUID
end

function SocketClient:getPlayerUUID()
	return self.playerUUID
end

function SocketClient:setPlayerKeyAndOrder(keyOnGate, msgOrder)

	self.playerKeyOnGate = keyOnGate
	self.playerMsgOrder  = msgOrder
end

return SocketClient


