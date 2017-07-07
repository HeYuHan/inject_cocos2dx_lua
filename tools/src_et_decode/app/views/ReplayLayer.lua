

local gt = cc.exports.gt

require("app/views/PlayManagerXZ")
require("app/views/PlayManagerXL")
require("app/views/PlayManagerSR")
require("app/views/PlayManagerDDH")
require("app/views/PlayManagerNJ")
require("app/views/PlayManagerDY")
require("app/views/PlayManagerSRSF")
require("app/views/PlayManagerMY")
require("app/views/PlayManagerWZ")
require("app/views/PlayManagerLZ")
require("app/views/PlayManagerYA")
require("app/views/PlayManagerLS")
require("app/views/PlayManagerZG")
require("app/views/PlayManagerGA")
require("app/views/PlayManagerZGSR")
require("app/views/PlayManagerNeiJiang")
require("app/views/PlayManagerErRen")

local ReplayLayer = class("ReplayLayer", function()
	return cc.Layer:create()
end)

ReplayLayer.PlayType = {
	-- 血战
	XUEZHAN				=  101,
	-- 血流
	XUELIU		        =  102,
	-- 三人
	SANREN			    =  103,
	--倒到胡
	DDH                 =  104,
	--四人两房
	NEIJIANG     		=  105,
	--德阳
	DEYANG    			=  106,
	--三人三房
	SRSF                =  107,
	--绵阳
	MIANYANG			=  108,
	--宜宾
	YIBIN				=  109,
	--万州
	WANZHOU				=  110,
	--泸州
	LUZHOU				=  111,
	--乐山
	LESHAN				=  112,
	--南充
	NANCHONG			=  113,
	--雅安
	YAAN				=  116,
    --广安
	GUANGAN             =  114,
	--自贡
	ZIGONG				=  115,
	--自贡四人
	ZIGONGSR			=  117,
    NEIJIANG3           =  118, -- 内江三人
    NEIJIANG4           =  119, -- 内江四人
    ERREN               =  120  -- 二人麻将
}

function ReplayLayer:ctor(replayData)
	-- 注册节点事件
	-- gt.videoState = true

	self:registerScriptHandler(handler(self, self.onNodeEvent))

	self.replayStepsData = replayData.m_oper
	gt.dump(replayData)

	--self:dumpReplayer()
	--replayData.m_card0 = {{1,1},{1,5},{1,6},{1,8},{2,1},{2,1},{2,1},{2,2},{2,2},{2,7},{2,7},{2,9},{3,3},{3,4}}
	--replayData.m_card1 = {{1,3},{1,4},{1,8},{2,6},{2,7},{2,7},{2,9},{3,2},{3,4},{3,5},{3,7},{3,8},{3,8}}
	--replayData.m_card2 = {{1,1},{1,5},{1,9},{2,2},{2,3},{2,3},{2,5},{2,5},{2,5},{2,9},{2,9},{3,7},{3,9}}
	--replayData.m_card3 = {{1,2},{1,2},{1,3},{1,5},{1,5},{1,9},{1,9},{2,5},{3,2},{3,4},{3,5},{3,7},{3,9}}
	--self.replayStepsData = {{3,57,{{1,1}}},{0,57,{{1,1}}},{1,57,{{1,1}}},{2,57,{{3,1}}},{2,2,{{3,9}}},{3,1,{{3,6}}},{3,2,{{1,1}}},{2,21,{{11,5}}},{2,22,{{11,5}}},{2,5,{{1,1},{1,1},{1,1}}},{2,2,{{3,9}}},{3,1,{{3,1}}},{3,2,{{1,2}}},{0,1,{{3,4}}},{0,2,{{1,1}}},{1,1,{{1,7}}},{1,2,{{1,9}}},{2,1,{{1,7}}},{2,2,{{3,5}}},{3,1,{{3,8}}},{3,2,{{1,9}}},{0,1,{{3,4}}},{0,2,{{1,7}}},{1,1,{{1,4}}},{1,2,{{1,7}}},{2,1,{{2,6}}},{2,2,{{2,8}}},{3,1,{{3,2}}},{3,2,{{2,9}}},{1,21,{{29,4},{29,5}}},{1,22,{{29,4}}},{1,6,{{2,9},{2,9},{2,9},{2,9}}},{1,1,{{3,1}}},{1,2,{{1,7}}},{2,1,{{1,9}}},{2,2,{{2,1}}},{3,1,{{3,5}}},{3,2,{{3,2}}},{0,21,{{32,5}}},{0,22,{{32,5}}},{0,5,{{3,2},{3,2},{3,2}}},{0,2,{{1,9}}},{1,1,{{3,5}}},{1,2,{{1,5}}},{2,1,{{2,7}}},{2,2,{{2,7}}},{0,21,{{27,5}}},{0,22,{{27,5}}},{0,5,{{2,7},{2,7},{2,7}}}}
	local index = 0
	for i = 1, #self.replayStepsData do
		if self.replayStepsData[i][2] == 1 then
			index = index + 1
			table.insert(self.replayStepsData[i],index)
		else
			table.insert(self.replayStepsData[i],0)
		end
	end
	gt.dump(self.replayStepsData)

	-- 加载界面资源
	local csbNode = nil
	local mjCount = 10 --玩法张数
	self.playerSeatIdx = 4
	self.remainCard = 55 --剩余牌数
	--101：血战102：血流 103 三人
	if replayData.m_state == ReplayLayer.PlayType.XUEZHAN then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.GUANGAN then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
		self.remainCard = 67
	elseif replayData.m_state == ReplayLayer.PlayType.XUELIU then
		csbNode = cc.CSLoader:createNode("ReplayLayerXL.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.SANREN then
		self.remainCard = 32
		self.playerSeatIdx = 3
		csbNode = cc.CSLoader:createNode("ReplayLayerSR.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.DDH then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.NEIJIANG or replayData.m_state == ReplayLayer.PlayType.SRSF or replayData.m_state == ReplayLayer.PlayType.ZIGONGSR then
		for i = 1, #replayData.m_playtype do
			if replayData.m_playtype[i] == 35 then
				mjCount = 7
				csbNode = cc.CSLoader:createNode("ReplayLayerNJ_SEV.csb")
				if replayData.m_state == ReplayLayer.PlayType.NEIJIANG or replayData.m_state == ReplayLayer.PlayType.ZIGONGSR then
					self.remainCard = 43
				elseif replayData.m_state == ReplayLayer.PlayType.SRSF then
					self.remainCard = 86
				end
				break
			elseif replayData.m_playtype[i] == 36 then
				mjCount = 10
				csbNode = cc.CSLoader:createNode("ReplayLayerNJ_TEN.csb")
				if replayData.m_state == ReplayLayer.PlayType.NEIJIANG then
					self.remainCard = 31
				elseif replayData.m_state == ReplayLayer.PlayType.SRSF then
					self.remainCard = 77
				end
				break
			elseif replayData.m_playtype[i] == 37 then
				mjCount = 13
				csbNode = cc.CSLoader:createNode("ReplayLayerNJ_THR.csb")
				if replayData.m_state == ReplayLayer.PlayType.NEIJIANG or replayData.m_state == ReplayLayer.PlayType.ZIGONGSR  then
					self.remainCard = 19
				elseif replayData.m_state == ReplayLayer.PlayType.SRSF then
					self.remainCard = 68
				end
				break
			end
		end
		if replayData.m_state == ReplayLayer.PlayType.SRSF then
			self.playerSeatIdx = 3
			csbNode = cc.CSLoader:createNode("ReplayLayerSR.csb")
		end
	elseif replayData.m_state == ReplayLayer.PlayType.ZIGONG then
		csbNode = cc.CSLoader:createNode("ReplayLayerSR.csb")
		

		local node_play = gt.seekNodeByName(csbNode, "Node_play")
		self.mjCount = 13
		self.remainCard = 32
		for i = 1, #replayData.m_playtype do
			if replayData.m_playtype[i] == 35 then
				self.mjCount = 7
				self.remainCard = 50
				break
			elseif replayData.m_playtype[i] == 37 then
				self.mjCount = 13
				self.remainCard = 32
				break
			end
		end
		
		for i = 1, 3 do
			local node_playerMjTiles = gt.seekNodeByName(node_play, "Node_playerMjTiles_" .. i)
			local node_playerInfo = gt.seekNodeByName(csbNode, "Node_playerInfo_" .. i)
			if i == 3 then
				node_playerInfo:setPosition(cc.p(node_playerInfo:getPositionX(), node_playerInfo:getPositionY() - 160 + self.mjCount * 10))
			end
			for _, node_playerMjTilesChild in ipairs(node_playerMjTiles:getChildren()) do
				if i == 1 then
					node_playerMjTilesChild:setPosition(cc.p(node_playerMjTilesChild:getPositionX(), node_playerMjTilesChild:getPositionY() + 260 - self.mjCount * 20))
				elseif i == 2 then
					node_playerMjTilesChild:setPosition(cc.p(node_playerMjTilesChild:getPositionX() , node_playerMjTilesChild:getPositionY() - 260 + self.mjCount * 20))
				elseif i == 3 then
					node_playerMjTilesChild:setPosition(cc.p(node_playerMjTilesChild:getPositionX() + 650 - self.mjCount * 50, node_playerMjTilesChild:getPositionY()))
					for j = 1, 3 do
						if node_playerMjTilesChild:getName() == "Spr_mjTileOut_" .. j then
							node_playerMjTilesChild:setPosition(cc.p(node_playerMjTilesChild:getPositionX() - 650 + self.mjCount * 50, node_playerMjTilesChild:getPositionY()))
						end
					end
				end
			end
		end

	elseif replayData.m_state == ReplayLayer.PlayType.DEYANG then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.MIANYANG then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.YIBIN then
		self.remainCard = 54
		csbNode = cc.CSLoader:createNode("ReplayLayer_YB.csb")	
	elseif replayData.m_state == ReplayLayer.PlayType.WANZHOU then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.LUZHOU then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
		for i = 1, #replayData.m_playtype do
			if replayData.m_playtype[i] == 171 then
				self.remainCard = 59
				break
			elseif replayData.m_playtype[i] == 172 then
				self.remainCard = 63
				break
			elseif replayData.m_playtype[i] == 173 then
				self.remainCard = 67
				break
			end
		end
	elseif replayData.m_state == ReplayLayer.PlayType.LESHAN then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.NANCHONG then
		csbNode = cc.CSLoader:createNode("ReplayLayer_YB.csb")
	elseif replayData.m_state == ReplayLayer.PlayType.YAAN then
		csbNode = cc.CSLoader:createNode("ReplayLayer.csb")
		for i = 1, #replayData.m_playtype do
			if replayData.m_playtype[i] == 35 then
				self.remainCard = 55
				--7张
		 		for j=1,4 do
					local mjTilesReferNode = gt.seekNodeByName(csbNode, "Node_playerMjTiles_" .. j)
					if j==4 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							gt.log("child:getName() = "..child:getName())
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionX(child:getPositionX()+250)
							end
						end
					elseif j == 1 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionY(child:getPositionY()+40)
							end
						end
					elseif j == 2 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionX(child:getPositionX()-120)
							end
						end
					elseif j == 3 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionY(child:getPositionY()-100)
							end
						end
					end
		 		end
			elseif replayData.m_playtype[i] == 36 then
				self.remainCard = 43
				for j=1,4 do
					local mjTilesReferNode = gt.seekNodeByName(csbNode, "Node_playerMjTiles_" .. j)
					if j==4 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionX(child:getPositionX()+150)
							end
						end
					elseif j == 1 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionY(child:getPositionY()+40)
							end
						end
					elseif j == 2 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionX(child:getPositionX()-40)
							end
						end
					elseif j == 3 then
						for _, child in ipairs(mjTilesReferNode:getChildren()) do
							if child:getName() ~= "Spr_mjTileOut_1" and child:getName() ~= "Spr_mjTileOut_2" and child:getName() ~= "Spr_mjTileOut_3" then
								child:setPositionY(child:getPositionY()-50)
							end
						end
					end
		 		end
			elseif replayData.m_playtype[i] == 37 then
				self.remainCard = 31
			end
		end
	elseif replayData.m_state == ReplayLayer.PlayType.NEIJIANG3 or replayData.m_state == ReplayLayer.PlayType.NEIJIANG4 then
        mjCount     = table.contains(replayData.m_playtype, 35) and 7 or 13
        local fangCount   = table.contains(replayData.m_playtype, 43) and 3 or 2
        local playerCount = (replayData.m_state == ReplayLayer.PlayType.NEIJIANG3) and 3 or 4

        self.remainCard = 36*fangCount - playerCount*mjCount - 1
		csbNode = cc.CSLoader:createNode("ReplayLayerNeiJiang.csb")
    elseif replayData.m_state == ReplayLayer.PlayType.ERREN then
        mjCount = 13
        local fangCount   = table.contains(replayData.m_playtype, 43) and 3 or 2
        local playerCount = 2

        self.remainCard = 36*fangCount - playerCount*mjCount - 1
		csbNode = cc.CSLoader:createNode("ReplayLayerNeiJiang.csb")
	end

	-- 容错处理，默认1
    local currentUID = gt.playerData.uid
    if (gt.isGM == 1) and gt.GM_simulate_uid then
        currentUID = gt.GM_simulate_uid
    end
	for seatIdx, uid in ipairs(replayData.m_userid) do
		if currentUID == uid then
			self.playerSeatIdx = seatIdx
			break
		end
	end

	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		gt.seekNodeByName(csbNode, "mahjong_table"):setScale(1280/960)
		gt.seekNodeByName(csbNode, "mahjong_table"):setAnchorPoint(0.5, 0.5)
		gt.seekNodeByName(csbNode, "mahjong_table"):setPositionX(640)
		gt.seekNodeByName(csbNode, "dismissTag"):setPositionY(758)
		gt.seekNodeByName(csbNode, "Label_time"):setPositionY(802)
		gt.seekNodeByName(csbNode, "Label_roomID"):setPositionY(802)
		gt.seekNodeByName(csbNode, "Lab_Play"):setPositionY(802)
	end
	
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	local Lab_Play = gt.seekNodeByName(self.rootNode, "Lab_Play")
	Lab_Play:setPositionX(Lab_Play:getPositionX() + 50)

	
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	self.remainTilesLabel = gt.seekNodeByName(roundStateNode, "Label_remainTiles")
	self.remainTilesLabel:setString(tostring(self.remainCard))
	local Label_remainRounds = gt.seekNodeByName(roundStateNode, "Label_remainRounds")
	Label_remainRounds:setString(string.format("%d/%d", (replayData.m_curCircle + 1), replayData.m_maxCircle))

	if not replayData.m_state then
		replayData.m_state = ReplayLayer.PlayType.XUEZHAN
	end

	self.playType = replayData.m_state

	local paramTbl = {}
	
	paramTbl.m_playtype 	= replayData.m_playtype
	paramTbl.roomID 		= replayData.m_deskId
	paramTbl.playType 		= replayData.m_state
	paramTbl.playerSeatIdx 	= self.playerSeatIdx
	paramTbl.mjCount 		= mjCount
	
	dump(replayData)

	--101:血战102:血流103:三人104:倒到胡105：四人两房106德阳107三人三房
	if self.playType == ReplayLayer.PlayType.XUEZHAN then
		self.playManager = gt.PlayManagerXZ:new(self.rootNode, paramTbl)
	elseif self.playType == ReplayLayer.PlayType.XUELIU then
		self.playManagerXL = gt.PlayManagerXL:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerXL
	elseif self.playType == ReplayLayer.PlayType.SANREN then
		self.playManagerSR = gt.PlayManagerSR:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerSR
	elseif self.playType == ReplayLayer.PlayType.DDH then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene55.png")
		self.playManagerDDH = gt.PlayManagerDDH:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerDDH
	elseif self.playType == ReplayLayer.PlayType.NEIJIANG then
		self.playManagerNJ = gt.PlayManagerNJ:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerNJ
	elseif self.playType == ReplayLayer.PlayType.DEYANG then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene83.png")
		self.playManagerDY = gt.PlayManagerDY:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerDY
	elseif self.playType == ReplayLayer.PlayType.SRSF then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene84.png")
		self.playManagerSRSF = gt.PlayManagerSRSF:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerSRSF
	elseif self.playType == ReplayLayer.PlayType.MIANYANG then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene63.png")
		self.playManagerMY = gt.PlayManagerMY:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerMY
	elseif self.playType == ReplayLayer.PlayType.YIBIN then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene75.png")
		self.playManager = gt.PlayManagerXZ:new(self.rootNode, paramTbl)
		self.playManager:hidePiaoImage()
	elseif self.playType == ReplayLayer.PlayType.WANZHOU then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene25.png")
		self.playManagerWZ = gt.PlayManagerWZ:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerWZ
	elseif self.playType == ReplayLayer.PlayType.LUZHOU then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene29.png")
		self.playManagerLZ = gt.PlayManagerLZ:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerLZ
	elseif self.playType == ReplayLayer.PlayType.LESHAN then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene30.png")
		self.playManagerLS = gt.PlayManagerLS:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerLS
	elseif self.playType == ReplayLayer.PlayType.ZIGONG then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene49.png")
		self.playManagerZG = gt.PlayManagerZG:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerZG
	elseif self.playType == ReplayLayer.PlayType.ZIGONGSR then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene49.png")
		self.playManager = gt.PlayManagerZGSR:new(self.rootNode, paramTbl)
	elseif self.playType == ReplayLayer.PlayType.NANCHONG then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene86.png")
		self.playManagerLZ = gt.PlayManagerLZ:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerLZ
		self.playManager:hidePiaoImage()
	elseif self.playType == ReplayLayer.PlayType.YAAN then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene48.png")
		self.playManagerYA = gt.PlayManagerYA:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerYA
	elseif self.playType == ReplayLayer.PlayType.GUANGAN then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene47.png")
        paramTbl.m_baseScore = replayData.m_baseScore
		self.playManagerGA = gt.PlayManagerGA:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerGA
	elseif self.playType == ReplayLayer.PlayType.NEIJIANG3 or self.playType == ReplayLayer.PlayType.NEIJIANG4 then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene95.png")
        paramTbl.roomState = self.playType
		self.playManagerNeiJiang = gt.PlayManagerNeiJiang:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerNeiJiang
	elseif self.playType == ReplayLayer.PlayType.ERREN then
		gt.seekNodeByName(self.rootNode, "Spr_PlayTile"):setSpriteFrame("playScene96.png")
        paramTbl.roomState = self.playType
		self.playManagerErRen = gt.PlayManagerErRen:new(self.rootNode, paramTbl)
		self.playManager = self.playManagerErRen
	end
	
	self:initRoomPlayersData(replayData)
	self.replayData = replayData

	-- 更新打牌时间
	-- self.time_now = 1469700778
	self.time_now = replayData.m_time
	gt.log("更新打牌时间")
	-- print(self.time_now)
	self.holdTime = 0
	self:updateCurrentTime()

	self.isPause = false
	local optBtnsSpr = gt.seekNodeByName(csbNode, "Spr_optBtns")
	-- 播放按键
	local playBtn = gt.seekNodeByName(optBtnsSpr, "Btn_play")
	playBtn:setVisible(false)
	self.playBtn = playBtn
	-- 暂停
	local pauseBtn = gt.seekNodeByName(optBtnsSpr, "Btn_pause")
	self.pauseBtn = pauseBtn
	gt.addBtnPressedListener(playBtn, function()
		self:setPause(false)
	end)
	gt.addBtnPressedListener(pauseBtn, function()
		self:setPause(true)
	end)
	-- 退出
	local exitBtn = gt.seekNodeByName(optBtnsSpr, "Btn_exit")
	gt.addBtnPressedListener(exitBtn, function()
		self:removeFromParent()
	end)
	-- 后退
	local preBtn = gt.seekNodeByName(optBtnsSpr, "Btn_rewind")
	self.preBtn = preBtn
	preBtn:setVisible(true)
	if preBtn then
		gt.addBtnPressedListener(preBtn, function()
			self:preRound()
		end)
	end
	-- 前进
	local nextBtn = gt.seekNodeByName(optBtnsSpr, "Btn_fastforward")
	self.nextBtn = nextBtn
	nextBtn:setVisible(true)
	if nextBtn then
		gt.addBtnPressedListener(nextBtn, function()
			self:nextRound()
		end)
	end

	-- 快进或者快退的步数
	self.quickStepNum	= 8
	-- 点击快进/快退开始的时间
	self.quickStartTime = 0
end


function ReplayLayer:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

		-- 逻辑更新定时器
		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)

		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
	end
end

function ReplayLayer:onTouchBegan(touch, event)
	return true
end

-- 快推的话,原理是将牌恢复到最初始状态
-- 然后快速行进到当前状态
function ReplayLayer:preRound()
	--self.remainCard = tonumber(self.remainCard) + 1
	--self.remainTilesLabel:setString(tostring(self.remainCard))
	-- -- 如果暂停或者已经结束,是否需要回退
	-- if self.isPause or self.isReplayFinish then
	-- 	return
	-- end


	if self.curReplayStep <= 1 then
		return
	end

	self.quickStartTime = os.time()

	-- 计算回退到何步骤
	local wihldReplayStep = self.curReplayStep - self.quickStepNum
	
	--计算剩余牌数
	local curStep = 1
	if wihldReplayStep == 1 then
		curStep = 1
		--self.remainTilesLabel:setString(tostring(self.remainCard))
	else
		curStep = tonumber(wihldReplayStep) + 1
	end
	
	if self.playType == ReplayLayer.PlayType.XUEZHAN or self.playType == ReplayLayer.PlayType.XUELIU or self.playType == ReplayLayer.PlayType.DEYANG or self.playType == ReplayLayer.PlayType.SRSF 
		or self.playType == ReplayLayer.PlayType.MIANYANG or self.playType == ReplayLayer.PlayType.YIBIN or self.playType == ReplayLayer.PlayType.WANZHOU or self.playType == ReplayLayer.PlayType.LUZHOU 
		or self.playType == ReplayLayer.PlayType.LESHAN  or self.playType == ReplayLayer.PlayType.ZIGONG   or self.playType == ReplayLayer.PlayType.NANCHONG
		or self.playType == ReplayLayer.PlayType.GUANGAN or self.playType == ReplayLayer.PlayType.YAAN or self.playType == ReplayLayer.PlayType.ZIGONGSR
        or self.playType == ReplayLayer.PlayType.NEIJIANG3 or self.playType == ReplayLayer.PlayType.NEIJIANG4 or self.playType == ReplayLayer.PlayType.ERREN then
	 	if curStep < 5 then
	 		self.remainTilesLabel:setString(tostring(self.remainCard))
	 	end

	elseif self.playType == ReplayLayer.PlayType.NEIJIANG then
		 if curStep < 2 then
	 		self.remainTilesLabel:setString(tostring(self.remainCard))
	 	end
	end

	if self.replayData.m_state == ReplayLayer.PlayType.XUEZHAN or self.replayData.m_state == ReplayLayer.PlayType.XUELIU or self.replayData.m_state == ReplayLayer.PlayType.MIANYANG 
		or self.replayData.m_state == ReplayLayer.PlayType.YIBIN or self.replayData.m_state == ReplayLayer.PlayType.WANZHOU or self.replayData.m_state == ReplayLayer.PlayType.LUZHOU 
		or self.replayData.m_state == ReplayLayer.PlayType.LESHAN or self.replayData.m_state == ReplayLayer.PlayType.NANCHONG or self.replayData.m_state == ReplayLayer.PlayType.GUANGAN
		or self.replayData.m_state == ReplayLayer.PlayType.YAAN or self.replayData.m_state == ReplayLayer.PlayType.ZIGONGSR
        or self.replayData.m_state == ReplayLayer.PlayType.NEIJIANG3 or self.replayData.m_state == ReplayLayer.PlayType.NEIJIANG4 or self.replayData.m_state == ReplayLayer.PlayType.ERREN then
		if wihldReplayStep < 5 then
			wihldReplayStep = 0
		end

		-- 清理桌面上的牌
		self.playManager:cleanMjFormLayer()

		if wihldReplayStep < 5 then
			self:initRoomPlayersData(self.replayData)
		else
			self:initRoomPlayersData(self.replayData, true)
		end

	elseif self.replayData.m_state == ReplayLayer.PlayType.DEYANG or self.replayData.m_state == ReplayLayer.PlayType.NEIJIANG  or self.replayData.m_state == ReplayLayer.PlayType.SANREN or self.replayData.m_state == ReplayLayer.PlayType.DDH or self.replayData.m_state == ReplayLayer.PlayType.SRSF or self.replayData.m_state == ReplayLayer.PlayType.ZIGONG then
		if wihldReplayStep < 0 then
			wihldReplayStep = 0
		end
		-- 清理桌面上的牌
		self.playManager:cleanMjFormLayer()

		self:initRoomPlayersData(self.replayData, true)
	end

	-- 步数设置为1
	self.curReplayStep = 1

	gt.log("wihldReplayStep ="..wihldReplayStep)
	for i=1,wihldReplayStep do
		if not self.isReplayFinish then
			self:doAction( self.curReplayStep, true)
		end
	end

	
end

-- 快速回合播放
function ReplayLayer:nextRound()
	-- -- 如果暂停或者已经结束,是否需要回退
	-- if self.isPause or self.isReplayFinish then
	-- 	return
	-- end
	self.quickStartTime = os.time()

	for i=1,self.quickStepNum do
		if not self.isReplayFinish then
			self:doAction( self.curReplayStep, true)
		end
	end
end

function ReplayLayer:doAction( curReplayStep, isQuick)
	self.preBtn:setTouchEnabled(true)
	self.nextBtn:setTouchEnabled(true)
	local replayStepData = self.replayStepsData[curReplayStep]

	-- 快进快退时不展示杠之后的牌
	if not isQuick then
		-- 如果展示杠后的两张牌则需要3秒
		if replayStepData[2] == 18 then
			self.showDelayTime = -2
		end
	end

	local seatIdx = replayStepData[1] + 1
	local optType = replayStepData[2]
	local mjColor = nil
	if replayStepData[3] and replayStepData[3][1] and replayStepData[3][1][1] then 
		mjColor = replayStepData[3][1][1]
	end
	local mjNumber = nil
	if replayStepData[3] and replayStepData[3][1] and replayStepData[3][1][2] then 
		mjNumber = replayStepData[3][1][2]
	end
	
	local remainCard = replayStepData[4]

	gt.log("optType = "..optType)
	self.playManager:setTurnSeatSign(seatIdx)
	if optType == 1 then
		-- 摸牌
		self.playManager:drawMjTile(seatIdx, mjColor, mjNumber)
		if remainCard > 0 then
			self.remainTilesLabel:setString(tostring(self.remainCard - tonumber(remainCard)))
		end
	elseif optType == 2 then
		-- 出牌
		if not isQuick then
			self.playManager:playOutMjTile(seatIdx, mjColor, mjNumber)
		else
			self.playManager:playOutMjTileQuick(seatIdx, mjColor, mjNumber)
		end
	elseif optType == 3 then
		
		-- 暗杠
		self.playManager:addMjTileBar(seatIdx, replayStepData[3], false)

		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.DARK_BAR)
		end
	elseif optType == 4 then
		
		-- 自摸明杠
		self.playManager:changePungToBrightBar(seatIdx, mjColor, mjNumber, replayStepData[3])

		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.BRIGHT_BAR)
		end
	elseif optType == 5 then
		-- 碰
		self.playManager:addMjTilePung(seatIdx, replayStepData[3])

		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.PUNG)
		end

		self.playManager:removePrePlayerOutMjTile(mjColor,mjNumber)
	elseif optType == 6 then
		-- 别人打的牌,自己可以明杠之
		self.playManager:addMjTileBar(seatIdx, replayStepData[3], true)

		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.BRIGHT_BAR)
		end

		self.playManager:removePrePlayerOutMjTile(mjColor,mjNumber)
	elseif optType == 7 then
		gt.log("dfadsfa==fd=s=g===g====")
		self.playManager:showPalyerWinCard(seatIdx,mjColor,mjNumber,true,isQuick, false)
		
		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.TAKE_CANNON_WIN)
		end
	elseif optType == 8 then
		-- 自摸胡
		gt.log("===f=f=sssssss==tttttttttttlllll=s88")
		self.playManager:showPalyerWinCard(seatIdx,mjColor,mjNumber,false, isQuick, false)
		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.SELF_DRAWN_WIN)
		end
	elseif optType == 9 then
		-- 流局
	elseif optType == 10 then
		--吃
		local eatGroup = {}
		table.insert(eatGroup,{replayStepData[3][1][2], 0, replayStepData[3][1][1]})
		table.insert(eatGroup,{replayStepData[3][2][2], 0, replayStepData[3][1][1]})
		table.insert(eatGroup,{replayStepData[3][3][2], 1, replayStepData[3][1][1]})

		self.playManager:pungBarReorderMjTiles(seatIdx, replayStepData[3][1][1], eatGroup)

		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.EAT)
		end

		-- self.playManager:removePrePlayerOutMjTile()
	elseif optType == 11 then
		-- 明补自己
		self.playManager:changePungToBrightBar(seatIdx, mjColor, mjNumber, replayStepData[3])
		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.BRIGHT_BU)
		end
	elseif optType == 12 then
		-- 明补他人
		self.playManager:addMjTileBar(seatIdx, replayStepData[3], true)
		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.BRIGHT_BU)
		end
		-- self.playManager:removePrePlayerOutMjTile()
	elseif optType == 13 then
		-- 暗补
		self.playManager:addMjTileBar(seatIdx, replayStepData[3], false)

		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.DARK_BU)
		end
	elseif optType == 14 then
		-- 飞
		gt.log("--飞")
		dump(replayStepData[3])
		local feiGroup = {}
		table.insert(feiGroup,{replayStepData[3][1][1], replayStepData[3][1][2]})
		table.insert(feiGroup,{replayStepData[3][2][1], replayStepData[3][2][2]})
		table.insert(feiGroup,{replayStepData[3][3][1], replayStepData[3][3][2]})
		self.playManager:addMjFei(seatIdx,feiGroup)
		self.playManager:showMakeDecision(seatIdx,userChooseDecisionType,true)
	elseif optType == 15 then
		-- 提
		gt.log("--提")
		dump(replayStepData[3])
		if self.playType == ReplayLayer.PlayType.LESHAN then
			self.playManager:changeTiao(seatIdx,replayStepData[3])
			self.playManager:showMakeDecision(seatIdx,userChooseDecisionType,true)
		else
			local feiGroup = {}
			table.insert(feiGroup,{replayStepData[3][1][1], replayStepData[3][1][2]})
			table.insert(feiGroup,{replayStepData[3][2][1], replayStepData[3][2][2]})
			table.insert(feiGroup,{replayStepData[3][3][1], replayStepData[3][3][2]})
			self.playManager:changeFeiToTi(seatIdx,feiGroup)
			self.playManager:showMakeDecision(seatIdx,userChooseDecisionType,true)
		end
	elseif optType == 16 then
		-- 四喜小胡
		self.playManager:showStartDecisionAnimation(seatIdx, optType-13, replayStepData[3])
	elseif optType == 17 then
		-- 六六顺小胡
		self.playManager:showStartDecisionAnimation(seatIdx, optType-13, replayStepData[3])
	elseif optType == 18 then
		-- 显示杠后两张牌
		self.playManager:showBarTwoCardAnimation(seatIdx,replayStepData[3],isQuick)
	elseif optType == 21 then
		-- 玩家思考
		local thinkList = replayStepData[3]
		gt.log("玩家思考")
		gt.dump(replayStepData)
		gt.dump(thinkList)
		if thinkList then
			local thinktype = {}
			local isShowMake = true
			for i,v in ipairs(thinkList) do
				local desType = v[2]
				if desType == 2 then
					-- 胡
					table.insert(thinktype,4)
				elseif desType == 5 then
					-- 碰
					table.insert(thinktype,2)
				elseif desType == 6 then
					-- 吃
					table.insert(thinktype,1)
				elseif desType == 7 or desType == 8 then
					-- 补
					table.insert(thinktype,3)
				elseif desType == 3 or desType == 4 then
					-- 杠
					table.insert(thinktype,3)
				elseif desType == 9 then
					-- 过 海底牌的时候
				-- elseif desType == 11 then--躺牌决策
				-- 	table.insert(thinktype,6)
				elseif desType == 10 then
					-- 飞
					isShowMake = false
				elseif desType == 11 then
					-- 提
					isShowMake = false
				end
			end
			table.insert(thinktype,5)
	
			if isShowMake then
				self.playManager:showMakeDecision(seatIdx,thinktype,isQuick)
			end
		end
	elseif optType == 22 then
		-- 玩家思考结果
		gt.dump(replayStepData)
		local thinkOpt = replayStepData[3][1][2]
		gt.log("玩家思考结果")
		gt.dump(thinkOpt)
		local userChooseDecisionType

		if thinkOpt == 2 then
			-- 胡
			userChooseDecisionType = 4
		elseif thinkOpt == 5 then
			-- 碰
			userChooseDecisionType = 2
		elseif thinkOpt == 6 then
			-- 吃
			userChooseDecisionType = 1
		elseif thinkOpt == 7 or thinkOpt == 8 then
			-- 补
			userChooseDecisionType = 3
		elseif thinkOpt == 3 or thinkOpt == 4 then
			-- 杠
			userChooseDecisionType = 3
		elseif thinkOpt == 9 then
			-- 过 还底牌的时候
			userChooseDecisionType = 5
		elseif thinkOpt == 20 then
			-- 补张 （中 发 赖子）
			userChooseDecisionType = 3
		elseif thinkOpt == 21 then
			-- 过  不要不要啦(中 发 赖子）
			userChooseDecisionType = 5
		-- elseif thinkOpt == 11 then--躺
		-- 	userChooseDecisionType = 6
		elseif thinkOpt == 10 then
			-- 飞
			userChooseDecisionType = 10
		elseif thinkOpt == 11 then
			-- 提
			userChooseDecisionType = 11
		else
			-- 都认为是点了过
			userChooseDecisionType = 5
		end
		if userChooseDecisionType < 9 then
			--todo
			self.playManager:decisionResult(seatIdx,userChooseDecisionType,isQuick)
		else
			self.playManager:showMakeDecision(seatIdx,userChooseDecisionType,true)
		end
		
	elseif optType == 53 then -- 海底提示
		self.playManager:showHaidiDecision(seatIdx,isQuick)
	elseif optType == 54 then -- 海底要
		self.playManager:decisionHaidiResult(seatIdx,true,isQuick)
	elseif optType == 55 then -- 海底过
		self.playManager:decisionHaidiResult(seatIdx,false,isQuick)
	elseif optType == 56 then -- 海底牌展示
		self.playManager:showHaidiResult( replayStepData[3][1][1], replayStepData[3][1][2], isQuick )
	elseif optType == 57 then -- 定缺
		self.playManager:showDingQueWithSeatIndex(seatIdx,mjColor)
	elseif optType == 58 then -- 换三张
		self.nextBtn:setTouchEnabled(false)
		if  not isQuick then
			self.replaceThreeCard = {{replayStepData[3][1][1],replayStepData[3][1][2]},{replayStepData[3][2][1],replayStepData[3][2][2]},{replayStepData[3][3][1],replayStepData[3][3][2]}}
			self.replaceThreeCard_new = {{replayStepData[3][4][1],replayStepData[3][4][2]},{replayStepData[3][5][1],replayStepData[3][5][2]},{replayStepData[3][6][1],replayStepData[3][6][2]}}
			gt.dump(self["changed_card" .. (seatIdx - 1)])
			self["changed_card" .. (seatIdx - 1)] = self.playManager:replaceThreeCardData(self["changed_card" .. (seatIdx - 1)],self.replaceThreeCard,self.replaceThreeCard_new)
			
			if self.playType == ReplayLayer.PlayType.XUEZHAN then
				self.playManager:replaceThreeCard(seatIdx,self.replaceThreeCard,self.replaceThreeCard_new, isQuick)
			elseif self.playType == ReplayLayer.PlayType.XUELIU then
				self.playManagerXL:replaceThreeCard(seatIdx,self.replaceThreeCard,self.replaceThreeCard_new, isQuick)
			elseif self.playType == ReplayLayer.PlayType.WANZHOU then
				self.playManager:replaceThreeCard(seatIdx,self.replaceThreeCard,self.replaceThreeCard_new, isQuick)
			elseif self.playType == ReplayLayer.PlayType.LUZHOU then
				self.playManager:replaceThreeCard(seatIdx,self.replaceThreeCard,self.replaceThreeCard_new, isQuick)
			elseif self.playType == ReplayLayer.PlayType.LESHAN then
				self.playManager:replaceThreeCard(seatIdx,self.replaceThreeCard,self.replaceThreeCard_new, isQuick)
			elseif self.playType == ReplayLayer.PlayType.ERREN then
				self.playManager:replaceThreeCard(seatIdx,self.replaceThreeCard,self.replaceThreeCard_new, isQuick)
			end
		end

	elseif optType == 60 then -- 抢杠胡
		-- 抢杠胡
		self.playManager:showPalyerWinCard(seatIdx,mjColor,mjNumber,true,isQuick, true)
		self.playManager:onRecUserRemoveBarCard(seatIdx,mjColor,mjNumber)
		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.TAKE_CANNON_WIN)
		end
	elseif optType == 61 then --解散房间
		gt.log("==optType=====61====")
		self.playManager:dismissRoom()
	elseif optType == 62 then
		-- 接炮胡 seatIdx:座位 mjColor颜色,mjNumber数值,true胡牌类型,isQuick是否快播, true是否抢杠, true:是否杠上花
		self.playManager:showPalyerWinCard(seatIdx,mjColor,mjNumber,false, isQuick, false, true)
		if not isQuick then
			self.playManager:showDecisionAnimation(seatIdx, gt.DecisionType.TAKE_CANNON_WIN)
		end
	elseif optType == 64 then
		gt.log("fbbb-------")
		self.playManager:addMjTileLang(seatIdx, replayStepData[3])
		self.playManager:playOutMjTile(seatIdx, replayStepData[3][1][1], replayStepData[3][1][2])
		self.playManager:removePrePlayerLangMjTile(seatIdx, replayStepData[3])
	elseif optType == 66 then
		--定飘
		gt.log("--定飘")
		dump(replayStepData[3])
		local feiGroup = {}
		table.insert(feiGroup,{replayStepData[3][1][1]})
		table.insert(feiGroup,{replayStepData[3][2][1]})
		table.insert(feiGroup,{replayStepData[3][3][1]})
        if replayStepData[3][4] then -- 有第四人的数据
            table.insert(feiGroup,{replayStepData[3][4][1]})
        end
		if self.playType == ReplayLayer.PlayType.NANCHONG then
			self.playManager:showPiaoNumImage(feiGroup)
		else
			self.playManager:showPiaoImage(feiGroup)
		end

	elseif optType == 67 then
		--翻金
		gt.log("------------更新翻屁股--------------")
		local FpgTab = {}
		FpgTab[1] = {}
		if replayStepData[3] and replayStepData[3][1] and replayStepData[3][1][1] then 
			FpgTab[1][1] = replayStepData[3][1][1]
		else
			FpgTab[1][1] = 0
		end
		if replayStepData[3] and replayStepData[3][1] and replayStepData[3][1][2] then 
			FpgTab[1][2] = replayStepData[3][1][2]
		else
			FpgTab[1][2] = 0
		end
		FpgTab[3] = {}
		if replayStepData[3] and replayStepData[3][2] and replayStepData[3][2][1] then 
			FpgTab[3][1] = replayStepData[3][2][1]
		else
			FpgTab[3][1] = 0
		end
		if replayStepData[3] and replayStepData[3][2] and replayStepData[3][2][2] then 
			FpgTab[3][2] = replayStepData[3][2][2]
		else
			FpgTab[3][2] = 0
		end

		FpgTab[2] = {}
		if replayStepData[3] and replayStepData[3][3] and replayStepData[3][3][1] then 
			FpgTab[2][1] = replayStepData[3][3][1]
		else
			FpgTab[2][1] = 0
		end
		if replayStepData[3] and replayStepData[3][3] and replayStepData[3][3][2] then 
			FpgTab[2][2] = replayStepData[3][3][2]
		else
			FpgTab[2][2] = 0
		end
		dump(replayStepData[3])
		dump(FpgTab)
		self.playManager:addFanFanJinCard(FpgTab)
	elseif optType == 101 then --报叫
		gt.log("=======ff===s===" .. seatIdx)
		self.playManager:setBaoJiaoTile(seatIdx, mjColor, mjNumber)
	elseif optType == 102 then -- 豹子
		self.playManager:setBaoZi(mjColor, mjNumber)
	end

	self.curReplayStep = self.curReplayStep + 1
	if self.curReplayStep > #self.replayStepsData then
		self.isReplayFinish = true
	end
end

function ReplayLayer:update(delta)
	if self.isPause or self.isReplayFinish then
		return
	end

	if os.time() - self.quickStartTime < 2 then -- 如果已经有2s没有触摸快进/快退按钮了,那么可以播放自动录像了
		return
	end

	self.holdTime = self.holdTime + delta
	self:updateCurrentTime()

	self.showDelayTime = self.showDelayTime + delta
	if self.showDelayTime > 1.5 then
		self.showDelayTime = 0

		self:doAction(self.curReplayStep)
	end
end

function ReplayLayer:initRoomPlayersData(replayData, isChangeData)
	for seatIdx, uid in ipairs(replayData.m_userid) do
		local roomPlayer = {}
		roomPlayer.seatIdx = seatIdx
		roomPlayer.uid = uid
		roomPlayer.nickname = replayData.m_nike[seatIdx]
		roomPlayer.headURL = replayData.m_imageUrl[seatIdx]
		roomPlayer.sex = replayData.m_sex[seatIdx]
		roomPlayer.score = replayData.m_score[seatIdx]

		self.playManager:roomAddPlayer(roomPlayer)
		gt.log("添加手牌")
		-- 添加持有牌
		--血战和血流
		if replayData.m_state == ReplayLayer.PlayType.XUEZHAN or replayData.m_state == ReplayLayer.PlayType.XUELIU or replayData.m_state == ReplayLayer.PlayType.MIANYANG 
			or replayData.m_state == ReplayLayer.PlayType.YIBIN or replayData.m_state == ReplayLayer.PlayType.WANZHOU or replayData.m_state == ReplayLayer.PlayType.LUZHOU 
			or replayData.m_state == ReplayLayer.PlayType.LESHAN or replayData.m_state == ReplayLayer.PlayType.NANCHONG or replayData.m_state == ReplayLayer.PlayType.GUANGAN 
			or replayData.m_state == ReplayLayer.PlayType.YAAN or replayData.m_state == ReplayLayer.PlayType.ZIGONGSR
            or replayData.m_state == ReplayLayer.PlayType.NEIJIANG4 or replayData.m_state == ReplayLayer.PlayType.ERREN then

			if isChangeData then
				dump(self["changed_card" .. (seatIdx - 1)])
				for _, v in ipairs(self["changed_card" .. (seatIdx - 1)]) do
					self.playManager:addMjTile(roomPlayer, v[1], v[2])
				end
			else
				for _, v in ipairs(replayData["m_card" .. (seatIdx - 1)]) do
					self:set_m_card(replayData["m_card" .. (seatIdx - 1)], (seatIdx - 1))
					self.playManager:addMjTile(roomPlayer, v[1], v[2])
				end
			end
		--三人
		elseif replayData.m_state == ReplayLayer.PlayType.DEYANG or replayData.m_state == ReplayLayer.PlayType.SANREN or replayData.m_state == ReplayLayer.PlayType.DDH or replayData.m_state == ReplayLayer.PlayType.NEIJIANG or replayData.m_state == ReplayLayer.PlayType.SRSF or replayData.m_state == ReplayLayer.PlayType.ZIGONG
        or replayData.m_state == ReplayLayer.PlayType.NEIJIANG3 then
			for _, v in ipairs(replayData["m_card" .. (seatIdx - 1)]) do
				
				self.playManager:addMjTile(roomPlayer, v[1], v[2])
			end
		end
		self.playManager:sortHoldMjTiles(roomPlayer)
	end

	self.curReplayStep = 1
	self.showDelayTime = 2
	self.isReplayFinish = false
end

function ReplayLayer:set_m_card(m_card,curseatIdx) 
	self["changed_card" .. curseatIdx] = {}
	for i = 1, #m_card do
		self["changed_card" .. curseatIdx][i] = {}
		self["changed_card" .. curseatIdx][i][1] = m_card[i][1]
		self["changed_card" .. curseatIdx][i][2] = m_card[i][2]
	end
	dump(self["changed_card" .. curseatIdx])
end

function ReplayLayer:setPause(isPause)
	self.isPause = isPause

	self.pauseBtn:setVisible(not isPause)
	self.playBtn:setVisible(isPause)
end

function ReplayLayer:updateCurrentTime()
	local presentTime = math.ceil(self.time_now+self.holdTime)

	local curTimeStr = os.date("%X", presentTime)
	local timeSections = string.split(curTimeStr, ":")
	local timeLabel = gt.seekNodeByName(self, "Label_time")

	-- 时:分
	timeLabel:setString(string.format("%s:%s", timeSections[1], timeSections[2]))
end

return ReplayLayer

