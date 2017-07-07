

local gt = cc.exports.gt

local FinalReport = class("FinalReport", function()
	return cc.Layer:create()
end)

function FinalReport:ctor(roomPlayers, rptMsgTbl)

	gt.log("进入FinalReport..........."..#roomPlayers)
	
	-- cc.SpriteFrameCache:getInstance():addSpriteFrames("images/GameEnd.plist")
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("FinalReport.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Spr_bg"):setScale(1280/960)
		gt.seekNodeByName(csbNode, "Img_bg"):setScaleY(1280/960)
		-- gt.seekNodeByName(csbNode, "Btn_back"):setPosition(cc.p( 100, 680 ))
		gt.seekNodeByName(csbNode, "Text_Tip"):setPosition(cc.p( 640, 750 ))

		gt.seekNodeByName(csbNode, "Spr_title"):setPositionY( 770 )
		gt.seekNodeByName(csbNode, "Btn_back"):setPositionY( 770 )
		gt.seekNodeByName(csbNode, "Btn_shard"):setPositionY( -25 )
	end
	self:addChild(csbNode)
	self.rootNode = csbNode

	local cannonMaxCount = 0
	for i, v in ipairs(rptMsgTbl.m_bomb) do
		for j, v_d in ipairs(rptMsgTbl.m_dbomb) do 
			if i == j then
				local curCannon = v+v_d
				if curCannon > cannonMaxCount then
					cannonMaxCount = curCannon
				end
			end
		end
	end
	gt.log("炮手。。。。。。。")
	print(cannonMaxCount)

	-- 大赢家
	local scoreMaxCount = 0
	for i, v in ipairs(rptMsgTbl.m_gold) do
		if v > scoreMaxCount then
			scoreMaxCount = v
		end
	end

	for seatIdx, roomPlayer in ipairs(roomPlayers) do
		local playerInfoNode = gt.seekNodeByName(csbNode, "Spr_playerbg"..seatIdx)
		-- 头像
		local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
		-- headSpr:setTexture(string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), roomPlayer.uid))
		if cc.FileUtils:getInstance():isFileExist(string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), roomPlayer.uid)) then
			headSpr:setTexture(string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), roomPlayer.uid))
		else
			if roomPlayer.sex == 1 then
				headSpr:setSpriteFrame("GameEnd10.png")
			else
				headSpr:setSpriteFrame("GameEnd9.png")
			end
		end

		-- 昵称
		local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Txt_name")
		nicknameLabel:setString(roomPlayer.nickname)
		-- uid
		local uidLabel = gt.seekNodeByName(playerInfoNode, "Txt_id")
		uidLabel:setString("ID: " .. roomPlayer.uid)

		-- 最佳炮手
		local bestCannoneerSpr = gt.seekNodeByName(playerInfoNode, "bestCannoneerSpr")
		bestCannoneerSpr:setVisible(false)

		-- 大赢家
		local bigWinnerSpr = gt.seekNodeByName(playerInfoNode, "Spr_winner")
		bigWinnerSpr:setVisible(false)
		if scoreMaxCount ~= 0 and scoreMaxCount == rptMsgTbl.m_gold[seatIdx] then
			bigWinnerSpr:setVisible(true)
		end

		-- 房主
		local spr_homeOwner = gt.seekNodeByName(playerInfoNode, "Sprite_houseOwner")
		spr_homeOwner:setVisible(false)

		if 1 == roomPlayer.seatIdx then
			-- 0号位置是房主
			spr_homeOwner:setVisible(true)
		end

		-- 判断房间类型

		-- 自摸次数
		local selfDrawnCountLabel = gt.seekNodeByName(playerInfoNode, "Txt_totalscore_6")
		selfDrawnCountLabel:setString(tostring(rptMsgTbl.m_zimo[seatIdx]))

		-- 接炮次数
		local takeCannonCountLabel = gt.seekNodeByName(playerInfoNode, "Txt_totalscore_7")
		takeCannonCountLabel:setString(tostring(rptMsgTbl.m_win[seatIdx]))

		-- 点炮次数
		local cannonCountLabel = gt.seekNodeByName(playerInfoNode, "Txt_totalscore_8")
		cannonCountLabel:setString(tostring(rptMsgTbl.m_bomb[seatIdx]))

		-- 暗杠次数
		local darkBarCountLabel = gt.seekNodeByName(playerInfoNode, "Txt_totalscore_9")
		darkBarCountLabel:setString(tostring(rptMsgTbl.m_agang[seatIdx]))

		-- 明杠次数
		local brightBarCountLabel = gt.seekNodeByName(playerInfoNode, "Txt_totalscore_10")
		brightBarCountLabel:setString(tostring(rptMsgTbl.m_mgang[seatIdx]))

		-- 查大叫
		local chadajiaoCountLabel = gt.seekNodeByName(playerInfoNode,"Txt_totalscore_11")
		chadajiaoCountLabel:setString(tostring(rptMsgTbl.m_ting[seatIdx]))

		-- 总成绩
		local totalScoreLabel = gt.seekNodeByName(playerInfoNode, "Txt_totalscore")
		totalScoreLabel:setString(tostring(rptMsgTbl.m_gold[seatIdx]))
	end
	----------------------------------最佳炮手显示判断---------------------------------------
	
	local samenum = {}
	self:sameArr(rptMsgTbl.m_bomb,rptMsgTbl.m_dbomb,samenum)
	local samehu = {}
	self:sameArr(rptMsgTbl.m_zimo,rptMsgTbl.m_win,samehu)

	local samearv = {}
	samearv = self:bigerArr(samenum,samearv)
	local samearv2 = {}
	samearv2 = self:comparetab(rptMsgTbl.m_gold,samearv,samearv2)
	local samearv3 = {}
	samearv3 = self:comparetab(samehu,samearv2,samearv3)
	if #samearv3 == 1 then
		if samenum[samearv3[1]]~=0 then
		    print(samearv3[1].."是最佳炮手(胡)")
		    local playerInfoNode = gt.seekNodeByName(csbNode, "Spr_playerbg"..samearv3[1])
			local bestCannoneerSpr = gt.seekNodeByName(playerInfoNode, "bestCannoneerSpr")
			bestCannoneerSpr:setVisible(true)
		end
	else
	    for i,v in ipairs(samearv3) do
	    	if samenum[samearv3[i]]~=0 then
		       print(samearv3[i].."是最佳炮手(胡)s")
		       local playerInfoNode = gt.seekNodeByName(csbNode, "Spr_playerbg"..samearv3[i])
		       local bestCannoneerSpr = gt.seekNodeByName(playerInfoNode, "bestCannoneerSpr")
		       bestCannoneerSpr:setVisible(true)
	   		end
	    end
	end
	------------------------------------------------------------------------------------

    if table.contains({103, 107, 115, 118}, gt.roomState) then
		gt.seekNodeByName(csbNode, "Spr_playerbg4"):setVisible(false)
		gt.seekNodeByName(csbNode, "Spr_playerbg3"):setPositionX(980)
		gt.seekNodeByName(csbNode, "Spr_playerbg2"):setPositionX(640)
		gt.seekNodeByName(csbNode, "Spr_playerbg1"):setPositionX(300)
    elseif table.contains({120}, gt.roomState) then
		gt.seekNodeByName(csbNode, "Spr_playerbg4"):setVisible(false)
		gt.seekNodeByName(csbNode, "Spr_playerbg3"):setVisible(false)
		gt.seekNodeByName(csbNode, "Spr_playerbg1"):setPositionX(gt.seekNodeByName(csbNode, "Spr_playerbg2"):getPositionX()-100)
		gt.seekNodeByName(csbNode, "Spr_playerbg2"):setPositionX(gt.seekNodeByName(csbNode, "Spr_playerbg3"):getPositionX()+100)
	end

	-- 返回游戏大厅
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	backBtn:setTouchEnabled(true)
	gt.addBtnPressedListener(backBtn, function(sender)
		sender:setTouchEnabled(false)
		gt.showLoadingTips(gt.getLocationString("LTKey_0016"))
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE)
		-- local mainScene = require("app/views/MainScene"):create(false, isRoomCreater, roomID)
		-- cc.Director:getInstance():replaceScene(cc.TransitionProgressOutIn:create(1, mainScene))
	end)

	-- 分享
	local shareBtn = gt.seekNodeByName(csbNode, "Btn_shard")
	gt.addBtnPressedListener(shareBtn, function()
		shareBtn:setEnabled(false)
		self:screenshotShareToWX()
	end)
	
	if gt.isIOSPlatform() and gt.isInReview then
		shareBtn:setVisible(false)
	else
		shareBtn:setVisible(true)
	end
end
--取俩数组相同位置的和并返回sameTab
function FinalReport:sameArr(argv1,argv2,sameTab)
    for i,v in ipairs(argv1) do
    	for j, v_d in ipairs(argv2) do 
    		if i == j then
    			local curCannon = v+v_d
    			table.insert(sameTab,curCannon)
    		end
    	end
    end
end
--从argv1数组里去出最大的值放入argc数组里并返回
function FinalReport:bigerArr(argv1,argc)
    local MaxArr = 0
    for i=1,#argv1 do
        if MaxArr<argv1[i] then
            MaxArr = argv1[i]
            argc = {i}
        elseif MaxArr==argv1[i] then
            table.insert(argc,i)
        end
    end
    return argc
end
--从argv数组里取argc里数组所有元素的位置返回最小值
function FinalReport:comparetab(argv,argc,salTal)
    local MinArr = argv[tonumber(argc[1])]
    for i=1,#argv do
        for j=1,#argc do
            if i == argc[j] then
                -- print(argc[j].." "..MinArr)
                if MinArr>argv[i] then
                    MinArr = argv[i]
                    salTal = {argc[j]}
                elseif MinArr==argv[i] then
                    table.insert(salTal,argc[j])
                end
            end
        end
    end
    return salTal
end

function FinalReport:screenshotShareToWX()
	local layerSize = self.rootNode:getContentSize()
	local screenshot = cc.RenderTexture:create(layerSize.width, layerSize.height)
	screenshot:begin()
	self.rootNode:visit()
	screenshot:endToLua()

	local screenshotFileName = string.format("wx-%s.jpg", os.date("%Y-%m-%d_%H:%M:%S", os.time()))
	screenshot:saveToFile(screenshotFileName, cc.IMAGE_FORMAT_JPEG, false)

	self.shareImgFilePath = cc.FileUtils:getInstance():getWritablePath() .. screenshotFileName
	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
end

function FinalReport:update()
	if self.shareImgFilePath and cc.FileUtils:getInstance():isFileExist(self.shareImgFilePath) then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		local shareBtn = gt.seekNodeByName(self.rootNode, "Btn_shard")
		shareBtn:setEnabled(true)

		if gt.isIOSPlatform() then
			local luaoc = require("cocos/cocos2d/luaoc")
			luaoc.callStaticMethod("AppController", "shareImageToWX", {imgFilePath = self.shareImgFilePath})
		elseif gt.isAndroidPlatform() then
			local luaj = require("cocos/cocos2d/luaj")
			luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareImageToWX", {self.shareImgFilePath}, "(Ljava/lang/String;)V")
		end
		self.shareImgFilePath = nil
	end
end

function FinalReport:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function FinalReport:onTouchBegan(touch, event)
	return true
end

return FinalReport


