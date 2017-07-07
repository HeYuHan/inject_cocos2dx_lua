
local gt = cc.exports.gt

local PaiTypeActivity = class("PaiTypeActivity", function()
	return gt.createMaskLayer()
end)

function PaiTypeActivity:ctor(msgTbl, playerSeatIdx, roomPlayers)
	gt.log("999------")
	gt.dump(msgTbl)
	local csbNode = cc.CSLoader:createNode("FangKaYuJieSuan.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
	end

	local referScale = 1
	local width = 10
	local paiType = {{0,"没胡"},{1,"小胡"},{2,"龙七对"},{3,"七小对"},{4,"清一色"},{5,"将将胡"},{6,"对对胡"},
					 {7,"全球人"},{8,"杠上开花"},{9,"杠上炮"},{10,	"海底捞(扫底胡)"},{11,"海底炮"},{12,"抢扛胡"},
					 {13,"起手四个赖子"},{14,"双豪华七小队"},{15,"天胡"},{16,"地胡"},{17,"单钓"},{18,"金钩钓"},
					 {19,"清对"},{20,"清七对"},{21,"清龙七对"},{22,"将对"},{23,"将7对"},{24,"全幺九"},{25,"门清"},
					 {26,"中张"},{7,"卡2条"},{28,"夹心5"},{29,"一条龙"},{30,"姊妹对"},{31,"超超豪华七小队"},
					 {101,"烂牌"},{102,"七心"},{103,"幺牌"},{104,"夹心五"},{105,"混一色"},{106,"大三元"},
					 {107,"小三元"},{108,"十风"},{109,"十三幺"},{110,"龙抓背"},{111,"四幺鸡"},{112,"杠上五梅花"},
					 {113,"无鸡"},{114,"小鸡归位"},{115,"楚雄四五筒"},{116,"单吊五杠上花"},{117,	"夹五筒杠上花"},
					 {118,"大对杠上花"},{119,	"大对单吊五杠上花"},{120,"双杠杠上花"},{121,"夹五筒双杠花"},
					 {122,"大对双杠花"},{123,	"大对单吊五筒双杠花"}
				}
	local m_rewardType = ""

	for seatIdx, roomPlayer in ipairs(roomPlayers) do
		if playerSeatIdx == seatIdx then
			local mjTileReferSpr = gt.seekNodeByName(csbNode, "Spr_mjTileRefer")
			-- 持有麻将信息
			--local mjTileReferSpr = gt.seekNodeByName(playerReportNode, "Spr_mjTileRefer")
			mjTileReferSpr:setVisible(false)
			local referPos = cc.p(mjTileReferSpr:getPosition())
			local mjTileSize = mjTileReferSpr:getContentSize()
			local referSpace = cc.p(mjTileSize.width, 0)

			local m_rewardHu = msgTbl.m_rewardHu[seatIdx]
			for k, v in ipairs(paiType) do
				if tonumber(v[1]) == tonumber(m_rewardHu) then
					m_rewardType = v[2]
				end
			end
			
			-- 暗杠
			for _, darkBar in ipairs(roomPlayer.mjTileDarkBars) do
				for i = 1, 4 do
					local mjTileName = string.format(gt.SelfMJSprFrame, darkBar.mjColor, darkBar.mjNumber)
					if i <= 3 then
						-- 前三张牌显示背面
						mjTileName = "tdbgs_4.png"
					end
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					if i <= 3 then
						mjTileSpr:setScale(1.5)
					else
						mjTileSpr:setScale(referScale)
					end
					mjTileSpr:setPosition(referPos)
					self.rootNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				
				referPos.x = referPos.x + width
			end
			-- 明杠
			for _, brightBar in ipairs(roomPlayer.mjTileBrightBars) do
				for i = 1, 4 do
					local mjTileName = string.format(gt.SelfMJSprFrame, brightBar.mjColor, brightBar.mjNumber)
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					self.rootNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end

				referPos.x = referPos.x + width
			end
			-- 明补
			for _, brightBar in ipairs(roomPlayer.mjTileBrightBu) do
				for i = 1, 4 do
					gt.log("===f=ff==f=f====")
					gt.dump(roomPlayer.mjTileBrightBu)
					local mjTileName = string.format(gt.SelfMJSprFrame, brightBar.mjColor, brightBar.mjNumber)
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					self.rootNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + width
			end
			-- 碰
			for _, pung in ipairs(roomPlayer.mjTilePungs) do
				for i = 1, 3 do
					local mjTileName = string.format(gt.SelfMJSprFrame, pung.mjColor, pung.mjNumber)
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					self.rootNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + width
			end

			--狼起
			if roomPlayer.langMjTiles then
				gt.log("=====")
				gt.dump(roomPlayer.langMjTiles)
				for _, lang in ipairs(roomPlayer.langMjTiles) do
					local mjTileName = string.format(gt.SelfMJSprFrame, lang[1], lang[2])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setColor(cc.c3b(255,255,100))
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					self.rootNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
			end
		
			--吃牌
			for _, eat in ipairs(roomPlayer.mjTileEat) do
				for i = 1, 3 do
					local mjTileName = string.format(gt.SelfMJSprFrame, eat[i][3], eat[i][1])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					mjTileSpr:setScale(referScale)
					mjTileSpr:setPosition(referPos)
					self.rootNode:addChild(mjTileSpr)
					referPos = cc.pAdd(referPos, referSpace)
				end
				referPos.x = referPos.x + width
			end

			-- 持有牌
			for _, v in ipairs(msgTbl["array" .. (seatIdx - 1)]) do
				local mjTileName = string.format(gt.SelfMJSprFrame, v[1], v[2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(referScale)
				mjTileSpr:setPosition(referPos)
				self.rootNode:addChild(mjTileSpr)
				referPos = cc.pAdd(referPos, referSpace)
			end	

			local hucardResult = msgTbl["m_hucards" .. seatIdx]
			if next(hucardResult) ~= nil then
				for i = 1, #hucardResult do
					local mjTileName = string.format(gt.SelfMJSprFrame, hucardResult[i][1], hucardResult[i][2])
					local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
					if mjTileSpr then

						mjTileSpr:setScale(referScale)
						if i == 1 then
							mjTileSpr:setPosition(referPos.x + width, referPos.y)
						elseif i == 2 then
							mjTileSpr:setPosition(referPos.x + width * 4, referPos.y)
						end
						self.rootNode:addChild(mjTileSpr)

						mjTileSpr:setColor(cc.c3b(200,200,200))
					end
				end
			end

		end
	end

	-- 关闭按钮
	local backBtn = gt.seekNodeByName(csbNode, "Button_back")
	gt.addBtnPressedListener(backBtn, function()
		self:removeFromParent()
	end)

	-- 解散按钮
	self.button_fenXiang = gt.seekNodeByName(csbNode, "Button_fenXiang")
	gt.addBtnPressedListener(self.button_fenXiang, function()
		local description = "我在熊猫麻将中胡了一把 " .. m_rewardType .. " ， 玩家" .. gt.playerData.nickname .. " ID" .. gt.playerData.uid .. "邀请你加入【熊猫麻将】"
		local title = "游戏邀请"
		local url = gt.shareWeb
		if gt.isIOSPlatform() then
			local luaoc = require("cocos/cocos2d/luaoc")
			local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
				{url = gt.shareWeb, title = "熊猫麻将", description = description})
		elseif gt.isAndroidPlatform() then
			local luaj = require("cocos/cocos2d/luaj")
			local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
				{gt.shareWeb, "熊猫麻将", description},
				"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
		end
		-- local shareSelect = require("app/views/ShareSelect"):create(description, title, url)
		-- local runningScene = cc.Director:getInstance():getRunningScene()
		-- runningScene:addChild(shareSelect, 68)
		
	end)
end

return PaiTypeActivity



