local mountPath = shell.getRunningProgram()
local pathDiv = string.find(mountPath,"/",nil,true)
mountPath = string.sub(mountPath,1,pathDiv)
local list = fs.list("system/APIs")
for i=1,#list do
    if fs.exists("system/APIs/"..list[i]) and list[i]~= "init.lua" then
        local result = require("system/APIs/"..list[i]:sub(1,-5))
        if mountPath == "rom/" then print("imported: system/APIs/"..list[i]:sub(1,-5),"status: "..tostring(result)) end
    end
end