local gt = cc.exports.gt

-- gt.isInReview = true

local CreateRoom = class("CreateRoom", function()
	return gt.createMaskLayer()
end)

function CreateRoom:ctor()
  self.data = require("app/views/CreateRoomData")
  -- dump(self.data)

  cc.SpriteFrameCache:getInstance():addSpriteFrames("images/createroom.plist")
	local csbNode = gt.loadCSB("CreateRoom_new.csb", self)
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	if display.autoscale == "FIXED_HEIGHT" then
		csbNode:setScale(0.75)
		self.spr_bg:setScaleY(1280/960)
    -- self.btn_back:setPosition(cc.p( 80, 680 ))
	end
	self:addChild(csbNode)

  -- 保存titile的x坐标待用
  self.titlePosX = self.spr_selectPlay_round:getPositionX()

	if (gt.isInReview) then
    self.nod_inputbox:setVisible(false)
    self.btn_add:setVisible(false)
    self.btn_sub:setVisible(false)
    self.lbl_xy:setVisible(false)
    self.spr_xybg:setVisible(false)
	end

	self.ListView_Type = self.lst_typelist
	self.ListView_Type:setScrollBarEnabled(false)
	self.ListView_Type:setItemsMargin(10)

	gt.addBtnPressedListener(self.btn_Up, function()
		self.ListView_Type:scrollToTop(1,true)
		end)

	gt.addBtnPressedListener(self.btn_Down, function()
		self.ListView_Type:scrollToBottom(1,true)
		end)

	self.GameType  = cc.UserDefault:getInstance():getIntegerForKey( "GameType", 101)

	gt.log("当前选择类型："..self.GameType)

  if (gt.isInReview) then
		self.GameType = 101
		gt.robotNum = 3
    gt.seekNodeByName(csbNode, "Text_1"):setVisible(false)
		self.btn_Down:setVisible(false)
		self.btn_Up:setVisible(false)
		self.lbl_tip:setVisible(false)
  end

	--初始化总游戏类型
	self:initTypeNode()

	-- 焦点在边框框上
	local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
            self.nod_inputbox:setString("")
            self:runAction(cc.MoveBy:create(0.225,cc.p(0, 300)))
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            self:runAction(cc.MoveBy:create(0.175, cc.p(0, -300)))
            local xyNum = self.nod_inputbox:getString()
            xyNum = tonumber( xyNum )
			if xyNum < 0 then
				xyNum = 0
			end
			if xyNum > gt.playerData.m_credit then
				xyNum = gt.playerData.m_credit
			end
			self.nod_inputbox:setString(tostring(xyNum))
        end
    end

	self.nod_inputbox:addEventListener(textFieldEvent)
	self.nod_inputbox:setTouchEnabled(true)
	-------------------创建房间回调，保存各个复选框数据---------------------------------------------------------
  gt.addBtnPressedListener(self.btn_create, function() self:onPressCreateRoom() end)

	-- 接收创建房间消息
	gt.socketClient:registerMsgListener(gt.GC_CREATE_ROOM, self, self.onRcvCreateRoom)
	-- 返回按键
	gt.addBtnPressedListener(self.btn_back, function()
    self:showType(self.GameType)
		-- self:removeFromParent()
		self:setVisible(false)
		self:setZOrder(self:getParent():getZOrder()-1)
		self.GameType  = cc.UserDefault:getInstance():getIntegerForKey( "GameType" )
	   	if self.GameType == 0 or self.GameType == nil then
	   		self.GameType = 101
	   	end
	   	self.ListView_Type:removeAllItems()
  		self:initTypeNode()
      self:showType(self.GameType)
	end)

	gt.addBtnPressedListener(self.btn_sub, function()
    local xyNum = self.nod_inputbox:getString()
		if not xyNum or not tonumber(xyNum) then
			self.nod_inputbox:setString("0")
			require("app/views/zanNoticeTips"):create("提示", "赞数只能输入数值!", nil, nil, true)
			return false
		end
		xyNum = tonumber( xyNum )
		xyNum = xyNum - 1
		if xyNum < 0 then
			xyNum = 0
			require("app/views/zanNoticeTips"):create("提示", "您设置的数量不能小于0。", nil, nil, true)
		end
		self.nod_inputbox:setString(xyNum)
	end)

	gt.addBtnPressedListener(self.btn_add, function()
    local xyNum = self.nod_inputbox:getString()
		if not xyNum or not tonumber(xyNum) then
			self.nod_inputbox:setString("0")
			require("app/views/zanNoticeTips"):create("提示", "赞数只能输入数值!", nil, nil, true)
			return false
		end
		xyNum = tonumber( xyNum )
		xyNum = xyNum + 1
		if xyNum > gt.playerData.m_credit then
			require("app/views/zanNoticeTips"):create("提示", "您设置的数量不能超过自己的获赞数。", nil, nil, true)
			xyNum = gt.playerData.m_credit
		end
		self.nod_inputbox:setString(xyNum)
	end)


  self.typeItems = {}
  self:showType(self.GameType)
end

-- 准备显示右侧面板
function CreateRoom:showType(typeIndex)
  for _, _typeItem in ipairs(self.typeItems) do
    _typeItem:removeFromParent()
  end
  self.typeItems = {}

  local data = self:getTypeData(typeIndex)
  if not data then return end

  local line = 1

  line = line + self:drawLines(data, "round",  line) -- 局数
  line = line + self:drawLines(data, "fang",   line) -- 方数
  line = line + self:drawLines(data, "people", line) -- 人数
  line = line + self:drawLines(data, "card",   line) -- 牌张
  line = line + self:drawLines(data, "top",    line) -- 封顶
  line = line + self:drawLines(data, "count",  line) -- 结算
  line = line + self:drawLines(data, "difen",  line) -- 底分
  line = line + self:drawLines(data, "play",   line) -- 玩法

  self:updateSpliter(data.row)

  self:updateVisibleByDefault()
  self:updateSelectByLocalData()
end

-- 显示某一块，局数，玩法，封顶等
function CreateRoom:drawLines(allData, tag, line)
  local data = allData.data[tag]
  local title = self["spr_selectPlay_" .. tag]
  title:setVisible(data ~= nil)

  if data == nil then
    return 0
  end

  local size = self.pnl_right:getContentSize()

  local lineWidth = (size.width - allData.xoffset) / allData.col -- (全宽-左侧偏移)/列数
  local lineHight = size.height / allData.row-- 行高

  local lineY = size.height - (line-0.5)*lineHight

  title:setPosition(self.titlePosX + (allData.titleoffset or 0), lineY)

  local _maxRow = 1
  for i, d in ipairs(data) do
    local node = self:getItem(d)

    local row    = d.row or 1
    local col    = d.col or i
    local offset = d.offsetnum or 0

     _maxRow = math.max(_maxRow, row)

    local x = allData.xoffset + (col-1)*lineWidth + offset
    local y = size.height - (line + row - 1.5)*lineHight

    node:setPosition(x, y)

    self.pnl_right:addChild(node)
  end

  return _maxRow
end

-- 右侧区域的分割条
function CreateRoom:updateSpliter(row)
  local size = self.pnl_right:getContentSize()

  local lineHight = size.height / row-- 行高

  for i=1, 8 do
    local node = self["spr_div" .. i]

    local y = size.height - i*lineHight
    node:setPositionY(y)
    node:setVisible(i <= row)
  end
end

-- 生成一个右侧的元素
function CreateRoom:getItem(d)
    local _typeMap = {
        ["radio"]    = "CreateRoom_Radio.csb",
        ["checkbox"] = "CreateRoom_Checkbox.csb",
        ["slider"]   = "CreateRoom_Slider.csb"}

  local btn_type_file = _typeMap[d.type]

  local node = gt.loadCSB(btn_type_file)
  table.insert(self.typeItems, node)

  node.typeData = d

  node.lbl_name:setString(d.name)

  if d.type ~= "slider" and d.select then
    self:setItemSelected(node, d.select)
  end

  local function touchItem(sender, eventType)
    if eventType == ccui.CheckBoxEventType.selected then
      self:setItemSelected(sender:getParent(), true)

      local spTypeData = sender:getParent().typeData
      if spTypeData and spTypeData.type == "radio" then

        for _, _el in ipairs(self.typeItems) do
          if _el.typeData.key == spTypeData.key and _el.chk_box ~= sender then
            self:setItemSelected(_el, false)
          end
        end
      end

      if spTypeData and spTypeData.parents then -- 该项目有依赖的父项目
        for _, _el in ipairs(self.typeItems) do
          if spTypeData.parents[_el.typeData.key] then
            self:setItemSelected(_el, true)
          end
        end
      end

      self:showOrHideOtherItems(spTypeData, "willShow", true)  -- 该项目选中后需要显示其他项目
      self:showOrHideOtherItems(spTypeData, "willHide", false) -- 该项目选中需要隐藏其他项目

      self:showOrHideOtherItemsByCount(sender:getParent())
    end

    if eventType == ccui.CheckBoxEventType.unselected then
      self:setItemSelected(sender:getParent(), false)

      local spTypeData = sender:getParent().typeData
      if spTypeData and spTypeData.children then -- 该项目有依赖的父项目
        for _, _el in ipairs(self.typeItems) do
          if spTypeData.children[_el.typeData.key] then
            self:setItemSelected(_el, false)
          end
        end
      end

      self:showOrHideOtherItemsByCount(sender:getParent())
    end
  end

  node.chk_box:addEventListener(touchItem)

  self:initSlider(node, d)

  return node
end

function CreateRoom:initSlider(node, data)
    if data.type ~= "slider" then return end

    local function SliderItem(sender, eventType)
        if eventType == ccui.SliderEventType.percentChanged then
            self:setSliderMeaningValue(node, data, true)
        elseif eventType == ccui.SliderEventType.slideBallUp then
            self:setSliderMeaningValue(node, data, true)
        end
    end

    local function onPressAdd(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            node.value = math.min(data.max, node.value+data.step)
            self:setSliderValue(node, data)
        end
    end

    local function onPressSub(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            node.value = math.max(data.min, node.value-data.step)
            self:setSliderValue(node, data)
        end
    end

    node.nod_proc:addEventListener(SliderItem)
    node.btn_add:addTouchEventListener(onPressAdd)
    node.btn_sub:addTouchEventListener(onPressSub)

    node.value = node.value or data.defaultvalue
    self:setSliderValue(node, data)
end

function CreateRoom:setSliderValue(node, data)
    node.lbl_text:setString(string.format(data.format, node.value))

    local idx = math.floor((node.value-data.min)/data.step)
    local stepWidth = 100/math.ceil((data.max-data.min)/data.step)
    node.nod_proc:setPercent(stepWidth*idx)
end

-- 根据当前选择到的值自动设置成最近的整数值
function CreateRoom:setSliderMeaningValue(node, data, isRestSliderSelf)
    local percent = node.nod_proc:getPercent()

    local lastPercent = 0
    local lastValue = data.min

    local stepWidth = 100/math.ceil((data.max-data.min)/data.step)
    for i=-stepWidth/2, 100+stepWidth/2, stepWidth do
        if percent >= i and percent < i+stepWidth then
            lastPercent = i+stepWidth/2
            break
        end
        lastValue = math.min(lastValue + data.step, data.max)
    end

    node.lbl_text:setString(string.format(data.format, node.value))
    if isRestSliderSelf then
        node.nod_proc:setPercent(lastPercent)
    end
    node.value = lastValue
end

-- 根据本地保存的数据，重设页面选择的元素
function CreateRoom:updateSelectByLocalData()
  local jsonStr = cc.UserDefault:getInstance():getStringForKey("GameTypeSetting" .. self.GameType, "{}")
  local obj = json.decode(jsonStr)

  for _, _el in ipairs(self.typeItems) do
    if obj[_el.typeData.key] then
      self:setItemSelected(_el, obj[_el.typeData.key] == _el.typeData.value)

      -- 处理需要隐藏或者显示的其他条目
      if obj[_el.typeData.key] == _el.typeData.value then
          self:showOrHideOtherItems(_el.typeData, "willShow", true)  -- 该项目选中后需要显示其他项目
          self:showOrHideOtherItems(_el.typeData, "willHide", false) -- 该项目选中需要隐藏其他项目

          self:showOrHideOtherItemsByCount(_el)
      end

      if _el.typeData.type == "slider" then
          _el.value = obj[_el.typeData.key]
          self:setSliderValue(_el, _el.typeData)
      end
    end
  end
end

function CreateRoom:updateVisibleByDefault()
    for _, _el in ipairs(self.typeItems) do
        if _el.chk_box:isSelected() then
            self:showOrHideOtherItems(_el.typeData, "willShow", true)  -- 该项目选中后需要显示其他项目
            self:showOrHideOtherItems(_el.typeData, "willHide", false) -- 该项目选中需要隐藏其他项目
        end

        self:showOrHideOtherItemsByCount(_el)
    end
end

function CreateRoom:showOrHideOtherItems(t, tKey, isVisible)
    if t and t[tKey] then -- 该项目选中需要隐藏其他项目
        for _, _ell in ipairs(self.typeItems) do
            if t[tKey][_ell.typeData.key] then
                _ell:setVisible(isVisible)
            end
        end
    end
end

function CreateRoom:showOrHideOtherItemsByCount(_el)
    local t = _el.typeData
    if not t or not t.willCountShow then return end

    local _targetArray = {}
    local _selectCount = {}
    for _, _ell in ipairs(self.typeItems) do
        if t.willCountShow[_ell.typeData.key] then
            table.insert(_targetArray, _ell)
        end

        if _ell.chk_box:isSelected() and _ell.typeData.willCountShow then
            table.merge(_selectCount, _ell.typeData.willCountShow)
        end
    end

    for _, _target in ipairs(_targetArray) do
        _target:setVisible(_selectCount[_target.typeData.key])
    end
end

-- 设置一个元素是否被选中
-- 注意radio类型的单选框，不会影响其他同祖的单选框
function CreateRoom:setItemSelected(node, isSelected)
  local red = cc.c3b(130, 255, 211)
  local notRed = cc.c3b(255, 213, 156)

  node.chk_box:setSelected(isSelected)
  if isSelected then
    node.lbl_name:setTextColor(red)
  else
    node.lbl_name:setTextColor(notRed)
  end

  if node.typeData.type == "radio" then
    node.chk_box:setTouchEnabled(not isSelected)
  end
end

function CreateRoom:getTypeData(typeIndex)
  for _, data in ipairs(self.data) do
    if data.tag == typeIndex then
      return data
    end
  end

  gt.log("Wrong typeIndex")
  return nil
end

--把玩法类型push进scorllview中
function CreateRoom:initTypeNode()
    local index = 0

    self.ListView_Type.cellVector = {}
    -- self

    local function createCellItemVector( BtnTypeItem , index )
        local size = BtnTypeItem:getContentSize()
        size.height = size.height - 5
        local size_width = size.width * 2 + 20

        local tempNum = (index - 1)%2
        local tempIndex = math.ceil(index/2)
        if tempNum == 0 then
          local cellItem = ccui.Widget:create()
          cellItem:setTouchEnabled(true)
          cellItem:setContentSize(cc.size(size.width,size.height+5))
          BtnTypeItem:setPosition(cc.p(size.width/2+5.5,size.height/2))
          cellItem:addChild(BtnTypeItem)
          self.ListView_Type:pushBackCustomItem(cellItem)
          self.ListView_Type.cellVector[tempIndex] = cellItem
        else
          local cellItem = self.ListView_Type.cellVector[tempIndex]
          BtnTypeItem:setPosition(cc.p(size.width/2*3 + 9,size.height/2))
          cellItem:addChild(BtnTypeItem)
        end
    end

    for i, d in ipairs(self.data) do
        local BtnTypeItem = self:createTypeItem(d)
        local cellItem = createCellItemVector( BtnTypeItem , i )
        -- self.ListView_Type:pushBackCustomItem(BtnTypeItem)

        if self.GameType == d.tag then
            index = i
        end
    end

  if index < #self.data*0.33 then
    self.ListView_Type:jumpToTop()
  elseif index>=#self.data*0.33 and index<#self.data*0.66 then
    self.ListView_Type:jumpToPercentVertical(50)
  elseif index >= #self.data*0.66 then
    self.ListView_Type:jumpToBottom()
  end
end

--创建单个Item
function CreateRoom:createTypeItem(data)
    local Btn_Type = ccui.Button:create()
    Btn_Type:setTouchEnabled(false)
    Btn_Type:setAnchorPoint(0,0)
    Btn_Type:setPosition(cc.p(-8,-8))
    Btn_Type:loadTextures("creatroom1.png", "creatroom2.png", "creatroom2.png",ccui.TextureResType.plistType)
    Btn_Type:setBright(self.GameType ~= data.tag)

    Btn_Type.data = data

    local Spr_Name = data.image

    local Spr_Type = cc.Sprite:createWithSpriteFrameName(Spr_Name)
    Spr_Type:setPosition(cc.p(Btn_Type:getContentSize().width*0.5,Btn_Type:getContentSize().height*0.55))
    Btn_Type:addChild(Spr_Type)

    if gt.FreeGameType then
    	for i=1,#gt.FreeGameType do
    		if data.tag == gt.FreeGameType[i] then
    			local Spr_Free = cc.Sprite:createWithSpriteFrameName("creatroom26.png")
    			Spr_Free:setScale(0.8)
			    Spr_Free:setPosition(cc.p(Btn_Type:getContentSize().width*0.1,Btn_Type:getContentSize().height*0.9))
			    Btn_Type:addChild(Spr_Free)
    		end
    	end
    end

	local cellSize = cc.size(140,64)--Btn_Type:getContentSize()

	local cellItem = ccui.Widget:create()
	cellItem:setTouchEnabled(true)
  -- cellItem:setScale(1.4)
	cellItem:setContentSize(cellSize)
	cellItem:addChild(Btn_Type)

  cellItem.data = data

	cellItem:addClickEventListener(handler(self, self.typeItemClick))

	return cellItem
end

function CreateRoom:typeItemClick(sender, eventType)
	gt.log("进入Item回调")
	local tag = sender.data.tag

  for _, child in ipairs(self.ListView_Type:getChildren()) do
    for key,aWidget in ipairs(child:getChildren()) do
      aWidget:getChildren()[1]:setBright(aWidget.data.tag ~= tag)
    end
    -- child:getChildren()[1]:setBright(child.data.tag ~= tag)
  end
	self.GameType = tag

  self:showType(tag)
end

function CreateRoom:onPressCreateRoom()
  local xyNum = self.nod_inputbox:getString()
	if not xyNum or not tonumber(xyNum) then
    self.nod_inputbox:setString("0")
		require("app/views/zanNoticeTips"):create("提示", "赞数只能输入数值!", nil, nil, true)
    return false
  end
	xyNum = tonumber( xyNum )
	if xyNum < 0 then
    require("app/views/zanNoticeTips"):create("提示", "您设置的数量不能小于0。", nil, nil, true)
		return false
	end
  if xyNum > gt.playerData.m_credit then
    require("app/views/zanNoticeTips"):create("提示", "您设置的数量不能超过自己的获赞数。", nil, nil, true)
    return false
	end

  local localData2Save = {} -- 保存当前选择到UserDefault
  local SCPlayType = {}     -- 发给服务器的数据
  local juShu = 0           -- 选择的局数
  local ren_state = nil     -- 根据人数选择的房间号
  local difen = nil         -- 底分设置

  for _, node in ipairs(self.typeItems) do
    if node.chk_box:isSelected() then
      localData2Save[node.typeData.key] = node.typeData.value

      if node.typeData.key == "ju" then
        juShu = node.typeData.value
      elseif node.typeData.key == "ren_state" then
        gt.log("====bb===")
        ren_state = node.typeData.value
      elseif node:isVisible() then -- 仅向服务器发送显示的节点数据
        table.insert(SCPlayType, node.typeData.value)
      end
    else
      if node.typeData.type == "checkbox" then
        localData2Save[node.typeData.key] = 0
      end
    end

    if node.typeData.type == "slider" then
        if node.typeData.key == "difen" then
            difen = node.value
        end
        localData2Save[node.typeData.key] = node.value
    end
  end

  local localData2SaveJson = json.encode(localData2Save)
  cc.UserDefault:getInstance():setStringForKey("GameTypeSetting" .. self.GameType, localData2SaveJson)
  cc.UserDefault:getInstance():setIntegerForKey("GameType", self.GameType)
  cc.UserDefault:getInstance():flush()

	-- 发送创建房间消息
  local msgToSend = {}
	-- 局数偏移矫正加一与服务器同步
  msgToSend.m_msgId = gt.CG_CREATE_ROOM
  msgToSend.m_flag = juShu --局数
  msgToSend.m_secret = "123456"
  msgToSend.m_baseScore = difen or 1
  msgToSend.m_state = self.GameType
  gt.log("---n--" .. msgToSend.m_state)
  if ren_state then -- 根据人数选择的房间号
    msgToSend.m_state = ren_state
  end


  msgToSend.m_playType = SCPlayType
  msgToSend.m_robotNum = tonumber(gt.robotNum)
  msgToSend.m_cardValue = gt.senTab
--   msgToSend.m_cardValue = {{2,1},{2,1},{2,1},{2,2},{2,2},{2,2},{2,3},{2,3},{2,3},{2,4},{2,4},{2,4},{2,5},
-- {2,5},{2,5},{2,6},{2,6},{2,7},{2,7},{3,1},{3,1},{3,2},{3,2},{3,8},{3,3},{3,4},
-- {3,5},{3,5},{3,5},{3,6},{3,6},{3,6},{2,8},{2,8},{2,8},{2,9},{2,6},{2,9},{3,8},
-- {2,5},{3,4}}
  msgToSend.m_credits = tonumber( xyNum )
	--msgToSend.m_cardValue = {{2,2},{2,3},{2,4},{3,1},{3,2},{3,3},{3,4},{2,1},{3,8},{2,3},{2,4},{2,5},{2,6},{2,7},{2,1},{3,9},{2,3},{2,4},{3,8},{2,6},{2,7},{2,1},{3,9},{2,3},{3,7},{3,8},{2,6},{2,7},{3,4}}

 --msgToSend.m_robotNum = 2

  gt.log("====ff=s====" .. msgToSend.m_state)
  gt.log("玩法："..self.GameType.."局数："..msgToSend.m_flag)
  gt.dump(msgToSend)
  gt.socketClient:sendMessage(msgToSend)

  -- 等待提示
  gt.showLoadingTips(gt.getLocationString("LTKey_0005"))
end

--创建房间消息
function CreateRoom:onRcvCreateRoom(msgTbl)
	gt.dump(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		-- 创建失败
		gt.removeLoadingTips()
		if msgTbl.m_errorCode == 1 then
			-- 房卡不足提示
			gt.log("房卡不足")
			if gt.isIOSPlatform() then
        if gt.checkIAPState() == true then
          local luaBridge = require("cocos/cocos2d/luaoc")
          local ok, ret = luaBridge.callStaticMethod("AppController", "getBundleID")
          if ret == "com.game.xiongmao" or ret == "com.sichuan.majiangxmjh" then
            local agreementPanel = require("app/views/Purchase/RechargeLayer"):create()
            self:addChild(agreementPanel, 66)
          elseif ret == "com.game.sichuan" then
            local agreementPanel = require("app/views/Purchase/RechargeLayer"):create()
            self:addChild(agreementPanel, 66)
          else
            require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
          end
        else
          require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
        end
      elseif gt.isAndroidPlatform() then
        require("app/views/NoticeBuyCard"):create(gt.roomCardBuyInfo)
      end
		elseif msgTbl.m_errorCode == 6 then
			-- 房卡不足提示
			gt.log("信用不足")
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), "点赞数不够", nil, nil, true)
		else
			gt.log("房卡充足")
		end
	end
end

return CreateRoom
