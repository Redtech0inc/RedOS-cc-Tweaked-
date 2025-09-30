local side
local modem = peripheral.find("modem",function (name,modem)
    if modem.isWireless() then
        side = name
        return true
    end
end) --get rednet modem and side

local tempFile = io.open("system/redMailData/ipc/port.txt","w") -- tell parallel process that the modem is open and the side
if side then tempFile:write(side) end
tempFile:close()

if not modem then error("couldn't find ender/wireless modem") end

rednet.open(side)

