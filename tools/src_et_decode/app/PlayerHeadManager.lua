
local gt = cc.exports.gt

local PlayerHeadManager = class("PlayerHeadManager", function()
	return cc.Node:create()
end)

function PlayerHeadManager:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	self.headImageObservers = {}

	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
end

function PlayerHeadManager:onNodeEvent(eventName)
	if "exit" == eventName then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
	end
end

function PlayerHeadManager:update(delta)
	local transObservers = {}
	local curTime = os.time()
	for i, observerData in ipairs(self.headImageObservers) do		
		if cc.FileUtils:getInstance():isFileExist(observerData.imgFileName) and (curTime-observerData.startTime)>2 then
			observerData.headSpr:setTexture(observerData.imgFileName)

			-- 更新下载后的url
			if observerData.isFlushImage then
				cc.UserDefault:getInstance():setStringForKey(observerData.imgFileName, observerData.headURL)
			end
		else
			table.insert(transObservers, observerData)
		end
	end
	self.headImageObservers = transObservers
end

function PlayerHeadManager:attach(headSpr, playerUID, headURL,sex)
	print("=========",headSpr,playerUID,headURL)
	if not headSpr or not headURL or string.len(headURL) == 2 then
		gt.log("0000000000000000000")
		if not sex then
			sex = 1
		end
		if sex == 1 then
			headSpr:setSpriteFrame("GameEnd10.png")
		else
			headSpr:setSpriteFrame("GameEnd9.png")
		end
		return
	end

	local imgFileName = string.format("head_img_%d.png", playerUID)
	-- gt.log("the imgfilename is ... " .. imgFileName)
	local observerData = {}

	observerData.headSpr = headSpr
	observerData.imgFileName = imgFileName
	observerData.headURL = headURL
	observerData.isFlushImage = false
	table.insert(self.headImageObservers, observerData)

	-- dump(self.headImageObservers)

	if cc.FileUtils:getInstance():isFileExist(observerData.imgFileName) then
		observerData.startTime = 0
		observerData.headSpr:setTexture(observerData.imgFileName)
	end

	local saveHeadURL = cc.UserDefault:getInstance():getStringForKey(imgFileName)
	if saveHeadURL ~= headURL then
		-- 当前头像不存在或者头像更新,重新下载
		observerData.startTime = os.time()
		cc.UtilityExtension:httpDownloadImage(headURL, playerUID)
		observerData.isFlushImage = true
	end
end

function PlayerHeadManager:detach(headSpr)
	for i, observerData in ipairs(self.headImageObservers) do
		if observerData.headSpr == headSpr then
			table.remove(self.headImageObservers, i)
			break
		end
	end
end

function PlayerHeadManager:detachAll()
	local x = #self.headImageObservers
	for i = x, 1, -1 do
		table.remove(self.headImageObservers, i)
	end
end

return PlayerHeadManager

