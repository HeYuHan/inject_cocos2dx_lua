local SoundManager = {}

local LANGUAGE_COMMON = 2 -- 2是普通话,1是长沙方言
local SEX_MAX = 1



-- local LANGUAGE_TYPE = {"common", "changsha"}
-- local SEX_TYPE = {"man", "woman"}

SoundManager.NAME_LIST = {
	queyise = "hu",
	banbanhu = "hu",
	sixi = "hu",
	liuliushun = "hu",

	haohuaxiaoqidui = "hu",
	-- "haohuaxiaoqidui" = "js_dh_haohuaqixiaodui_zimo",

	qixiaodui = "hu",
	-- "qixiaodui" = "js_dh_qixiaodui_zimo",

	qingyise = "hu",
	-- "qingyise" = "js_dh_qingyise_zimo",

	jiangjianghu = "hu",
	-- "jiangjianghu" = "js_dh_jiangjianghu_zimo",

	pengpenghu = "hu",
	-- "pengpenghu" = "js_dh_pengpenghu_zimo",

	quanqiuren = "hu",
	-- "quanqiuren" = "js_dh_quanqiuren_zimo",

	gangshangkaihua = "hu",
	-- "gangshangkaihua" = "js_dh_gangshangkaihua_zimo",

	gangshangpao = "hu",

	haidilaoyue = "hu",
	-- "haidilaoyue" = "js_dh_haidilaoyue_zimo",

	haidipao = "hu",

	qiangganghu = "hu",

	hu = {
		"xiaohu",
		"xiaohu",
	},
	huMore = {
		"xiaohu",
		"xiaohu",
		"xiaohu",
	},
	zimo = {
		"zimo",
		"zimo",
	},
	gang = {
		"gang",
		"gang",
	},
	gangMore = {
		"gang",
		"gang",
		"gang",
	},
	peng = {
		"peng",
		"peng",
		"peng",
		"peng",
	},
	pengMore = {
		"peng",
		"peng",
		"peng",
		"peng",
		"peng",
	},
	chi = {
		"chi",
		"chi",
		"chi",
	},
	chiMore = {
		"chi1",
		"chi2",
		"chi3",
		"chi4",
	},
	buzhang = "buzhang",
}

function SoundManager:PlaySpeakSound(sex, _type, roomPlayer)

	local path = SoundManager:getPath(sex)
	gt.soundEngine:playEffect(string.format("%s/%s", path, _type))

end

function SoundManager:PlayCardSound(sex, color, number)

	local path = SoundManager:getPath(sex)

	gt.soundEngine:playEffect(string.format("%s/mjt%d_%d", path, color, number))
end

function SoundManager:PlayFixSound(sex, id)
	local path = SoundManager:getPath(sex)
	gt.log("path = " .. path .. ", id = " .. id)
	gt.soundEngine:playEffect(string.format("%s/fix_msg_%d", path, id))
end

function SoundManager:getPath(sex)

	   if sex == SEX_MAX then
			return "man"
		else
			return "woman"
		end
end

return SoundManager