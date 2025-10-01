local path = shell.getRunningProgram()
path = string.sub(path,1,#path-#"executable.lua")
local function arrowRead(arrow,char)
    arrow = arrow or ">"
    arrow = tostring(arrow)
    term.write(arrow.." ")
    return read(char)
end
local function readInput(strings,arrow,char)
    arrow = arrow or ">"

    for i=1,#strings do
        print(tostring(strings[i]))
    end
    local _,y =term.getCursorPos()
    term.write(tostring(arrow))
    local input = read(char)
    term.setCursorPos(1,y+1)

    return input
end
local function githubUrl(owner,repo,path)
    local path = path or ""
    return 'https://api.github.com/repos/'..owner..'/'..repo..'/contents/'..path
end
local function download(url,GITHUB_TOKEN)
    local handle, err, err_handle
    if GITHUB_TOKEN then
        handle, err, err_handle = http.get(url,{
            ["Authorization"] = "token " .. GITHUB_TOKEN,
            ["User-Agent"] = "RedOS-PreInstaller"
        })
    else
        handle, err, err_handle = http.get(url)
    end
    if not handle then
        printError(err_handle and err_handle.readAll() or "-")
        error(err, 0)
    end
    return handle.readAll()
end
local function downloadRepo(path,url,GITHUB_TOKEN)
    path = path or ""
    local paths = textutils.unserialiseJSON(download(url,GITHUB_TOKEN))
    for _,p in pairs(paths) do
        print("installing: "..p.path)
        if p.download_url then
            local h = fs.open(path..p.path,"w")
            h.write(download(p.download_url, GITHUB_TOKEN))
            h.close()
        else 
            downloadRepo(path,p.url)
        end
    end
end
local function setTextColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end
local settings = {}
local function loadSettingsJSON(dir)
    if not fs.exists(dir) then return end
    local temp = io.open(dir,"r")
    local content = temp:read("a")
    temp:close()

    content = textutils.unserialiseJSON(content)
    if type(content) == "table" then
        settings = content
    end
end
local function saveSettingsAsJSON(dir)
    local content = textutils.serialiseJSON(settings)
    local temp = io.open(dir,"w")
    temp:write(content)
    temp:close()
end
local function programEnd(token)
    if token then
        local input = readInput({"do you want me to remember this token: "..string.sub(token, 1, 4).."..."..string.sub(token, -4).."? under setting 'github.token'","this setting will be deleted together with the installer"},"y/n:")
        if string.find(input,"y",nil,true) then
            settings.token=token
        end
        print("to protect your secrete token this chat will auto wipe in 1 seconds")
        sleep(1)
        term.clear()
        term.setCursorPos(1,1)
    end
end
local updaterLog
local fileAmount = 0
local function recursionDir(folderDir)
    local fileList = fs.list("os/"..folderDir)
    --print("file list ="..textutils.serialise(fileList,{compact= true}))
    fs.delete(folderDir)
    fs.makeDir(folderDir)
    for i=1,#fileList do
        if fs.isDir("os/"..folderDir..fileList[i]) then
            term.setTextColor(colors.green)
            print("redirecting to directory: ".."os/"..folderDir..fileList[i].."/")
            if updaterLog then updaterLog:write("redirecting to directory: ".."os/"..folderDir..fileList[i].."/","\n") end
            sleep(0.5)
            recursionDir(folderDir..fileList[i].."/")
            if updaterLog then updaterLog:flush() end
        else
            fileAmount = fileAmount + 1
            fs.delete(folderDir..fileList[i])
            fs.copy("os/"..folderDir..fileList[i],folderDir..fileList[i])
            term.setTextColor(colors.white)
            term.write("copied: ")
            term.setTextColor(colors.magenta)
            term.write("os/"..folderDir..fileList[i])
            term.setTextColor(colors.white)
            term.write(" to ")
            term.setTextColor(colors.yellow)
            print(folderDir..fileList[i])
            if updaterLog then updaterLog:write("copied: ".."os/"..folderDir..fileList[i].." to "..folderDir..fileList[i],"\n") end
        end
        sleep(0.1)
    end
end
local function run()
    local answer = arrowRead("y/n:")
    if string.find(string.lower(answer),"y",nil,true) then
        loadSettingsJSON(path.."/settings.json")
        local confirmed, token
        if settings.token and input ~= "e" then
            token = settings.token
            local input = readInput({"you have provided a token:"..string.sub(token, 1, 4).."..."..string.sub(token, -4),"do you want to reset it?"},"y/n:")
            if string.find(input,"y",nil,true) then
                settings.token = nil
            end
            token = nil
            print()
        end
        while not (confirmed or token)and input ~= "e" do
            token = readInput({"please enter your github token for a higher rate limit (5,000 requests/hour)","press enter if you don't want to do this"},nil,"*")
            if #token < 1 then
                print("warning you are using unauthenticated download requests")
                print("this means you can only do 60 requests / hour")
                confirmed = true
                token = nil
            else
                local input = readInput({"is this your token? "..string.sub(token, 1, 4).."..."..string.sub(token, -4)},"y/n:")
                if string.find(input,"y",nil,true) then
                    confirmed = true
                end
            end
        end
        if token and input ~= "e" then
            print()
            print("using github token: "..string.sub(token, 1, 4).."..."..string.sub(token, -4))
        end
        print()
        downloadRepo("",githubUrl("Redtech0inc","RedOS-cc-Tweaked-","os/"),token)
        print()
        updaterLog = io.open(path.."updaterLog.log","w")
        if updaterLog then updaterLog:write("---------------------------START-OF-INSTALLER-LOG---------------------------","\n") end
        local fileList = fs.list("os/")
        for i=1,#fileList do
            if fs.isDir("os/"..fileList[i]) then
                term.setTextColor(colors.green)
                print("redirecting to directory: ".."os/"..fileList[i].."/")
                if updaterLog then updaterLog:write("redirecting to directory: ".."os/"..fileList[i].."/","\n") end
                sleep(0.5)
                recursionDir(fileList[i].."/")
                if updaterLog then updaterLog:flush() end
            else
                fileAmount = fileAmount + 1
                fs.delete(fileList[i])
                fs.copy("os/"..fileList[i],fileList[i])
                term.setTextColor(colors.white)
                term.write("copied: ")
                term.setTextColor(colors.magenta)
                term.write("os/"..fileList[i])
                term.setTextColor(colors.white)
                term.write(" to ")
                term.setTextColor(colors.yellow)
                print(fileList[i])
                if updaterLog then updaterLog:write("copied: ".."os/"..fileList[i].." to "..fileList[i],"\n") end
            end
            sleep(0.1)
        end
        if updaterLog then updaterLog:write("updated "..fileAmount.." files","\n") end
        if updaterLog then updaterLog:write("----------------------------END-OF-INSTALLER-LOG----------------------------") end
        if updaterLog then updaterLog:close() end
        fs.delete("os/")
        setTextColor(colors.green)
        print("done!")
        sleep(2.5)
        setTextColor(colors.white)
        programEnd(token)
        saveSettingsAsJSON(path.."/settings.json")
    end
end
setTextColor(colors.red)
term.write("Red")
setTextColor(colors.yellow)
term.write("OS")
setTextColor(colors.white)
print(" Updater:")
print("would you like to update the RedOS (your files won't be lost but backing up data is never a bad idea ;) )")
run()
