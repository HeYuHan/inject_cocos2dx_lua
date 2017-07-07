
local gt = cc.exports.gt

gt.CG_LOGIN					= 1
gt.GC_LOGIN					= 2
gt.CG_RECONNECT				= 10
gt.CG_LOGIN_SERVER			= 11
gt.GC_LOGIN_SERVER			= 12
gt.GC_ROOM_CARD				= 13
gt.GC_MARQUEE				= 14
gt.CG_HEARTBEAT				= 15
gt.GC_HEARTBEAT				= 16
gt.CG_REQUEST_NOTICE		= 17
gt.GC_REQUEST_NOTICE		= 18
gt.CG_CREATE_ROOM			= 20
gt.GC_CREATE_ROOM			= 21
gt.CG_JOIN_ROOM				= 22
gt.GC_JOIN_ROOM				= 23
gt.CG_QUIT_ROOM				= 24
gt.GC_QUIT_ROOM				= 25
gt.CG_DISMISS_ROOM			= 26
gt.GC_DISMISS_ROOM			= 27
gt.CG_APPLY_DISMISS			= 28
gt.GC_ENTER_ROOM			= 30
gt.GC_ADD_PLAYER			= 31
gt.GC_REMOVE_PLAYER			= 32
gt.GC_SYNC_ROOM_STATE		= 35
gt.CG_READY					= 36
gt.GC_READY					= 37
gt.GC_OFF_LINE_STATE		= 40
gt.GC_ROUND_STATE			= 41
gt.GC_START_GAME			= 50
gt.GC_TURN_SHOW_MJTILE		= 51
gt.CG_SHOW_MJTILE			= 52
gt.GC_SYNC_SHOW_MJTILE		= 53
gt.GC_MAKE_DECISION			= 54
gt.CG_PLAYER_DECISION		= 55
gt.GC_SYNC_MAKE_DECISION	= 56
gt.CG_CHAT_MSG				= 57
gt.GC_CHAT_MSG				= 58
gt.GC_ROUND_REPORT			= 60
gt.GC_START_DECISION		= 65
gt.CG_START_PLAYER_DECISION	= 66
gt.GC_SYNC_START_PLAYER_DECISION= 67
gt.GC_SYNC_BAR_TWOCARD      = 68
gt.CG_SYNC_HAIDI			= 69
gt.CG_CHOOSE_HAIDI			= 70
gt.CG_TURN_HAIDI			= 71
gt.CG_REMOVE_BAR_CARD		= 72
gt.CG_WUHAN_HAIDI			= 75
gt.GC_FINAL_REPORT			= 80
gt.CG_HISTORY_RECORD		= 90
gt.GC_HISTORY_RECORD		= 91
gt.CG_REPLAY				= 92
gt.GC_REPLAY				= 93
gt.CG_USER_DING_QUE			= 110
gt.GC_USER_DING_QUE			= 111
-- gt.GC_ROUND_COUNT			= 115
gt.GC_XUELIU_ROUND			= 115
gt.CG_REPLACE_CARD          = 112
gt.GC_REPLACE_CARD			= 113
gt.CG_REPLACE_CARD_CHOOSE	= 114
gt.CG_USER_DING_QUE_COMPLATE = 116
gt.CG_S_ROOM_LOG			= 117
gt.GC_S_ROOM_LOG 			= 118
gt.GC_BAOJIAO               = 119
gt.CG_BAOJIAO               = 120
gt.GC_BAOJIAO_COMPLATE      = 121

gt.CG_FIND_INVITE_PLAYER   	= 130 --获取玩家信息
gt.GC_FIND_INVITE_PLAYER    = 131 --返回玩家信息
gt.CG_GET_INVITE_INFO   	= 132 --获取邀请信息
gt.GC_GET_INVITE_INFO    	= 133 --返回邀请信息
gt.CG_INVITE_OK   			= 134 --绑定邀请者
gt.GC_INVITE_OK    			= 135 --绑定邀请者结果
gt.CG_SHARE_GAME    		= 136 --玩家通过微信分享了游戏

gt.CG_TANGCARD    			= 139 --发送选择躺的牌
gt.GC_TANGCARD    			= 140 --服务器返回躺结果

gt.CG_CREHIS				= 141 --请求信誉列表
gt.GC_CREHIS				= 142 --服务器返回信誉列表
gt.CG_GTU 					= 143 --客户端请求发赞
gt.GC_GTU 					= 144 --服务器返回赞成功

gt.CG_EXCHANGEGOLD			= 145 --客户端请求换金币
gt.GC_EXCHANGEGOLD			= 146 --服务器返回换金币

gt.CG_SHARE_SUCCESS			= 220 -- 用户成功分享游戏发送给服务器
gt.GC_SHARE_SUCCESS			= 221 -- 服务器回复赠送房卡信息
---------------金币场相关--------------------
gt.CG_ENTER_GOLD_ROOM			= 44	--进入金币场消息
gt.GC_ENTER_GOLD_ROOM			= 45	--玩家请求创建房间结果
gt.GC_OUT_GOLD_ROONM			= 16403	--玩家被踢出房间
gt.GC_GIVE_GLOLD				= 16404	--给玩家赠送金币
gt.CG_GOON_NEXTGAME				= 16401	--玩家点击继续游戏
gt.GC_GOON_NEXTGAME				= 16402	--服务器回复消息
gt.GC_USER_AI_GIVE				= 64	--服务器发送玩家摸牌后的操作
gt.CG_USER_OUT_CARD				= 63	--金币场等待倒计时给服务器发送

gt.CG_GET_GOLDS					= 16405	--玩家请求领取金币
gt.GC_GET_GOLDS					= 16406	--服务器返回玩家领取金币
gt.GC_PLAYER_GOLDS				= 16407	--广播其他玩家金币数量
-----------------------------------------
-- 转盘抽奖相关
gt.GC_LOTTERY				= 94  -- 服务器推送活动相关信息
gt.CG_GET_GETLOTTERY		= 95  -- 玩家请求抽奖
gt.GC_RET_GETLOTTERY		= 96  -- 服务器返回此次抽奖结果
gt.CG_SAVE_PHONENUM			= 97  -- 客户端请求写入电话号码
gt.GC_SAVE_PHONENUM			= 98  -- 服务器返回写入电话号码结果
gt.CG_GET_GETLOTTERYRESULT	= 99  -- 玩家请求自己的抽奖结果
gt.GC_GET_GETLOTTERYRESULT	= 100 -- 服务器返回玩家抽奖结果
gt.GC_IS_ACTIVITIES			= 101 -- 服务器推送是否有活动(已作废)
gt.CG_GET_ACTIVITIES		= 102 -- 客户端请求活动信息 返回94号指令(已作废)

gt.CG_LOGIN_GATE			= 170 --客户端登录Gate
gt.GC_LOGIN_GATE			= 171 --Gate回客户端登录消息

gt.GC_ACTIVITY_INFO 		= 200 --通用的活动内容 服务器退给客户端
gt.CG_ACTIVITY_WRITE_PHONE  = 201 --填写活动相关的电话号码 客户端->服务器
gt.GC_ACTIVITY_WRITE_PHONE  = 202 --回复电话号码
gt.CG_ACTIVITY_REQUEST_LOG  = 203 --请求中奖纪录
gt.GC_ACTIVITY_REPLY_LOG	= 204 --回复中奖纪录
--转盘
gt.CG_ACTIVITY_REQUEST_DRAW_OPEN 	= 211 --请求打开转盘
gt.GC_ACTIVITY_REPLY_DRAW_OPEN		= 212 --返回请求打开转盘消息
gt.CG_ACTIVITY_REQUEST_DRAW 		= 213 --客户端请求抽卡
gt.GC_ACTIVITY_REPLY_DRAW 			= 214 --通知客户端抽卡结果

gt.CG_ACTIVITY_REQUEST_DRAGON_DRAW 	= 215 --客户端请求端午节抽奖结果

gt.CG_ACTIVITY_REQUEST_INVITE_OPEN 	= 230 --请求开启邀请活动
gt.GC_ACTIVITY_REPLY_INVITE_OPEN 	= 231 --回复开启邀请活动结果
gt.CG_ACTIVITY_REQUEST_INVITE 		= 232 --请求邀请玩家ID
gt.GC_ACTIVITY_REPLY_INVITE 		= 233 --回复邀请玩家结果

gt.CG_ACTIVITY_REQUEST_DRAGON_OPEN	= 240 --请求端午节活动
gt.GC_ACTIVITY_REPLY_DRAGON_OPEN	= 241 --返回端午节活动用户详情

gt.CG_VERIFY_HEAD           = 500

