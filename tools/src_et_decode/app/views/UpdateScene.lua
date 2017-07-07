local gt = cc.exports.gt

local WritablePath          = cc.FileUtils:getInstance():getWritablePath()
local LocalProjectManifest  = "project.manifest"
local CachedProjectManifest = WritablePath..LocalProjectManifest
local TempDirectory         = WritablePath.."update_temp".."/"

local RequestType_Version   = 1
local RequestType_Manifest  = 2
local RequestType_File      = 3

local InitText = {}
InitText[1] = "加载中,请稍候……"
InitText[2] = "加载中,请稍候……"
InitText[3] = "正在启动游戏，请稍候……"
InitText[4] = "触摸屏幕开始"
InitText[5] = "读取manifest[%s]文件错误"
InitText[6] = "已是最新版无需更新"
InitText[7] = "创建目录失败"
InitText[8] = "下载文件错误"
InitText[9] = "正在更新文件"
InitText[10] = "更新配置文件格式错误"
InitText[11] = "更新完成"
InitText[12] = "正在检查文件"
InitText[13] = "正在写入文件"

local function hex(s)
    s=string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
    -- print("====数值",s)
    return s, string.len(s)
end

-- 读取文件
local function readFile( path )
    local file = io.open( path, "rb" )
    if file then
        local content = file:read( "*all" )
        io.close(file)
        return content
    end

    return nil
end

local function checkDirOK( path )
    local cpath = cc.FileUtils:getInstance():isFileExist(path)
    if cpath then
        return true
    end

    return cc.FileUtils:getInstance():createDirectory( path )
end

-- 比较获取需要下载的文件名字
local function compManifest( oList, newList )
    local oldList = {}
    for k,v in pairs(oList) do
        oldList[k] = v["md5"]
    end

    local list = {}
    for k,v in pairs(newList) do
        local name = k
        if v["md5"] ~= oldList[k] then
            local saveTab = {}
            saveTab.name    = name
            saveTab.md5code = v["md5"]
            table.insert( list, saveTab )
        end
    end

    return list
end

local function checkFile( fileName, cryptoCode )
    if not io.exists(fileName) then -- 测试fileName文件是否存在
        return false -- 如果文件不存在,那么返回false
    end

    local data = readFile(fileName)
    if data == nil then
        return false
    end

    if cryptoCode == nil then
        return true
    end
    local needMd5Str, needLen = hex(data)
    local ms = cc.UtilityExtension:generateMD5( needMd5Str, needLen )
    if ms==cryptoCode then
        return true
    end

    -- print("md5差异Error:", fileName, cryptoCode, ms)
    return false
end

local function checkCacheDirOK( root_dir, path )
    path = string.gsub( string.trim(path), "\\", "/" )
    local info = io.pathinfo(path)
    if not checkDirOK(root_dir..info.dirname) then
        return false
    end

    return true
end

local function removeFile( path )
    --print("removeFile---------------> " .. path)
    io.writefile(path, "")
    if device.platform == "windows" then
        os.remove(string.gsub(path, '/', '\\'))
    else
        cc.FileUtils:getInstance():removeFile( path )
    end
end

local function renameFile(path, newPath)
    removeFile(newPath)
    os.rename(path, newPath)
    --print("renameFile---------------> " .. path .. "  ==> " .. newPath)
end

local function moveFile(from, destination)
    local ret = false
    if from and destination then
        local content = io.readfile(from)
        if content then
            ret = io.writefile(destination, content)
            if ret then
                removeFile(from)
            end
        end
    end

    return ret
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UpdateScene类
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local UpdateScene = class("UpdateScene", function()
    return cc.Scene:create()
end)

function UpdateScene:ctor()
    self:registerScriptHandler(handler(self, self.onNodeEvent))
    self.totalToDownload       = 0
    self.totalWaitToDownload   = 0
    self:resetUI(true)
end

function UpdateScene:onNodeEvent(eventName)
    if "enter" == eventName then
        if not cc.FileUtils:getInstance():isDirectoryExist(WritablePath) then
            self:onFatalError()
            return
        end

        -- 逻辑更新定时器
        self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.updateFunc), 0, false)

        self.localManifest = nil

        --从初始目录读文件列表
        local manifestFile = nil
        if cc.FileUtils:getInstance():isFileExist(CachedProjectManifest) then
            manifestFile = CachedProjectManifest
        elseif cc.FileUtils:getInstance():isFileExist(LocalProjectManifest) then
            manifestFile = LocalProjectManifest
        end

        if manifestFile then
            local fileData = cc.FileUtils:getInstance():getStringFromFile(manifestFile)
            require("json")
            self.localManifest = json.decode(fileData)
        end

        -- 未找到project.manifest文件,则重新下载一遍所有的资源
        if not self.localManifest then
            self.localManifest.version               = "1.0.0"
            self.localManifest.remoteVersionUrl      = "http://update.xlpdk.cn/client/mahjongsichuan/version.manifest"
            self.localManifest.remoteManifestUrl     = "http://update.xlpdk.cn/client/mahjongsichuan/project.manifest"
            self.localManifest.byremoteVersionUrl    = "http://update.xlsymj.com/client/mahjongsichuan/version.manifest"
            self.localManifest.byremoteManifestUrl   = "http://update.xlsymj.com/client/mahjongsichuan/project.manifest"
            self.localManifest.assets                = {}
        end

        -- 记录一下版本号
        gt.resVersion = self.localManifest.version

        self.updateNum = 1
        -- 请求版本号
        self:request(RequestType_Version, self.localManifest.remoteVersionUrl)
    end
end

function UpdateScene:updateFunc(delta)
    if self.dataRecv then -- 如果已经收到了数据
        if self.requestType == RequestType_Version then -- 如果是请求版本号的服务器返回消息
            require("json")
            self.dataRecv = json.decode(self.dataRecv)
            -- 如果服务器 客户端 版本不同, 那么请求project.manifest
            if self.dataRecv.version ~= self.localManifest.version then
                gt.log("需要请求版本")
                if self.progressLabel then
                    self.progressLabel:setVisible(true)
                    self.updateSlider:setVisible( true )
                end
                dump(self.dataRecv)
                if self.updateNum == 1 then
                    gt.log("self.updateNum == 1")
                    self:request(RequestType_Manifest, self.dataRecv.remoteManifestUrl)
                else
                    self:request(RequestType_Manifest, self.dataRecv.byremoteManifestUrl)
                end
                
                gt.isUpdate = true
            else
                gt.log("==无需更新版本")
                self:updateIgnored()
            end
        elseif self.requestType == RequestType_Manifest then
            require("json")
            -- 记录一下从服务器下载的project.manifest内容
            self.tempManifest = json.decode(self.dataRecv)
            if self.tempManifest.version == self.localManifest.version then
                self:updateIgnored() -- 如果版本相同 InitText[6] = "已是最新版无需更新"
                return
            end
            -- 通过比较获得需要更新的文件
            self.needUpdateList = nil
            self.numFileCheck = nil
            self.needUpdateList = compManifest( self.localManifest.newassets, self.tempManifest.newassets )
            
            if self.totalToDownload <= 0 then
                self.totalToDownload = #self.needUpdateList
                self.totalWaitToDownload = #self.needUpdateList
            end
            -- -- 打印一下需要更新的文件的名字
            -- for i,v in ipairs(self.needUpdateList) do
            --     print( v.name, v.md5code )
            -- end

            if self.totalToDownload == 0 then
                self:updateSucceed()
            else
                self:startUpdate()
            end
        elseif self.requestType == RequestType_File then
            local path = self.curStageFile.name
            local tempPath = TempDirectory..io.pathinfo(path).filename
            if io.writefile( tempPath, self.dataRecv ) then
                -- 检查 MD5
                local md5 = self.curStageFile.md5code
                if checkFile( tempPath, md5 ) then
                    local cachedPath = WritablePath..path
                    if checkCacheDirOK( WritablePath, path ) and moveFile( tempPath, cachedPath ) then
                        -- 修改本地 Manifest 中该文件的 MD5
                        self:modifyLocalManifestMD5(path, md5)
                        -- 继续下载下一个文件
                        self:reqNextFile()
                    else
                        self:onFatalError()
                    end
                else
                    self:updateFailed( InitText[8] ) -- InitText[8] = "下载文件错误"
                end
            else
                -- 无法写入文件
                self:onFatalError()
            end
        end
    end
end

function UpdateScene:request(type, url)
    self.requestType    = type
    self.dataRecv       = nil
    self:requestFromServer(url)
end

-- 向服务器发送请求消息
function UpdateScene:requestFromServer( needurl)
    if not self.xhr then
        self.xhr = cc.XMLHttpRequest:new()
        self.xhr:retain()
        self.xhr.timeout = 5 -- 设置超时时间
        gt.dump(self.xhr)
    end

    self.xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    local refreshTokenURL = needurl
    self.xhr:open("GET", refreshTokenURL)
    gt.log("refreshTokenURL = "..refreshTokenURL)
    self.xhr:registerScriptHandler( handler(self,self.onResp) )
    self.xhr:send()
end

function UpdateScene:onResp()
    if self.xhr.readyState == 4 and (self.xhr.status >= 200 and self.xhr.status < 207) then
        self.dataRecv = self.xhr.response -- 获取到数据
        self.xhr:unregisterScriptHandler()
    elseif self.xhr.readyState == 1 and self.xhr.status == 0 then
        -- 网络问题,异常断开
        self.xhr:unregisterScriptHandler()
        self:updateFailed( InitText[8] )
    end
end

function UpdateScene:reqNextFile()
    self.totalWaitToDownload = self.totalWaitToDownload - 1
    self.numFileCheck = self.numFileCheck + 1
    self.curStageFile = self.needUpdateList[self.numFileCheck]

    if not self.curStageFile then
        self:updateSucceed()
    else
        -- 进度条
        if self.updateSlider then
            local percent = (self.totalToDownload - self.totalWaitToDownload) / self.totalToDownload * 100
            gt.log("Update Checked: "..self.numFileCheck.." Update Percentage: " .. percent)
            self.progressLabel:setString( "正在更新游戏资源".." "..math.floor(percent).."%")
            self.updateSlider:setPercent( percent )
        end

        -- 如果文件已经存在了(例如MainScene.luac文件),检查此文件是否是已经下载过的文件(比较md5值)
        local fn = WritablePath..self.curStageFile.name
        if checkFile( fn, self.curStageFile.md5code ) then
            self:reqNextFile()
            return
        end

        -- 向服务器发送消息请求self.curStageFile.name文件
        
        local fileRemotePath = self.tempManifest.packageUrl .. "/" .. self.curStageFile.name
        if self.updateNum == 2 then
            fileRemotePath = self.tempManifest.bypackageUrl .. "/" .. self.curStageFile.name
        end
        self:request(RequestType_File, fileRemotePath);
    end
end

function UpdateScene:startUpdate()
    -- 检查并创建临时文件夹
    local ret = true
    if cc.FileUtils:getInstance():isDirectoryExist(TempDirectory) then
        ret = cc.FileUtils:getInstance():removeDirectory(TempDirectory)
    end

    if ret and cc.FileUtils:getInstance():createDirectory(TempDirectory) then
        self.numFileCheck = 0
        self:reqNextFile()
    else
        self:onFatalError()
    end
end

function UpdateScene:modifyLocalManifestMD5( file, md5 )
    if self.localManifest then
        local assets = self.localManifest.newassets
        if not assets then
            self.localManifest.newassets = {}
            assets = self.localManifest.newassets
        end

        local t = assets[file]
        if not t then
            assets[file] = {}
            t = assets[file]
        end

        t.md5 = md5

        -- save to file
        require("json")
        local data = json.encode(self.localManifest)
        return io.writefile(CachedProjectManifest, data)
    end
end

function UpdateScene:updateIgnored()
    gt.log("已经是最新版本！")

    self:onFinished()
    self:endCB()
end

function UpdateScene:updateSucceed()
    -- 下载完毕之后,需要修改后缀名等操作
    require("json")
    local data = json.encode(self.tempManifest)
    if io.writefile(CachedProjectManifest, data) then
        gt.resVersion = self.tempManifest.version
        gt.log("更新成功！")

        self:onFinished()
        -- 将资源从Cache中清除，以避免热更某些资源造成界面显示错误
        print("removeSpriteFrames: begin")
        cc.SpriteFrameCache:getInstance():removeSpriteFrames()
        print("removeSpriteFrames: end")
        self:endCB()
    else
        self:onFatalError()
    end
end

function UpdateScene:updateFailed(endInfo)
    if endInfo then
        gt.log("更新失败,原因: "..endInfo)
    end

    self:onFinished()

    if self.updateNum == 1 then
        self.updateNum = 2
        -- 请求版本号
        print("备用包更新。。。。")
        self:request(RequestType_Version, self.localManifest.byremoteVersionUrl)
    else
        require("app/views/NoticeTipsForUpdate"):create("更新失败", "更新失败,请检查您的网络连接", handler(self,self.endError), nil, true)
    end  
end

function UpdateScene:onFatalError()
    gt.log("严重错误：无法写入文件！")

    self:onFinished()
    require("app/views/NoticeTipsForUpdate"):create("更新失败", "文件无法写入，请重启设备后再次尝试", handler(self,self.endError), nil, true)
end

function UpdateScene:onFinished()
    -- 接收到的数据
    self.dataRecv   = nil
    -- 服务器的 Manifest
    self.tempManifest = nil

    if not cc.FileUtils:getInstance():removeDirectory( TempDirectory ) then
        gt.log("删除临时文件夹失败")
    end
end

function UpdateScene:resetUI(resetProgress)
    if not self.csbNode then
        local csbNode = cc.CSLoader:createNode("Update.csb")
        csbNode:setPosition(gt.winCenter)
        if display.autoscale == "FIXED_HEIGHT" then
            csbNode:setScale(0.75)
            gt.seekNodeByName(csbNode, "bg"):setScaleY(1280/960)   
        end
        self.csbNode = csbNode
        self:addChild(csbNode)
    end

    -- 显示更新状态
    if not self.progressLabel then
        local progressLabel = gt.seekNodeByName(self.csbNode, "Label_progress")
        progressLabel:setString(gt.getLocationString("LTKey_0033"))
        local fadeOut = cc.FadeOut:create(1)
        local fadeIn = cc.FadeIn:create(1)
        local seqAction = cc.Sequence:create(fadeOut, fadeIn)
        progressLabel:runAction(cc.RepeatForever:create(seqAction))
        self.progressLabel = progressLabel
    end

    if gt.isIOSPlatform() and gt.isInReview then
        self.progressLabel:setVisible(false)
    end

    -- 更新进度条
    if not self.updateSlider then
        self.updateSlider = gt.seekNodeByName(self.csbNode, "Slider_update")
    end

    if self.updateSlider then
        self.updateSlider:setVisible( false )
        if resetProgress then
            self.updateSlider:setPercent(0)
        end
        -- if gt.isIOSPlatform() and gt.isInReview then -- 苹果审核状态,不显示更新进度条
        --     self.updateSlider:setVisible( false )
        --     self.updateSlider:setPercent(0)
        -- else
        --     self.updateSlider:setVisible( true )
        --     self.updateSlider:setPercent(0)
        -- end
    end
end

function UpdateScene:endCB()
    if self.scheduleHandler then
        gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
    end

    gt.log("resVersion:" .. gt.resVersion)

    local loginScene = require("app/views/LoginScene"):create()
    cc.Director:getInstance():replaceScene(loginScene)
end

function UpdateScene:endError()
    
    local csbNode = cc.CSLoader:createNode("UpdataError.csb")
    csbNode:setAnchorPoint(0.5, 0.5)
    csbNode:setPosition(cc.p(0,0))
    self.csbNode:addChild(csbNode)

    local Btn_back = gt.seekNodeByName(csbNode,"Btn_back")
    gt.addBtnPressedListener(Btn_back, function()
        gt.log("更新失败  提示后回调的函数........")

        csbNode:removeFromParent()

        if self.scheduleHandler then
            gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
        end

        self:resetUI(false)
        self:onNodeEvent("enter")
    end)
end

return UpdateScene