local mountPath = shell.getRunningProgram()
local pathDiv = string.find(mountPath,"/",nil,true)
mountPath = string.sub(mountPath,1,pathDiv)
local function arrowRead(arrow,char)
    arrow = arrow or ">"
    arrow = tostring(arrow)
    term.write(arrow.." ")
    return read(char)
end
local installerLog
local fileAmount = 0
local function recursionDir(folderDir)
    local fileList = fs.list(mountPath..folderDir)
    --print("file list ="..textutils.serialise(fileList,{compact= true}))
    fs.delete(folderDir)
    fs.makeDir(folderDir)
    for i=1,#fileList do
        if fs.isDir(mountPath..folderDir..fileList[i]) then
            term.setTextColor(colors.green)
            print("redirecting to directory: "..folderDir..fileList[i].."/")
            if installerLog then installerLog:write("redirecting to directory: "..folderDir..fileList[i].."/","\n") end
            sleep(0.5)
            recursionDir(folderDir..fileList[i].."/")
            if installerLog then installerLog:flush() end
        else
            fileAmount = fileAmount + 1
            fs.delete(folderDir..fileList[i])
            fs.copy(mountPath..folderDir..fileList[i],folderDir..fileList[i])
            term.setTextColor(colors.white)
            term.write("copied: ")
            term.setTextColor(colors.magenta)
            term.write(mountPath..folderDir..fileList[i])
            term.setTextColor(colors.white)
            term.write(" to ")
            term.setTextColor(colors.yellow)
            print(folderDir..fileList[i])
            if installerLog then installerLog:write("copied: "..mountPath..folderDir..fileList[i].." to "..folderDir..fileList[i],"\n") end
        end
        sleep(0.1)
    end
end
_G.ROSFiles = {
        "startup.lua",
        "system",
        "Console",
        ".error.txt",
        ".terminate.txt",
        "installerLog.log"
    }
local function cope()
    printError("the desktop setup failed!")
    printError("this could be because of an internal issue or the file is missing completely")
    printError("should the RedOS be removed to stop the error from reappearing?")
    local answer = arrowRead("y/n:")
    if string.find(answer:lower(),"y",nil,true) then
        for i=1,#ROSFiles do
            fs.delete(ROSFiles[i])
        end
        fs.delete(".error.txt")
        os.reboot()
    end
    sleep(0.5)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end
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
--[[REDOS-INSTALLER]]
if string.find(mountPath,"disk",nil,true) then
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.blue)
    print("This is the RedOS Installer what would you like to do")
    term.setTextColor(colors.yellow)
    print("-I: installs the system")
    print("-D: deinstalls the system")
    print("-other: does nothing")
    term.setTextColor(colors.white)
    local selected = arrowRead(">")
    selected = string.lower(selected)
    if selected == "i" then
        installerLog = io.open("installerLog.log","w")
        if installerLog then installerLog:write("---------------------------START-OF-INSTALLER-LOG---------------------------","\n") end
        local fileList = fs.list(mountPath)
        for i=1,#fileList do
            if fs.isDir(mountPath..fileList[i]) then
                term.setTextColor(colors.green)
                print("redirecting to directory: "..mountPath..fileList[i].."/")
                if installerLog then installerLog:write("redirecting to directory: "..mountPath..fileList[i].."/","\n") end
                sleep(0.5)
                recursionDir(fileList[i].."/")
                if installerLog then installerLog:flush() end
            else
                fileAmount = fileAmount + 1
                fs.delete(fileList[i])
                fs.copy(mountPath..fileList[i],fileList[i])
                term.setTextColor(colors.white)
                term.write("copied: ")
                term.setTextColor(colors.magenta)
                term.write(mountPath..fileList[i])
                term.setTextColor(colors.white)
                term.write(" to ")
                term.setTextColor(colors.yellow)
                print(fileList[i])
                if installerLog then installerLog:write("copied: "..mountPath..fileList[i].." to "..fileList[i],"\n") end
            end
            sleep(0.1)
        end
        if installerLog then installerLog:write("installed "..fileAmount.." files","\n") end
        if installerLog then installerLog:write("----------------------------END-OF-INSTALLER-LOG----------------------------") end
        if installerLog then installerLog:close() end
        peripheral.find("drive",function (_,diskDrive)
            local mountPath = diskDrive.getMountPath()
            if mountPath then
                if fs.exists(mountPath.."/startup.lua") then
                    local temp =  io.open(mountPath.."/startup.lua","r")
                    local content = temp:read("a")
                    temp:close()
                    if string.find(content,"--[[REDOS-INSTALLER]]",nil,true) then
                        diskDrive.setDiskLabel("RedOS-Disk")
                        diskDrive.ejectDisk()
                    end
                end
            end
        end)
        sleep(1)
        print()
        term.setTextColor(colors.white)
        print("Installed "..fileAmount.." files!")
        print("Generated installerLog.log all installed files listed there")
        term.setTextColor(colors.blue)
        print("RedOS is now installed, restart to load OS")
        print("do you want to restart the system now")
        term.setTextColor(colors.white)
        local answer = arrowRead("y/n:")
        if string.find(answer:lower(),"y",nil,true) then
            os.reboot()
        end
    else
        print("ok bye!")
    end
else
    term.clear()
    term.setCursorPos(1,1)
    xpcall(function() os.loadAPI("system/ROSLibs/graphicLib.lua")
        if UIs then os.reboot() end
        _G.UIs = {}
        UIs.Startup = graphicLib.Frame:init("RedOS")
        local logo
        if fs.exists("system/ROSPics/ROSLogo.nfp") then
            logo = UIs.Startup:loadImage("system/ROSPics/ROSLogo.nfp")
        else
            logo = makeCheckerPattern(29,9,colors.gray,colors.magenta)
        end
        local width, height = term.getSize()
        local logoSprite = UIs.Startup.sprite:addSprite(logo,nil,(width-#logo)/2,(height-#logo[2])/2)
        logoSprite:render()
        sleep(1)
        term.setBackgroundColor(colors.black)
        UIs.Startup:quit(false)
        term.setCursorPos(1,1)
    end, function (returnedError)
        term.setCursorPos(1,1)
        printError("ERROR: "..returnedError)
        printError("graphicLib.lua Is Missing or Brocken -> mainScreen.lua failed")
        cope()
    end)
    xpcall(function() local result = shell.run("system/ROSLibs/ROSMainScreen.lua") if not result then error("something went wrong whilst running the desktop") end end, function (returnedError)
        if not fs.exists(".terminate.txt") then
            printError("ERROR: "..returnedError)
        else
            print("You're now outside of the RedOS and are using CraftOS (built-in)")
            print()
            print("enter 'reboot' or restart the computer to restart RedOS")
        end
        if fs.exists(".error.txt") then
            cope()
            local temp = io.open(".terminate.txt","w")
            temp:close()
            term.clear()
        end
        if not fs.exists(".terminate.txt") then
            local temp = io.open(".error.txt","w")
            temp:close()
            os.reboot()
        else
            fs.delete(".terminate.txt")
        end
    end)
end
