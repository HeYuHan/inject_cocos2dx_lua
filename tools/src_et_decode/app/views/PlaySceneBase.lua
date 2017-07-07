local PlaySceneBase = class("PlaySceneBase", function() return cc.Scene:create() end )

local gt = cc.exports.gt

function PlaySceneBase:ctor(enterRoomMsgTbl)
    self.colorGray  = cc.c3b(100, 100, 100)
    self.colorWhite = cc.c3b(255, 255, 255)
end

function PlaySceneBase:IsSameIp()
    assert(self.nod_ip and self.lbl_IPSameTip, "Please make sure nod_ip lbl_IPSameTip is vaild")

    local tmp = {}
    for _, roomPlayer in ipairs(self.roomPlayers) do
        tmp[tostring(roomPlayer.ip)] = tmp[tostring(roomPlayer.ip)] or {}
        table.insert(tmp[tostring(roomPlayer.ip)], " 玩家:" .. tostring(roomPlayer.nickname))
    end

    local showStr = ""
    for k,v in pairs(tmp) do
        if #v > 1 then
            showStr = showStr .. table.concat(v, "") .. "为同一IP\n"
        end
    end
    gt.log("showStr = "..showStr)

    if string.len(showStr) > 0 then
        self.nod_ip:setLocalZOrder(888) -- TODO z值应该统一规划
        gt.runCSBAction(self.nod_ip, "playscene/IPSame.csb")

        self.lbl_IPSameTip:setString(showStr)
    end
end

-- csb中要保持nod_smallToast为默认不可见
function PlaySceneBase:showSmallToast(message)
    assert(self.nod_smallToast and self.lbl_SmallToastTxt, "Please make sure nod_smallToast lbl_SmallToastTxt is vaild")

    self.nod_smallToast:setVisible(true)

    gt.runCSBAction(self.nod_smallToast, "playscene/SmallToast.csb")
    self.lbl_SmallToastTxt:setString(message)
end

return PlaySceneBase
