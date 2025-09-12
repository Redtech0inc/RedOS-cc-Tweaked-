winAPI={}

winAPI.WindowClass = {}
winAPI.WindowClass.__index = winAPI.WindowClass

function winAPI.WindowClass:create(name, x, y, sizeX, sizeY, backgroundColor, titleBarColor, roundEdges)
    local obj = {}
    local maxX, maxY = term.getSize()

    name = name or "window"
    backgroundColor = backgroundColor or colors.white
    titleBarColor = titleBarColor or colors.gray
    x = x or 1
    y = y or 1
    sizeX = sizeX or 3
    sizeY = sizeY or 3

    if sizeX < 3 then sizeX = 3 end
    if sizeX > maxX then sizeX = maxX end
    if sizeY < 3 then sizeY = 3 end
    if sizeY > maxY then sizeY = maxY end

    obj.x = x
    obj.y = y
    obj.sizeX = sizeX
    obj.sizeY = sizeY

    name = tostring(name)
    obj.name = name:sub(1,sizeX)

    obj.displayOBJ = graphicLib.Frame:init(name)

    obj.bodyImage = {}

    for i = 1, sizeX do
        obj.bodyImage[i] = {}
        for j = 1, sizeY do
            if j == 1 then
                obj.bodyImage[i][1] = titleBarColor
            else
                obj.bodyImage[i][j] = backgroundColor
            end
            if roundEdges then
                if ((i % sizeX == 1) or (i % sizeX == 0)) and ((j % sizeY == 1) or (j % sizeY == 0)) then
                    obj.bodyImage[i][j] = nil
                end
            end
        end
    end

    obj.body = obj.displayOBJ.sprite:addSprite(obj.bodyImage,nil,obj.x,obj.y)

    obj.lines = {}

    local lineX = obj.x
    if roundEdges then
        lineX = lineX + 1
    end
    for i=1,sizeY-1 do
        table.insert(obj.lines,obj.displayOBJ.hologram:addHologram("",{{colors.black,1}},nil,nil,lineX,obj.y+i,nil,false))
    end

    obj.XButton = obj.displayOBJ.hologram:addHologram("X",{{colors.white,1}},{{colors.red,1}},nil,obj.x,obj.y)
    obj.label = obj.displayOBJ.hologram:addHologram(obj.name,{{colors.white,1}},{{colors.gray,1}},nil,obj.x+1,obj.y,nil,false)

    obj.oldValues = {lines = {}}

    obj.textMaxWidth = obj.sizeX
    if roundEdges then
        obj.textMaxWidth = obj.textMaxWidth - 2
    end

    obj.roundEdges = roundEdges

    setmetatable(obj,self)
    self.__index = self

    return obj
end

function winAPI.WindowClass:update()
    self.displayOBJ:render()
end

function winAPI.WindowClass:setColorScheme(backgroundColor,titleBarColor,changeLineColor)
    if changeLineColor == nil then changeLineColor = true end
    backgroundColor = backgroundColor or colors.white
    titleBarColor = titleBarColor or colors.gray

    local bodyImage = {}
    for i=1,self.sizeX do
        bodyImage[i]={}
        for j=1,self.sizeY do
            if j == 1 then
                bodyImage[i][1] = titleBarColor
            else
                bodyImage[i][j] = backgroundColor
            end
            if self.roundEdges then
                if ((i % self.sizeX == 1) or (i % self.sizeX == 0)) and ((j % self.sizeY == 1) or (j % self.sizeY == 0)) then
                    bodyImage[i][j] = nil
                end
            end
        end
    end
    self.bodyImage = bodyImage
    self.body:changeSpriteData(bodyImage)
    self.label:changeHologramData(nil,nil,{{titleBarColor,1}})

    if changeLineColor then
        for i=1,#self.lines do
            self.lines[i]:changeHologramData(nil,nil,{{backgroundColor,1}})
        end
    end
end

function winAPI.WindowClass:write(line, text, colorFormat, backgroundColorFormat)
    line = line or 1

    text = text or ""
    text = tostring(text)
    text = text:sub(1,self.textMaxWidth)

    if self.lines[line] then
        self.lines[line]:changeHologramData(text,colorFormat,backgroundColorFormat)
    end
    self:update()
end

function winAPI.WindowClass:clear(line)
    if type(line) == "number" then
        if self.lines[line] then
            self.lines[line]:changeHologramData("")
        end
    else
        for i=1,#self.lines do
            self.lines[i]:changeHologramData("")
        end
    end

    self:update()
end

function winAPI.WindowClass:setWindowPos(rootX,rootY)
    if type(rootX) ~= "number" or type(rootY) ~= "number" then return end
    self.x = rootX
    self.y = rootY
    self.XButton:changeHologramData(nil,nil,nil,rootX,rootY)
    self.label:changeHologramData(nil,nil,nil,rootX+1,rootY)
    self.body:changeSpriteData(nil,rootX,rootY)
    local lineX = rootX
    if self.roundEdges then
        lineX = lineX + 1
    end
    for i=1,#self.lines do
        self.lines[i]:changeHologramData(nil,nil,nil,lineX,self.y+i)
    end

    UIs.mainScreen:render()
    self:update()
end

function winAPI.WindowClass:interrupt()
    self.loop = false
end

function winAPI.WindowClass:run(func, ...)
    if type(func) ~= "function" then error("Can't run without function given to run method (arg1 type:"..type(func)..")") end

    local arguments = {...}
    self.loop = true

    local function windowCode()
        local dragSelected = false
        local distanceToRoot = 0
        while true do
            local events = {os.pullEvent()}
            if events[1] == "mouse_click" then
                if events[3] == self.x and events[4] == self.y then
                    return
                elseif events[4] == self.y and (events[3] >= self.x and events[3] <= self.x+(self.sizeX-1)) then
                    distanceToRoot = self.x - events[3]
                    dragSelected = true
                else
                    dragSelected = false
                end
            elseif events[1] == "mouse_drag" and dragSelected then
                self:setWindowPos(events[3]+distanceToRoot,events[4])
                sleep(0.1)
            end
            if not self.loop then
                return
            end
        end
    end

    UIs.mainScreen:render()
    self:update()
    parallel.waitForAny(
        function ()
            while self.loop do
                func(table.unpack(arguments))
                sleep(0.1)
            end
        end
    ,windowCode)
end

function winAPI.WindowClass:disappear()
    self.oldValues = {lines = {}}

    for i=1,#self.lines do
        table.insert(self.oldValues.lines,self.lines[i].text[1])
    end

    self:clear()
    self.XButton:changeHologramData("")
    self.label:changeHologramData("")

    self.body:changeSpriteData({{}})
    self:update()
    UIs.mainScreen:render()
end

function winAPI.WindowClass:reappear()
    self.XButton:changeHologramData("X")
    self.label:changeHologramData(self.name)

    self.body:changeSpriteData(self.bodyImage)

    for i=1,#self.lines do
        if self.oldValues.lines[i] then
            self.lines[i]:changeHologramData(self.oldValues.lines[i])
        else
            self.lines[i]:changeHologramData("")
        end
    end

    self:update()

    self.oldValues = {lines = {}}

    for i=1,#self.lines do
        table.insert(self.oldValues.lines,self.lines[i].text[1])
    end
end