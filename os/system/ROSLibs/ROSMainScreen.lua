local LOG_EVERYTHING = false
ROSSystemLog:space(2)
ROSSystemLog:write("----------------------------- "..shell.getRunningProgram().." -----------------------------",nil,nil,false)
ROSSystemLog:space(2)

MainScreenElements = {}
MainScreenElements.__index = MainScreenElements

if UIs.mainScreen then ROSSystemLog:close() os.reboot() end
ROSSystemLog:write("initializing mainScreen graphic frame")
UIs.mainScreen = graphicLib.Frame:init("RedOS")

local screenElements = {}

local sizeX, sizeY = term.getSize()

local taskBarState = {text={"R","O","S",nil,"0"},state=nil}

for i=1,sizeX do
    if taskBarState.text[i] == nil then
        taskBarState.text[i] = " "
    end
end

local function makeTaskBar()
    local taskBarString = ""
    for i=1,#taskBarState.text do
        taskBarString = taskBarString .. taskBarState.text[i]
    end
    return taskBarString
end

local currentPage, maxPage = 1, 1
local function resetTaskBar()
    taskBarState = {text={"R","O","S",nil,"0"},state={"default"}}

    for i=1,sizeX do
        if taskBarState.text[i] == nil then
            taskBarState.text[i] = " "
        end
    end

    taskBarState.text[sizeX] = "\026"
    taskBarState.text[sizeX-1] = "\027"
    taskBarState.text[sizeX-2] = maxPage
    taskBarState.text[sizeX-3] = "/"
    taskBarState.text[sizeX-4] = currentPage
    taskBarState.text[sizeX-6] = "+"

    return makeTaskBar()
end

local function ColorTaskBar(isBackground,colorTable)
    local colorScheme
    if not isBackground then
        colorScheme = {{colors.red,1},{colors.yellow,2},{colors.red,5},{colors.white,6}}
        if type(colorTable) == "table" then
            for i=1,#colorTable do
                if type(colorTable[i]) == "table" then
                    table.insert(colorScheme,colorTable[i])
                end
            end
        end
    else
        colorScheme = {{colors.lightGray,1},{colors.gray,sizeX-1}}
        if type(colorTable) == "table" then
            for i=1,#colorTable do
                if type(colorTable[i]) == "table" then
                    table.insert(colorScheme,colorTable[i])
                end
            end
        end
    end
    return colorScheme
end

ROSSystemLog:write("initializing Red OS Desktop UI")
local fileTextDisplay = UIs.mainScreen.hologram:addHologram("",nil,nil,nil,1,1,false,nil,true)
local dirTextDisplay = UIs.mainScreen.hologram:addHologram("",nil,nil,nil,1,1,false,false,true)
local taskBar = UIs.mainScreen.hologram:addHologram(resetTaskBar(),ColorTaskBar(),ColorTaskBar(true),nil,1,sizeY)

local navigatorActive = (not term.isColor())

local dfpwm
local dfpwmSuccess, _ = pcall(function()
    dfpwm = require("cc.audio.dfpwm")
end)

local function makeCheckerPattern(width,height,darkColor, lightColor)
    local background = {}
    for i=1,width do
        background[i] = {}
        for j = 1,height do
            if j % 2 == 0 then
                if i % 2 == 0 then
                    background[i][j] = darkColor
                else
                    background[i][j] = lightColor
                end
            else
                if i % 2 == 0 then
                    background[i][j] = lightColor
                else
                    background[i][j] = darkColor
                end
            end
        end
    end
    return background
end

local function loadImage(dir)
    if fs.exists(dir) then
        return UIs.mainScreen:loadImage(dir)
    else
        return makeCheckerPattern(3,3,colors.gray,colors.magenta)
    end
end

ROSSystemLog:write("loading default file Logos")
local defaultLogos, defaultLogosLen = {}, 6
defaultLogos[0] = makeCheckerPattern(3,3,colors.gray,colors.magenta)
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/folder.nfp")) --1 folder
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/exe.nfp")) --2 exe
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/pic.nfp")) --3 pic
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/file.nfp")) --4 file
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/music.nfp")) --5 music
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/log.nfp")) -- 6 log

UIs.mainScreen:setBackgroundImage(UIs.mainScreen:getShapeSprite(colors.black,nil,sizeX,sizeY))

if type(UIs.mainScreen.sprite) ~= "table" then
    ROSSystemLog:write("incorrect type for 'UIs.mainScreen.sprite' is type: "..type(UIs.mainScreen.sprite).." should be table","INIT-ERROR")
    error("incorrect type for 'UIs.mainScreen.sprite' is type: "..type(UIs.mainScreen.sprite).." should be table")
end
if type(MainScreenElements) ~= "table" then
    ROSSystemLog:write("incorrect type for 'MainScreenElements' is type: "..type(MainScreenElements).." should be table","INIT-ERROR")
    error("incorrect type for 'MainScreenElements' is type: "..type(MainScreenElements).." should be table")
end
if type(screenElements) ~= "table" then
    ROSSystemLog:write("incorrect type for 'screenElements' is type: "..type(screenElements).." should be table","INIT-ERROR")
    error("incorrect type for 'screenElements' is type: "..type(screenElements).." should be table")
end
fileTextDisplay:changeHologramData("")
dirTextDisplay:changeHologramData("")

if type(defaultLogos) ~= "table" then
    ROSSystemLog:write("incorrect type for 'defaultLogos' is type: "..type(defaultLogos).." should be table","INIT-ERROR")
    error("incorrect type for 'defaultLogos' is type: "..type(defaultLogos).." should be table")
end
if #defaultLogos < defaultLogosLen then 
    ROSSystemLog:write("length of 'defaultLogos' is not long enough length: "..#defaultLogos.." should be "..defaultLogosLen,"INIT-ERROR")
    error("length of 'defaultLogos' is not long enough length: "..#defaultLogos.." should be "..defaultLogosLen)
end
for i=1,#defaultLogos do
    if type(defaultLogos[i]) ~= "table" then
        ROSSystemLog:write("incorrect type for 'defaultLogos["..i.."]' is type: "..type(defaultLogos[i]).." should be table","INIT-ERROR")
        error("incorrect type for 'defaultLogos["..i.."]' is type: "..type(defaultLogos[i]).." should be table")
    end
end

local function isPic(dir)
    local ext  = settings.get("paint.default_extension")
    local ext = "."..ext

    if dir:sub(-#ext) == ext then
        return true
    end
    return false
end

local function isMusic(dir)
    local ext = ".dfpwm"

    if dir:sub(-#ext) == ext then
        return true
    end
    return false
end

local function findCenterFromPoint(x,logo,text)
    local point = x + math.floor(#logo/2)

    local returnValue = math.floor(point-(#text/2))

    if returnValue < 1 then
        returnValue = 1
    elseif returnValue+#text > sizeX then
        returnValue = sizeX-#text
    end
    return returnValue
end

local function closeRednet()
    if ROSSystemLog then ROSSystemLog:write("closing all Rednet Ports") end
    local modemNames = {}
    peripheral.find("modem",function (name,modem)
        if modem.isWireless() then
            table.insert(modemNames,name)
        end
    end)
    for i=1,#modemNames do
        rednet.close(modemNames[i])
    end
end

function MainScreenElements:new(x,y)
    local obj = {}

    obj.logo = {{}}
    obj.sprite = UIs.mainScreen.sprite:addSprite(obj.logo,nil,x,y,true)
    obj.hologram = UIs.mainScreen.hologram:addHologram("",nil,nil,nil,x,y+1)
    obj.dir = nil
    obj.name = nil
    obj.type = nil
    obj.x = x or 1
    obj.y = y or 1

    setmetatable(obj,self)
    self.__index = self

    return obj
end

function MainScreenElements:setLogo(fileDir)
    local ext  = settings.get("paint.default_extension")
    local ext = "."..ext
    if fs.isDir(fileDir) then
        if fs.exists(fileDir.."/logo"..ext) then
            local logo = UIs.mainScreen:loadImage(fileDir.."/logo"..ext)
            self.logo = {}
            for i=1,3 do
                self.logo[i] = {}
                for j=1,3 do
                    if type(logo[i]) == "table" then
                        self.logo[i][j] = logo[i][j]
                    end
                end
            end
            if #self.logo < 1 or type(self.logo[1]) ~= "table" then
                self.logo = defaultLogos[0]
            elseif (#self.logo[1] < 1) and  (#self.logo[2] < 1) and (#self.logo[3] < 1) then
                self.logo = defaultLogos[0]
            end
        elseif fs.exists(fileDir.."/executable.lua") then
            self.logo = defaultLogos[2]
        else
            self.logo = defaultLogos[1]
        end
        self.dir = fileDir
        self.type = "folder"
    elseif isMusic(fileDir) then
        self.logo = defaultLogos[5]
        self.dir = fileDir
        self.type = "music"
    elseif isPic(fileDir) then
        self.logo = defaultLogos[3]
        self.dir = fileDir
        self.type = "pic"
    elseif fileDir:sub(-4) == ".log" then
        self.logo = defaultLogos[6]
        self.dir = fileDir
        self.type = "log"
    elseif fileDir:sub(-4) == ".lua" then
        self.logo = defaultLogos[4]
        self.dir = fileDir
        self.type = "lua"
    elseif fs.exists(fileDir) then
        self.logo = defaultLogos[4]
        self.dir = fileDir
        self.type = "file"
    else
        self.logo = {{}}
        self.dir = nil
        self.type = nil
    end
    self.sprite:changeSpriteData(self.logo)
end

function MainScreenElements:resetLogo()
    self.logo = {{}}
    self.type = nil
    self.dir = nil
    self.name = ""
    self.sprite:changeSpriteData(self.logo)
    self.hologram:changeHologramData(self.name)
end

function  MainScreenElements:isSelected(x,y)
    if type(x) ~= "number" or type(y) ~= "number" then
        print(tostring(x),tostring(y))
        sleep(0.5)
    end
    if UIs.mainScreen:isCollidingRaw(x,y,self.sprite,true) then
        fileTextDisplay:changeHologramData(self.name,nil,{{colors.black,1}},findCenterFromPoint(self.x,self.logo,self.name),self.y+3,nil,true)
        if self.type == "folder" then
            if fs.exists(self.dir.."/executable.lua") then
                fileTextDisplay:changeHologramData(self.name..".exe",{{colors.white,1}},nil,findCenterFromPoint(self.x,self.logo,self.name..".exe"))
            else
                fileTextDisplay:changeHologramData(nil,{{colors.green,1}})
            end
        else
            fileTextDisplay:changeHologramData(nil,{{colors.white,1}})
        end
        UIs.mainScreen:render()
        return true
    end
end

local function setupScreen()
    local addElements = true
    local startX, startY, offsetX, offsetY = 1, 1, 1, 1
    ROSSystemLog:write("adding Screen Elements")
    while addElements do
        table.insert(screenElements,MainScreenElements:new(startX+offsetX,startY+offsetY))
        if startX+offsetX+5 >= sizeX and not (startY+offsetY+5 >= sizeY) then
            offsetY = offsetY + 4
            offsetX = startX
        elseif startY+offsetY+5 >= sizeY and startX+offsetX+5 >= sizeX then
            addElements = false
        else
            offsetX = offsetX + 4
        end
    end
    ROSSystemLog:write("added "..#screenElements.." Screen Elements")
end


local function setLogos(dir,isRefreshLoop)

    if not isRefreshLoop and LOG_EVERYTHING then ROSSystemLog:write("setting screenElements") end --only happens for main loop to stop race conditions

    for i=1,#screenElements do
        screenElements[i]:resetLogo()
    end

    local fileList = fs.list(dir)

    --Pre-Processing
    local offset = 0
    for i=1,#fileList do
        i= i - offset
        if fileList[i] then
            if fileList[i] == "rom" then
                table.remove(fileList,i)
                offset = offset + 1
            elseif fileList[i]:sub(1,1) == "." then
                table.remove(fileList,i)
                offset = offset + 1
            elseif fileList[i] == "startup.lua" then
                table.remove(fileList,i)
                offset = offset + 1
            elseif fileList[i] == "ROSLibs" then
                table.remove(fileList,i)
                offset = offset + 1
            end
        end
    end

    local j=1
    local list = {{}}
    for i=1,#fileList do
        if #list[j] > #screenElements-1 then
            j=j+1
            list[j]={}
        end
        table.insert(list[j],fileList[i])
    end
    if not isRefreshLoop then
        taskBarState.text[sizeX-2] = #list
        taskBar:changeHologramData(makeTaskBar())
    end

    maxPage = #list

    local drives = {{},{}}
    peripheral.find("drive",function (name)
        table.insert(drives[1],name)
    end)
    for k=1,#drives[1] do
        drives[2][k] = disk.getMountPath(drives[1][k])
    end

    for i=1,#screenElements do
        if list[currentPage][i] then
            screenElements[i].isDisk = false
            if #dir > 0 then
                screenElements[i]:setLogo(dir.."/"..list[currentPage][i])
                screenElements[i].name = list[currentPage][i]
            else
                screenElements[i]:setLogo(list[currentPage][i])
                screenElements[i].name = list[currentPage][i]
            end
            if #dir < 1 and string.find(screenElements[i].name,"disk",nil,true) then
                if string.find(screenElements[i].name,"copy",nil,true) then
                    fs.delete(screenElements[i].dir)
                else
                    local driveID
                    for k=1,#drives[1] do
                        if screenElements[i].name == drives[2][k] then
                            driveID = k
                            break
                        end
                    end
                    ROSSystemLog:write(textutils.serialise(drives,{compact = true}))
                    if drives[1][driveID] then
                        screenElements[i].name = disk.getLabel(drives[1][driveID]).."("..disk.getID(drives[1][driveID])..")"
                    else
                        screenElements[i].name = drives[2][driveID] or "failed to load"
                    end
                    screenElements[i].isDisk = true
                end
            end
            if screenElements[i].type == "folder" then
                if fs.exists(screenElements[i].dir.."/executable.lua") then
                    local displayName, displayColorTable = screenElements[i].name:sub(1,2), {{colors.white,1}}
                    if fs.exists(screenElements[i].dir.."/title.json") then
                        local temp = io.open(screenElements[i].dir.."/title.json","r")
                        local content = temp:read("a")
                        temp:close()

                        local jsonTable = textutils.unserialiseJSON(content)
                        if type(jsonTable) == "table" then
                            if type(jsonTable.label) == "string" then displayName = jsonTable.label:sub(1,2) end
                            if type(jsonTable.name) == "string" then screenElements[i].name = jsonTable.name end
                            if type(jsonTable.color) == "table" then
                                for i=1,#jsonTable.color do
                                    if type(jsonTable.color[i]) == "table" and colors[jsonTable.color[i][1]] then
                                        displayColorTable[i] = {colors[jsonTable.color[i][1]],jsonTable.color[i][2]}
                                    end
                                end
                            end
                        end
                    end

                    table.insert(displayColorTable,{colors.red,3})

                    screenElements[i].hologram:changeHologramData(displayName.."e",displayColorTable)
                else
                    local displayName, displayColorTable = screenElements[i].name:sub(1,3), {{colors.green,1}}
                    if fs.exists(screenElements[i].dir.."/title.json") then
                        local temp = io.open(screenElements[i].dir.."/title.json","r")
                        local content = temp:read("a")
                        temp:close()

                        local jsonTable = textutils.unserialiseJSON(content)
                        if type(jsonTable) == "table" then
                            if type(jsonTable.label) == "string" then displayName = jsonTable.label:sub(1,3) end
                            if type(jsonTable.name) == "string" then screenElements[i].name = jsonTable.name end
                            if type(jsonTable.color) == "table" then
                                for i=1,#jsonTable.color do
                                    if type(jsonTable.color[i]) == "table" and colors[jsonTable.color[i][1]] then
                                        displayColorTable[i] = {colors[jsonTable.color[i][1]],jsonTable.color[i][2]}
                                    end
                                end
                            end
                        end
                    end
                    screenElements[i].hologram:changeHologramData(displayName,displayColorTable)
                end
            elseif screenElements[i].type == "pic" then
                screenElements[i].hologram:changeHologramData(screenElements[i].name:sub(1,2)..screenElements[i].name:sub(-1),{{colors.white,1},{colors.magenta,3}})
            elseif screenElements[i].type == "music" then
                screenElements[i].hologram:changeHologramData(screenElements[i].name:sub(1,2)..screenElements[i].name:sub(-1),{{colors.white,1},{colors.yellow,3}})
            elseif screenElements[i].type == "log" then
                screenElements[i].hologram:changeHologramData(screenElements[i].name:sub(1,2).."g",{{colors.white,1},{colors.orange,3}})
            elseif screenElements[i].type == "lua" then
                screenElements[i].hologram:changeHologramData(screenElements[i].name:sub(1,2).."l",{{colors.white,1},{colors.blue,3}})
            else
                screenElements[i].hologram:changeHologramData(screenElements[i].name:sub(1,2)..screenElements[i].name:sub(-1),{{colors.white,1},{colors.lightGray,3}})
            end
        end
    end
    if not isRefreshLoop then
        fileTextDisplay:changeHologramData("",nil,nil,1,1)
        taskBar:changeHologramData(resetTaskBar(),ColorTaskBar(),ColorTaskBar(true))
        taskBarState.state=nil
    end

    if #dir > sizeX and not isRefreshLoop then
        dirTextDisplay:changeHologramData("..."..dir:sub(#dir - (sizeX-4),#dir).."/",{{colors.white,1}})
    elseif #dir > 0 and not isRefreshLoop then
        dirTextDisplay:changeHologramData(dir.."/",{{colors.white,1}})
    elseif not isRefreshLoop then
        dirTextDisplay:changeHologramData("",{{colors.white,1}})
    end

    term.setCursorBlink(false)
    UIs.mainScreen:render()
end

local function resetScreen()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end

local function showErrorMessage(message, elementNum)
    message = tostring(message)
    ROSSystemLog:write(message,"ERRORecp")
    local eraseLen = 0
    if #screenElements[elementNum].name > #message then
        eraseLen = #screenElements[elementNum].name - #message
    end
    fileTextDisplay:changeHologramData(string.rep(" ",math.ceil(eraseLen/2))..message..string.rep(" ",math.ceil(eraseLen/2)),{{colors.red,1}},nil,findCenterFromPoint(screenElements[elementNum].x,screenElements[elementNum].logo,message..string.rep(" ",math.ceil(eraseLen/2))))
    fileTextDisplay:render()
    if navigatorActive then sleep(0.1) os.pullEvent("key") else os.pullEvent("mouse_click") end
end

local openedFile = false
local function execute(...)
    openedFile = true
    local inputs = {...}
    local str = ""
    for i=1,#inputs do
        str = str .. tostring(inputs[i])
        if i~=#inputs then
            str = str ..", "
        end
    end
    ROSSystemLog:write("execute function called with args: "..str)

    local startTime = os.clock()
    resetScreen()
    local result = shell.run(table.unpack(inputs))
    if not result then
        sleep(0.2)
        term.setCursorPos(1,sizeY-2)
        term.setBackgroundColor(colors.black)
        ROSSystemLog:write("the executed Program has run into an unexpected Error","ERRORecp")
        printError("the Program has run into an unexpected Error")
        print()
        term.write("do anything to return to desktop"..string.rep(" ",sizeX-32))
        local event = {}
        while not (event[1] == "key" or event[1] == "char" or event[1] == "mouse_click") do
            event = {os.pullEvent()}
        end
    end
    local endTime = os.clock()
    if (endTime-startTime) < 0.5 and result then
        sleep(0.2)
        term.setCursorPos(1,sizeY)
        term.setBackgroundColor(colors.black)
        term.write("do anything to return to desktop"..string.rep(" ",sizeX-32))
        local event = {}
        while not (event[1] == "key" or event[1] == "char" or event[1] == "mouse_click") do
            event = {os.pullEvent()}
        end
    end
    ROSSystemLog:write("finished execution")
    fileTextDisplay:changeHologramData("",nil,nil,1,1)
    UIs.mainScreen:render()
    openedFile = false
end
_G.SPEAKERS={stopAudio = false}
local usedSpeakers, SpeakerScheduler, activeAudioBrokers = {}, {}, 0

SpeakerScheduler.allocateSpeaker = function()
    local index
    local speaker = peripheral.find("speaker",function (name)
        if not index then
            for i=1,#usedSpeakers do
                if name == usedSpeakers[i] then return false end
            end
            --term.setCursorPos(1,4)
            --print("giving out: "..name)
            table.insert(usedSpeakers, name)
            index = name
            return true
        end
    end)
    return speaker, index
end

SpeakerScheduler.deAllocateSpeaker = function(item)
    if not item then return end
    --term.setCursorPos(1,4)
    --print("taking back: "..item)
    for i=#usedSpeakers, 1, -1 do
        if item == usedSpeakers[i] then table.remove(usedSpeakers,i) return end
    end
    if activeAudioBrokers < 1 then
        usedSpeakers = {}
        activeAudioBrokers = 0
    end
end

local function AudioDataBroker(dir,elementNum)
    SPEAKERS.stopAudio = false

    local speaker, speakerSide = SpeakerScheduler.allocateSpeaker()

    if not dfpwmSuccess then
        showErrorMessage("ccTweaked version too low!", elementNum)
    elseif not speaker then
        showErrorMessage("no speaker Available!", elementNum)
    end
    if not (dfpwmSuccess and speaker) then
        if speakerSide then
            SpeakerScheduler.deAllocateSpeaker(speakerSide)
        end
        return
    end

    activeAudioBrokers = activeAudioBrokers + 1
    local decoder = dfpwm.make_decoder()
    for chunk in io.lines(dir, 3072) do
        local buffer = decoder(chunk)
        --term.setCursorPos(1,1)
        --print(textutils.serialise(usedSpeakers,{compact = true}))
        --print(speakerSide)
        --print(activeAudioBrokers)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
            if SPEAKERS.stopAudio then
                activeAudioBrokers = activeAudioBrokers - 1
                SpeakerScheduler.deAllocateSpeaker(speakerSide)
                return
            end
        end
    end
    activeAudioBrokers = activeAudioBrokers - 1
    SpeakerScheduler.deAllocateSpeaker(speakerSide)
end

local navigatorSelected = 1
local function useNavigator(event)
    if event[2] == keys.right and navigatorSelected < #screenElements then
        if screenElements[navigatorSelected+1].dir then
            navigatorSelected = navigatorSelected + 1
            event[1] = "mouse_click"
            event[2] = 1
            event[3] = screenElements[navigatorSelected].x or screenElements[1].x
            event[4] = screenElements[navigatorSelected].y or screenElements[1].y
        end
    elseif event[2] == keys.left and navigatorSelected > 1 then
        navigatorSelected = navigatorSelected - 1
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = screenElements[navigatorSelected].x or screenElements[1].x
        event[4] = screenElements[navigatorSelected].y or screenElements[1].y
    elseif event[2] == keys.up or event[2] == keys.enter then
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = screenElements[navigatorSelected].x or screenElements[1].x
        event[4] = screenElements[navigatorSelected].y or screenElements[1].y
    elseif event[2] == keys.down or event[2] == keys.rightShift then
        event[1] = "mouse_click"
        event[2] = 2
        event[3] = screenElements[navigatorSelected].x or screenElements[1].x
        event[4] = screenElements[navigatorSelected].y or screenElements[1].y
    elseif event[2] == keys.m then
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = 7
        event[4] = sizeY
    elseif event[2] == keys.r then
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = 9
        event[4] = sizeY
    elseif event[2] == keys.c then
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = 11
        event[4] = sizeY
    elseif event[2] == keys.d then
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = 13
        event[4] = sizeY
    end
    event[2] = event[2] or 1
    event[3] = event[3] or screenElements[navigatorSelected].x
    event[4] = event[4] or screenElements[navigatorSelected].y

    sleep(0.2)
    return event
end

local function getOrigin(dir)
    local testString = dir
    while true do
        testString = testString:sub(1,#testString-1)
        if testString:sub(-1) == "/" or #testString == 0 then
            return testString:sub(1,#testString-1)
        elseif #dir > 1000 then
            sleep(0.01)
        end
    end
end

local function getNameWithoutExtension(name)
    local testString, extension = name, ""
    while true do
        extension = testString:sub(-1)..extension
        testString = testString:sub(1,#testString-1)
        if #testString == 0 then
            return name, ""
        elseif testString:sub(-1) == "." then
            return testString:sub(1,#testString-1), extension
        elseif #name > 50 then
            sleep(0.01)
        end
    end
end

local function renameFile(obj)
    fileTextDisplay:changeHologramData(string.rep(" ",#obj.name))
    fileTextDisplay:render()
    term.setCursorPos(1,fileTextDisplay.y)
    term.setBackgroundColor(colors.black)
    term.write(obj.name.." -> ")
    local newFileName = io.read()
    newFileName = string.gsub(newFileName,"/","")
    newFileName = string.gsub(newFileName," ","_")
    if newFileName:sub(1,1) == "." then
        newFileName = newFileName:sub(2,#newFileName)
    end
    return newFileName
end

local function changeTaskBarTextToString(startPos,text)
    for i=1,#text do
        taskBarState.text[startPos+(i-1)] = text:sub(i,i)
    end
end

local currentShownDir, terminated  = "", false
local function runScreen(isSubProcess)
    setLogos(currentShownDir)
    UIs.mainScreen:render()

    local selected
    local didAction, startedSubProcess =  false, true

    if navigatorActive then
        selected = screenElements[1]
        screenElements[1]:isSelected(2,2)
    end

    while true do

        local event = {os.pullEvent()}
        if (not startedSubProcess) and isSubProcess then return end
        if navigatorActive then
            event = useNavigator(event)
        end

        if event[1] == "mouse_click" then
            didAction = false
            if (event[3] == sizeX and event[4] == sizeY) and currentPage < maxPage then
                selected = nil
                currentPage=currentPage+1
                if LOG_EVERYTHING then ROSSystemLog:write("changed page to: "..currentPage) end
                setLogos(currentShownDir)
            elseif (event[3] == sizeX-1 and event[4] == sizeY) and currentPage > 1 then
                selected = nil
                currentPage=currentPage-1
                if LOG_EVERYTHING then ROSSystemLog:write("changed page to: "..currentPage) end
                setLogos(currentShownDir)
            elseif event[3] == sizeX-6 and event[4] == sizeY then
                openedFile = true
                resetTaskBar()
                changeTaskBarTextToString(6,"[E]Exit")
                changeTaskBarTextToString(13,"[F]+File")
                changeTaskBarTextToString(21,"[O]+Dir")
                taskBar:changeHologramData(makeTaskBar(),ColorTaskBar(false,{{colors.red,6},{colors.white,13},{colors.green,21},{colors.white,28}}),ColorTaskBar(true))
                for i=1,#screenElements do
                    screenElements[i]:resetLogo()
                end
                fileTextDisplay:changeHologramData("")
                UIs.mainScreen:render()
                local addType, waitForInput = nil, true
                while waitForInput do
                    local internalEvent = {os.pullEvent()}
                    if internalEvent[1] == "key" or internalEvent[1] == "mouse_click" then
                        if (internalEvent[1]=="key" and internalEvent[2]==keys.f) or (internalEvent[1]=="mouse_click" and internalEvent[4]==sizeY and (internalEvent[3]>=13 and internalEvent[3]<=19)) then
                            waitForInput = false
                            addType = "file"
                        elseif (internalEvent[1]=="key" and internalEvent[2]==keys.o) or (internalEvent[1]=="mouse_click" and internalEvent[4]==sizeY and (internalEvent[3]>=21 and internalEvent[3]<=27)) then
                            waitForInput = false
                            addType = "folder"
                        elseif (internalEvent[1]=="key" and internalEvent[2]==keys.e) or (internalEvent[1]=="mouse_click" and internalEvent[4]==sizeY and (internalEvent[3]>=6 and internalEvent[3]<=12)) then
                            waitForInput = false
                        end
                    end
                    sleep(0.1)
                end
                if addType == "file" then
                    screenElements[1].logo = defaultLogos[4]
                    screenElements[1].sprite:changeSpriteData(defaultLogos[4])
                elseif addType == "folder" then
                    screenElements[1].logo = defaultLogos[1]
                    screenElements[1].sprite:changeSpriteData(defaultLogos[1])
                end
                local fileName
                if addType then
                    UIs.mainScreen:render()
                    term.setCursorPos(1,screenElements[1].y+3)
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.white)
                    term.write("Name:")
                    parallel.waitForAny(function ()
                        fileName = io.read()
                    end,function ()
                        local internalEvent = {}
                        while not (internalEvent[1] == "mouse_click" and internalEvent[4] ~= 5) do
                            internalEvent = {os.pullEvent()}
                        end
                        fileName = ""
                    end)
                    fileName = string.gsub(fileName,"/","")
                    fileName = string.gsub(fileName," ","_")
                    if fileName:sub(1,1) == "." then
                        fileName = fileName:sub(2,#fileName)
                    end
                end
                if addType and #fileName > 0 and fileName ~= "ROSLibs" then
                    local preDir = currentShownDir
                    if preDir ~= "" then
                        preDir = preDir.."/"
                    end
                    if addType == "file" then
                        if fs.exists(preDir..fileName) then
                            local suffix = 1
                            local name, extension = getNameWithoutExtension(fileName)
                            while fs.exists(preDir..name.."-"..suffix.."."..extension) do
                                suffix = suffix + 1
                            end
                            fileName = name.."-"..suffix.."."..extension
                        end
                        local temp = io.open(preDir..fileName,"w")
                        temp:close()
                        ROSSystemLog:write("adding file: "..preDir..fileName)
                    elseif addType == "folder" then
                        if fs.exists(preDir..fileName) then
                            local suffix = 1
                            while fs.exists(preDir..fileName.."-"..suffix) do
                                suffix = suffix + 1
                            end
                            fileName = fileName.."-"..suffix
                        end
                        fs.makeDir(preDir..fileName)
                        ROSSystemLog:write("added folder: "..preDir..fileName)
                    end
                end
                setLogos(currentShownDir)
                taskBarState.state = nil
                openedFile = false
                selected = nil
            elseif (event[3] == 7 and event[4] == sizeY) and taskBarState.state == "fileOptions" then
                openedFile = true
                dirTextDisplay:changeHologramData("Move "..selected.name.." to where?")
                local isFirst = true
                for i=1,#screenElements do
                    if isFirst and currentShownDir ~= "" and not (screenElements[i].type == "folder" or screenElements[i] == selected) then
                        screenElements[i]:setLogo(currentShownDir.."/..")
                        screenElements[i].name = "Previous Directory"
                        screenElements[i].hologram:changeHologramData("..",{{colors.green,1}})
                        isFirst = false
                    elseif not (screenElements[i].type == "folder" or screenElements[i] == selected) then
                        screenElements[i]:resetLogo()
                    end
                end
                resetTaskBar()
                changeTaskBarTextToString(7,"[B]Back")
                taskBar:changeHologramData(makeTaskBar(),ColorTaskBar(false,{{colors.red,7},{colors.white,14}}),ColorTaskBar(true))
                UIs.mainScreen:render()
                local fileName, directoryName =selected.name, nil --file stuff
                local internalEvent, moved = {}, false -- functional stuff
                local currentLocation = getOrigin(selected.dir)
                while not moved do
                    internalEvent = {os.pullEvent()}
                    if (internalEvent[1]=="key" and (internalEvent[2]==keys.b or internalEvent[2]==keys.backspace)) or (internalEvent[1]=="mouse_click" and internalEvent[4]==sizeY and (internalEvent[3]>=7 and internalEvent[3]<=13)) then
                        moved =  true
                    elseif navigatorActive or (internalEvent[1] == "key" and internalEvent[2] == keys.tab) then
                        term.setCursorPos(1,5)
                        term.setTextColor(colors.white)
                        term.setBackgroundColor(colors.black)
                        term.write("move where?:")
                        local location = io.read() 
                        if fs.exists(currentLocation.."/"..location) and not fs.isReadOnly(currentLocation.."/"..location) then
                            moved = true
                            fs.delete(currentLocation.."/"..location.."/"..selected.name)
                            fs.move(selected.dir,currentLocation.."/"..location.."/"..selected.name)
                        end
                    elseif type(internalEvent[3])=="number" and type(internalEvent[4])=="number" then
                        for i=1,#screenElements do
                            if screenElements[i] ~= selected and screenElements[i].dir and screenElements[i]:isSelected(internalEvent[3],internalEvent[4]) then
                                directoryName = screenElements[i].name
                                fs.delete(screenElements[i].dir.."/"..selected.name)
                                fs.move(selected.dir,screenElements[i].dir.."/"..selected.name)
                                setLogos(currentShownDir)
                                dirTextDisplay:changeHologramData("Moved "..fileName.." to "..directoryName)
                                dirTextDisplay:render()
                                moved = true
                            end
                        end
                    end
                end
                ROSSystemLog:write("moved file: "..fileName.." to: "..directoryName)
                setLogos(currentShownDir)
                selected = nil
                taskBarState.state = nil
            elseif (event[3] == 9 and event[4] == sizeY) and taskBarState.state == "fileOptions" then
                local oldName = selected.dir
                openedFile = true
                local newFileName
                taskBar:changeHologramData(resetTaskBar(),nil,ColorTaskBar(true))
                taskBar:render()
                parallel.waitForAny(function ()
                    newFileName = renameFile(selected)
                end,function ()
                    local internalEvent = {}
                    while not (internalEvent[1] == "mouse_click" and internalEvent[4] ~= fileTextDisplay.y) do
                        internalEvent = {os.pullEvent()}
                    end
                    newFileName = ""
                end)
                if #newFileName ~= 0 then
                    newFileName = getOrigin(selected.dir).."/"..newFileName
                    if selected.dir ~= newFileName and fs.exists(newFileName) then
                        local suffix = 1
                        while fs.exists(newFileName.."-"..suffix) do
                            suffix = suffix + 1
                        end
                        newFileName = newFileName.."-"..suffix
                    end
                    ROSSystemLog:write("renamed file: "..oldName.." to: "..newFileName)
                    fs.move(selected.dir,newFileName)
                end
                openedFile = false
                selected = nil
                taskBarState.state = nil
                setLogos(currentShownDir)
            elseif (event[3] == 11 and event[4] == sizeY) and taskBarState.state == "fileOptions" then
                local newFileName, extension = getNameWithoutExtension(selected.dir)
                if fs.exists(newFileName.."-copy".."."..extension) then
                    local orgName = newFileName
                    local suffix = 1
                    newFileName = newFileName.."-copy"..suffix.."."..extension
                    while fs.exists(newFileName) do
                        suffix = suffix + 1
                        newFileName = orgName.."-copy"..suffix.."."..extension
                    end
                else
                    newFileName = newFileName.."-copy".."."..extension
                end
                ROSSystemLog:write("copied file: "..selected.dir)
                fs.copy(selected.dir,newFileName)
                selected = nil
                taskBarState.state = nil
                setLogos(currentShownDir)
            elseif (event[3]== 13 and event[4] == sizeY) and taskBarState.state == "fileOptions" then
                fs.delete(selected.dir)
                ROSSystemLog:write("Deleted file: "..selected.dir)
                selected = nil
                taskBarState.state = nil
                setLogos(currentShownDir)
                sleep(0.2)
            elseif (event[3]==7 and event[4]==sizeY) and taskBarState.state == "driveOptions" then
                local drives = {{},{}}
                peripheral.find("drive",function(name)
                    table.insert(drives[1],name)
                end)
                for i=1,#drives[1] do
                    drives[2][i] = disk.getMountPath(drives[1][i])
                end
                for i=1,#drives[1] do
                    if drives[2][i] == selected.dir then
                        disk.eject(drives[1][i])
                        break
                    end
                end
            else
                for i=1,#screenElements do

                    if screenElements[i]:isSelected(event[3],event[4]) and not (selected == screenElements[i]) then
                        didAction = true
                        if not screenElements[i].isDisk then
                            taskBarState.state="fileOptions"
                            taskBarState.text[7]="M"
                            taskBarState.text[9]="R"
                            taskBarState.text[11] = "C"
                            taskBarState.text[13] = "D"
                            taskBar:changeHologramData(makeTaskBar(),nil,ColorTaskBar(true,{{colors.darkGray,7},{colors.red,13},{colors.lightGray,14}}))
                            taskBar:render()
                        elseif screenElements[i].isDisk then
                            taskBarState.state="driveOptions"
                            taskBarState.text[7]="E"
                            taskBarState.text[9]=" "
                            taskBarState.text[11] = " "
                            taskBarState.text[13] = " "
                            taskBar:changeHologramData(makeTaskBar(),ColorTaskBar(nil,{{colors.red,1}}),ColorTaskBar(true,{{colors.darkGray,7}}))
                            taskBar:render()
                        else
                            taskBar:changeHologramData(resetTaskBar(),ColorTaskBar(),ColorTaskBar(true))
                            taskBar:render()
                        end
                        selected = screenElements[i]
                    elseif screenElements[i]:isSelected(event[3],event[4]) and (selected == screenElements[i]) then
                        didAction = true
                        if event[2] == 1 then
                            selected = nil
                            if screenElements[i].type == "folder" then
                                if fs.exists(screenElements[i].dir.."/executable.lua") then
                                    execute(screenElements[i].dir.."/executable.lua")
                                elseif fs.exists(screenElements[i].dir) then
                                    currentShownDir = screenElements[i].dir
                                    if navigatorActive then
                                        selected = screenElements[1]
                                        screenElements[1]:isSelected(2,2)
                                        navigatorSelected = 1
                                    end
                                    if LOG_EVERYTHING then ROSSystemLog:write("redirected to: /"..currentShownDir) end
                                end
                            elseif screenElements[i].type == "pic" and term.isColor() then
                                execute("paint",screenElements[i].dir)
                            elseif screenElements[i].type == "pic" and not term.isColor() then
                                showErrorMessage("Can't use paint!",i)
                            elseif screenElements[i].type == "music" then
                                if peripheral.find("speaker") then
                                    ROSSystemLog:write("playing sound: "..screenElements[i].dir)
                                    parallel.waitForAll(function ()
                                        startedSubProcess = true
                                        AudioDataBroker(screenElements[i].dir,i)
                                    end,function () runScreen(true) end)
                                    ROSSystemLog:write("finished playing music")
                                else
                                    showErrorMessage("No Speaker Attached!", i)
                                end
                            elseif screenElements[i].type == "lua" then
                                execute(screenElements[i].dir)
                            else
                                execute("edit",screenElements[i].dir)
                            end
                        elseif event[2] == 2 then
                            selected = nil
                            if screenElements[i].type == "folder" then
                                currentShownDir = screenElements[i].dir
                                if LOG_EVERYTHING then ROSSystemLog:write("redirected to: /"..currentShownDir) end
                            else
                                execute("edit",screenElements[i].dir)
                            end
                        end
                        setLogos(currentShownDir)
                    end
                end
            end
        elseif event[1] == "key" or event[1] == "key_up" then
            if currentShownDir ~= "" and event[2] == keys.left then
                if navigatorActive then
                    selected = screenElements[1]
                    screenElements[1]:isSelected(2,2)
                    navigatorSelected = 1
                else
                    selected = nil
                end
                currentShownDir = getOrigin(currentShownDir)
                if LOG_EVERYTHING then ROSSystemLog:write("redirected to: /"..currentShownDir) end
                currentPage = 1
                setLogos(currentShownDir)
            elseif event[2] == keys.zero then
                closeRednet()
                ROSSystemLog:close()
                os.shutdown()
            elseif event[2] == keys.numPadEnter then
                terminated = true
                return
            elseif event[2] == keys.q then
                SPEAKERS.stopAudio = true
                ROSSystemLog:write("stopping all music")
            elseif event[2] == keys.tab then
                if navigatorActive then
                    navigatorActive = false
                    dirTextDisplay:changeHologramData(string.rep(" ",#dirTextDisplay.text[1]))
                    dirTextDisplay:changeHologramData("Navigator OFF",{{colors.red,11}})
                    dirTextDisplay:render()
                else
                    navigatorActive = true
                    dirTextDisplay:changeHologramData(string.rep(" ",#dirTextDisplay.text[1]))
                    dirTextDisplay:changeHologramData("Navigator ON ",{{colors.green,11}})
                    dirTextDisplay:render()
                end
                sleep(0.2)
            end
        end
        if selected and not didAction then
            selected = nil
            taskBar:changeHologramData(resetTaskBar(),ColorTaskBar(),ColorTaskBar(true))
            taskBarState.state=nil
            fileTextDisplay:changeHologramData("",nil,nil,1,1)
            UIs.mainScreen:render()
        elseif not didAction and event[1] == "mouse_click" and event[2] == 2 and currentShownDir ~= "" and (type(event[3])=="number" and type(event[4])=="number") then
            if navigatorActive then
                selected = screenElements[1]
                screenElements[1]:isSelected(2,2)
                navigatorSelected = 1
            else
                selected = nil
            end
            currentShownDir = getOrigin(currentShownDir)
            if LOG_EVERYTHING then ROSSystemLog:write("redirected to: /"..currentShownDir) end
            currentPage = 1
            setLogos(currentShownDir)
        end
        sleep(0.1)
        if fs.exists(".error.txt") then fs.delete(".error.txt") end
    end
end

local function updateDesktop()
    while true do
        sleep(2.5)
        if not openedFile then
            setLogos(currentShownDir,true)
        end
    end
end
setupScreen()
ROSSystemLog:write("collecting Background Scripts")
ROSSystemLog:write("filtering system/BGScripts Folder for lua scripts")
local BGSList = fs.list("system/BGScripts")
local offset = 0
for i=1,#BGSList do
    i=i-offset
    if BGSList[i]:sub(-4) ~= ".lua" then
        table.remove(BGSList,i)
        offset = offset + 1
    end
end
offset = nil
ROSSystemLog:write("cleaning Background Scripts")
for i=1,#BGSList do
    local content = {}
    local BGScript = io.open("system/BGScripts/"..BGSList[i],"r")
    local lines = 0
    if BGScript then
        local lastOutput = ""
        while lastOutput do
            local text = BGScript:read("l")
            if text then
                local orgText = text
                local comStart = string.find(text,"--",nil,true)
                if comStart then text = string.sub(text,1,comStart-1) end
                if #text > 1 then
                    if string.find(text,"os.reboot",nil,true) then
                        text = "--removed this line because of suspected os.reboot call | "..orgText
                        lines = lines + 1
                    elseif string.find(text,"os.shutdown",nil,true) then
                        text = "--removed this line because of suspected os.shutdown call | "..orgText
                        lines = lines + 1
                    end
                    table.insert(content,text)
                else
                    table.insert(content,orgText)
                end
            end
            lastOutput = text
        end
        BGScript:close()
        ROSSystemLog:write("cleaned "..lines.." lines from script: system/BGScripts/"..BGSList[i])
        local BGScript = io.open("system/BGScripts/"..BGSList[i],"w")
        for i=1,#content do
            BGScript:write(content[i])
            if i ~= #content then BGScript:write("\n") end
        end
        BGScript:close()
    end
end
ROSSystemLog:write("converting Background Scripts to function")
local BGScripts = {}

for i=1,#BGSList do
    table.insert(BGScripts,function()
        local processDir = "system/BGScripts/"..BGSList[i]
        local fn, err
        if not setfenv then
            fn, err = loadfile(processDir,nil,_ENV)
        else
            fn, err = loadfile(processDir)
            if fn then fn = setfenv(fn,_ENV) end
        end
        if type(fn) ~= "function" then
            ROSSystemLog:write("PROCESS-LOADING-ERROR:\n"..string.rep("    ",11).."FILE:"..processDir.."\n"..string.rep("    ",11).."ERROR:"..err,"SUB-PROCESS-ERROR")
        else
            xpcall(fn,function(err) ROSSystemLog:write("PROCESS-RUNTIME-ERROR:\n"..string.rep("    ",11).."FILE:"..processDir.."\n"..string.rep("    ",11).."ERROR:"..err,"SUB-PROCESS-ERROR") end)
        end
    end)
end
ROSSystemLog:write("created "..#BGScripts.." sub-Process Function(s)")

local function runSubProcesses()
    parallel.waitForAll(table.unpack(BGScripts))
    ROSSystemLog:write("all sub-Processes finished")
    while true do
        sleep(600)
    end
end

local erroredOut
parallel.waitForAny(runScreen,updateDesktop,runSubProcesses)
local temp = io.open(".terminate.txt","w")
temp:close()

closeRednet()

resetScreen()

if terminated then
    print("You're now outside of the RedOS and are using CraftOS (built-in)")
    print()
    print("enter 'startup' or restart the computer to restart RedOS")
end
