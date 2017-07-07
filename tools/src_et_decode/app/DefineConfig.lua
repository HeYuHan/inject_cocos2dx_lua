
local gt = cc.exports.gt

-- 公测	--外网连接 {ip = "120.55.90.59", port = "5031"}
-- appstore {ip = "scmj.ixianlai.top", port = "5031"}	

-- 新版测试服		{ip = "121.43.114.235", port = "5001"}		sc.xianlaiyx.com
-- 				{ip = "119.23.152.186", port = "5001"}
-- debug测试服	{ip = "112.124.47.217", port = "5001"}

--书峰	{ip = "192.168.62.20", port = "5001"}
--文峰	{ip = "192.168.62.200", port = "5001"} linux -- {ip = "192.168.10.60", port = "5001"}
--苗磊	{ip = "192.168.20.31", port = "5001"}
--测试服
gt.TestLoginServer	= {ip = "120.55.90.59", port = "5031"}

-- 正式服
gt.LoginServer		= {ip = "120.55.90.59", port = "5031"}

-- 陈超主机
-- gt.TestLoginServer	= {ip = "192.168.62.223", port = "5002"}
-- gt.LoginServer      = {ip = "192.168.62.223", port = "5002"}

-- 陈超虚拟机
-- gt.TestLoginServer	= {ip = "192.168.10.92", port = "5002"}
-- gt.LoginServer      = {ip = "192.168.10.92", port = "5002"}

gt.GateServer		= {}


-- 通用弹出面板
gt.CommonZOrder = {
	LOADING_TIPS				= 66,
	NOTICE_TIPS					= 67,
	TOUCH_MASK					= 68
}

gt.PlayZOrder = {
	MJTABLE						= 1,
	PLAYER_INFO					= 2,
	MJTILES_LAYER				= 6,
	OUTMJTILE_SIGN				= 7,
	DECISION_BTN				= 8,
	DECISION_SHOW				= 9,
	PLAYER_INFO_TIPS			= 10,
	REPORT						= 16,
	DISMISS_ROOM				= 17,
	SETTING						= 18,
	CHAT						= 20,
	MJBAR_ANIMATION				= 21,
	FLIMLAYER           	    = 16,
	HAIDILAOYUE					= 23
}

gt.EventType = {
	NETWORK_ERROR				= 1,
	BACK_MAIN_SCENE				= 2,
	APPLY_DIMISS_ROOM			= 3,
	GM_CHECK_HISTORY			= 4,
	PURCHASE_SUCCESS			= 5,
}

gt.DecisionType = {
	-- 接炮胡
	TAKE_CANNON_WIN				= 1,
	-- 自摸胡
	SELF_DRAWN_WIN				= 2,
	-- 明杠
	BRIGHT_BAR					= 3,
	-- 暗杠
	DARK_BAR					= 4,
	-- 碰
	PUNG						= 5,
	-- 吃
	EAT					        = 6,
	--眀补
	BRIGHT_BU                   = 7,
	--暗补
	DARK_BU                     = 8,
	--飞
	FEI 						= 10,
	--提
	TI 							= 11,
	--挑
	TIAO						= 12,
}

gt.StartDecisionType = {
	-- 缺一色
	TYPE_QUEYISE				= 1,
	-- 板板胡
	TYPE_BANBANHU				= 2,
	-- 四喜
	TYPE_DASIXI					= 3,
	-- 六六顺
	TYPE_LIULIUSHUN				= 4
}

gt.ChatType = {
	FIX_MSG						= 1,
	INPUT_MSG					= 2,
	EMOJI						= 3,
	VOICE_MSG					= 4,
}

gt.RoomType = {
	ROOM_ZHUANZHUAN				= 0,   --转转麻将
	ROOM_SICHUAN				= 3	   --四川麻将
}



