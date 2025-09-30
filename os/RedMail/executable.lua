local programPath = shell.getRunningProgram()
local prePath = programPath:sub(1,#programPath-14)

local function combinePathFromRoot(path,combinePath)
    local _,count = string.gsub(path,"/","")
    for _=1,count do
        combinePath = "../"..combinePath
    end

    return combinePath
end

require(combinePathFromRoot(programPath,"system/APIs/redOsAPI"))
require(combinePathFromRoot(programPath,"system/APIs/windowAPI"))

function winAPI.WindowClass:writeWrapped(line,text,prefix,applyToAllLines,colorFormat,backgroundColorFormat)
    prefix = prefix or ""
    text = tostring(text)
    local wrappedText = rosAPI.textutils.wrapText(text,self.x,self.sizeX)
    for i=1,#wrappedText do
        if (i == 1) or applyToAllLines then wrappedText[i] = prefix ..wrappedText[i] end
        self:write(line+(i-1),wrappedText[i],colorFormat,backgroundColorFormat)
    end
end

--creation of IPC space for client and background process
if not fs.exists("system/redMailData") then
    fs.makeDir("system/redMailData/mail") --shared space for actual mail
    fs.makeDir("system/redMailData/ipc") --shared data space betweene Background script and main client
end

--add background script to system/BGScripts
if fs.exists(prePath.."RedMail_bgs.lua") then
    fs.delete("system/BGScripts/RedMail_bgs.lua")
    fs.copy(prePath.."RedMail_bgs.lua","system/BGScripts/RedMail_bgs.lua")
    fs.delete(prePath.."RedMail_bgs.lua") -- file gone marks task complete
    _G.REDMAILFIRSTEXECUTION = true
end

if not (fs.exists("system/redMailData/ipc/port.txt") or _G.REDMAILFIRSTEXECUTION) then error("something went wrong with the redMail system") end

local winX,winY,winSizeX,winSizeY
local device = rosAPI.getDevice()
if device == "turtle" then
    winX,winY = rosAPI.formatting.center(40,15)
    winSizeX,winSizeY = 40,15
elseif device == "pocket" then
    winX,winY = rosAPI.formatting.center(15,20)
    winSizeX,winSizeY = 15,20
else
    winX,winY = rosAPI.formatting.center(41,16)
    winSizeX,winSizeY = 41,16
end
local mailWindow = winAPI.WindowClass:create(" RedMail",winX,winY,winSizeX,winSizeY)

mailWindow:write(1," Welcome to RedMail",{{colors.blue,1},{colors.black,9},{colors.red,12},{colors.lightGray,16}},{{colors.white,1}})
if _G.REDMAILFIRSTEXECUTION then
    local function main(...)
        local inArgs = {...}
        mailWindow:writeWrapped(3,"Please Restart to be able to receive Mail!"," ",true)
        mailWindow:writeWrapped(6,"reason: background scripts need to restart to start mail receiver thread"," ",true,{{colors.lightGray,1}})
        while true do
            sleep(5)
        end
    end

    mailWindow:run(main)
else
    local tempFile = io.open("system/redMailData/ipc/port.txt","r")
    local side = tempFile:read("a")
    tempFile:close()

    local modem = peripheral.wrap(side)

    if not modem then error("missing ender/wireless modem! once one is attached please restart!") end

    local function createMailList(x,y,sizeY)
        local mailDisplayList = {}
        for i=1,sizeY-y do
            table.insert(mailDisplayList,mailWindow:addHologram("",{{colors.black,1}},{{colors.white,1}},nil,x,1+(i-1)))
        end
        return mailDisplayList
    end

    local function displayMail(offset,mailDisplayList,sizeX)
        local mailList = fs.list("system/redMailData/mail")
        for i=1,#mailList do
            if mailDisplayList[2+(i-1)] then
                if mailList[i+offset] then
                    local name = mailList[i+offset]:sub(1,sizeX)
                    mailDisplayList[2+(i-1)]:changeHologramData(name..string.rep(" ",sizeX-#name))
                else
                    mailDisplayList[2+(i-1)]:changeHologramData(string.rep(" ",sizeX))
                end
                mailDisplayList[2+(i-1)]:render()
            end
        end
    end

    local function isInArea(x,y,MinX,MinY,MaxX,MaxY)
        return (x >= MinX and x <= MaxX) and (y >= MinY and y <= MaxY)
    end

    local function makeLetterLines(x,y,sizeX,sizeY)
        local background = mailWindow:addSprite(mailWindow.displayOBJ:getShapeSprite(colors.lightGray,nil,sizeX,sizeY),nil,x,y)
        local letterLines = {}
        for i=1,sizeY do
            table.insert(letterLines,mailWindow:addHologram("",{{colors.black,1}},nil,nil,x,y+(i-1)))
        end
        return letterLines, background
    end

    local function openMail(displayTable,letterLines,offset,background)
        background:render()
        for i=1,#letterLines do
            if displayTable[i+offset] then
                letterLines[i]:changeHologramData(displayTable[i+offset],{{colors.black,1}},{{colors.lightGray,1}})
            else
                letterLines[i]:changeHologramData("")
            end
            letterLines[i]:render()
        end
    end

    local function mainComputer(...)
        local inArgs = {...}
        local mailDisplayList = createMailList(mailWindow.sizeX-15,2,mailWindow.sizeY)
        local letterLines, letterBackground = makeLetterLines(2,2,mailWindow.sizeX-20,mailWindow.sizeY-3)
        local listOffset = 0
        local letterOffset = 0
        local displayedDir
        local displayTable = {}

        mailDisplayList[1]:changeHologramData("Your Mail:")
        mailDisplayList[1]:render()
        displayMail(0,mailDisplayList,15)

        while true do
            local events={os.pullEvent()}

            if events[1] == "mouse_scroll" and isInArea(events[3],events[4],(mailWindow.x-1)+mailWindow.sizeX-15,mailWindow.y+1,(mailWindow.x-1)+mailWindow.sizeX,(mailWindow.y-1)+mailWindow.sizeY-1) then
                listOffset = listOffset + 5*events[2]
                if listOffset < 0 then
                    listOffset = 0
                end

            elseif events[1] == "mouse_click" and isInArea(events[3],events[4],(mailWindow.x-1)+mailWindow.sizeX-15,mailWindow.y+1,(mailWindow.x-1)+mailWindow.sizeX,(mailWindow.y-1)+mailWindow.sizeY-1) then
                for i=2,#mailDisplayList do

                    if mailWindow.displayOBJ:isCollidingRaw(events[3],events[4],mailDisplayList[i]) then
                        displayedDir = "system/redMailData/mail/"..mailDisplayList[i].text[1]
                        letterOffset = 0
                        displayTable = {}
                        for line in io.lines(displayedDir) do
                            if #line > 0 then
                                local text = rosAPI.textutils.wrapText(line,2,mailWindow.sizeX-20)
                                for i=1,#text do
                                    table.insert(displayTable,text[i])
                                end
                            else
                                table.insert(displayTable,"")
                            end
                        end
                    end
                end
            elseif events[1] == "mouse_scroll" and isInArea(events[3],events[4],(mailWindow.x-1)+2,(mailWindow.y-1)+4,(mailWindow.x-1)+mailWindow.sizeX-20,(mailWindow.y-1)+mailWindow.sizeY-1) then
                letterOffset = letterOffset + 5*events[2]
                if letterOffset < 0 then
                    letterOffset = 0
                elseif #letterLines > #displayTable-letterOffset then
                    letterOffset = #displayTable-#letterLines
                end
            end
            openMail(displayTable,letterLines,letterOffset,letterBackground)
            displayMail(listOffset,mailDisplayList,15)
            sleep(0.1)
        end

        mailWindow:interrupt()
    end

    mailWindow:run(mainComputer)
end