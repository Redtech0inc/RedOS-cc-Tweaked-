local path = shell.getRunningProgram()
path = string.sub(path,1,#path-#"executable.lua")

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
        return UIs.uninstaller:loadImage(dir)
    else
        return makeCheckerPattern(3,3,colors.gray,colors.magenta)
    end
end
UIs.mainScreen:render()
if UIs then
    if UIs.mainScreen then
        UIs.uninstaller = graphicLib.Frame:init("ROSUninstaller")
    end
end
local sizeX, sizeY = term.getSize()
local uninstallerLog
local fileAmount = 0
local function recursionDir(folderDir)
    local fileList = fs.list(folderDir)
    for i=1,#fileList do
        if fs.isDir(folderDir..fileList[i]) then
            term.setTextColor(colors.green)
            print("redirecting to directory: "..folderDir..fileList[i].."/")
            if uninstallerLog then uninstallerLog:write("redirecting to directory: "..folderDir..fileList[i].."/","\n") end
            sleep(0.5)
            recursionDir(folderDir..fileList[i].."/")
            if uninstallerLog then uninstallerLog:flush() end
        elseif fs.exists(folderDir..fileList[i]) then
            fileAmount = fileAmount + 1
            fs.delete(folderDir..fileList[i])
            term.setTextColor(colors.white)
            term.write("deleted: ")
            term.setTextColor(colors.red)
            print(folderDir..fileList[i])
            if uninstallerLog then uninstallerLog:write("deleted: "..folderDir..fileList[i],"\n") end
        end
        sleep(0.1)
    end
    fs.delete(folderDir)
    term.setTextColor(colors.white)
    term.write("deleted: ")
    term.setTextColor(colors.lightGray)
    print(folderDir)
    if uninstallerLog then uninstallerLog:write("deleted: "..folderDir,"\n") end
end
local function runUninstaller()
    uninstallerLog = io.open("uninstallerLog.log","w")
    if uninstallerLog then uninstallerLog:write("---------------------------START-OF-UNINSTALLER-LOG---------------------------","\n") end
    if uninstallerLog then uninstallerLog:write("Targeted Files/Directories:","\n") end
    for i=1,#ROSFiles do
        if uninstallerLog then uninstallerLog:write("-"..ROSFiles[i],"\n") end
    end
    if uninstallerLog then uninstallerLog:write("------------------------------------------------------------------------------","\n") end
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    for i=1,#ROSFiles do
        if fs.isDir(ROSFiles[i]) then
            term.setTextColor(colors.green)
            print("redirecting to directory: "..ROSFiles[i].."/")
            if uninstallerLog then uninstallerLog:write("redirecting to directory: "..ROSFiles[i].."/","\n") end
            recursionDir(ROSFiles[i].."/")
            if uninstallerLog then uninstallerLog:flush() end
        elseif fs.exists(ROSFiles[i]) then
            fileAmount = fileAmount + 1
            fs.delete(ROSFiles[i])
            term.setTextColor(colors.white)
            term.write("deleted: ")
            term.setTextColor(colors.red)
            print(ROSFiles[i])
            if uninstallerLog then uninstallerLog:write("deleted: "..ROSFiles[i],"\n") end
        end
    end
    if uninstallerLog then uninstallerLog:write("uninstalled "..fileAmount.." files","\n") end
    if uninstallerLog then uninstallerLog:write("----------------------------END-OF-UNINSTALLER-LOG----------------------------") end
    if uninstallerLog then uninstallerLog:close() end
    print()
    term.setTextColor(colors.yellow)
    print("Uninstalled "..fileAmount.." files!")
    print("Generated uninstallerLog.log all uninstalled files listed there")
    sleep(0.5)
    term.setTextColor(colors.white)
    print("do anything to return to CraftOS")
    local event = {}
    while event[1] ~= "mouse_click" and event[1] ~= "key" do
        event = {os.pullEvent()}
    end
    os.reboot()
end
local final = false
local function useBody(XButton,UButton,confirmButton,cancelButton)
    while true do
        local event = {os.pullEvent()}
        if event[1] == "mouse_click" then
            if UIs.uninstaller:isCollidingRaw(event[3],event[4],UButton,true) then
                confirmButton:changeHologramData("!Confirm! [Enter]")
                cancelButton:changeHologramData("X")
                UButton:changeHologramData("")
                sleep(0.2)
                UIs.uninstaller:render()
                final = true
            elseif UIs.uninstaller:isCollidingRaw(event[3],event[4],confirmButton,true) then
                runUninstaller()
            elseif UIs.uninstaller:isCollidingRaw(event[3],event[4],XButton,true) or UIs.uninstaller:isCollidingRaw(event[3],event[4],cancelButton,true) then
                return
            end
        elseif event[1] == "key" then
            if event[2] == keys.enter and not final then
                confirmButton:changeHologramData("!Confirm! [Enter]")
                cancelButton:changeHologramData("X")
                UButton:changeHologramData("")
                sleep(0.2)
                UIs.uninstaller:render()
                final = true
            elseif event[2] == keys.enter and final then
                runUninstaller()
            elseif event[2] == keys.x or event[2] == keys.backspace then
                return
            end
        end
    end
end

local colorSchemeX = {{colors.red,1}}
if not term.isColor() then
    colorSchemeX = {{colors.lightGray,1}}
end

local bodySprite = loadImage(path.."body.nfp")
UIs.uninstaller.sprite:addSprite(bodySprite,nil,(sizeX-#bodySprite)/2,(sizeY-#bodySprite[1])/2)
UIs.uninstaller.hologram:addHologram("Uninstaller",{{colors.black,1}},nil,nil,((sizeX-#bodySprite)/2)+1,((sizeY-#bodySprite[1])/2)+6)
local XButton = UIs.uninstaller.hologram:addHologram("X",colorSchemeX,{{colors.blue,1}},nil,(sizeX-#bodySprite)/2,(sizeY-#bodySprite[1])/2)
UIs.uninstaller.hologram:addHologram("This Uninstalls the RedOS",{{colors.red,1}},{{colors.white,1}},nil,((sizeX-#bodySprite)/2)+1,((sizeY-#bodySprite[1])/2)+8)
UIs.uninstaller.hologram:addHologram("forever and unrecoverable!",{{colors.red,1}},nil,nil,((sizeX-#bodySprite)/2)+1,((sizeY-#bodySprite[1])/2)+9)
local UButton = UIs.uninstaller.hologram:addHologram("!Uninstall! [Enter]",{{colors.yellow,1}},{{colors.blue,1}},nil,((sizeX-#bodySprite)/2)+1,((sizeY+#bodySprite[1])/2)-2)
local confirmButton = UIs.uninstaller.hologram:addHologram("",{{colors.yellow,1}},{{colors.red,1}},nil,((sizeX-#bodySprite)/2)+1,((sizeY+#bodySprite[1])/2)-2)
local cancelButton = UIs.uninstaller.hologram:addHologram("",{{colors.black,1}},{{colors.green,1}},nil,((sizeX-#bodySprite)/2)+19,((sizeY+#bodySprite[1])/2)-2)
UIs.uninstaller:render()
sleep(0.5)
useBody(XButton,UButton,confirmButton,cancelButton)
XButton:changeHologramData(nil,nil,{{colors.lightBlue,1}})
if final then
    cancelButton:changeHologramData(nil,nil,{{colors.lime,1}})
end
UIs.uninstaller:render()
sleep(0.5)
UIs.uninstaller:quit()