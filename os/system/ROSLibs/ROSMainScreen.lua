MainScreenElements = {}
MainScreenElements.__index = MainScreenElements

if UIs.mainScreen then os.reboot() end
UIs.mainScreen = graphicLib.Frame:init("RedOS")

local screenELements = {}

local sizeX, sizeY = term.getSize()

local fileTextDisplay = UIs.mainScreen.hologram:addHologram("",nil,nil,nil,1,1,false,nil,true)
local dirTextDisplay = UIs.mainScreen.hologram:addHologram("",nil,nil,nil,1,1,false,false,true)
local taskBar = UIs.mainScreen.hologram:addHologram("ROS 0"..string.rep(" ",sizeX-5),{{colors.red,1},{colors.yellow,2},{colors.red,5},{colors.white,6}},{{colors.lightGray,1}},nil,1,sizeY)

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

local defaultLogos, defaultLogosLen = {}, 5
defaultLogos[0] = makeCheckerPattern(3,3,colors.gray,colors.magenta)
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/folder.nfp"))
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/exe.nfp"))
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/pic.nfp"))
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/file.nfp"))
table.insert(defaultLogos,loadImage("system/ROSPics/fileLogos/music.nfp"))

UIs.mainScreen:setBackgroundImage(UIs.mainScreen:getShapeSprite(colors.black,nil,sizeX,sizeY))

local function checkNeededStuff()
    if type(UIs.mainScreen.sprite) ~= "table" then error("incorrect type for 'UIs.mainScreen.sprite' is type: "..type(UIs.mainScreen.sprite).." should be table") end
    if type(MainScreenElements) ~= "table" then error("incorrect type for 'MainScreenElements' is type: "..type(MainScreenElements).." should be table") end
    if type(screenELements) ~= "table" then error("incorrect type for 'screenELements' is type: "..type(screenELements).." should be table") end
    fileTextDisplay:changeHologramData("")
    dirTextDisplay:changeHologramData("")

    if type(defaultLogos) ~= "table" then error("incorrect type for 'defaultLogos' is type: "..type(defaultLogos).." should be table") end
    if #defaultLogos < defaultLogosLen then error("length of 'defaultLogos' is not long enough length: "..#defaultLogos.." should be "..defaultLogosLen) end
    for i=1,#defaultLogos do
        if type(defaultLogos[i]) ~= "table" then error("incorrect type for 'defaultLogos["..i.."]' is type: "..type(defaultLogos[i]).." should be table") end
    end
end

checkNeededStuff()

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

--[[local function getBiggestIndex(matrix)
    local maxIndexX, maxIndexY = #matrix,1
    for i=1,maxIndexX do
        if maxIndexY < #matrix[i] then
            maxIndexY = #matrix[i]
        end
    end

    return maxIndexX, maxIndexY
end]]

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
    while addElements do
        table.insert(screenELements,MainScreenElements:new(startX+offsetX,startY+offsetY))
        if startX+offsetX+5 >= sizeX and not (startY+offsetY+5 >= sizeY) then
            offsetY = offsetY + 4
            offsetX = startX
        elseif startY+offsetY+5 >= sizeY and startX+offsetX+5 >= sizeX then
            addElements = false
        else
            offsetX = offsetX + 4
        end
        --print(offsetX,offsetY)
    end
end

local function setLogos(dir,isRefreshLoop)
    for i=1,#screenELements do
        screenELements[i]:resetLogo()
    end

    local fileList = fs.list(dir)

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

    for i=1,#fileList do
        if screenELements[i] then
            if #dir > 0 then
                screenELements[i]:setLogo(dir.."/"..fileList[i])
                screenELements[i].name = fileList[i]
            else
                screenELements[i]:setLogo(fileList[i])
                screenELements[i].name = fileList[i]
            end
            if screenELements[i].type == "folder" then
                if fs.exists(screenELements[i].dir.."/executable.lua") then
                    local displayName, displayColorTable = screenELements[i].name:sub(1,2), {{colors.white,1}}
                    if fs.exists(screenELements[i].dir.."/title.json") then
                        local temp = io.open(screenELements[i].dir.."/title.json","r")
                        local content = temp:read("a")
                        temp:close()

                        local jsonTable = textutils.unserialiseJSON(content)
                        if type(jsonTable) == "table" then
                            if type(jsonTable.name) == "string" then displayName = jsonTable.name:sub(1,2) end
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

                    screenELements[i].hologram:changeHologramData(displayName.."e",displayColorTable)
                else
                    local displayName, displayColorTable = screenELements[i].name:sub(1,3), {{colors.green,1}}
                    if fs.exists(screenELements[i].dir.."/title.json") then
                        local temp = io.open(screenELements[i].dir.."/title.json","r")
                        local content = temp:read("a")
                        temp:close()

                        local jsonTable = textutils.unserialiseJSON(content)
                        if type(jsonTable) == "table" then
                            if type(jsonTable.name) == "string" then displayName = jsonTable.name:sub(1,3) end
                            if type(jsonTable.color) == "table" then
                                for i=1,#jsonTable.color do
                                    if type(jsonTable.color[i]) == "table" and colors[jsonTable.color[i][1]] then
                                        displayColorTable[i] = {colors[jsonTable.color[i][1]],jsonTable.color[i][2]}
                                    end
                                end
                            end
                        end
                    end
                    screenELements[i].hologram:changeHologramData(displayName,displayColorTable)
                end
            elseif screenELements[i].type == "pic" then
                screenELements[i].hologram:changeHologramData(screenELements[i].name:sub(1,2)..screenELements[i].name:sub(-1),{{colors.white,1},{colors.magenta,3}})
            elseif screenELements[i].type == "music" then
                screenELements[i].hologram:changeHologramData(screenELements[i].name:sub(1,2)..screenELements[i].name:sub(-1),{{colors.white,1},{colors.yellow,3}})
            else
                screenELements[i].hologram:changeHologramData(screenELements[i].name:sub(1,2)..screenELements[i].name:sub(-1),{{colors.white,1},{colors.lightGray,3}})

                if screenELements[i].name:sub(-4) == ".lua" then
                    screenELements[i].hologram:changeHologramData(screenELements[i].name:sub(1,2).."l",{{colors.white,1},{colors.blue,3}})
                end
            end
        end
    end
    if not isRefreshLoop then fileTextDisplay:changeHologramData("",nil,nil,1,1) end

    if #dir > sizeX and not isRefreshLoop then
        dirTextDisplay:changeHologramData("..."..dir:sub(#dir - (sizeX-4),#dir).."/",{{colors.white,1}})
    elseif #dir > 0 and not isRefreshLoop then
        dirTextDisplay:changeHologramData(dir.."/",{{colors.white,1}})
    elseif not isRefreshLoop then
        dirTextDisplay:changeHologramData("",{{colors.white,1}})
    end

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
    local eraseLen = 0
    if #screenELements[elementNum].name > #message then
        eraseLen = #screenELements[elementNum].name - #message
    end
    fileTextDisplay:changeHologramData(string.rep(" ",math.ceil(eraseLen/2))..message..string.rep(" ",math.ceil(eraseLen/2)),{{colors.red,1}},nil,findCenterFromPoint(screenELements[elementNum].x,screenELements[elementNum].logo,message..string.rep(" ",math.ceil(eraseLen/2))))
    fileTextDisplay:render()
    if navigatorActive then sleep(0.1) os.pullEvent("key") else os.pullEvent("mouse_click") end
end

local openedFile = false
local function execute(...)
    openedFile = true
    local inputs = {...}

    local startTime = os.clock()
    local result = shell.run(table.unpack(inputs))
    if not result then
        sleep(0.2)
        term.setCursorPos(1,sizeY-2)
        term.setBackgroundColor(colors.black)
        printError("the Program has run into an unexpected Error")
        print()
        term.write("do anything to return to desktop"..string.rep(" ",sizeX-32))
        local event = {}
        while not (event[1] == "key" or event[1] == "char" or event[1] == "mouse_click") do
            event = {os.pullEvent()}
        end
    end
    local endTime = os.clock()
    if (endTime-startTime) < 1 and result then
        sleep(0.2)
        term.setCursorPos(1,sizeY)
        term.setBackgroundColor(colors.black)
        term.write("do anything to return to desktop"..string.rep(" ",sizeX-32))
        local event = {}
        while not (event[1] == "key" or event[1] == "char" or event[1] == "mouse_click") do
            event = {os.pullEvent()}
        end
    end
    fileTextDisplay:changeHologramData("",nil,nil,1,1)
    UIs.mainScreen:render()
    openedFile = false
end

local stopAudio, usedSpeakers, SpeakerScheduler, activeAudioBrokers = false, {}, {}, 0

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
    stopAudio = false

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
            if stopAudio then
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
    if event[2] == keys.right and navigatorSelected < #screenELements then
        if screenELements[navigatorSelected+1].dir then
            navigatorSelected = navigatorSelected + 1
            event[1] = "mouse_click"
            event[2] = 1
            event[3] = screenELements[navigatorSelected].x
            event[4] = screenELements[navigatorSelected].y
        end
    elseif event[2] == keys.left and navigatorSelected > 1 then
        navigatorSelected = navigatorSelected - 1
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = screenELements[navigatorSelected].x
        event[4] = screenELements[navigatorSelected].y
    elseif event[2] == keys.up or event[2] == keys.enter then
        event[1] = "mouse_click"
        event[2] = 1
        event[3] = screenELements[navigatorSelected].x
        event[4] = screenELements[navigatorSelected].y
    elseif event[2] == keys.down or event[2] == keys.rightShift then
        event[1] = "mouse_click"
        event[2] = 2
        event[3] = screenELements[navigatorSelected].x
        event[4] = screenELements[navigatorSelected].y
    end

    sleep(0.2)
    return event
end


local currentShownDir  = ""
local function runScreen(isSubProcess)
    setLogos("")
    UIs.mainScreen:render()

    local selected
    local didAction, startedSubProcess =  false, true

    if navigatorActive then
        selected = screenELements[1]
        screenELements[1]:isSelected(2,2)
    end

    while true do

        local event = {os.pullEvent()}
        if (not startedSubProcess) and isSubProcess then return end
        if navigatorActive then
            event = useNavigator(event)
        end

        if event[1] == "mouse_click" then
            didAction = false
            for i=1,#screenELements do

                if screenELements[i]:isSelected(event[3],event[4]) and not (selected == screenELements[i]) then
                    didAction = true
                    selected = screenELements[i]
                elseif screenELements[i]:isSelected(event[3],event[4]) and (selected == screenELements[i]) then
                    didAction = true
                    if event[2] == 1 then
                        selected = nil
                        if screenELements[i].type == "file" then
                            resetScreen()
                            execute(screenELements[i].dir)
                        elseif screenELements[i].type == "folder" then
                            if fs.exists(screenELements[i].dir.."/executable.lua") then
                                resetScreen()
                                execute(screenELements[i].dir.."/executable.lua")
                            elseif fs.exists(screenELements[i].dir) then
                                currentShownDir = screenELements[i].dir
                                if navigatorActive then
                                    selected = screenELements[1]
                                    screenELements[1]:isSelected(2,2)
                                    navigatorSelected = 1
                                end
                            end
                        elseif screenELements[i].type == "pic" and term.isColor() then
                            resetScreen()
                            execute("paint",screenELements[i].dir)
                        elseif screenELements[i].type == "pic" and not term.isColor() then
                            showErrorMessage("Can't use paint!",i)
                        elseif screenELements[i].type == "music" then
                            if peripheral.find("speaker") then
                                parallel.waitForAll(function () runScreen(true) end,function ()
                                    startedSubProcess = true
                                    AudioDataBroker(screenELements[i].dir,i)
                                end)
                            else
                                showErrorMessage("No Speaker Attached!", i)
                            end
                        end
                    elseif event[2] == 2 then
                        selected = nil
                        if screenELements[i].type == "folder" then
                            currentShownDir = screenELements[i].dir
                        else
                            execute("edit",screenELements[i].dir)
                        end
                    end
                    term.setCursorBlink(false)
                    setLogos(currentShownDir)
                end
            end
        elseif event[1] == "key" or event[1] == "key_up" then
            if currentShownDir ~= "" and event[2] == keys.left then
                if navigatorActive then
                    selected = screenELements[1]
                    screenELements[1]:isSelected(2,2)
                    navigatorSelected = 1
                else
                    selected = nil
                end
                local testString, traceBack = currentShownDir, true
                while traceBack do
                    testString = testString:sub(1,#testString-1)
                    if testString:sub(-1) == "/" or #testString == 0 then
                        traceBack = false
                        currentShownDir = testString:sub(1,#testString-1)
                    elseif #currentShownDir > 50 then
                        sleep(0.01)
                    end
                    setLogos(currentShownDir)
                end
            elseif event[2] == keys.zero then
                os.shutdown()
            elseif event[2] == keys.numPadEnter then
                return
            elseif event[2] == keys.q then
                stopAudio = true
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

            fileTextDisplay:changeHologramData("",nil,nil,1,1)
            UIs.mainScreen:render()
        elseif not didAction and event[1] == "mouse_click" and event[2] == 2 and currentShownDir ~= "" then
            if navigatorActive then
                selected = screenELements[1]
                screenELements[1]:isSelected(2,2)
                navigatorSelected = 1
            else
                selected = nil
            end
            local testString, traceBack = currentShownDir, true
            while traceBack do
                testString = testString:sub(1,#testString-1)
                if testString:sub(-1) == "/" or #testString == 0 then
                    traceBack = false
                    currentShownDir = testString:sub(1,#testString-1)
                elseif #currentShownDir > 50 then
                    sleep(0.01)
                end
                setLogos(currentShownDir)
            end
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

xpcall(parallel.waitForAny(runScreen,updateDesktop),function (err)
    printError("Error: "..err)
    sleep(2)
end)
local temp = io.open(".terminate.txt","w")
temp:close()

resetScreen()