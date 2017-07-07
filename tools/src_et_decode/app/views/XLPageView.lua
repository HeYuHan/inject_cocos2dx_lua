-- create by shz 
-- 缺陷：
-- 1. 层级要相对较低，因为此控件吞噬了触摸事件
-- api 
	-- local pageView = require("app/views/XLPageView"):create(cc.size(964,465))
	-- pageView:setTouchEnabled(true) 
	-- pageView:setPointOnAndOffTexture( "page_now.png" , "page_grey.png" , true) --设置点文理
	
	-- pageView:setPVInnerContainerSize(cc.size(964*5,465)) --设置Container size 
	-- pageView:setPVDirection(ccui.ScrollViewDir.horizontal ) --设置方向
	-- pageView:setPosition(cc.p(21.5 + 964/2,96 + 465/2) ) --设置位置
	-- pageView:setBetweenPagePointsDis( 40 )--设置点 间距
	-- pageView:setPointNodePos(cc.p(0,15)) -- 设置点高度
	-- -- pageView:setPointScale(1) --设置点大小
	-- pageView:show(self.root,3)
	-- local contentSize = pageView:getPVContentSize()
	-- local pagesNum = 5
	-- for i=1,pagesNum do
 --       	local sp = cc.Sprite:createWithSpriteFrameName("page_".. i ..".png")
 --       	-- sp:setPosition(cc.p(contentSize.width/2,contentSize.height/2))
 --        pageView:addPage(sp)

 --        local maskLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 180), contentSize.width, 30)
	-- 	maskLayer:setPosition(cc.p(0,0))
	-- 	sp:addChild(maskLayer)
 --    end
 --    pageView:openLoopScroll(5)--设置 循环滚动 参数为时间间隔

local XLPageView = class("XLPageView",function (  )
		return cc.Layer:create()
		
end)

function XLPageView:ctor( contentSize , ... )
	--默认 size 200 * 200
	self.pointDistance = 20 -- 默认点和点之间的距离为20像素
	self.pointScale = 1 --默认点的大小
	self.nowPageIndex = 1 --默认第一页显示

	self.XLpageview = ccui.ScrollView:create()
	self.XLpageview:setSwallowTouches(false)
	self:addChild(self.XLpageview) 
	self:registerScriptHandler(handler(self, self.onNodeEvent))
	contentSize = contentSize or cc.size(200,200)
	gt.log("contentSize =========== "..contentSize.width)
	self.XLpageview._contentSize = contentSize
	self.XLpageview:setAnchorPoint(cc.p(0.5,0.5))
	self.XLpageview:setContentSize(contentSize)
	self.XLpageview:setBounceEnabled(false) -- 默认不能回弹
	self:setPVScrollBarWidth(0 ) --设置滚动条宽度为0 不可见状态
	self:initPageIndexPointNode()
end

--返回 显示区域 size
function XLPageView:getPVContentSize()
	return self.XLpageview:getContentSize()
end

function XLPageView:initPageIndexPointNode()
	local pointsNode = cc.Node:create()
	local size = self.XLpageview._contentSize
	pointsNode:setPosition(cc.p(0,-size.height/2))
	self:addChild(pointsNode,2)

	self.pointsNode = pointsNode
end

function XLPageView:onNodeEvent(eventName)
	gt.log("============== onNodeEvent  ")
	if "enter" == eventName then 
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		listener:registerScriptHandler(handler(self, self.onTouchCancelled), cc.Handler.EVENT_TOUCH_CANCELLED)
		
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function XLPageView:onTouchCancelled(touch, event)

end

function XLPageView:onTouchBegan(touch, event)
	if self.openLoop then
		self:stopLoopScroll()
	end
	self.beginTouchX = touch:getLocation().x
	return true
end

function XLPageView:setScrollSensitive( sensitive )
	self.scrollSensitive = sensitive or 50
end

function XLPageView:setUserTouchLoop( status )
	self.isUserTouchLoop = status
end

function XLPageView:onTouchEnded(touch, event)
	if self.openLoop then
		self:scrollLoopOnDuration( )
	end
	
	local endTouchX = touch:getLocation().x
	local pageDis = self.scrollSensitive or 50 -- 滑动灵敏度
	local judgeNum = self:getPageCount()
	if endTouchX - self.beginTouchX > pageDis then
		if not self.isUserTouchLoop then
			if self.nowPageIndex > 1 then
				self:scrollFuncToLeft()
			end
		else
			self:scrollFuncToLeft()
		end
	elseif endTouchX - self.beginTouchX < -pageDis then
		if not self.isUserTouchLoop then
			if self.nowPageIndex < judgeNum then
				self:scrollFuncToRight()
			end
		else
			self:scrollFuncToRight()
		end
	else
		self:adjustPages()
	end
end

function XLPageView:scrollFuncToLeft()
	local judgeNum = self:getPageCount()
	local toPageNum = self.nowPageIndex  -- 3
	local duration = 0.3
	if toPageNum <= 1 then
		toPageNum = judgeNum + 1
		duration = (judgeNum - 1)*duration
	end
	self.nowPageIndex = toPageNum - 1
	self.XLpageview:scrollToPercentHorizontal(100/(judgeNum-1)*(toPageNum - 2),duration,false)
	self:updateAllPointTexture()
end

function XLPageView:scrollFuncToRight( ... )
	-- body
	local judgeNum = self:getPageCount()
	local toPageNum = self.nowPageIndex 
	local duration = 0.3
	if toPageNum > judgeNum - 1 then
		toPageNum = 0
		duration = (judgeNum - 1)*duration
	end
	self.nowPageIndex = toPageNum + 1
	self.XLpageview:scrollToPercentHorizontal(100/(judgeNum-1)*toPageNum,duration,false)
	self:updateAllPointTexture()
end

function XLPageView:adjustPages( ... )
	local containerSize = self.XLpageview:getInnerContainerSize()
	local pos 			= self.XLpageview:getInnerContainerPosition() 
	if pos.x < 0 and pos.x > -containerSize.width then
		local distance = -pos.x
		local viewcontentsize =  self.XLpageview:getContentSize()
		local judgeNum = self:getPageCount()
		local toPageNum = 0
		gt.log("========================= pos.x"..pos.x)
		for i=judgeNum-1,0,-1 do
			if distance > (viewcontentsize.width/2 + (i - 1)*viewcontentsize.width ) then --or (distance < viewcontentsize.width/2) then
				toPageNum = i
				break
			end
		end
		self.nowPageIndex = toPageNum + 1
		self:updateAllPointTexture()
		self.XLpageview:scrollToPercentHorizontal(100/(judgeNum-1)*toPageNum,0.2,false)
	end
end

function  XLPageView:getPageCount( )
	self.pageVector = self.pageVector or {}
	return #self.pageVector
end

function XLPageView:show( parent , zOrder , ... )
	local function __handler( sender , eventType )
		if SCROLLVIEW_EVENT_SCROLLING == eventType and self.isTouchBegan then

		end
	end
	-- se;f:registerScriptHandler(scrollView2DidScroll, CCScrollView.kScrollViewScroll)
	self.XLpageview:addEventListener(__handler)
	parent = parent or cc.Director:getInstance():getRunningScene()
	zOrder = zOrder or 60
	parent:addChild(self,zOrder)
end

function XLPageView:hide( action , ... )
	if not action then
		self:removeFromParent( true )
	else
		--接口，根据需求修改
		self:removeFromParent( true )
	end
end

function XLPageView:setPVTouchEnabled( enable )
	self.XLpageview:setTouchEnabled( enable )
end

function XLPageView:setPVDirection( direction )
	direction = direction or ccui.ScrollViewDir.vertical --horizontal 为横向
	self.XLpageview :setDirection(direction)
end

function XLPageView:setPVScrollBarWidth( width )
	width = width or 30
	self.XLpageview:setScrollBarWidth(width)
end

function XLPageView:setPVScrollBarColor( color )
	color = color or cc.RED
	self.XLpageview:setScrollBarColor(color)
end

function XLPageView:setPVScrollBarPositionFromCorner( pos ) 
	pos = pos or cc.p(2,2) 
	self.XLpageview:setScrollBarPositionFromCorner(pos) 
end

function XLPageView:setPVInnerContainerSize( size )
	size = size or self.XLpageview._contentSize
	self.XLpageview:setInnerContainerSize(size)
end



function XLPageView:addPage( page ) 
	if not page then
		return 
	end

	-- self._contentSize
	self.pageVector = self.pageVector or {}
	self.pointVector  = self.pointVector or {}
	local pageNum = #self.pageVector 
	local pointNum = #self.pointVector
	local direction = self.XLpageview:getDirection()
	local container = self.XLpageview:getInnerContainer()
	local containerSize = self.XLpageview:getInnerContainerSize()
	
	if direction == ccui.ScrollViewDir.vertical then --纵向
		page:setPosition(cc.p(0,containerSize.height - self.XLpageview._contentSize.height*(pageNum + 1)))
		container:addChild( page )
		

	elseif direction == ccui.ScrollViewDir.horizontal then --横向
		page:setAnchorPoint(cc.p(0,0))
		page:setPosition(cc.p(self.XLpageview._contentSize.width*pageNum ,0))
		container:addChild( page )
		local picName = self.offPicPath
		if pointNum == 0 then
			picName = self.onPicPath
		end
		local aPointS
		if self.isSpriteFrame then
		 	aPointS = cc.Sprite:createWithSpriteFrameName(picName)
		else
			aPointS = cc.Sprite:create(picName)
		end
		self.pointsNode:addChild(aPointS)
		aPointS:setScale(self.pointScale)
		table.insert( self.pointVector, aPointS )
		self:updateAllPointPos()
	end
	table.insert( self.pageVector, page)
end

function XLPageView:setBetweenPagePointsDis( dis )
	self.pointDistance = dis
	self:updateAllPointPos()
end

function XLPageView:updateAllPointPos()
	if not self.pointVector or #self.pointVector == 0  then
		return 
	end
	local pointCount =  #self.pointVector
	
	local totalDis = (pointCount - 1)*self.pointDistance
	for i=1,pointCount do
		local posX = -totalDis/2 + self.pointDistance * (i - 1)
		self.pointVector[i]:setPositionX(posX)
	end
end

function XLPageView:setPointOnAndOffTexture( onPicPath , offPicPath ,isSpriteFrame )
	self.isSpriteFrame = isSpriteFrame
	self.onPicPath = onPicPath
	self.offPicPath = offPicPath
	-- self:updateAllPointTexture()
end

function XLPageView:updateAllPointTexture()
	-- local pointCount = 
	if not self.pointVector or #self.pointVector == 0 then
		return 
	end
	local pointCount =  #self.pointVector
	for i=1,pointCount do
		if (self.nowPageIndex) == i then
			if self.isSpriteFrame then
				self.pointVector[i]:setSpriteFrame(self.onPicPath)
			else
				self.pointVector[i]:setTexture(self.onPicPath)
			end
		else
			if self.isSpriteFrame then
				self.pointVector[i]:setSpriteFrame(self.offPicPath)
			else
				self.pointVector[i]:setTexture(self.offPicPath)
			end
		end 
	end
end

function XLPageView:setPointScale(sale)
	self.pointScale = sale or self.pointScale
	self:updatePointScale( )
end
function XLPageView:updatePointScale( )
	if not self.pointVector or #self.pointVector == 0 then
		return 
	end
	local pointCount =  #self.pointVector
	for i=1,pointCount do
		self.pointVectorp[i]:setScale(self.pointScale)
	end
end

function XLPageView:setPointNodePos( pos )
	pos = pos or cc.p(0,0)
	local selfPos = cc.p(self.pointsNode:getPosition())
	self.pointsNode:setPosition(cc.pAdd(pos,selfPos))
end

function XLPageView:openLoopScroll( delay )
	self.openLoop = true
	self:scrollLoopOnDuration( delay )
end

function XLPageView:scrollLoopOnDuration( delay )
	self.loopDuration = self.loopDuration or delay or 5
	local callFunc1 = cc.CallFunc:create(function(sender)
		self:scrollFuncToRight()
		-- local judgeNum = self:getPageCount()
		-- local toPageNum = self.nowPageIndex 
		-- local duration = 0.3
		-- if toPageNum > judgeNum - 1 then
		-- 	toPageNum = 0
		-- 	duration = (judgeNum - 1)*duration
		-- end
		-- self.nowPageIndex = toPageNum + 1
		-- self.XLpageview:scrollToPercentHorizontal(100/(judgeNum-1)*toPageNum,duration,false)
		-- self:updateAllPointTexture()
	end)
	local delayTime = cc.DelayTime:create(self.loopDuration)
	local seqAction = cc.Sequence:create(delayTime,callFunc1)
	self:runAction(cc.RepeatForever:create(seqAction))
end

function XLPageView:stopLoopScroll()
	self:stopAllActions()
end

return XLPageView










