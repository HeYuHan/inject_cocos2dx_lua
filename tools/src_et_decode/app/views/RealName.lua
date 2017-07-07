
local gt = cc.exports.gt

local RealName = class("RealName", function()
	return gt.createMaskLayer()
end)

function RealName:ctor(callback)

	local Symbol = {"，","《","。","》","／","？","；","：","“","’","｀","～","！","@","＃","¥","％","&","＊","（","）","——","－","＋","＝","、","｜","］","｝","［","｛"}

	local csbNode = cc.CSLoader:createNode("RealName.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	self.Tex_Name = gt.seekNodeByName(csbNode, "Tex_Name")
	self.Tex_CardNum = gt.seekNodeByName(csbNode, "Tex_CardNum")

	-- 关闭按钮
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()
		self:removeFromParent()
	end)

	-- 确定按钮
	local Btn_Sure = gt.seekNodeByName(csbNode, "Btn_Sure")
	gt.addBtnPressedListener(Btn_Sure, function()
		local LabName = self.Tex_Name:getStringValue()
		local LabCardNum = self.Tex_CardNum:getStringValue()

		for i=1,string.len(LabName) do
			if string.byte(LabName,i)<127 then
				require("app/views/NoticeTips"):create("提示", "您输入的名字包含其他字符,请输入正确中文姓名", nil, nil, true)
				return
			end
		end

		for i=1,#Symbol do
			if string.find(LabName,Symbol[i]) then
				require("app/views/NoticeTips"):create("提示", "您输入的名字包含特殊符号,请输入正确姓名", nil, nil, true)
				return
			end
		end

		if string.len(LabName) < 6 then
			require("app/views/NoticeTips"):create("提示", "姓名至少为两个字,请输入姓名", nil, nil, true)
		elseif string.len(LabCardNum) == 0 then
			require("app/views/NoticeTips"):create("提示", "身份证号为空,请输入身份证号", nil, nil, true)
		elseif string.len(LabCardNum) < 18 or string.len(LabCardNum) > 18 then
			require("app/views/NoticeTips"):create("提示", "身份证号码个数错误,请输入正确身份证号", nil, nil, true)
			gt.log("string.len(LabName) = "..string.len(LabCardNum))
		elseif type(tonumber(LabCardNum)) ~= "number" and string.sub(tostring(LabCardNum),-1) ~= "x" then
			require("app/views/NoticeTips"):create("提示", "身份证号码格式错误,请输入正确身份证号", nil, nil, true)
			gt.log("type(LabCardNum) = "..type(LabCardNum))
			gt.log("string.sub(tostring(LabCardNum),-1)"..string.sub(tostring(LabCardNum),-1))
		else
			cc.UserDefault:getInstance():setStringForKey("LabName", tostring(LabName))
			cc.UserDefault:getInstance():setStringForKey("LabCardNum", tostring(LabCardNum))
			cc.UserDefault:getInstance():setIntegerForKey("IsShowRealName", 1)
			self:removeFromParent()
			callback()
			require("app/views/NoticeTips"):create("提示", "实名认证成功!!!", nil, nil, true)
		end
	end)

end

return RealName



