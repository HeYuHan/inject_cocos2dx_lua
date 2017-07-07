local CreateRoomData = {}

local function Item(t)
  local function default(t)
    local _t = clone(t)
    _t["select"] = true
    return Item(_t)
  end

  local function offset(t, _offset)
    local _t = clone(t)
    _t["offsetnum"] = _offset

    return Item(_t)
  end

  local function pos(t, _row, _col)
    local _t = clone(t)
    _t["row"] = _row
    _t["col"] = _col

    return Item(_t)
  end

  local function text(t, newText)
    local _t = clone(t)
    _t["name"] = newText

    return Item(_t)
  end

  local function parent(t, _parent)
    local _t = clone(t)

    local _v = {}
    if _parent.key then
      _v[_parent.key] = true
    else
      for _, _p in ipairs(_parent) do
        _v[_p.key] = true
      end
    end
    _t["parents"] = _v

    return Item(_t)
  end

  local function child(t, _child)
    local _t = clone(t)

    local _v = {}
    if _child.key then
      _v[_child.key] = true
    else
      for _, _c in ipairs(_child) do
        _v[_c.key] = true
      end
    end
    _t["children"] = _v

    return Item(_t)
  end

  local function show(t, _showItems)
      local _t = clone(t)

      local _v = {}

      for _, _s in ipairs(_showItems) do
          _v[_s.key] = true
      end
      _t["willShow"] = _v

      return Item(_t)
  end

  local function hide(t, _hideItems)
      local _t = clone(t)
      local _v = {}
      for _, _s in ipairs(_hideItems) do
          _v[_s.key] = true
      end
      _t["willHide"] = _v

      return Item(_t)
  end

  local function countShow(t, _showItems)
      local _t = clone(t)
      local _v = {}

      for _, _s in ipairs(_showItems) do
          _v[_s.key] = true
      end
      _t["willCountShow"] = _v

      return Item(_t)
  end

  t["default"] = default
  t["offset"]  = offset
  t["pos"]  = pos
  t["text"] = text

  t["parent"] = parent
  t["child"]  = child

  t["show"] = show
  t["hide"] = hide
  t["countShow"] = countShow

  return t
end

-- 局数
local ju4 = Item({type = "radio", key = "ju", name =  "4局(房卡X2)", value =  1})
local ju8 = Item({type = "radio", key = "ju", name =  "8局(房卡X3)", value =  2})

-- 人数
local ren3_zigong = Item({type = "radio", key = "ren_state", name =  "3人", value =  115})
local ren4_zigong = Item({type = "radio", key = "ren_state", name =  "4人", value =  117})

local ren3_neijiang = Item({type = "radio", key = "ren_state", name =  "3人", value =  118})
local ren4_neijiang = Item({type = "radio", key = "ren_state", name =  "4人", value =  119})

local fang2 = Item({type = "radio", key = "fang", name =  "两方", value =  42})
local fang3 = Item({type = "radio", key = "fang", name =  "三方", value =  43})

-- 番数
local fan2 = Item({type = "radio", key = "fan", name =  "2番", value =  24})
local fan3 = Item({type = "radio", key = "fan", name =  "3番", value =  25})
local fan4 = Item({type = "radio", key = "fan", name =  "4番", value =  26})
local fan5 = Item({type = "radio", key = "fan", name =  "5番", value = 101})
local fan6 = Item({type = "radio", key = "fan", name =  "6番", value = 102})
local fan4_10 = Item({type = "radio", key = "fan", name = "4番(极品10分)", value = 188})
local fan4_16 = Item({type = "radio", key = "fan", name = "4番(极品16分)", value = 189})

-- 鬼数
local gui4  = Item({type = "radio", key = "gui", name =  "4鬼",  value =  171})
local gui8  = Item({type = "radio", key = "gui", name =  "8鬼",  value =  172})
local gui12 = Item({type = "radio", key = "gui", name =  "12鬼", value =  173})

-- 牌张
local pai7  = Item({type = "radio", key = "pai", name =  "7张",  value =  35})
local pai10 = Item({type = "radio", key = "pai", name =  "10张", value =  36})
local pai13 = Item({type = "radio", key = "pai", name =  "13张", value =  37})

local zimojiadi  = Item({type = "radio", key = "zimojia", name =  "自摸加底", value =  22})
local zimojiafan = Item({type = "radio", key = "zimojia", name =  "自摸加番", value =  23})
local zimobujia  = Item({type = "radio", key = "zimojia", name =  "自摸不加", value =  0})

local zimohu        = Item({type = "radio", key = "zenmehu", name =  "自摸胡 ", value =  1})
local dianpaohu     = Item({type = "radio", key = "zenmehu", name =  "点炮胡", value =  103})
local dianpaohugang = Item({type = "radio", key = "zenmehu", name =  "点炮胡(可抢杠)", value =  2})

local dianganghuadianpao  = Item({type = "radio", key = "dianganghua", name =  "点杠花(点炮)", value =  29})
local dianganghuazimo     = Item({type = "radio", key = "dianganghua", name =  "点杠花(自摸)", value =  30})
local dianganghua1renzimo = Item({type = "radio", key = "dianganghua", name =  "点杠花(一人自摸)", value =  51})

-- 拖拖拖
local tuo1_1 = Item({type = "radio", key = "tuo", name =  "1拖1", value =  31})
local tuo1_2 = Item({type = "radio", key = "tuo", name =  "1拖2", value =  32})
local tuo3_5 = Item({type = "radio", key = "tuo", name =  "3拖5", value =  33})

-- 最大飘数(南充)
local piao0 = Item({type = "radio", key = "piao", name =  "不能飘", value =  105})
local piao3 = Item({type = "radio", key = "piao", name =  "飘3个", value =  106})
local piao4 = Item({type = "radio", key = "piao", name =  "飘4个", value =  107})
local piao5 = Item({type = "radio", key = "piao", name =  "飘5个", value =  108})

local wuguifan1 = Item({type = "radio", key = "wuguifan", name = "无鬼1番", value = 211})
local wuguifan2 = Item({type = "radio", key = "wuguifan", name = "无鬼2番", value = 212})
local wuguifan3 = Item({type = "radio", key = "wuguifan", name = "无鬼3番", value = 213})

local gangshangpaofan1 = Item({type = "radio", key = "gangshangpaofan", name = "杠上炮1番", value = 214})
local gangshangpaofan2 = Item({type = "radio", key = "gangshangpaofan", name = "杠上炮2番", value = 215})
local gangshangpaofan3 = Item({type = "radio", key = "gangshangpaofan", name = "杠上炮3番", value = 216})

local qianggangfan1 = Item({type = "radio", key = "qianggangfan", name = "抢杠1番", value = 217})
local qianggangfan2 = Item({type = "radio", key = "qianggangfan", name = "抢杠2番", value = 218})
local qianggangfan3 = Item({type = "radio", key = "qianggangfan", name = "抢杠3番", value = 219})

local s_difen = Item({type = "slider", key = "difen", name = "底分", min = 1, max = 9, step = 1, defaultvalue = 1, format="%d 分"})

-- 以下是复选框
local k_kehuqidui = Item({type = "checkbox", key = "kehuqidui", name = "可胡七对 ", value = 5})

local k_huansanzhang      = Item({type = "checkbox", key = "huansanzhang",      name = "换三张",  value = 20})
local k_yaojiujiangdui    = Item({type = "checkbox", key = "yaojiujiangdui",    name = "幺九将对", value = 27})
local k_menqingzhongzhang = Item({type = "checkbox", key = "menqingzhongzhang", name = "门清中张", value = 28})
local k_menqing           = Item({type = "checkbox", key = "menqing",           name = "门清",    value = 47})
local k_zhongzhang        = Item({type = "checkbox", key = "zhongzhang",        name = "中张",    value = 48})

local k_tiandihu = Item({type = "checkbox", key = "tiandihu", name = "天地胡", value = 34})

local k_kaertiao         = Item({type = "checkbox", key = "kaertiao",         name = "卡二条",     value = 38})
local k_dianpaokepinghu  = Item({type = "checkbox", key = "dianpaokepinghu",  name = "点炮可平胡", value = 39})
local k_duiduihuliangfan = Item({type = "checkbox", key = "duiduihuliangfan", name = "对对胡两番", value = 40})
local k_jiaxin5          = Item({type = "checkbox", key = "jiaxin5",          name = "夹心五",     value = 41})

local k_piao = Item({type = "checkbox", key = "piao", name = "飘", value = 104})

local k_liangjiabutang = Item({type = "checkbox", key = "liangjiabutang", name = "两家不躺", value = 150})
local k_baojiaobihu    = Item({type = "checkbox", key = "baojiaobihu",    name = "报叫必胡", value = 151})
local k_youtangbihu    = Item({type = "checkbox", key = "youtangbihu",    name = "有躺必胡", value = 151})
local k_langqibihu    = Item({type = "checkbox", key = "langqibihu",    name = "廊起必胡", value = 151})

local k_xuezhandaodi = Item({type = "checkbox", key = "xuezhandaodi", name = "血战到底", value = 160})
local k_yaojidai     = Item({type = "checkbox", key = "yaojidai",     name = "幺鸡代", value = 161})

local k_siyaoji        = Item({type = "checkbox", key = "siyaoji",        name = "四幺鸡",  value = 49})
local k_ruanpengkegang = Item({type = "checkbox", key = "ruanpengkeyong", name = "软碰可杠", value = 50})

local k_baipai = Item({type = "checkbox", key = "baipai", name = "摆牌", value = 52})

local k_yaojiu = Item({type = "checkbox", key = "yaojiu", name =  "幺九", value =  201})
local k_jiangdui = Item({type = "checkbox", key = "jiangdui", name =  "将对", value =  202})
-- 支持中发白
local k_paizfb = Item({type = "checkbox", key = "paizfb", name =  "中发白", value =  203})

local k_hujiaozhuanyi = Item({type = "checkbox", key = "hujiaozhuanyi", name = "转雨",  value = 184})
local k_chajiaotuishui = Item({type = "checkbox", key = "chajiaotuishui", name = "查叫退税", value = 185})
local k_guoshuijiafan = Item({type = "checkbox", key = "guoshuijiafan", name = "过水加番可胡", value = 186})
local k_guansi  = Item({type = "checkbox", key = "guansi",  name = "关死", value = 187})

local k_zipaihuojian = Item({type = "checkbox", key = "zipaihuojian", name = "字牌火箭", value = 177})
local k_dasanyuanfanbei = Item({type = "checkbox", key = "dasanyuanfanbei", name = "大三元翻倍", value = 178})
local k_mendadiejia = Item({type = "checkbox", key = "mendadiejia", name = "门大叠加", value = 179})
local k_dingque = Item({type = "checkbox", key = "dingque", name = "定缺", value = 180})
local k_guoshoujiakekehu = Item({type = "checkbox", key = "guoshoujiakekehu", name = "过手加颗可胡", value = 181})
local k_zipaifeiji = Item({type = "checkbox", key = "zipaifeiji", name = "字牌飞机", value = 182})
local k_shibaxueshi = Item({type = "checkbox", key = "shibaxueshi", name = "十八学士", value = 183})

local k_quemen    = Item({type = "checkbox", key = "quemen",    name = "缺门",   value = 190})
local k_badaotang = Item({type = "checkbox", key = "badaotang", name = "巴倒烫", value = 191})
local k_yibangao  = Item({type = "checkbox", key = "yibangao",  name = "一般高", value = 192})
local k_baozi     = Item({type = "checkbox", key = "baozi",     name = "豹子",   value = 193})

local k_penghoukegang = Item({type = "checkbox", key = "penghoukegang", name = "碰后可杠", value = 162})

local k_yaojiujiangdui3fan = Item({type = "checkbox", key = "yaojiujiangdui3fan", name = "幺九将对3番", value = 204})
-- 这块是示例
-- local dataReview = { -- 将改变量添加入CreateRoomData中
--   tag   = 101,
--   name  = "审核专用",
--   image = "creatroom17.png",
--   col   = 3, -- 列数
--   row   = 6, -- 行数
--   xoffset = 200, -- 右侧条目整体偏移
--   titleoffset = - 30, -- 标题(局数，封顶等)偏移 可选的，可不设置
--   data  = {
--     round = { ju4, ju8:default():offset(100) }, -- default设置是否默认选择, offset设置x坐标偏移
--     top   = { fan2, fan3:default(), fan4 },
--     play  = { zimojiadi, zimojiafan,
--               dianganghuadianpao:pos(2, 1), dianganghuazimo:pos(2, 2), -- pos 设置行列位置
--               k_huansanzhang:pos(3, 1), k_yaojiujiangdui:pos(3, 2),
--               k_menqingzhongzhang:pos(4, 1), k_tiandihu:pos(4, 2)
--               k_yaojidai:default():text("幺鸡任用"):pos(3, 1):child(k_siyaoji),
--               k_siyaoji:pos(3, 2):parent({k_yaojidai, k_ruanpengkeyong}),
--               -- parent和child的调用总是成对出现，可以传入单个Item或Item的数组
--               -- text函数用于设置一个不同的名字
--               }
--   }
-- }

local dataYaAn = {
  tag   = 116,
  name  = "雅安麻将",
  image = "creatroom48.png",
  col   = 3,
  row   = 7,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default()},
    card  = { pai7, pai10:default(), pai13},
    top =   { fan4:default(), fan5},
    play =  { zimojiafan, zimojiadi, zimobujia:default(),
              dianganghuazimo:default():pos(2, 1), dianganghuadianpao:pos(2, 2),
              k_paizfb:pos(3, 1), k_tiandihu:pos(3, 2), k_langqibihu:pos(3,3),
              k_yaojiu:pos(4, 1):countShow({k_yaojiujiangdui3fan}), k_jiangdui:pos(4, 2):countShow({k_yaojiujiangdui3fan}), k_yaojiujiangdui3fan:pos(4,3):default()
     }
  }
}

local dataGuangan = {
    tag = 114,
    name = "广安麻将",
    image = "creatroom53.png",
    col = 3,
    row = 6,
    xoffset = 200,
    data  = {
        round  = { ju4, ju8:default()},
        -- people = { ren3, ren4:default()},
        difen = { s_difen},
        play =  { k_guoshoujiakekehu:default(), k_dasanyuanfanbei:default(),
                  k_zipaifeiji:default():pos(2, 1), k_zipaihuojian:default():pos(2, 2),
                  k_dingque:pos(3, 1), k_shibaxueshi:pos(3, 2),
                  k_mendadiejia:pos(4, 1)}
    }
}

local dataNanchong = {
  tag   = 113,
  name  = "南充麻将",
  image = "creatroom46.png",
  col   = 2,
  row   = 4,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default()},
    play =  { piao0:default(),piao3,piao4:pos(2, 1),piao5:pos(2, 2),k_baipai:pos(3, 1)}
  }
}

local dataLeshan = {
  tag   = 112,
  name  = "乐山麻将",
  image = "creatroom28.png",
  col   = 3,
  row   = 6,
  xoffset = 130,
  titleoffset = -20,
  data  = {
    round = { ju4, ju8:default()},
    top =   { fan4:default():text("4番(精品)"), fan5:text("5番(豪金)")},
    play =  { zimojiafan:default(), zimojiadi, zimobujia,
              dianganghuazimo:pos(2, 1), dianganghuadianpao:pos(2, 2), dianganghua1renzimo:default():pos(2, 3),

              k_yaojidai:text("幺鸡任用"):pos(3, 1):child({k_siyaoji,k_ruanpengkegang}),
              k_siyaoji:pos(3, 2):parent(k_yaojidai),
              k_ruanpengkegang:pos(3, 3):parent(k_yaojidai),

              k_tiandihu:default():pos(4, 1), k_menqing:default():pos(4, 2), k_zhongzhang:pos(4, 3) }
  }
}

local dataLuzhou = {
  tag   = 111,
  name  = "泸州麻将",
  image = "creatroom27.png",
  col   = 3,
  row   = 6,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default()},
    top =   { fan4:default():text("20颗"), fan5:text("40颗"), fan6:text("80颗(5分起胡)")},
    play =  { gui4:default(), gui8, gui12,
              wuguifan1:pos(2,1), wuguifan2:pos(2,2), wuguifan3:pos(2,3):default(),
              gangshangpaofan1:pos(3,1), gangshangpaofan2:pos(3,2), gangshangpaofan3:pos(3,3):default(),
              qianggangfan1:pos(4,1), qianggangfan2:pos(4,2), qianggangfan3:pos(4,3):default()

    }
  }
}

local dataWanzhou = {
  tag   = 110,
  name  = "万州麻将",
  image = "creatroom25.png",
  col   = 3,
  row   = 4,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { k_xuezhandaodi, k_yaojidai,
              k_baojiaobihu:pos(2,1), k_penghoukegang:pos(2,2) }
  }
}

local dataXuezhan = {
  tag   = 101,
  name  = "血战到底",
  image = "creatroom17.png",
  col   = 3,
  row   = 6,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(),           zimojiafan,
              dianganghuadianpao:pos(2, 1),  dianganghuazimo:pos(2, 2):default(),
              k_huansanzhang:pos(3, 1),      k_yaojiujiangdui:pos(3, 2),
              k_menqingzhongzhang:pos(4, 1), k_tiandihu:pos(4,2)}
  }
}

local dataSanrenLiangfang = {
  tag   = 103,
  name  = "三人两房",
  image = "creatroom13.png",
  col   = 3,
  row   = 6,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(),           zimojiafan,
              dianganghuadianpao:pos(2, 1),  dianganghuazimo:pos(2, 2):default(),
              k_yaojiujiangdui:pos(3, 1),    k_menqingzhongzhang:pos(3, 2),        k_tiandihu:pos(3, 3),
              k_dianpaokepinghu:pos(4, 1),   k_duiduihuliangfan:pos(4, 2),         k_jiaxin5:pos(4, 3)}
  }
}

local dataYibin = {
  tag   = 109,
  name  = "宜宾麻将",
  image = "creatroom24.png",
  col   = 3,
  row   = 4,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan5:default(), fan6 },
    play =  { zimohu:default(), dianpaohu,
              k_piao:pos(2, 1) }
  }
}

local dataSanrenSanfang = {
  tag   = 107,
  name  = "三人三房",
  image = "creatroom10.png",
  col   = 4,
  row   = 6,
  xoffset = 100,
  titleoffset = -40,
  data  = {
    round = { ju4, ju8:default() },
    card  = { pai7, pai10, pai13:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(), zimojiafan, dianganghuadianpao, dianganghuazimo:default(),
              k_yaojiujiangdui:pos(2, 1), k_menqingzhongzhang:pos(2, 2), k_tiandihu:pos(2, 3), k_dianpaokepinghu:pos(2, 4),
              k_duiduihuliangfan:pos(3, 1) }
  }
}

local dataMianyang = {
  tag   = 108,
  name  = "绵阳麻将",
  image = "creatroom22.png",
  col   = 3,
  row   = 6,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(),          zimojiafan,
              dianganghuadianpao:pos(2, 1), dianganghuazimo:default():pos(2, 2),
              k_yaojiujiangdui:pos(3, 1),   k_tiandihu:pos(3, 2),
              k_liangjiabutang:pos(4, 1),   k_youtangbihu:pos(4, 2) }
  }
}

local dataSirenLiangfang = {
  tag   = 105,
  name  = "四人两房",
  image = "creatroom14.png",
  col   = 3,
  row   = 6,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    card  = { pai7, pai10, pai13:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(),          zimojiafan,
              dianganghuadianpao:pos(2, 1), dianganghuazimo:default():pos(2, 2),
              k_kaertiao:pos(3, 1) }
  }
}

local dataXueliu = {
  tag   = 102,
  name  = "血流成河",
  image = "creatroom16.png",
  col   = 3,
  row   = 6,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(),           zimojiafan,
              dianganghuadianpao:pos(2, 1),  dianganghuazimo:default():pos(2, 2),
              k_huansanzhang:pos(3, 1),      k_yaojiujiangdui:pos(3, 2),
              k_menqingzhongzhang:pos(4, 1), k_tiandihu:pos(4, 2)}
  }
}

local dataDeyang = {
  tag   = 106,
  name  = "德阳麻将",
  image = "creatroom21.png",
  col   = 3,
  row   = 5,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    top =   { fan2, fan3:default(), fan4 },
    play =  { zimojiadi:default(),           zimojiafan,
              dianganghuadianpao:pos(2, 1),  dianganghuazimo:default():pos(2, 2),
              k_yaojiujiangdui:pos(3, 1) }
  }
}

local dataDaodaohu = {
  tag   = 104,
  name  = "倒倒胡",
  image = "creatroom7.png",
  col   = 3,
  row   = 4,
  xoffset = 200,
  data  = {
    round = { ju4, ju8:default() },
    count = { tuo1_1, tuo1_2:default(), tuo3_5 },
    play  = { zimohu, dianpaohugang:default(),
              k_kehuqidui:pos(2, 1) }
  }
}

local dataZigong = {
  tag   = 115,
  name  = "自贡麻将",
  image = "creatroom51.png",
  col   = 3,
  row   = 8,
  xoffset = 150,
  data  = {
    round = { ju4, ju8:default() },
    top   = { fan3, fan4_10:default(), fan4_16 },
    people = { ren3_zigong:default(), ren4_zigong},
    card  = { pai7, pai13:default()},
    play  = { zimojiafan, zimojiadi:default(), zimobujia,
              dianganghuadianpao:pos(2, 1), dianganghuazimo:pos(2, 2), dianganghua1renzimo:pos(2, 3):default(),
              k_guansi:default():pos(3, 1), k_tiandihu:pos(3, 2),
              k_hujiaozhuanyi:default():pos(3, 3), k_chajiaotuishui:default():pos(4, 1),  k_guoshuijiafan:pos(4, 2)}
  }


}

local dataNeijiang = {
    tag   = 119, -- 三人118，四人119, 这里固定为119
    name  = "内江麻将",
    image = "creatroom55.png",
    col   = 3,
    row   = 8,
    xoffset = 200,
    data  = {
        round =  { ju4, ju8:default() },
        fang  =  { fang2:show({pai7, pai13}):hide({k_quemen}),
                   fang3:show({k_quemen}):hide({pai7, pai13}):default(),
                   pai7:pos(1,3):offset(-70), pai13:default():pos(1, 3):offset(70), k_quemen:pos(1, 3)},
        people = { ren3_neijiang, ren4_neijiang:default()},
        top   =  { fan3, fan4:default() },
        play  =  { zimojiafan, zimojiadi:default(), zimobujia,
                   k_yibangao:default():pos(2,1), k_baipai:default():text("报叫"):pos(2,2):child({k_guansi}), k_guansi:default():pos(2,3):parent({k_baipai}),
                   k_hujiaozhuanyi:default():text("呼叫转移"):pos(3,1), k_chajiaotuishui:default():pos(3, 2), k_tiandihu:pos(3, 3),
                   k_badaotang:pos(4,1), k_baozi:pos(4,2), k_piao:pos(4,3)}
    }
}

local data2Ren = {
    tag   = 120,
    name  = "两人麻将",
    image = "creatroom64.png",
    col   = 3,
    row   = 8,
    xoffset = 200,
    data  = {
        round =  { ju4, ju8:default() },
        fang  =  { fang2, fang3:default()},
        top   =  { fan2, fan3, fan4:default() },
        play  =  { zimojiafan, zimojiadi:default(),
                   dianganghuadianpao:pos(2,1), dianganghuazimo:default():pos(2,2),
                   k_huansanzhang:pos(3,1), k_yaojiu:pos(3,2), k_jiangdui:pos(3,3),
                   k_tiandihu:pos(4,1), k_menqing:pos(4,2), k_zhongzhang:pos(4,3),
                   k_dianpaokepinghu:pos(5,1):text("两分起胡")}
    }
}

-- 可以调整下面的顺序以调整显示顺序
table.insert(CreateRoomData, data2Ren)       --120
table.insert(CreateRoomData, dataNeijiang)   --119
table.insert(CreateRoomData, dataYaAn)--116
table.insert(CreateRoomData, dataZigong) --115
table.insert(CreateRoomData, dataGuangan)--114
table.insert(CreateRoomData, dataNanchong)--113
table.insert(CreateRoomData, dataXuezhan)--101
table.insert(CreateRoomData, dataSanrenLiangfang)--103
table.insert(CreateRoomData, dataLeshan)--112
table.insert(CreateRoomData, dataSirenLiangfang)--105
table.insert(CreateRoomData, dataSanrenSanfang)--107
table.insert(CreateRoomData, dataMianyang)--108
table.insert(CreateRoomData, dataDaodaohu)--104
table.insert(CreateRoomData, dataXueliu)--102
table.insert(CreateRoomData, dataWanzhou)--110
table.insert(CreateRoomData, dataDeyang)--106
table.insert(CreateRoomData, dataYibin)--109
table.insert(CreateRoomData, dataLuzhou)--111


if gt.isInReview then
  CreateRoomData = {dataXuezhan}
end

return CreateRoomData
