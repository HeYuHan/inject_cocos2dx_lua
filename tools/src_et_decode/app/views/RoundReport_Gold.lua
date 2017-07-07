local gt = cc.exports.gt

local RoundReport_Gold = class("RoundReport_Gold", function()
	return cc.Layer:create()
end)

function RoundReport_Gold:ctor(roomPlayers, playerSeatIdx, rptMsgTbl,playerScore)

	gt.log("进入单局结算 。。。。。。 ")
	local showStrArr = {"自摸 ","接炮 ","点炮 ","大胡自摸 ","大胡接炮 ","大胡点炮 ","有叫 "}
	local strHuTypeArr 		= {"平胡 ","龙七对 ","七对 ","清一色 "," ","对对胡 "," ","杠上开花 ","杠上炮 ","扫底胡 ","海底炮 ","抢杠胡 "," "," ","天胡 ","地胡 "," ","金钩钓 ","清对 ","清七对 ","清龙七对 ","将对 ","将七对 ","全幺九 ","门清 ","中张 ","卡二条 ","夹心五 ","一条龙 ","姊妹对 "}
	gt.dump(rptMsgTbl)
	self.playerSeatIdx = playerSeatIdx

	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("RoundReport_Gold.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Spr_bg"):setScaleY(1280/960)
		gt.seekNodeByName(csbNode, "Panel_1"):setScaleY(1280/960)
		gt.seekNodeByName(csbNode, "Node_reportTitle"):setPositionY(780)
		gt.seekNodeByName(csbNode, "Btn_NextGame"):setPositionY(-50)
		gt.seekNodeByName(csbNode, "Btn_Quit"):setPositionY(-50)
	end
	self.rootNode = csbNode
	self:addChild(csbNode)

	local timeLabel = gt.seekNodeByName(csbNode, "Text_createDockTime")
	if timeLabel then
		timeLabel:setVisible(false)
	end
	
	local tableStr = ""
	for i=1,#rptMsgTbl.m_playType do
		if rptMsgTbl.m_playType[i] == 20 then
			tableStr = tableStr .. "换三张 "
		elseif rptMsgTbl.m_playType[i] == 22 then
			tableStr = tableStr .. "自摸加底 "
		elseif rptMsgTbl.m_playType[i] == 23 then
			tableStr = tableStr .. "自摸加番 "
		elseif rptMsgTbl.m_playType[i] == 24 then
			tableStr = tableStr .. "二番封顶 "
		elseif rptMsgTbl.m_playType[i] == 25 then
			tableStr = tableStr .. "三番封顶 "
		elseif rptMsgTbl.m_playType[i] == 26 then
			tableStr = tableStr .. "四番封顶 "
		elseif rptMsgTbl.m_playType[i] == 101 then
			tableStr = tableStr .. "五番封顶 "
		elseif rptMsgTbl.m_playType[i] == 102 then
			tableStr = tableStr .. "六番封顶 "
		elseif rptMsgTbl.m_playType[i] == 27 then
			tableStr = tableStr .. "幺九将对 "
		elseif rptMsgTbl.m_playType[i] == 28 then
			tableStr = tableStr .. "门清中张 "
		elseif rptMsgTbl.m_playType[i] == 29 then
			tableStr = tableStr .. "点杠花(点炮) "
		elseif rptMsgTbl.m_playType[i] == 30 then
			tableStr = tableStr .. "点杠花(自摸) "
		elseif rptMsgTbl.m_playType[i] == 34 then
			tableStr = tableStr .. "天地胡 "
		elseif rptMsgTbl.m_playType[i] == 46 then
			tableStr = tableStr .. "八番封顶 "
		end
	end
	--玩法类型
	local TextType = gt.seekNodeByName(csbNode,"Text_Type")
	TextType:setString(tableStr)

	if string.len(tableStr)>120 then
		TextType:setFontSize(25)
	end

	-- 结束标题
	local reportTitleNode = gt.seekNodeByName(csbNode, "Node_reportTitle")
	for _, reportTitleSpr in ipairs(reportTitleNode:getChildren()) do
		reportTitleSpr:setVisible(false)
	end

	local ownerWinSorce = 0
	-- 具体信息
	for seatIdx, roomPlayer in ipairs(roomPlayers) do
		if playerSeatIdx == seatIdx then
			-- 自己的分数
			ownerWinSorce = rptMsgTbl.m_coins[seatIdx]
		end

		local playerReportNode = gt.seekNodeByName(csbNode, "Node_playerReport_" .. seatIdx)
		-- 昵称
		local nicknameLabel = gt.seekNodeByName(playerReportNode, "Label_nickname")
		nicknameLabel:setString(roomPlayer.nickname)
		--头像
		-- local userHead = gt.seekNodeByName(playerReportNode,"Spr_headImage")
		-- userHead:setTexture(string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), roomPlayer.uid))
		local userHead = gt.seekNodeByName(playerReportNode,"Spr_headImage")
		if cc.FileUtils:getInstance():isFileExist(string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), roomPlayer.uid)) then
			userHead:setTexture(string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), roomPlayer.uid))
		else
			if roomPlayer.sex == 1 then
				userHead:setSpriteFrame("GameEnd10.png")
			else
				userHead:setSpriteFrame("GameEnd9.png")
			end
		end

		-- 详细结果
		local detailLabel = gt.seekNodeByName(playerReportNode, "Label_detail")
		local detailTxt = ""
		
		if playerScore then
			gt.log("血流结算信息")
			local allHuarrType = ""
			for i,userRound in ipairs(playerScore[seatIdx]) do
				local strHuType = {}
				local HuarrType = ""
				--其它操作
				if tonumber(userRound[1])+1 == seatIdx then
					if userRound[2] == 4 then
						for j, v in ipairs (userRound[3]) do
							table.insert(strHuType, strHuTypeArr[userRound[3][tonumber(j)]])
						end
						if strHuType ~= 0 then
							-- 胡牌总显示
							for k=1,#strHuType do
								HuarrType = HuarrType..strHuType[k]
							end
							allHuarrType = showStrArr[1] .. "(" .. HuarrType .. ")  "
						else
							-- 胡牌总显示
							allHuarrType = showStrArr[1]
						end
					else
						for j, v in ipairs (userRound[3]) do
							table.insert(strHuType, strHuTypeArr[userRound[3][tonumber(j)]])
						end
						if strHuType ~= 0 then
							-- 胡牌总显示
							for k=1,#strHuType do
								HuarrType = HuarrType..strHuType[k]
							end
							allHuarrType = showStrArr[2] .. "(" .. HuarrType .. ")  "
						else
							-- 胡牌总显示
							allHuarrType = showStrArr[2]
						end
					end
					
				elseif tonumber(userRound[2])+1 == seatIdx then
					for j, v in ipairs (userRound[3]) do
							table.insert(strHuType, strHuTypeArr[userRound[3][tonumber(j)]])
						end
					if strHuType ~= 0 then
						-- 胡牌总显示
						for k=1,#strHuType do
							HuarrType = HuarrType..strHuType[k]
						end
						allHuarrType = showStrArr[3] .. "(" .. HuarrType .. ")  "
					else
						-- 胡牌总显示
						allHuarrType = showStrArr[3]
					end
				end
				gt.dump(allHuarrType)
				detailTxt = detailTxt..allHuarrType
			end
		end

		-- 明杠 暗杠 点杠 根
		local agangCount = rptMsgTbl.m_agang[seatIdx]
		if agangCount ~= 0 then
			detailTxt = " " .. detailTxt .. string.format("暗杠x%d",agangCount)
		end

		local mgangCount = rptMsgTbl.m_mgang[seatIdx]
		if mgangCount ~= 0 then
			detailTxt = " " .. detailTxt .. string.format("明杠x%d",mgangCount)
		end

		local bgangCount = rptMsgTbl.m_mbgang[seatIdx]
		if bgangCount ~= 0 then
			detailTxt = " " .. detailTxt .. string.format("巴杠x%d",bgangCount)
		end
		
		local dgangCount = rptMsgTbl.m_dgang[seatIdx]
		if dgangCount ~= 0 then
			detailTxt = " " .. detailTxt .. string.format("点杠x%d",dgangCount)
		end

		local genCount = rptMsgTbl.m_gen[seatIdx]
		if genCount ~= 0 then
			detailTxt = " " .. detailTxt .. string.format("根x%d",genCount)
		end

		local ggangCount = rptMsgTbl.m_gsgang[seatIdx]
		if ggangCount ~= 0 then
			detailTxt = " " .. detailTxt .. string.format("过手杠x%d",ggangCount)
		end

		detailLabel:setString(detailTxt)

		-- 查听
		local checkTing = rptMsgTbl.m_checkTing[seatIdx]
		if checkTing == 1 then
			-- 查叫
			local checkLabel = gt.seekNodeByName(playerReportNode, "Label_chajiao")
			checkLabel:setString("查叫")
		else
			-- 不查叫
			local checkLabel = gt.seekNodeByName(playerReportNode, "Label_chajiao")
			checkLabel:setString("")
		end
	
		-- X番
		local regionScoreLabel = gt.seekNodeByName(playerReportNode, "Label_regionScore")
		regionScoreLabel:setVisible(false)
		if gt.debugMode then
			regionScoreLabel:setVisible(true)
		end
		regionScoreLabel:setString(string.format("%d番 %d分", math.abs(rptMsgTbl.m_fan[seatIdx]),rptMsgTbl.m_score[seatIdx]))
		
		-- 积分变更为金币
		local scoreLabel = gt.seekNodeByName(playerReportNode, "Label_score")
		scoreLabel:setString(tostring(rptMsgTbl.m_coins[seatIdx]))

		if rptMsgTbl.m_totalcoins[seatIdx] <= 0 then
			gt.log("玩家输光了"..seatIdx)
			local Spr_loser = gt.seekNodeByName(playerReportNode, "Spr_loser")--显示输光了
			Spr_loser:setVisible(true)
		end
		roomPlayer.scoreLabel:setString(tostring(gt.formatCoinNumber(rptMsgTbl.m_totalcoins[seatIdx])))

		-- 庄家标识
		local bankerSignSpr = gt.seekNodeByName(playerReportNode, "Spr_bankerSign")
		bankerSignSpr:setVisible(false)
		if roomPlayer.isBanker then
			bankerSignSpr:setVisible(true)
		end

		-- 持有麻将信息
		local mjTileReferSpr = gt.seekNodeByName(playerReportNode, "Spr_mjTileRefer")
		mjTileReferSpr:setVisible(false)
		local referScale = mjTileReferSpr:getScale()
		local referPos = cc.p(mjTileReferSpr:getPosition())
		local mjTileSize = mjTileReferSpr:getContentSize()
		local referSpace = cc.p(mjTileSize.width * referScale, 0)

		-- 暗杠
		for _, darkBar in ipairs(roomPlayer.mjTileDarkBars) do
			for i = 1, 4 do
				local mjTileName = string.format(gt.SelfMJSprFrameOut, darkBar.mjColor, darkBar.mjNumber)
				if i <= 3 then
					-- 前三张牌显示背面
					mjTileName = "tdbgs_4.png"
				end
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				playerReportNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end
			referPos.x = referPos.x + 16
		end
		-- 明杠
		for _, brightBar in ipairs(roomPlayer.mjTileBrightBars) do
			for i = 1, 4 do
				local mjTileName = string.format(gt.SelfMJSprFrameOut, brightBar.mjColor, brightBar.mjNumber)
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				playerReportNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end
			referPos.x = referPos.x + 16
		end
		-- 明补
		for _, brightBar in ipairs(roomPlayer.mjTileBrightBu) do
			for i = 1, 4 do
				local mjTileName = string.format(gt.SelfMJSprFrameOut, brightBar.mjColor, brightBar.mjNumber)
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				playerReportNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end
			referPos.x = referPos.x + 16
		end
		-- 碰
		for _, pung in ipairs(roomPlayer.mjTilePungs) do
			for i = 1, 3 do
				local mjTileName = string.format(gt.SelfMJSprFrameOut, pung.mjColor, pung.mjNumber)
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				playerReportNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end
			referPos.x = referPos.x + 16
		end

		--吃牌
		for _, eat in ipairs(roomPlayer.mjTileEat) do
			for i = 1, 3 do
				local mjTileName = string.format(gt.SelfMJSprFrameOut, eat[i][3], eat[i][1])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				playerReportNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end
			referPos.x = referPos.x + 16
		end

		-- 持有牌
		for _, v in ipairs(rptMsgTbl["array" .. (seatIdx - 1)]) do
			local mjTileName = string.format(gt.SelfMJSprFrame, v[1], v[2])
			local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
			mjTileSpr:setScale(0.66*referScale)
			mjTileSpr:setPosition(referPos)
			playerReportNode:addChild(mjTileSpr)
			referPos = cc.pAdd(referPos, referSpace)
		end
		
		if playerScore then
			gt.dump(playerScore)
			for i,userRound in ipairs(playerScore[seatIdx]) do
				--其它操作
				if tonumber(userRound[1])+1 == seatIdx then
					referPos.x = referPos.x + 33
					if userRound~= nil then
						local mjTileName = string.format(gt.SelfMJSprFrameOut, userRound[5][1], userRound[5][2])
						local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
						if mjTileSpr then
							mjTileSpr:setScale(referScale)
							mjTileSpr:setPosition(referPos.x, referPos.y)
							playerReportNode:addChild(mjTileSpr)

							mjTileSpr:setColor(cc.c3b(200,200,200))
						end
					end
				end
			end
		else
			local hucardResult = rptMsgTbl["m_hucards" .. seatIdx]
			if next(hucardResult) ~= nil then
				for i = 1, #hucardResult do
					local mjTileName = string.format(gt.SelfMJSprFrameOut, hucardResult[i][1], hucardResult[i][2])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					if mjTileSpr then

						mjTileSpr:setScale(referScale)
						if i == 1 then
							mjTileSpr:setPosition(referPos.x + 16, referPos.y)
						elseif i == 2 then
							mjTileSpr:setPosition(referPos.x + 16 * 4, referPos.y)
						end
						playerReportNode:addChild(mjTileSpr)

						mjTileSpr:setColor(cc.c3b(200,200,200))
					end
				end
			end
		end
	end

	if ownerWinSorce > 0 then
		local reportTitleSpr = gt.seekNodeByName(reportTitleNode, "Spr_winTitle")
		reportTitleSpr:setVisible(true)

		gt.soundEngine:playEffect("common/audio_win")

	elseif ownerWinSorce < 0 then
		local reportTitleSpr = gt.seekNodeByName(reportTitleNode, "Spr_loseTitle")
		reportTitleSpr:setVisible(true)

		gt.soundEngine:playEffect("common/audio_lose")

	elseif ownerWinSorce == 0 then
		if rptMsgTbl.m_result == 2 or rptMsgTbl.m_result == 3 then
			-- 慌庄
			gt.log("解散房间显示流局")
			local reportTitleSpr = gt.seekNodeByName(reportTitleNode, "Spr_liujuTitle")
			reportTitleSpr:setVisible(true)

			gt.soundEngine:playEffect("common/audio_liuju")
		else
			local reportTitleSpr = gt.seekNodeByName(reportTitleNode, "Spr_winTitle")
			reportTitleSpr:setVisible(true)

			gt.soundEngine:playEffect("common/audio_win")
		end
	end

	-- 继续
	local Btn_NextGame = gt.seekNodeByName(csbNode, "Btn_NextGame")
	gt.addBtnPressedListener(Btn_NextGame, function()
		-- self:removeFromParent()
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_GOON_NEXTGAME
		msgToSend.m_state = 1102
		msgToSend.m_playType = rptMsgTbl.m_playType
		gt.dump(msgToSend)
		gt.socketClient:sendMessage(msgToSend)
	end)
	
	-- 结束
	local Btn_Quit = gt.seekNodeByName(csbNode, "Btn_Quit")
	gt.addBtnPressedListener(Btn_Quit, function()
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_QUIT_ROOM
		msgToSend.m_pos = playerSeatIdx - 1
		gt.socketClient:sendMessage(msgToSend)
		gt.dump(msgToSend)
		self:removeFromParent()
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE)
	end)

	local roomPlayerCount = #roomPlayers or 4
    self:adjustUIfor3People(csbNode, gt.roomState,roomPlayerCount)
end

function RoundReport_Gold:adjustUIfor3People(csbNode, roomState,roomPlayerCount)
    -- if roomState ~= 118 then return end
    if roomPlayerCount == 4 then return end
    local _nodeList = gt.findNodeArray(csbNode, "Node_playerReport_#1#4", "Spr_slid#1#3")
    _nodeList.Node_playerReport_4:setVisible(false)

    local _infoYoffsetMap = {-30, -60, -90}
    local _infoYoffsetMap2 = {-60, -60, -52}
    for i=1, 3 do
        local _infoNode = _nodeList["Node_playerReport_" .. i]

        _infoNode:setPositionY(_infoNode:getPositionY() + _infoYoffsetMap2[i])
        _nodeList["Spr_slid"..i]:setPositionY(_nodeList["Spr_slid"..i]:getPositionY() + _infoYoffsetMap[i])
    end
end


function RoundReport_Gold:onNodeEvent(eventName)
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

function RoundReport_Gold:onTouchBegan(touch, event)
	return true
end

return RoundReport_Gold

