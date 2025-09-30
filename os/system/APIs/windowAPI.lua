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

    obj.holograms = {window={}}
    obj.sprites = {window={}}

    obj.sprites.body = obj.displayOBJ.sprite:addSprite(obj.bodyImage,nil,obj.x,obj.y)

    obj.holograms.lines = {}

    local lineX = obj.x
    if roundEdges then
        lineX = lineX + 1
    end
    for i=1,sizeY-1 do
        table.insert(obj.holograms.lines,obj.displayOBJ.hologram:addHologram("",{{colors.black,1}},{{backgroundColor,1}},nil,lineX,obj.y+i,nil,false))
    end

    obj.sprites.XButton = obj.displayOBJ.hologram:addHologram("X",{{colors.white,1}},{{colors.red,1}},nil,obj.x,obj.y)
    obj.holograms.label = obj.displayOBJ.hologram:addHologram(obj.name,{{colors.white,1}},{{colors.gray,1}},nil,obj.x+1,obj.y,nil,false)

    obj.oldValues = {lines = {}}

    obj.textMaxWidth = obj.sizeX
    if roundEdges then
        obj.textMaxWidth = obj.textMaxWidth - 2
    end

    obj.roundEdges = roundEdges

    obj.loop = false

    setmetatable(obj,self)
    self.__index = self

    return obj
end

function winAPI.WindowClass:update()
    if self.loop then self.displayOBJ:render() end
end

function winAPI.WindowClass:setLabel(text,color)
    if not text then return end
    self.name = tostring(text:sub(1,self.sizeX))
    self.holograms.label:changeHologramData(self.name,color)
    self:update()
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
    self.sprites.body:changeSpriteData(bodyImage)
    self.holograms.label:changeHologramData(nil,nil,{{titleBarColor,1}})

    if changeLineColor then
        for i=1,#self.holograms.lines do
            self.holograms.lines[i]:changeHologramData(nil,nil,{{backgroundColor,1}})
        end
    end
end

function winAPI.WindowClass:write(line, text, colorFormat, backgroundColorFormat)
    line = line or 1

    if text then
        text = tostring(text)
        text = text:sub(1,self.textMaxWidth)
    end

    if self.holograms.lines[line] then
        self.holograms.lines[line]:changeHologramData(text,colorFormat,backgroundColorFormat)
    end
    self:update()
end

function winAPI.WindowClass:clear(line)
    if type(line) == "number" then
        if self.holograms.lines[line] then
            self.holograms.lines[line]:changeHologramData("")
        end
    else
        for i=1,#self.holograms.lines do
            self.holograms.lines[i]:changeHologramData("")
        end
    end

    self:update()
end

function winAPI.WindowClass:addSprite(img,priority,x,y)
    x = x or 1
    y = y or 1
    x = x - 1
    if self.x+x > self.sizeX then x = self.sizeX-1 end
    if self.y+y > self.sizeY then y = self.sizeY-1 end
    local spriteOBJ = self.displayOBJ.sprite:addSprite(img,priority,self.x+x,self.y+y,false)
    table.insert(self.sprites.window,spriteOBJ)
    return spriteOBJ
end

function winAPI.WindowClass:addHologram(text,textColor,textBackgroundColor,priority,x,y,dynamic,wrapped)
    x = x or 1
    y = y or 1
    x = x - 1
    if self.x+(x-1) > self.sizeX then x = self.sizeX-1 end
    if self.y+(y-1) > self.sizeY then y = self.sizeY-1 end
    local hologramOBJ = self.displayOBJ.hologram:addHologram(text,textColor,textBackgroundColor,priority,self.x+x,self.y+y,dynamic,wrapped,false)
    table.insert(self.holograms.window,hologramOBJ)
    return hologramOBJ
end

function winAPI.WindowClass:setWindowPos(rootX,rootY)
    if type(rootX) ~= "number" or type(rootY) ~= "number" then return end
    self.x = rootX
    self.y = rootY

    self.sprites.XButton:changeHologramData(nil,nil,nil,rootX,rootY)
    self.holograms.label:changeHologramData(nil,nil,nil,rootX+1,rootY)

    self.sprites.body:changeSpriteData(nil,rootX,rootY)
    local lineX = rootX
    if self.roundEdges then
        lineX = lineX + 1
    end
    for i=1,#self.holograms.lines do
        self.holograms.lines[i]:changeHologramData(nil,nil,nil,lineX,self.y+i)
    end
end

function winAPI.WindowClass:getSize()
    return self.textMaxWidth, self.sizeY-1

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
                if events[3] == self.x and events[4] == self.y and not self.roundEdges then
                    self.loop = false
                elseif events[4] == self.y and (events[3] >= self.x and events[3] <= self.x+(self.sizeX-1)) then
                    distanceToRoot = self.x - events[3]
                    dragSelected = true
                else
                    dragSelected = false
                end
            elseif events[1] == "mouse_drag" and dragSelected then
                for i=1,#self.sprites.window do
                    if type(self.sprites.window[i].x) == "number" then self.sprites.window[i].relX = self.sprites.window[i].x - self.x end
                    if type(self.sprites.window[i].y) == "number" then self.sprites.window[i].relY = self.sprites.window[i].y - self.y end
                end
                for i=1,#self.holograms.window do
                    if type(self.holograms.window[i].x) == "number" then self.holograms.window[i].relX = self.holograms.window[i].x - self.x end
                    if type(self.holograms.window[i].y) == "number" then self.holograms.window[i].relY = self.holograms.window[i].y - self.y end
                end
                self:setWindowPos(events[3]+distanceToRoot,events[4])
                for i=1,#self.sprites.window do
                    self.sprites.window[i]:changeSpriteData(nil,self.x+self.sprites.window[i].relX,self.y+self.sprites.window[i].relY)
                end
                for i=1,#self.holograms.window do
                    self.holograms.window[i]:changeHologramData(nil,nil,nil,self.x+self.holograms.window[i].relX,self.y+self.holograms.window[i].relY)
                end
                if self.loop then UIs.mainScreen:render() end
                self:update()
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

    for i=1,#self.holograms.lines do
        table.insert(self.oldValues.lines,self.holograms.lines[i].text[1])
    end

    self:clear()
    self.sprites.XButton:changeHologramData("")
    self.holograms.label:changeHologramData("")

    self.sprites.body:changeSpriteData({{}})
    self:update()
    UIs.mainScreen:render()
end

function winAPI.WindowClass:reappear()
    self.sprites.XButton:changeHologramData("X")
    self.holograms.label:changeHologramData(self.name)

    self.sprites.body:changeSpriteData(self.bodyImage)

    for i=1,#self.holograms.lines do
        if self.oldValues.lines[i] then
            self.holograms.lines[i]:changeHologramData(self.oldValues.lines[i])
        else
            self.holograms.lines[i]:changeHologramData("")
        end
    end

    self:update()

    self.oldValues = {lines = {}}

    for i=1,#self.holograms.lines do
        table.insert(self.oldValues.lines,self.holograms.lines[i].text[1])
    end
end
