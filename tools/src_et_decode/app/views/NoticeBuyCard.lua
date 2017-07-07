
local gt = cc.exports.gt

local NoticeBuyCard = class("NoticeBuyCard", function()
	return gt.createMaskLayer()
end)

function NoticeBuyCard:ctor(tipsText)
	local csbNode = cc.CSLoader:createNode("NoticeBuyCard.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	local showStrLabel1 = gt.seekNodeByName(csbNode, "Text_1")
	local showStrLabel2 = gt.seekNodeByName(csbNode, "Text_2")
	local showStrLabel3 = gt.seekNodeByName(csbNode, "Text_3")
	local Text_label1 = gt.seekNodeByName(csbNode, "Text_label1")
	Text_label1:setString("游戏代理咨询")
	local Text_label2 = gt.seekNodeByName(csbNode, "Text_label2")
	Text_label2:setString("游戏代理咨询")
	local Text_label3 = gt.seekNodeByName(csbNode, "Text_label3")
	Text_label3:setString("游戏问题与建议")
	
	if tipsText then
		local strTab = string.split(tipsText, ",")
		gt.dump(strTab)

		if strTab[2] then
			showStrLabel1:setString(strTab[2])
		else
			showStrLabel1:setString("")
		end

		local TabNum = tonumber(gt.playerData.uid)% #gt.NameTab + 1
		if TabNum then
			if TabNum>0 and TabNum<=#gt.NameTab then
				showStrLabel2:setString(gt.NameTab[TabNum])
			else
				showStrLabel2:setString("xmscmj666【公众号】")
			end
		else
			showStrLabel2:setString("xmscmj666【公众号】")
		end

		-- showStrLabel2:setString("xmscmj666【公众号】")
		
		if strTab[3] then
			showStrLabel3:setString(strTab[3])
		else
			showStrLabel3:setString("xmscmj666【公众号】")
		end
	end
	local tipsText1 = showStrLabel1:getString()
	if string.len(tipsText1)>0 then
		tipsText1 = string.sub(tipsText1,1,string.find(tipsText1,"【")-1)
	end
	local tipsText2 = showStrLabel2:getString()
	if string.len(tipsText2)>0 then
		tipsText2 = string.sub(tipsText2,1,string.find(tipsText2,"【")-1)
	end
	local tipsText3 = showStrLabel3:getString()
	if string.len(tipsText3)>0 then
		tipsText3 = string.sub(tipsText3,1,string.find(tipsText3,"【")-1)
	end
	
	local Button_1 = gt.seekNodeByName(csbNode, "Button_1")
	local Button_2 = gt.seekNodeByName(csbNode, "Button_2")
	local Button_3 = gt.seekNodeByName(csbNode, "Button_3")
	if gt.isUseNewMusic() then
		Button_1:setVisible(true)
		Button_2:setVisible(true)
		Button_3:setVisible(true)
	else
		Button_1:setVisible(false)
		Button_2:setVisible(false)
		Button_3:setVisible(false)
	end
	gt.addBtnPressedListener(Button_1, function()
		gt.CopyText(tipsText1)
	end)
	gt.addBtnPressedListener(Button_2, function()
		gt.CopyText(tipsText2)
	end)
	gt.addBtnPressedListener(Button_3, function()
		gt.CopyText(tipsText3)
	end)

	local okBtn = gt.seekNodeByName(csbNode, "Btn_ok")
	gt.addBtnPressedListener(okBtn, function()
		self:removeFromParent()
	end)

	local runningScene = cc.Director:getInstance():getRunningScene()
	if runningScene then
		runningScene:addChild(self, gt.CommonZOrder.NOTICE_TIPS)
	end
end

return NoticeBuyCard

