
local gt = cc.exports.gt

local LoginScene = require("app/views/LoginScene")
local loginStrategy = require("app/LoginIpStrategy")

local VisitorsLogin = class("VisitorsLogin", function()
	return gt.createMaskLayer()
end)

function VisitorsLogin:ctor()
	-- 注册节点事件
	-- self:registerScriptHandler(handler(self, self.onNodeEvent))
	local csbNode = cc.CSLoader:createNode("VisitorsLogin.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	self.PhoneUrl = ""
	if gt.debugMode then
		self.PhoneUrl = "http://112.124.121.184:8010"
	else
		
	end

	if gt.isInReview then
		self.PhoneUrl = "http://test-payment.ixianlai.com/oauth"
	end
	
	local Img_Text1 = gt.seekNodeByName(csbNode, "Img_Text1")
	--获取输入的图片验证码
	local TextField_ImageCode = gt.seekNodeByName(Img_Text1, "TextField_ImageCode")
	self.ImageCode = TextField_ImageCode:getString()
	local function textFieldEvent1(sender, eventType)
        self.ImageCode = TextField_ImageCode:getString()
    end
	TextField_ImageCode:addEventListener(textFieldEvent1)
	-- 验证码图片
	local Btn_ImageCode = gt.seekNodeByName(Img_Text1, "Btn_ImageCode")
	-- Btn_ImageCode:setTouchEnabled(false)
	self.Btn_ImageCode = Btn_ImageCode
	--图形验证码返回的sessionId
	self.sessionId = ""
	--显示验证码图片
	self:RefreshImageCode()
	local Btn_Next = gt.seekNodeByName(Img_Text1, "Btn_Next")
	self.Btn_Next = Btn_Next
	Btn_Next:setTouchEnabled(true)
	gt.addBtnPressedListener(Btn_Next, function()
		self.Btn_Next:setTouchEnabled(false)
		self:RefreshImageCode()
	end)

	local Img_Text2 = gt.seekNodeByName(csbNode, "Img_Text2")
	--输入的手机号
	local TextField_PhoneNum = gt.seekNodeByName(Img_Text2, "TextField_PhoneNum")
	self.PhoneNum = TextField_PhoneNum:getString()
	local function textFieldEvent2(sender, eventType)
        self.PhoneNum = TextField_PhoneNum:getString()
    end
	TextField_PhoneNum:addEventListener(textFieldEvent2)
	--获取手机验证码
	local Btn_PhoneCode = gt.seekNodeByName(Img_Text2, "Btn_PhoneCode")
	self.Btn_PhoneCode = Btn_PhoneCode
	Btn_PhoneCode:setTouchEnabled(true)
	gt.addBtnPressedListener(Btn_PhoneCode, function()
		if type(tonumber(self.PhoneNum)) ~= "number" or string.len(tonumber(self.PhoneNum)) < 11 then
			self:floatText("手机号码输入错误，请重新输入")
		elseif string.len(self.ImageCode) == 0 or string.len(self.ImageCode) > 4 then
			self:floatText("图中字符输入错误，请重新输入")
		else
			self.Btn_PhoneCode:setTouchEnabled(false)
			self:PhoneVerification()
		end
	end)

	local Img_Text3 = gt.seekNodeByName(csbNode, "Img_Text3")
	--验证码
	local TextField_Code = gt.seekNodeByName(Img_Text3, "TextField_Code")
	self.PhoneCode = TextField_Code:getString()
	local function textFieldEvent3(sender, eventType)
        self.PhoneCode = TextField_Code:getString()
    end
    TextField_Code:addEventListener(textFieldEvent3)
	
	local Img_Text4 = gt.seekNodeByName(csbNode, "Img_Text4")
	--性别选项
	local userSex = 2
	local CheckBox_woman = gt.seekNodeByName(Img_Text4, "CheckBox_woman")
	self.CheckBox_woman = CheckBox_woman
	self.CheckBox_woman:setTouchEnabled(false)
	CheckBox_woman:setTag(2)
	local CheckBox_man = gt.seekNodeByName(Img_Text4, "CheckBox_man")
	self.CheckBox_man = CheckBox_man
	CheckBox_man:setTag(1)
	local function chooseCheckBoxEvt(senderBtn, eventType)
		if eventType == ccui.CheckBoxEventType.selected then
			self.CheckBox_woman:setTouchEnabled(true)
			self.CheckBox_woman:setSelected(false)
			self.CheckBox_man:setTouchEnabled(true)
			self.CheckBox_man:setSelected(false)
			senderBtn:setTouchEnabled(false)
			senderBtn:setSelected(true)
			userSex = senderBtn:getTag()
		elseif eventType == ccui.CheckBoxEventType.unselected then
		end
	end
	CheckBox_woman:addEventListener(chooseCheckBoxEvt)
	CheckBox_man:addEventListener(chooseCheckBoxEvt)
	--用户协议
	local Btn_Agreement = gt.seekNodeByName(csbNode, "Btn_Agreement")
	local CheckBox_Agreement = gt.seekNodeByName(csbNode, "CheckBox_Agreement")
	gt.addBtnPressedListener(Btn_Agreement, function()
		local agreementPanel = require("app/views/AgreementPanel"):create()
		self:addChild(agreementPanel, 6)
	end)
	--进入游戏
	self.PhoneUuid = ""--注册成功返回的uuid
	local Btn_JoinGame = gt.seekNodeByName(csbNode, "Btn_JoinGame")
	gt.addBtnPressedListener(Btn_JoinGame, function()
		if not CheckBox_Agreement:isSelected() then
			self:floatText("请确认并同意用户协议")
		else
			if gt.debugIpGet then
				self:VerificationPhoneLogin(gt.TestLoginServer.ip,gt.TestLoginServer.port,self.PhoneNum,userSex)
			else
				LoginScene:getHttpServerIp(self.PhoneUuid)
			end
		end
	end)
	--退出按钮
	local Btn_QuitGame = gt.seekNodeByName(csbNode, "Btn_QuitGame")
	gt.addBtnPressedListener(Btn_QuitGame, function()
		self:setVisible(false)
		self:setZOrder(self:getParent():getZOrder()-1)
	end)
end
--base64格式图片解码
function VisitorsLogin:decodeBase64(str64)
	local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'  
    local temp={}  
    for i=1,64 do  
        temp[string.sub(b64chars,i,i)] = i  
    end  
    temp['=']=0  
    local str=""  
    for i=1,#str64,4 do  
        if i>#str64 then  
            break  
        end  
        local data = 0  
        local str_count=0  
        for j=0,3 do  
            local str1=string.sub(str64,i+j,i+j)  
            if not temp[str1] then 
                return  
            end  
            if temp[str1] < 1 then  
                data = data * 64  
            else  
                data = data * 64 + temp[str1]-1  
                str_count = str_count + 1  
            end  
        end  
        for j=16,0,-8 do  
            if str_count > 0 then  
                str=str..string.char(math.floor(data/math.pow(2,j)))  
                data=math.mod(data,math.pow(2,j))  
                str_count = str_count - 1  
            end  
        end  
    end
  
    local last = tonumber(string.byte(str, string.len(str), string.len(str)))  
    if last == 0 then  
        str = string.sub(str, 1, string.len(str) - 1)  
    end
    return str
end
--刷新验证码图片
function VisitorsLogin:RefreshImageCode()
	local screenshotFileName = ""
	--请求图形验证码
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local timestamp = tostring(os.time())
	local key = "B1081EE774CE54FB6CAC607500972918"
	local stringMd5 = string.format("timestamp=%s&key=%s",timestamp,key)
	local sign = string.upper(cc.UtilityExtension:generateMD5(stringMd5,string.len(stringMd5)))
	local ImageInfoURL = string.format("%s/code/image?timestamp=%s&sign=%s",self.PhoneUrl,timestamp,sign)
	xhr:open("GET", ImageInfoURL)
	local function onResp()
		if not tolua.isnull(self) then
			self.Btn_Next:setTouchEnabled(true)
			local response = xhr.response
			require("json")
			local respJson = json.decode(response)
			gt.dump(respJson)
			if respJson.meta.code == "2000" then
				gt.log("获取图片成功")
				screenshotFileName = respJson.data.codeImage
				screenshotFileName = string.gsub(screenshotFileName,"\n","")
				self.sessionId = respJson.data.sessionId
				gt.log("self.sessionId = "..self.sessionId)
				local PasswordText =  self:decodeBase64(screenshotFileName)
				local textName = "VisitorsLoginPassword.png"
				local textPath = tostring(cc.FileUtils:getInstance():getWritablePath()) .. textName
				if PasswordText ~= nil then
					-- local file = io.open(textPath, "w+")
					-- file:write(PasswordText, "w+")
					-- file:close()
					io.writefile(textPath, PasswordText)
				end
				cc.TextureCache:getInstance():reloadTexture(textPath)
				local  sprFrames = cc.Sprite:create(textPath)
				-- local  texture = cc.TextureCache:getInstance():addImage(textPath)
				-- local frame = cc.SpriteFrame.create(texture)
				self.Btn_ImageCode:setSpriteFrame(sprFrames:getSpriteFrame())
				-- 逻辑更新定时器
				-- self.scheduleHandler = gt.scheduler:scheduleScriptFunc(function ()
				-- 	gt.log("延迟一帧显示图片")
				-- 	if io.exists(textPath) then
				-- 		cc.TextureCache:getInstance():reloadTexture(textPath)
				-- 		local  sprFrames = cc.Sprite:create(textPath)
				-- 		-- local  texture = cc.TextureCache:getInstance():addImage(textPath)
				-- 		-- local frame = cc.SpriteFrame.create(texture)
				-- 		self.Btn_ImageCode:setSpriteFrame(sprFrames:getSpriteFrame())
				-- 	end
				-- 	gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
				-- end, 0.1,false)
				gt.log("图片写入完成"..textPath)
			else
				self:floatText("图片验证码未获取，请点击换一张")
				gt.log("获取图片失败"..respJson.meta.code)
			end
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end
--请求手机验证码
function VisitorsLogin:PhoneVerification()
	--请求手机验证码
	--图形验证码
	local imageCode = tostring(self.ImageCode)
	--手机号码
	local telphone = tostring(self.PhoneNum)
	--时间戳
	local timestamp = tostring(os.time())
	--签名
	local key = "B1081EE774CE54FB6CAC607500972918"
	gt.log("self.sessionId = "..self.sessionId)
	local stringMd5 = string.format("imageCode=%s&sessionId=%s&telphone=%s&timestamp=%s&key=%s",imageCode,self.sessionId,telphone,timestamp,key)
	local sign = string.upper(cc.UtilityExtension:generateMD5(stringMd5,string.len(stringMd5)))
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local PhoneVerificationURL = string.format("%s/phone/code?imageCode=%s&sessionId=%s&telphone=%s&timestamp=%s&sign=%s",self.PhoneUrl,imageCode,self.sessionId,telphone,timestamp,sign)
	xhr:open("POST", PhoneVerificationURL)
	local function onResp()
		if not tolua.isnull(self) then
			self.Btn_PhoneCode:setTouchEnabled(true)
			local response = xhr.response
			require("json")
			local respJson = json.decode(response)
			gt.dump(respJson)
			if respJson.meta.code == "2000" then
				gt.log("获取手机验证码成功")
			else
				self:RefreshImageCode()
				if respJson.meta.code == "6012" then
					self:floatText("图中字符输入错误，请重新输入")
				elseif respJson.meta.code == "6014" then
					self:floatText("手机号码输入错误，请重新输入")
				elseif respJson.meta.code == "6017" then
					self:floatText("您的操作过于频繁，请60秒后再试")
				else
					self:floatText("您输入的信息有误，请重新输入")
					--请重新刷新
					gt.log("获取手机验证码失败"..respJson.meta.code)
				end
			end
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end
--验证
function VisitorsLogin:VerificationPhoneLogin(ip,port,nickname,sex)
	--手机号码
	local telphone = tostring(self.PhoneNum)
	--手机验证码
	local code = tostring(self.PhoneCode)
	--时间戳
	local timestamp = tostring(os.time())
	--签名
	local key = "B1081EE774CE54FB6CAC607500972918"
	local stringMd5 = string.format("code=%s&telphone=%s&timestamp=%s&key=%s",code,telphone,timestamp,key)
	local sign = string.upper(cc.UtilityExtension:generateMD5(stringMd5,string.len(stringMd5)))

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local PhoneVerificationURL = string.format("%s/user/login?code=%s&telphone=%s&timestamp=%s&sign=%s",self.PhoneUrl,code,telphone,timestamp,sign)
	xhr:open("POST", PhoneVerificationURL)
	local function onResp()
		if not tolua.isnull(self) then
			local response = xhr.response
			require("json")
			local respJson = json.decode(response)
			gt.dump(respJson)
			if respJson.meta.code == "2000" then
				local uuid = respJson.data.uuid
				gt.log("手机注册成功")
				self:sendPhoneLogin(ip,port,nickname,sex,uuid)
			elseif respJson.meta.code == "6018" or respJson.meta.code == "6019" then
				self:floatText("验证码输入错误，请重新输入")
			else
				self:floatText("注册失败，请确认信息")
				--请重新刷新
				gt.log("手机注册失败"..respJson.meta.code)
			end
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end
--登陆
function VisitorsLogin:sendPhoneLogin(ip,port,nickname,sex,uuid)
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))	
	-- 记录当前的ip   
	loginStrategy.ip = ip
	gt.socketClient:setPlayerUUID(uuid)
	gt.socketClient:close()
	local errorCode = gt.socketClient:connect(ip, port, true)
	if errorCode == true then
		gt.resume_time = 30
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_LOGIN
		msgToSend.m_plate = "phone"
		msgToSend.m_openId = tostring(nickname)
		msgToSend.m_severID = 15001
		msgToSend.m_sex = tonumber(sex)
		msgToSend.m_nikename = tostring(nickname)
		msgToSend.m_uuid = uuid
		gt.unionid = uuid
		cc.UserDefault:getInstance():setStringForKey( "Phone_Num", tostring(nickname) )
		cc.UserDefault:getInstance():setStringForKey( "Phone_Sex", tostring(sex) )
		cc.UserDefault:getInstance():setStringForKey( "Phone_Uuid", uuid )
		gt.wxNickName = nickname
		local catStr = string.format("%s%s",nickname,uuid)
		msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
		gt.dump(msgToSend)
		gt.socketClient:sendMessage(msgToSend)
	else
		loginStrategy.ip = ip
		loginStrategy.port = port
		loginStrategy:getIpByIpServer()
	end
end
--浮动文本
function VisitorsLogin:floatText(content)
	gt.golbalZOrder = 10000
	gt.fontNormal = "res/fonts/DFYuanW7-GB2312.ttf"
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

return VisitorsLogin



