easyLog = {}

easyLog.Log={}
easyLog.Log.__index = easyLog.Log

function easyLog.Log:open(name,logTimeFunc,copyErrors,errorDIR)
    local obj= {}

    obj.errorDIR = errorDIR or "logs/"

    --setting all the variables
    obj.name = tostring(name)
    obj.lines = 1

    if obj.name == nil then
        obj.name=tostring(os.date("%c"))
    end

    --opens log
    obj.log=io.open(obj.name,"w")

    if type(logTimeFunc) == "function" then
        obj.logTimeFunc = logTimeFunc
    else
        obj.logTimeFunc = function ()
            return os.date("%c")
        end
    end

    obj.copyErrors = copyErrors
    if copyErrors then obj.copyName = {} end

    --setmetatable
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function easyLog.Log:write(text,logClass,endLine,includePreInfo,saveText)

    --check that logClass isn't nil
    logClass=logClass or "INFO"
    logClass = tostring(logClass)
    if endLine == nil then endLine = true end
    if includePreInfo == nil then includePreInfo = true end
    if saveText == nil then saveText = true end

    --write in Log
    if includePreInfo then
        self.log:write(tostring(self.logTimeFunc()).." ["..logClass.."]: ")
    end
    if endLine == true then
        self.log:write(tostring(text),"\n")
        self.lines=self.lines+1
    else
        self.log:write(tostring(text))
    end

    --save written text
    if saveText then self.log:flush() end

    if self.copyErrors then
        if string.find(string.lower(logClass),"error",nil,true) and string.lower(logClass) ~= "errorecp" then
            if not saveText then self.log:flush() end
            fs.delete(self.errorDIR..logClass..".log")
            fs.copy(self.name,self.errorDIR..logClass..".log")
        end
    end
end

function easyLog.Log:space(number)
    if type(number) ~= "number" then
        number = 1
    end
    for i = 1,number do
        self.log:write("\n")
    end
end

function easyLog.Log:getLines()
    return self.lines
end

function easyLog.Log:close()
    self.log:close()
    setmetatable(self, {
        __index = function()
        end
    })
end
