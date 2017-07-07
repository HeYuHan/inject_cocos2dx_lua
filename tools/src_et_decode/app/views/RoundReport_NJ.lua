local gt = cc.exports.gt

local RoundReport_NJ = class("RoundReport_NJ", function()
	return cc.Layer:create()
end)

function RoundReport_NJ:ctor(roomPlayers, playerSeatIdx, rptMsgTbl, isLast)

	gt.log("进入单局结算 。。。。。。 ")
	local showStrArr = {"自摸 ","接炮 ","点炮 ","大胡自摸 ","大胡接炮 ","大胡点炮 ","有叫 "}
	-- local strHuTypeArr	= {"平胡 ","龙七对 ","七对 ","清一色 "," ","对对胡 "," ","杠上开花 ","杠上炮 ","扫底胡 ","海底炮 ","抢杠胡 "," "," ","天胡 ","地胡 "," ","金钩钓 ","清对 ","清七对 ","清龙七对 ","将对 ","将七对 ","全幺九 ","门清 ","中张 ","卡二条 ","夹心五 ","一条龙 ","姊妹对 ","","","","","","","","","","","金钩炮","无听用","本金"}
	local strHuTypeTab = {[1] = "平胡 ",[2] = "龙七对 ",[3] = "七对 ",[4] = "清一色 ",[5] = "将将胡 ",[6] = "对对胡 ",[7] = "全球人 ",[8] = "杠上开花 ",[9] = "杠上炮 ",[10] = "扫底胡 ",
						[11] = "海底炮 ",[12] = "抢杠胡 ",[13] = "起手四赖子 ",[14] = "双龙七对 ",[15] = "天胡 ",[16] = "地胡 ",[17] = "单钓 ",[18] = "金钩钓 ",[19] = "清对 ", [20] = "清七对 ",
						[21] = "清龙七对 ",[22] = "将对 ",[23] = "将七对 ",[24] = "全幺九 ",[25] = "门清 ",[26] = "中张 ",[27] = "卡二条 ",[28] = "夹心五 ",[29] = "一条龙 ", [30] = "姊妹对 ",
						[31] = "超超豪华七小对 ",[41] = "金钩炮 ",[42] = "无听用 ",[43] = "本金 ",[44] = "报听 ",[80] = "清三搭 ",[81] = "前四 ",[82] = "后四 ",
						[101] = "烂牌 ",[102] = "七心 ",[103] = "幺牌 ",[104] = "夹心五 ",[105] = "混一色 ",[106] = "大三元 ",[107] = "小三元 ",[108] = "十风 ",[109] = "十三幺 ", [110] = "龙爪背 ",
						[111] = "四幺鸡 ",[112] = "杠上五梅花 ",[113] = "无鸡 ",[114] = "小鸡归位 ",[115] = "两杠 ",
                        [50] = "三字牌 ", [51] = "字牌飞机 ", [52] = "字牌火箭 ", [53] = "字牌大飞机 ", [54] = "中发白大火箭 ",
                        [55] = "单吊五 ", [56] = "大板子 ", [57] = "五板子 ", [58] = "六板子 ", [59] = "七板子 ",
                        [60] = "飞机 ", [61] = "大飞机 ", [62] = "超级大飞机 ", [63] = "火箭 ", [64] = "大火箭 ",
                        [65] = "超级大火箭 ", [66] = "十八学士 ", [67] = "卡边吊 ", [68] = "明杠 ", [69] = "暗杠 ",
                        [70] = "明字杠 ", [71] = "暗字杠 ", [72] = "门大 ",
                        [83] = "缺一门 ",
                        [150] = "明杠 ", [151] = "暗杠 ", [152] = "补杠 ", [153] = "呼叫转移 "}
	dump(rptMsgTbl)

	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("RoundReport_MY.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	
	local timeLabel = gt.seekNodeByName(csbNode, "Text_createDockTime")

	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "Spr_bg"):setScaleY(1280/960)
		gt.seekNodeByName(csbNode, "Panel_1"):setScaleY(1280/960)
		gt.seekNodeByName(csbNode, "Node_reportTitle"):setPositionY(780)
		gt.seekNodeByName(csbNode, "Btn_shard"):setPositionY(-50)
		gt.seekNodeByName(csbNode, "Btn_endGame"):setPositionY(-50)
		gt.seekNodeByName(csbNode, "Btn_startGame"):setPositionY(-50)

		if timeLabel then
			gt.log("sunhaozhisunhaozhisunhaozhisunhaozhisunhaozhi")
			timeLabel:setPositionY(770)
		end
	end
	self.rootNode = csbNode
	self:addChild(csbNode)
	
	if timeLabel then
		local date=os.date("%Y-%m-%d %H:%M")
		local desk_ID = gt.report_desk_id or 537292
		timeLabel:setString("房间号:"..desk_ID.."  "..date)
	end

    gt.findNodeArray(self.rootNode, "Spr_FanType"):dump():setLocalZOrder(999)

	local TypeStr,tableStr = gt.PalyTypeText(gt.roomState,rptMsgTbl.m_playType)
	--玩法类型
	local TextType = gt.seekNodeByName(csbNode,"Text_Type")
	TextType:setString(tableStr)

	if string.len(tableStr)>120 then
		TextType:setFontSize(25)
	end

    if table.contains(rptMsgTbl.m_playType, 35) then -- 属于7张玩法
        strHuTypeTab[2] = "龙四对 "
        strHuTypeTab[3] = "四对 "
        strHuTypeTab[20] = "清四对 "
        strHuTypeTab[21] = "清龙四对 "
        strHuTypeTab[23] = "将四对 "
    end

	if table.contains({118, 119}, gt.roomState) then
		strHuTypeTab[6]  = "大对子 "
		strHuTypeTab[30]  = "一般高 "
	end

	-- 结束标题
	local reportTitleNode = gt.seekNodeByName(csbNode, "Node_reportTitle")
	for _, reportTitleSpr in ipairs(reportTitleNode:getChildren()) do
		reportTitleSpr:setVisible(false)
	end

	self.WanNengPaiCarTable = {}
	if rptMsgTbl.m_hunCard then
		local h = 670
		for i, v in ipairs(rptMsgTbl.m_hunCard) do
			-- self:addMjTileToPlayer(v[1], v[2])
			if v[1] ~= 0 and v[2] ~= 0 then
				local mjTileName = string.format("p%ds%d_%d.png", 4, v[1], v[2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				if i == 2 then
					mjTileSpr:setPosition( cc.p(455, h) )
					mjTileSpr:setColor(cc.c3b(255,255,100))
					table.insert( self.WanNengPaiCarTable, v )
				elseif i == 3 then
					mjTileSpr:setPosition( cc.p(405, h) )
				else
					mjTileSpr:setPosition( cc.p(355, h) )
					mjTileSpr:setColor(cc.c3b(255,255,100))
					table.insert( self.WanNengPaiCarTable, v )
				end

				self.rootNode:addChild(mjTileSpr)
			end
		end
	end

	local ownerWinSorce = 0
	-- 具体信息
	for seatIdx, roomPlayer in ipairs(roomPlayers) do
		if playerSeatIdx == seatIdx then
			-- 自己的分数
			ownerWinSorce = rptMsgTbl.m_score[seatIdx]
		end

		gt.log( "----seatIdx:" .. seatIdx)
		local playerReportNode = gt.seekNodeByName(csbNode, "Node_playerReport_" .. seatIdx)
		--飘几
		local Spr_piao = gt.seekNodeByName(playerReportNode, "Spr_piao")
		local Text_PiaoNum = gt.seekNodeByName(Spr_piao,"Text_PiaoNum")
		Spr_piao:setVisible(false)
		if roomPlayer.piaoNum then
			if roomPlayer.piaoNum>0 then
				Spr_piao:setVisible(true)
				Text_PiaoNum:setString("x"..roomPlayer.piaoNum)
			end
		end
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
		-- 自己胡牌的信息
		-- 结果
		local roundResult = rptMsgTbl.m_win[seatIdx]
		local showStr = ""
		if roundResult~=0 and roundResult~=nil then
			showStr = showStrArr[tonumber(roundResult)]
		end

		local strHuType = ""
		local roundResult = rptMsgTbl["m_hu" .. seatIdx]
		local resultTab = {}
		for i,v in ipairs(roundResult) do
            if strHuTypeTab[tonumber(v)] then
                strHuType = strHuTypeTab[tonumber(v)]
            else -- 调试
                strHuType = "未知" .. v .. " "
            end
            table.insert(resultTab, strHuType)
		end

		strHuType = ""
		for i,v in ipairs(resultTab) do
			strHuType = strHuType .. v
		end

		if string.len(strHuType) ~= 0 then
			-- 胡牌总显示
			detailTxt = showStr .. "(" .. strHuType .. ") "
		else
			-- 胡牌总显示
			detailTxt = showStr
		end


		-- 点炮的
		local strDianType = ""
		local dianResult = rptMsgTbl["m_dian" .. seatIdx]
		local dianTab = {}
		for i = 1, #dianResult do
			if dianResult[i] == 1 then
				strDianType = "点1胡 "
			elseif dianResult[i] == 2 then
				strDianType = "点2胡 "
			elseif dianResult[i] == 3 then
				strDianType = "点3胡 "
			end
			table.insert(dianTab, strDianType)
		end

		strDianType = ""
		for i,v in ipairs(dianTab) do
			strDianType = strDianType .. v
		end

		-- 点炮总显示
		detailTxt = detailTxt..strDianType

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

        if table.contains({118, 119}, gt.roomState) and rptMsgTbl.m_isBaoJiao[seatIdx] == 1 then
			detailTxt = detailTxt .. " 报叫"
        end

        if rptMsgTbl.m_isBaozi then
			detailTxt = detailTxt .. " 豹子"
        end

		--关死
        if table.contains({115, 117, 118, 119}, gt.roomState) and rptMsgTbl.m_iGuanSi  then
            local piaoCount = rptMsgTbl.m_iGuanSi[seatIdx]
            if piaoCount ~= 0 then
                detailTxt = " " .. detailTxt .. string.format(" 关死", piaoCount)
            end
        end

		local fanCount = rptMsgTbl.m_fan[seatIdx]
		if fanCount >= 0 then
			detailTxt = " " .. detailTxt .. string.format("		%d 番",fanCount)
		end

		detailLabel:setString(detailTxt)

        gt.findNodeArray(playerReportNode, "Spr_piao"):setVisible(rptMsgTbl.m_ybPiao[seatIdx] == 1)

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

		-- -- X番
		-- local regionScoreLabel = gt.seekNodeByName(playerReportNode, "Label_regionScore")
		-- regionScoreLabel:setVisible(true)
		-- regionScoreLabel:setString(string.format("%d番", math.abs(rptMsgTbl.m_fan[seatIdx])))

		-- 胡标识
		-- 第几个胡
		local winIdx = rptMsgTbl.m_winList[seatIdx]
		local Spr_FanType = gt.seekNodeByName(playerReportNode, "Spr_FanType")
		local Label_WinType = gt.seekNodeByName(Spr_FanType, "Label_WinType")
		if winIdx == 1 then
			Label_WinType:setString("1胡")
		elseif winIdx == 2 then
			Label_WinType:setString("2胡")
		elseif winIdx == 3 then
			Label_WinType:setString("3胡")
		else
			Label_WinType:setVisible(false)
		end
		--积分
		local scoreLabel = gt.seekNodeByName(Spr_FanType, "Label_score")
		scoreLabel:setString(tostring(rptMsgTbl.m_score[seatIdx]))
		-- 更新积分
		roomPlayer.score = roomPlayer.score + rptMsgTbl.m_score[seatIdx]
		roomPlayer.scoreLabel:setString(tostring(roomPlayer.score))

        local maxUser = 4 -- 三人玩法或者四人玩法
        for j=1, maxUser-1 do
            local nod_title = gt.seekNodeByName(Spr_FanType, "Label_Num"..j)
            local nod_value = gt.seekNodeByName(Spr_FanType, "Label_Num"..j.."_Tang")

            local _idx = tonumber(string.sub(nod_title:getString(), 0, 1))

            local _pvMap = {[0] = "无飘", "飘", "对飘"}
            local _pValue = _pvMap[rptMsgTbl["m_piaoFen"..seatIdx][_idx]]

            local _bvMap = {[0] = "无报", "报叫", "对报"}
            local _bValue = _bvMap[rptMsgTbl["m_tangFen"..seatIdx][_idx]]

            local _vTable = {}
            if table.contains(rptMsgTbl.m_playType, 104) then -- 可飘
                table.insert(_vTable, _pValue)
            end

            if table.contains(rptMsgTbl.m_playType, 52) then -- 报叫
                table.insert(_vTable, _bValue)
            end

            nod_value:setString(table.concat(_vTable, " "))
        end

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
		if roomPlayer.mjTileDarkBars then
			for _, darkBar in ipairs(roomPlayer.mjTileDarkBars) do
				for i = 1, 4 do
					local mjTileName = string.format("p4s%d_%d.png", darkBar.mjColor, darkBar.mjNumber)
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
		end

		-- 明杠
		if roomPlayer.mjTileBrightBars then
			for _, brightBar in ipairs(roomPlayer.mjTileBrightBars) do
				for i = 1, 4 do
					local mjTileName = string.format("p4s%d_%d.png", brightBar.mjColor, brightBar.mjNumber)
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					playerReportNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + 16
			end
		end

		-- 明补
		if roomPlayer.mjTileBrightBu then
			for _, brightBar in ipairs(roomPlayer.mjTileBrightBu) do
				for i = 1, 4 do
					local mjTileName = string.format("p4s%d_%d.png", brightBar.mjColor, brightBar.mjNumber)
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					playerReportNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + 16
			end
		end

		-- 碰
		if roomPlayer.mjTilePungs then
			for _, pung in ipairs(roomPlayer.mjTilePungs) do
				for i = 1, 3 do
					local mjTileName = string.format("p4s%d_%d.png", pung.mjColor, pung.mjNumber)
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					playerReportNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + 16
			end
		end

		if roomPlayer.mjTileFeis then
			for _, feiData in ipairs(roomPlayer.mjTileFeis) do
				--飞
				for i=1,3 do
					local mjTileName = string.format("p4s%d_%d.png", feiData.feiGroup[i][1], feiData.feiGroup[i][2])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					if i == 2 then
						mjTileSpr:setColor(cc.c3b(255,255,100))
					end
					playerReportNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + 16
			end
		end


		--躺
		if roomPlayer.langMjTiles then
			gt.dump(roomPlayer.langMjTiles)
			for _, tang in ipairs(roomPlayer.langMjTiles) do
				local mjTileName = string.format("p4s%d_%d.png", tang[1], tang[2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setColor(cc.c3b(255,255,100))
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				playerReportNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end
		end

		--吃牌
		if roomPlayer.mjTileEat then
			for _, eat in ipairs(roomPlayer.mjTileEat) do
				for i = 1, 3 do
					local mjTileName = string.format("p4s%d_%d.png", eat[i][3], eat[i][1])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					playerReportNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + 16
			end
		end


		-- 持有牌
		for _, v in ipairs(rptMsgTbl["array" .. (seatIdx - 1)]) do
			local mjTileName = string.format("p4b%d_%d.png", v[1], v[2])
			local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
			mjTileSpr:setScale(0.66*referScale)
			mjTileSpr:setPosition(referPos)
			for i,wan in ipairs(self.WanNengPaiCarTable) do
				if v[1] == wan[1] and v[2] == wan[2] then
					mjTileSpr:setColor(cc.c3b(255,255,100))
				end
			end
			playerReportNode:addChild(mjTileSpr)
			referPos = cc.pAdd(referPos, referSpace)
		end

		if playerScore then
			for i,userRound in ipairs(playerScore[seatIdx]) do
				--其它操作
				if tonumber(userRound[1])+1 == seatIdx then
					referPos.x = referPos.x + 33
					if userRound~= nil then
						local mjTileName = string.format("p4s%d_%d.png", userRound[5][1], userRound[5][2])
						local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
						if mjTileSpr then
							mjTileSpr:setScale(referScale)
							mjTileSpr:setPosition(referPos.x, referPos.y)
							playerReportNode:addChild(mjTileSpr)

							for j,wan in ipairs(self.WanNengPaiCarTable) do
								if userRound[5][1] == wan[1] and userRound[5][2] == wan[2] then
									mjTileSpr:setColor(cc.c3b(255,255,100))
								else
									mjTileSpr:setColor(cc.c3b(200,200,200))
								end
							end
						end
					end
				end
			end
		else
			local hucardResult = rptMsgTbl["m_hucards" .. seatIdx]
			if next(hucardResult) ~= nil then
				for i = 1, #hucardResult do
					local mjTileName = string.format("p4s%d_%d.png", hucardResult[i][1], hucardResult[i][2])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					if mjTileSpr then

						mjTileSpr:setScale(referScale)
						if i == 1 then
							mjTileSpr:setPosition(referPos.x + 16, referPos.y)
						elseif i == 2 then
							mjTileSpr:setPosition(referPos.x + 16 * 4, referPos.y)
						end
						playerReportNode:addChild(mjTileSpr)

						for j,wan in ipairs(self.WanNengPaiCarTable) do
							if hucardResult[i][1] == wan[1] and hucardResult[i][2] == wan[2] then
								mjTileSpr:setColor(cc.c3b(255,255,100))
							else
								mjTileSpr:setColor(cc.c3b(200,200,200))
							end
						end
					end
				end
			end
		end

		-- 玩家持有牌
		roomPlayer.holdMjTiles = {}
		-- 玩家已出牌
		roomPlayer.outMjTiles = {}
		-- 碰
		roomPlayer.mjTilePungs = {}
		-- 飞
		roomPlayer.mjTileFeis = {}
		-- 明杠
		roomPlayer.mjTileBrightBars = {}
		-- 暗杠
		roomPlayer.mjTileDarkBars = {}
		--吃
		roomPlayer.mjTileEat = {}
		-- 明补
		roomPlayer.mjTileBrightBu = {}
		-- 暗补
		roomPlayer.mjTileDarkBu = {}
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

	-- 开始下一局
	local startGameBtn = gt.seekNodeByName(csbNode, "Btn_startGame")
	gt.addBtnPressedListener(startGameBtn, function()
		self:removeFromParent()

		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_READY
		msgToSend.m_pos = playerSeatIdx - 1
		gt.socketClient:sendMessage(msgToSend)
	end)
	-- 结束界面
	local endGameBtn = gt.seekNodeByName(csbNode, "Btn_endGame")
	gt.addBtnPressedListener(endGameBtn, function()
		self:removeFromParent()
	end)

	if isLast==0 then
		-- 不是最后一局
		startGameBtn:setVisible( true )
		endGameBtn:setVisible( false )
	elseif isLast==1 then
		-- 最后一局
		startGameBtn:setVisible( false )
		endGameBtn:setVisible( true )
	end

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

    self:adjustPiaoIcon(csbNode)
    local roomPlayerCount = #roomPlayers or 4
    self:adjustUIfor3People(csbNode, gt.roomState,roomPlayerCount)
end

function RoundReport_NJ:adjustPiaoIcon(csbNode)
    local _nodeList = gt.findNodeArray(csbNode, {"Node_playerReport_#1#4", "Spr_piao"})
    _nodeList:setPosition(cc.p(150, 600)):removeAllChildren()
end

function RoundReport_NJ:adjustUIfor3People(csbNode, roomState,roomPlayerCount)
    if roomPlayerCount == 3 then
    	local _nodeList = gt.findNodeArray(csbNode, {"Node_playerReport_#1#4", "Label_Num#1#3", "Label_Num3_Tang"}, "Spr_slid#1#3")
	    _nodeList.Node_playerReport_4:setVisible(false)

	    local _infoYoffsetMap = {-30, -60, -90}

	    for i=1, 3 do
	        local _infoNode = _nodeList["Node_playerReport_" .. i]
	        _infoNode:setPositionY(_infoNode:getPositionY() + _infoYoffsetMap[i])
	        _nodeList["Spr_slid"..i]:setPositionY(_nodeList["Spr_slid"..i]:getPositionY() + _infoYoffsetMap[i])
	    end
    end

    if roomState == 118 then 
    	local _nodeList = gt.findNodeArray(csbNode, {"Node_playerReport_#1#4", "Label_Num#1#3", "Label_Num3_Tang"}, "Spr_slid#1#3")
	    _nodeList.Node_playerReport_4:setVisible(false)
    	for i=1, 3 do
	        local _infoNode = _nodeList["Node_playerReport_" .. i]
	        _infoNode.Label_Num3:setVisible(false)
	        _infoNode.Label_Num3_Tang:setVisible(false)
	        _infoNode.Label_Num3_Tang:setVisible(false)
	    end
    end
end

function RoundReport_NJ:screenshotShareToWX()
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

function RoundReport_NJ:update()
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


function RoundReport_NJ:onNodeEvent(eventName)
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

function RoundReport_NJ:onTouchBegan(touch, event)
	return true
end

return RoundReport_NJ
