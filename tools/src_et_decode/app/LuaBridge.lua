local gt = cc.exports.gt

local bridge = {}
gt.bridge = bridge

local luaBridge = nil
local _ = nil

if gt.isIOSPlatform() then
    luaBridge = require("cocos/cocos2d/luaoc")
elseif gt.isAndroidPlatform() then
    luaBridge = require("cocos/cocos2d/luaj")
end

function bridge.getVersionName()
    local appVersion = "0.0.0"

    if gt.isIOSPlatform() then
        _, appVersion = luaBridge.callStaticMethod("AppController", "getVersionName")
    elseif gt.isAndroidPlatform() then
        _, appVersion = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
    end

    return appVersion
end

function bridge.openFeedback()
    if gt.isIOSPlatform() then
        luaBridge.callStaticMethod("AppController", "openFeedback")
    elseif gt.isAndroidPlatform() then
        luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openFeedback", nil, "()V")
    end
end

function bridge.openWebURL(url)
    if gt.isIOSPlatform() then
        luaBridge.callStaticMethod("AppController", "openWebURL", {webURL = url})
    elseif gt.isAndroidPlatform() then
        luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL", {url}, "(Ljava/lang/String;)V")
    end
end

function bridge.setAppInfo(key, value)
    if gt.isIOSPlatform() then
        local _t = {}
        _t[key] = value

        luaBridge.callStaticMethod("AppController", "setAppInfo", _t)
    end
end

function bridge.playVoice(url)
    local ok = nil
    if gt.isIOSPlatform() then
        ok = luaBridge.callStaticMethod("AppController", "playVoice", {voiceUrl = url})
    elseif gt.isAndroidPlatform() then
        ok = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "playVoice", {url}, "(Ljava/lang/String;)V")
    end

    return ok
end

function bridge.startVoice(audioPath)
    if gt.isIOSPlatform() then
        local ok = luaBridge.callStaticMethod("AppController", "startVoice", {recodePath = audioPath})
    elseif gt.isAndroidPlatform() then
        local ok, ret = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "startVoice",nil,"()Z")
    end
end

function bridge.stopVoice()
    if gt.isIOSPlatform() then
        local ok, ret = luaBridge.callStaticMethod("AppController", "stopVoice")
    elseif gt.isAndroidPlatform() then
        local ok, ret = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "stopVoice",nil,"()Z")
    end
end

function bridge.cancelVoice()
    if gt.isIOSPlatform() then
        local ok, ret = luaBridge.callStaticMethod("AppController", "cancelVoice")
    elseif gt.isAndroidPlatform() then
        local ok, ret = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "cancelVoice",nil,"()Z")
    end
end

function bridge.getVoiceUrl()
    local ret = ""
    if gt.isIOSPlatform() then
        _, ret = luaBridge.callStaticMethod("AppController", "getVoiceUrl")
    elseif gt.isAndroidPlatform() then
        _, ret = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getVoiceUrl", nil, "()Ljava/lang/String;")
        gt.log("the ret is .." .. ret)
    end

    return ret
end

function bridge.getDeviceBattery()
    local result = 0
    if gt.isIOSPlatform() then
        _, result = luaBridge.callStaticMethod("AppController", "getDeviceBattery")
    elseif gt.isAndroidPlatform() then
        _, result = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getDeviceBattery", nil, "()Ljava/lang/String;")
    end

    return tonumber(result)
end

function bridge.getDeviceSignalStatus()
    local result = ""
    if gt.isIOSPlatform() then
        _, result = luaBridge.callStaticMethod("AppController", "getDeviceSignalStatus")
    elseif gt.isAndroidPlatform() then
        _, result = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getDeviceSignalStatus", nil, "()Ljava/lang/String;")
    end

    return result
end

function bridge.getDeviceSignalLevel()
    local signalStatus = bridge.getDeviceSignalStatus()

    local signalLevel = 0
    if signalStatus == "WIFI" then
        if gt.isIOSPlatform() then
            _, signalLevel = luaBridge.callStaticMethod("AppController", "getDeviceSignalLevel")
        elseif gt.isAndroidPlatform() then
            _, signalLevel = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getDeviceSignalLevel", nil, "()Ljava/lang/String;")
        end
    else
        signalLevel = 4
        if gt.isAndroidPlatform() then
            _, signalLevel = luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getDeviceNoWifiLevel", nil, "()Ljava/lang/String;")
        elseif gt.isIOSPlatform() then
            _, signalLevel = luaBridge.callStaticMethod("AppController", "getDeviceSignalLevel")
        end
    end

    return tonumber(signalLevel)
end
