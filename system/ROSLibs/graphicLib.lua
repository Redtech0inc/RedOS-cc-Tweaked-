local colorTable = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black,
}
local function isColorValue(colorValue)
    for color=1,#colorTable do
        if colorTable[color] == colorValue then
            return true
        end
    end
    return false
end
local function toboolean(input)
    if input then
        return true
    end
    return false
end
local function getFileLines(dir)
    if not fs.exists(dir) then error("'"..dir.."' is not an existing file") end
    local file=io.open(dir,"r")
    local output={}
    local returnNext = false
    while true do
        local line=file:read("l")
        if line then
            table.insert(output,line)
            returnNext = false
        elseif returnNext and not line then
            return output
        else
            returnNext = true
        end
    end
end
local function getBiggestIndex(matrix,returnBoth)
    local index1
    local index2 = 0
    for i = 1,#matrix do
        for j = 1,table.maxn(matrix[i]) do
            if j > index2 then
                index2 = j
                index1 = i
            end
        end
    end
    if returnBoth then
        return index1, index2
    end
    return index2
end
local function fromBlit(value)
    if tostring(value) == "0" then return colors.white end
    if tostring(value) == "1" then return colors.orange end
    if tostring(value) == "2" then return colors.magenta end
    if tostring(value) == "3" then return colors.lightBlue end
    if tostring(value) == "4" then return colors.yellow end
    if tostring(value) == "5" then return colors.lime end
    if tostring(value) == "6" then return colors.pink end
    if tostring(value) == "7" then return colors.gray end
    if tostring(value) == "8" then return colors.lightGray end
    if tostring(value) == "9" then return colors.cyan end
    if tostring(value) == "a" then return colors.purple end
    if tostring(value) == "b" then return colors.blue end
    if tostring(value) == "c" then return colors.brown end
    if tostring(value) == "d" then return colors.green end
    if tostring(value) == "e" then return colors.red end
    if tostring(value) == "f" then return colors.black end
end
local function wrapHologramText(text, x, width)
    local text = tostring(text)
    local textTable = {}
    local line = ""
    local width = width- (x - 1)
    for rawLine in text:gmatch("([^\n]*)\n?") do
        local words = {}
        for word in rawLine:gmatch("%S+") do
            table.insert(words, word)
        end
        local i = 1
        while i <= #words do
            local word = words[i]
            if #word > width then
                if #line > 0 then
                    table.insert(textTable, line)
                    line = ""
                end
                while #word > width do
                    table.insert(textTable, word:sub(1, width))
                    word = word:sub(width + 1)
                end
                line = word
            elseif #line + #word + (line == "" and 0 or 1) > width then
                table.insert(textTable, line)
                line = word
            else
                line = (#line > 0) and (line .. " " .. word) or word
            end
            i = i + 1
        end
        if #line > 0 then
            table.insert(textTable, line)
            line = ""
        end
    end
    if #line > 0 then
        table.insert(textTable, line)
    end
    local maxWidth = 0
    for i = 1, #textTable do
        if #textTable[i] > maxWidth then
            maxWidth = #textTable[i]
        end
    end
    return textTable, maxWidth
end
local function drawPixel(x, y, color)
    if monitor then
        monitor.setCursorPos(x, y)
        monitor.setBackgroundColor(color)
        monitor.write(" ")
    else
        term.setCursorPos(x, y)
        term.setBackgroundColor(color)
        term.write(" ")
    end
end
Frame={}
Frame.__index = Frame
local sprite = {}
sprite.__index = sprite
local hologram = {}
hologram.__index = hologram
local group = {}
group.__index = group
function sprite:clone(parentObject,priority,x,y,screenBound,group)
    local spriteData = {}
    local sandbox = parentObject.sandbox
    if type(priority) ~= "number" then
        priority=#sandbox.data.objects.render.sprites.list+1
    end
    if type(x) ~= "number" then
        x=1
    end
    if type(y) ~= "number" then
        y=1
    end
    if (x < 1-#parentObject.sprite or x > sandbox.data.width) and parentObject.screenBound then
        x=1
    end
    if (y < 1-table.maxn(parentObject.sprite[1]) or y > sandbox.data.height) and parentObject.screenBound then
        y=1
    end
    spriteData.x = math.floor(x)
    spriteData.y = math.floor(y)
    spriteData.type = "spriteClone"
    spriteData.sprite = parentObject
    spriteData.priority = priority
    spriteData.group = group
    spriteData.screenBound = toboolean(screenBound)
    setmetatable(spriteData,sprite)
    table.insert(sandbox.data.objects.render.sprites.list,{spriteData,priority})
    if group then
        group:addObjectsToGroup({spriteData})
    end
    return spriteData
end
function hologram:clone(parentObject,priority,x,y,screenBound,group,wrapped)
    local hologramData= {}
    local sandbox = parentObject.sandbox
    if not priority then
        if parentObject.dynamic then
            priority = #sandbox.data.objects.render.holograms.list+1
        else
            priority = #sandbox.data.objects.render.backgroundHolograms.list+1
        end
    end
    local textMaxWidth, correctionsCycles
    if wrapped then correctionsCycles=3 else correctionsCycles = 1 end
    for _=1,correctionsCycles do
        if wrapped then
            _, textMaxWidth = wrapHologramText(parentObject.text,hologramData.x,sandbox.data.width)
        else
            textMaxWidth = #parentObject.text
        end
        if (x < 1-textMaxWidth or x > sandbox.data.width) and screenBound then
            x=1
        end
        if (y < 1 or y > sandbox.data.height) and screenBound then
            y=1
        end
    end
    hologramData.x = math.floor(x)
    hologramData.y = math.floor(y)
    hologramData.text = parentObject
    hologramData.priority = priority
    hologramData.textMaxWidth = textMaxWidth
    hologramData.type = "hologramClone"
    hologramData.group = group
    hologramData.wrapped = toboolean(wrapped)
    hologramData.screenBound = toboolean(screenBound)
    setmetatable(hologramData,hologram)
    if parentObject.dynamic then
        table.insert(sandbox.data.objects.render.holograms.list,{hologramData,priority})
    else
        table.insert(sandbox.data.objects.render.backgroundHolograms.list,{hologramData,priority})
    end
    if group then
        group:addObjectsToGroup({hologramData})
    end
    return hologramData
end
function sprite:changeSpriteCloneData(x,y,screenBound)
    local sandbox = self.sandbox
    if self.type == "sprite" then return end
    if screenBound ~= nil then self.screenBound = toboolean(screenBound) end
    if self.sprite.sprite then
        if type(x) == "number" then
            if not (x < 2-#self.sprite.sprite) and not (x > sandbox.data.width) then
                self.x = math.floor(x)
            elseif not self.screenBound then
                self.x = math.floor(x)
            end
        end
        if type(y) == "number" then
            if not (y < 2-table.maxn(self.sprite.sprite[1])) and not (y > sandbox.data.height) then
                self.y = math.floor(y)
            elseif not self.screenBound then
                self.y = math.floor(y)
            end
        end
    end
end
function hologram:changeHologramCloneData(x,y,screenBound,wrapped)
    local sandbox = self.sandbox
    if self.type == "hologram" then return end
    if wrapped ~= nil then self.wrapped = toboolean(wrapped) end
    if screenBound ~= nil then self.screenBound = toboolean(screenBound) end
    local correctionsCycles
    if wrapped then correctionsCycles=3 else correctionsCycles = 1 end
    for _=1,correctionsCycles do
        if self.text.text ~= nil then
            if type(x) == "number" then
                if not (x < 2-self.text.textMaxWidth) and not (x > sandbox.data.width) then
                    self.x = math.floor(x)
                elseif not self.screenBound then
                    self.x = math.floor(x)
                end
            end
            if type(y) == "number" then
                if not (y < 1) and not (y > sandbox.data.height) then
                    self.y = math.floor(y)
                elseif not self.screenBound then
                    self.y = math.floor(y)
                end
            end
        end
    end
end
function Frame:gatherColorValues()
    local r, g, b
    for i = 1,#colorTable do
        if self.data.monitor then
            r,g,b = self.data.monitor.getPaletteColor(colorTable[i])
        else
            r,g,b = term.getPaletteColor(colorTable[i])
        end
        table.insert(self.data.colorList,{r,g,b})
    end
end
function Frame:useColorValues()
    for i =1,#self.data.colorList do
        if self.data.monitor then
            self.data.monitor.setPaletteColor(colorTable[i],self.data.colorList[i][1],self.data.colorList[i][2],self.data.colorList[i][3])
        else
            term.setPaletteColor(colorTable[i],self.data.colorList[i][1],self.data.colorList[i][2],self.data.colorList[i][3])
        end
    end
end
function Frame:init(name,onErrorCall,useMonitor,allowFallback,monitorFilter,pixelSize,screenStartX,screenStartY,screenWidth,screenHeight)
    local obj = {data={screen={},groups={list={},lastID=0},objects={render={background={},backgroundHolograms={list={},listLen=-1,renderList={},lastID=0},sprites={list={},listLen=-1,renderList={},lastID=0},holograms={list={},listLen=-1,renderList={},lastID=0}}}}}
    setmetatable(obj,self)
    self.__index = self
    local sizeX,sizeY = term.getSize()
    screenWidth = screenWidth or sizeX+1
    screenHeight = screenHeight or sizeY+1
    obj.data.renderStartX = screenStartX or 1
    obj.data.renderStartY = screenStartY or 1
    obj.data.renderStartX = obj.data.renderStartX -1
    obj.data.renderStartY = obj.data.renderStartY -1
    obj.data.screenEndX = obj.data.renderStartX + (screenWidth - 1)
    obj.data.screenEndY = obj.data.renderStartY + (screenHeight - 1)
    name = name or "Game"
    obj.data.gameName = tostring(name)
    obj.data.colorList = {}
    if type(onErrorCall) ~= "function" then obj.data.errFunc = function() return end end
    if useMonitor then
        if type(monitorFilter) == "table" then
            obj.data.monitor = peripheral.find("monitor",function(name)
                if monitorFilter then 
                    for i =1,#monitorFilter do
                        if name == monitorFilter[i] then
                            return true
                        end
                    end
                    return false
                end
                return true
            end)
        elseif type(monitorFilter) == "function" then
            obj.data.monitor = peripheral.find("monitor",function(name, monitor)
                return monitorFilter(name, monitor)
            end)
        end
        if not obj.data.monitor and not allowFallback then
            if monitorFilter then
                obj.data.errFunc()
                if type(monitorFilter) == "function" then
                    error("could not find monitor, make sure that a monitor that get's accepted by the function is attached or disable the useMonitor variable")
                else
                    error("could not find monitor, make sure that a monitor named:"..textutils.serialise(monitorFilter,{compact=true}).." is attached or disable the useMonitor variable")
                end
                else
                obj.data.errFunc()
                error("could not find monitor, make sure that a monitor is attached or disable the useMonitor variable")
            end
        end
        if type(pixelSize) == "number" and obj.data.monitor then
            if pixelSize >= 0.5 and pixelSize <= 5 then
                obj.data.monitor.setTextScale(pixelSize)
            else
                obj.data.errFunc()
                error("Screen size must be in range of 0.5 to 5")
            end
        end
        if obj.data.monitor then
            obj.data.width, obj.data.height = obj.data.monitor.getSize()
        elseif not obj.data.monitor and allowFallback then
            obj.data.width, obj.data.height = term.getSize()
        end
    else
        obj.data.width, obj.data.height = term.getSize()
    end
    obj.hologram = setmetatable({sandbox=obj},hologram)
    obj.sprite = setmetatable({sandbox=obj},sprite)
    obj.group = setmetatable({sandbox=obj},group)
    Frame.gatherColorValues(obj)
    return obj
end
function Frame:quit(restart,exitMessage,exitMessageColor)
    self:clearFrameWork()
    if type(restart) ~= "boolean" then
        restart=false
    end
    if not isColorValue(exitMessageColor) then
        exitMessageColor = colors.white
    end
    if self.data.monitor then
        self.data.monitor.setTextScale(1)
        self.data.monitor.clear()
        self.data.monitor.setCursorPos(1,1)
    end
    term.clear()
    term.setCursorPos(1,1)
    self:useColorValues()
    if not restart then
        if exitMessage then
            local currentTextColor= term.getTextColor()
            term.write(gameName..": ")
            term.setTextColor(exitMessageColor)
            print(exitMessage)
            term.setTextColor(currentTextColor)
        end
        sleep(0.2)
    else
        os.reboot()
    end
    self.data.gameName, self.data.errFunc, self.data.renderStartX, self.data.renderStartY, self.data.screenEndX, self.data.screenEndY, self.data.width, self.data.height, self.data.monitor = nil, nil ,nil, nil, nil, nil, nil, nil, nil, nil
end
function Frame:clearFrameWork()
    local colorList = self.data.colorList
    self.data={colorList=colorList,screen={},groups={list={},lastID=0},objects={render={background={},backgroundHolograms={list={},listLen=-1,renderList={},lastID=0},sprites={list={},listLen=-1,renderList={},lastID=0},holograms={list={},listLen=-1,renderList={},lastID=0}}}}
end
function Frame:loadImage(imgDir)
    if not fs.exists(imgDir) then self.data.errFunc() error("'"..tostring(imgDir).."' is not an existing File") return end
    local img={}
    local fileLines = getFileLines(imgDir)
    for i=1,#fileLines do
        if img[i] == nil then
            img[i]={}
        end
        for j=1,#fileLines[i] do
            if type(fileLines[i]) == "string" then
                table.insert(img[i],string.sub(fileLines[i],j,j))
            end
        end
    end
    local newImg={}
    for i=1,#img do
        for j=1,table.maxn(img[i]) do
            if newImg[j] == nil then
                newImg[j]={}
            end
            newImg[j][i]=fromBlit(img[i][j])
        end
    end
    return newImg
end
function Frame:setPaletteColor(color,hex,g,b)
    if not color or not hex then self.data.errFunc() error("no color and/or hex given!") return end
    local r
    if not g and not b then
        if string.find(hex,"#",1,true) then
            hex = string.gsub(hex,"#","0x",1)
            if not tonumber(hex) then self.data.errFunc() error("hex argument was not acceptable may have been incorrectly formatted") end
            hex = tonumber(string.format("0x%X", hex))
        elseif type(hex) ~= "number" then
            hex=tonumber(hex)
        end
        if not hex then self.data.errFunc() error("hex argument was not acceptable may have been incorrectly formatted") end
        r,g,b=colors.unpackRGB(hex)
    else
        r=hex
        if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
            self.data.errFunc() error("hex,g and b argument must be number")
        end
    end
    if self.data.monitor then
        self.data.monitor.setPaletteColor(color,r,g,b)
    else
        term.setPaletteColor(color,r,g,b)
    end
end
function Frame:getShapeSprite(color,shape,width,height,rightAngled,side)
    local shapeSprite = {}
    if shape == "circle" then
        local center = width + 1
        for i= 1, 2*width + 1 do
            shapeSprite[i]={}
            for j= 1, 2*width+1 do
                local dx = j - center
                local dy = i - center
                if dx * dx + dy * dy <= width * width then
                    shapeSprite[i][j] = color
                end
            end
        end
    elseif shape == "triangle" then
        if rightAngled then
            for i = 1, height do
                shapeSprite[i] = {}
                for j = 1, height do
                    if j <= i and (not side) or side == "upper" then
                        shapeSprite[i][j] = color
                    elseif j >= i and side then
                        shapeSprite[i][j] = color
                    end
                end
            end
        else
            shapeSprite = {}
            local centerX = height
            for i = 1,height do
                for j = 1,height * 2 do
                    if not shapeSprite[j] then
                        shapeSprite[j] = {}
                    end
                    if j >= centerX - (i-1) and j<= centerX + (i-1) then
                        shapeSprite[j][i] = color
                    end
                end
            end
        end
    else
        for i=1,width do
            shapeSprite[i]={}
            for j=1,height do
                shapeSprite[i][j]=color
            end
        end
    end
    return shapeSprite
end
function Frame:turnSprite(sprite, times)
    if not sprite then self.data.errFunc() error("the sprite variable has to be a 2D Image(Matrix)") end
    if type(times) ~= "number" then times = 0 end
    times = times % 4
    for _ = 1, times do
        local rotated = {}
        local rows = #sprite
        local maxCol = 0
        for i = 1, #sprite do
            maxCol = math.max(maxCol, #sprite[i])
        end
        for x = 1, maxCol do
            rotated[x] = {}
            for y = rows, 1, -1 do
            rotated[x][rows - y + 1] = sprite[y][x] or nil
            end
        end
        sprite={}
        for i=1,#rotated do
            sprite[i]={}
            for j=1,table.maxn(rotated[i]) do
                sprite[i][j] = rotated[i][j]
            end
        end
    end
    return sprite
end
function Frame:setBackgroundImage(img)
    self.data.objects.render.background=img
end
function sprite:addSprite(img,priority,x,y,screenBound)
    local spriteData = {}
    setmetatable(spriteData,sprite)
    local sandbox = self.sandbox
    spriteData.sandbox = sandbox
    if type(x) ~= "number" then x = 1 end
    if type(y) ~= "number" then y = 1 end
    if screenBound == nil then screenBound = true end
    spriteData.screenBound = toboolean(screenBound)
    if type(img) ~= "table" then sandbox.data.errFunc() error("image has to be a table ('"..type(img).."' was supplied)") end
    if type(priority) ~= "number" then
        priority=#sandbox.data.objects.render.sprites.list+1
    end
    if type(x) ~= "number" then
        x=1
    end
    if type(y) ~= "number" then
        y=1
    end
    if (x < 1-#img or x > sandbox.data.width) and spriteData.screenBound then
        x=1
    end
    if (y < 1-table.maxn(img[1]) or y > sandbox.data.height) and spriteData.screenBound then
        y=1
    end
    spriteData.id = sandbox.data.objects.render.sprites.lastID + 1
    sandbox.data.objects.render.sprites.lastID = sandbox.data.objects.render.sprites.lastID + 1
    spriteData.x = math.floor(x)
    spriteData.y = math.floor(y)
    spriteData.type = "sprite"
    spriteData.sprite = img
    spriteData.priority = priority
    table.insert(sandbox.data.objects.render.sprites.list,{spriteData,priority})
    return spriteData
end
function hologram:addHologram(text,textColor,textBackgroundColor,priority,x,y,dynamic,wrapped,screenBound)
    local hologramData= {}
    setmetatable(hologramData,hologram)
    local sandbox = self.sandbox
    hologramData.sandbox = sandbox
    if type(x) ~= "number" then x = 1 end
    if type(y) ~= "number" then y = 1 end
    if dynamic == nil then dynamic = true end
    hologramData.dynamic = toboolean(dynamic)
    hologramData.wrapped = toboolean(wrapped)
    hologramData.screenBound = toboolean(screenBound)
    hologramData.textColor = textColor
    hologramData.textBackgroundColor = textBackgroundColor

    if hologramData.dynamic then
        hologramData.id = sandbox.data.objects.render.holograms.lastID + 1
        sandbox.data.objects.render.holograms.lastID = sandbox.data.objects.render.holograms.lastID + 1
    else
        hologramData.id = sandbox.data.objects.render.backgroundHolograms.lastID + 1
        sandbox.data.objects.render.backgroundHolograms.lastID = sandbox.data.objects.render.backgroundHolograms.lastID + 1
    end

    if not priority then
        if hologramData.dynamic then
            priority = #sandbox.data.objects.render.holograms.list+1
        else
            priority = #sandbox.data.objects.render.backgroundHolograms.list+1
        end
    end
    local textOut, textMaxWidth, correctionsCycles
    if hologramData.wrapped then correctionsCycles=3 else correctionsCycles = 1 end
    for _=1,correctionsCycles do
        if wrapped then
            textOut, textMaxWidth = wrapHologramText(hologramData.text,hologramData.x,sandbox.data.width)
        else
            textOut = {text}
            textMaxWidth = #text
        end
        if (x < 1-textMaxWidth or x > sandbox.data.width) and screenBound then
            x=1
        end
        if (y < 1 or y > sandbox.data.height) and screenBound then
            y=1
        end
    end
    hologramData.x = math.floor(x)
    hologramData.y = math.floor(y)
    hologramData.text = textOut
    hologramData.priority = priority
    hologramData.textMaxWidth = textMaxWidth
    hologramData.type = "hologram"
    if hologramData.dynamic then
        table.insert(sandbox.data.objects.render.holograms.list,{hologramData,priority})
    else
        table.insert(sandbox.data.objects.render.backgroundHolograms.list,{hologramData,priority})
    end
    return hologramData
end
function group:groupObjects(objects)
    local groupData = {}
    setmetatable(groupData,group)
    local sandbox = self.sandbox
    groupData.sandbox = sandbox
    groupData.id = sandbox.data.groups.lastID + 1
    sandbox.data.groups.lastID = sandbox.data.groups.lastID + 1
    if type(objects) == "table" and not (objects.x or objects.lvlTable) then
        groupData.lvlTable = objects
    else
        groupData.lvlTable = {}
    end
    groupData.type = "group"
    table.insert(sandbox.data.groups.list,groupData)
    return groupData
end
function hologram:remove()
    local sandbox = self.sandbox
    if self.dynamic then
        for i=1,#sandbox.data.objects.render.holograms.list do
            print(self.id,sandbox.data.objects.render.holograms.list[i][1].id)
            sleep(0.1)
            if self.id == sandbox.data.objects.render.holograms.list[i][1].id then
                sandbox.data.objects.render.holograms.list[i] = nil
            end
        end
        sandbox.data.objects.render.holograms.listLen = -1
    else
        for i=1,#sandbox.data.objects.render.backgroundHolograms.list do
            if self.id == sandbox.data.objects.render.backgroundHolograms.list[i][1].id then
                sandbox.data.objects.render.backgroundHolograms.list[i] = nil
            end
        end
        sandbox.data.objects.render.backgroundHolograms.listLen = -1
    end
    setmetatable(self, {
        __index = function()
            return function()
                sandbox.data.errFunc()
                error("ERROR: Can't use a removed hologram")
            end
        end
    })
end
function sprite:remove()
    local sandbox =self.sandbox
    for i=1,#sandbox.data.objects.render.sprites.list do
        if self.id == sandbox.data.objects.render.sprites.list[i][1].id then
            sandbox.data.objects.render.sprites.list[i] = nil
        end
    end
    setmetatable(self, {
        __index = function()
            return function()
                sandbox.data.errFunc()
                error("ERROR: Can't use a removed sprite")
            end
        end
    })
    sandbox.data.objects.render.sprites.listLen =  -1
end
function group:remove()
    local sandbox = self.sandbox
    for i=1,#sandbox.data.groups.list do
        if self.id == sandbox.data.groups.list[i].id then
            sandbox.data.groups.list[i] = nil
        end
    end
    setmetatable(self, {
        __index = function()
            return function()
                sandbox.data.errFunc()
                error("ERROR: Can't use a removed group")
            end
        end
    })
end
function sprite:changeSpriteData(img,x,y,screenBound)
    local sandbox = self.sandbox
    if self.type == "spriteClone" then self:changeSpriteCloneData(x, y, screenBound) return end
    if screenBound ~= nil then self.screenBound = toboolean(screenBound) end
    if self.sprite then
        if type(x) == "number" then
            if not (x < 2-#self.sprite) and not (x > sandbox.data.width) then
                self.x = math.floor(x)
            elseif not self.screenBound then
                self.x = math.floor(x)
            end
        end
        if type(y) == "number" then
            if not (y < 2-table.maxn(self.sprite[1])) and not (y > sandbox.data.height) then
                self.y = math.floor(y)
            elseif not self.screenBound then
                self.y = math.floor(y)
            end
        end
    end
    if type(img) =="table" and self.sprite then
        self.sprite = img
    end
end
function hologram:changeHologramData(text,textColor,textBackgroundColor,x,y,wrapped,screenBound)
    local sandbox = self.sandbox
    if self.type == "hologramClone" then self:changeHologramCloneData(x, y,screenBound,wrapped) return end
    if wrapped ~= nil then self.wrapped = toboolean(wrapped) end
    if screenBound ~= nil then self.screenBound = toboolean(screenBound) end
    local correctionsCycles
    if wrapped then correctionsCycles=3 else correctionsCycles = 1 end
    for _=1,correctionsCycles do
        if self.text ~= nil then
            if type(x) == "number" then
                if not (x < 2-self.textMaxWidth) and not (x > sandbox.data.width) then
                    self.x = math.floor(x)
                elseif not self.screenBound then
                    self.x = math.floor(x)
                end
            end
            if type(y) == "number" then
                if not (y < 1) and not (y > sandbox.data.height) then
                    self.y = math.floor(y)
                elseif not self.screenBound then
                    self.y = math.floor(y)
                end
            end
        end
        if text then
            if wrapped then
                self.text, self.textMaxWidth = wrapHologramText(text,self.x,sandbox.data.width)
            else
                self.text = {text}
                self.textMaxWidth = #text
            end
        end
    end
    if type(textColor) == "table" then
        self.textColor = textColor
    end
    if type(textBackgroundColor) == "table" then
        self.textBackgroundColor = textBackgroundColor
    end
end
function group:addObjectsToGroup(objects)
    local sandbox =self.sandbox
    if type(objects) ~= "table" then
        sandbox.data.errFunc() error("this function was not give a tables made of objects")
    end
    if objects.x or objects.lvlTable then
        error("this is a object")
    end
    for i=1,#objects do
        table.insert(self.lvlTable,objects[i])
    end
end
function group:removeObjectFromGroup(object)
    for i = 1,#self.lvlTable do
        if object == self.lvlTable[i] then
            table.remove(self.lvlTable,i)
        end
    end
end
function group:changeGroupData(x,y,screenBound)
    for i = 1,#self.lvlTable do
        local object = self.lvlTable[i]
        if type(x) == "number" then
            object.x = object.x + math.floor(x)
        end
        if type(y) == "number" then
            object.y = object.y + math.floor(y)
        end
        if not screenBound == nil then
            object.screenBound = toboolean(screenBound)
        end
    end
end
function Frame:cloneObject(object,priority,x,y,screenBound,group,wrapped)
    if object.type == "sprite" then
        return sprite:clone(object,priority,x,y,screenBound,group)
    elseif object.type == "hologram" then 
        return hologram:clone(object,priority,x,y,screenBound,group,wrapped)
    end
end
function Frame:isColliding(obj1, obj2, isTransparent)
    if isTransparent == nil then
        isTransparent = false
    end
    if not obj1 or not obj2 or not obj1.type or not obj2.type then return false end
    if obj1.type == "group" and obj2.type == "group" then
        local groupList1=obj1.lvlTable
        local groupList2=obj2.lvlTable
        if type(groupList1) ~= "table" or type(groupList2) ~= "table" then return false end
        for i=1,table.maxn(groupList1) do
            for j=1,table.maxn(groupList2) do
                if isColliding(groupList1[i], groupList2[j], isTransparent) then
                    return true
                end
            end
        end
        return false
    elseif obj1.type == "group" and obj2.type ~= "group" then
        local groupList=obj1.lvlTable
        if type(groupList) ~= "table" then return false end
        for i=1,table.maxn(groupList) do
            if isColliding(groupList[i], obj2, isTransparent) then
                return true
            end
        end
        return false
    elseif obj1.type ~= "group" and obj2.type == "group" then
        local groupList=obj2.lvlTable
        if type(groupList) ~= "table" then return false end
        for i=1,table.maxn(groupList) do
            if isColliding(groupList[i], obj1, isTransparent) then
                return true
            end
        end
        return false
    end
    if not (obj1.x and obj1.y and obj2.x and obj2.y) then return false end
    local x1, y1 = obj1.x + self.data.renderStartX, obj1.y + self.data.renderStartY
    local x2, y2 = obj2.x + self.data.renderStartX, obj2.y + self.data.renderStartY
    local w1, h1, w2, h2 = 0, 0, 0, 0
    if obj1.type == "sprite" or obj1.type == "spriteClone" then
        if not obj1.sprite then return false end
        if obj1.type == "spriteClone" then
            if not obj1.sprite.sprite then return false end
            w1, h1 = #obj1.sprite.sprite, getBiggestIndex(obj1.sprite.sprite)
        else
            w1, h1 = #obj1.sprite, getBiggestIndex(obj1.sprite)
        end
    elseif obj1.type == "hologram" or obj1.type == "hologramClone" then
        if not obj1.text then return false end
        local text
        if obj1.type == "hologramClone" then
            if not obj1.text.text then return false end
            text = obj1.text.text
        else
            text = obj1.text.text
        end
        for i=1,#text do
            if w1 < #tostring(text[i]) then
                w1 = #tostring(text[i])
            end
        end
        h1 = #text
    end
    if obj2.type == "sprite" or obj2.type == "spriteClone" then
        if not obj2.sprite then return false end
        if obj2.type == "spriteClone" then
            if not obj2.sprite.sprite then return false end
            w2, h2 = #obj2.sprite.sprite, getBiggestIndex(obj2.sprite.sprite)
        else
            w2, h2 = #obj2.sprite, getBiggestIndex(obj2.sprite)
        end
    elseif obj2.type == "hologram" or obj2.type == "hologramClone" then
        if not obj2.text then return false end
        local text
        if obj2.type == "hologramClone" then
            if not obj2.text.text then return false end
            text = obj2.text.text
        else
            text = obj2.text
        end
        for i=1,#text do
            if w2 < #tostring(text[i]) then
                w2 = #tostring(text[i])
            end
        end
        h2 = #text
    end
    if x1 + w1 <= x2 or x1 >= x2 + w2 or y1 + h1 <= y2 or y1 >= y2 + h2 then
        return false
    end
    if (obj1.type == "sprite" or obj1.type == "spriteClone") and (obj2.type == "sprite" or obj2.type == "spriteClone") then
        local sprite1, sprite2 = obj1.sprite, obj2.sprite
        if obj1.type=="spriteClone" then
            sprite1 = obj1.sprite.sprite
        end
        if obj2.type=="spriteClone" then
            sprite2 = obj2.sprite.sprite
        end
        if not (sprite1 and sprite2) then return false end
        for i = 1, #sprite1 do
            for j = 1, table.maxn(sprite1[i]) do
                local px1, py1 = x1 + i - 1, y1 + j - 1
                local relX, relY = px1 - x2 + 1, py1 - y2 + 1
                if relX > 0 and relY > 0 and sprite2[relX] and sprite2[relX][relY] then
                    if (not isTransparent) and (isColorValue(sprite1[i][j]) and isColorValue(sprite2[relX][relY])) then
                        return true
                    elseif isTransparent then
                        return true
                    end
                end
            end
        end
    end
    if (obj1.type == "sprite" or obj1.type == "spriteClone") and (obj2.type == "hologram" or obj2.type == "hologramClone") then
        local sprite = obj1.sprite
        if obj1.type=="spriteClone" then
            sprite = obj1.sprite.sprite
        end
        local text = obj2.text
        if obj2.type == "hologramClone" then
            text = obj2.text.text
        end
        if not sprite then return false end
        for i = 1, #sprite do
            for j = 1, table.maxn(sprite[i]) do
                if relY >= 1 and relY <= #text then
                    local textLine = text[relY]
                    if relX >= 1 and relX <= #textLine then
                        local textChar = textLine:sub(relX, relX)
                        if sprite[i][j] and textChar ~= " " and not isTransparent then
                            return true
                        elseif isTransparent then
                            return true
                        end
                    end
                end
            end
        end
    end
    if obj1.type == "hologram" and (obj2.type == "sprite" or obj2.type == "spriteClone") then
        return isColliding(obj2, obj1, isTransparent)
    end
    if (obj1.type == "hologram" or obj1.type == "hologramClone") and (obj2.type == "hologram" or obj2.type == "hologramClone") then
        local text1, text2 = obj1.text, obj2.text
        if obj1.type == "hologramClone" then
            text1 = obj1.text.text
        end
        if obj2.type == "hologramClone" then
            text2 = obj2.text.text
        end
        for i = 1, #text1 do
            if relY >= 1 and relY <= #text2 then
                local textLine1 = text1[i]
                local textLine2 = text2[relY]
                local startX1 = x1 + (text1[i]:find("%S") or 1) - 1
                local startX2 = x2 + (text2[relY]:find("%S") or 1) - 1
                for j = 1, #textLine1 do
                    local relX = startX1 + (j - 1) - startX2 + 1
                    if relX >= 1 and relX <= #textLine2 then
                        local char1 = textLine1:sub(j, j)
                        local char2 = textLine2:sub(relX, relX)
                        if char1 ~= " " and char2 ~= " " and not isTransparent then
                            return true
                        elseif isTransparent then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
function Frame:isCollidingRaw(xIn, yIn, obj, isTransparent)
    if type(xIn) ~="number" or type(yIn) ~= "number" then
        self.data.errFunc()
        error("argument 1 and 2 must be numbers")
    end
    if isTransparent == nil then
        isTransparent = false
    end
    if not obj or not obj.type then return false end
    if obj.type == "group" then
        local groupList=obj.lvlTable
        if type(groupList) ~= "table" then return false end
        for i=1,#groupList do
            if isCollidingRaw(xIn, yIn, groupList[i], isTransparent) then
                return true
            end
        end
        return false
    end
    if not (obj.x and obj.y) then return false end
    local x, y = obj.x + self.data.renderStartX, obj.y + self.data.renderStartY
    local w, h = 0, 0
    if obj.type == "sprite" or obj.type == "spriteClone" then
        if not obj.sprite then return false end
        if obj.type == "spriteClone" then
            if not obj.sprite.sprite then return false end
            w, h = #obj.sprite.sprite , getBiggestIndex(obj.sprite.sprite )
        else
            w, h = #obj.sprite, getBiggestIndex(obj.sprite)
        end
    elseif obj.type == "hologram" or obj.type == "hologramClone" then
        if not obj.text then return false end
        local text 
        if obj.type == "hologramClone" then
            text = obj.text.text
        else
            text = obj.text
        end
        for i=1,#text do
            if w < #tostring(text[i]) then
                w = #tostring(text[i])
            end
        end
        h = #text
    end
    if xIn < x or xIn >= x + w or yIn < y or yIn >= y + h then
        return false
    end
    if obj.type == "sprite" or obj.type == "spriteClone" then
        local sprite
        if obj.type == "spriteClone" then
            sprite=obj.sprite.sprite
        else
            sprite = obj.sprite
        end
        if not sprite then return false end
        local spriteX = xIn - x + 1
        local spriteY = yIn - y + 1
        local pixel = sprite[spriteX] and sprite[spriteX][spriteY]
        if not isColorValue(pixel) and not isTransparent then
            return false
        end
    end
    if obj.type == "hologram" or obj.type == "hologramClone" then
        local text
        if obj.type == "hologramClone" then
            text = obj.text.text
        else
            text = obj.text
        end
        local textX = xIn - x + 1
        local textY = yIn - y + 1
        local line = text[textY]
        if line then
            local char = line:sub(textX, textX)
            if char == " " and not isTransparent then
                return false
            end
        else
            return false
        end
    end
    return true
end
function hologram:read(width, preFix, character, onChar, onKey)
    local sandbox = self.sandbox
    if sandbox.data.monitor then printError("ERRORecp: TDGameLib.read should not be used when rendering on a screen!") end
    if not (self.text and self.y and self.x) then sandbox.data.errFunc() error("Invalid hologram object") end
    if type(width) ~= "number" then sandbox.data.errFunc() error("width must be a number") end
    if self.type == "hologramClone" then sandbox.data.errFunc() error("1 argument can't be a clone") end
    preFix = preFix or ""
    preFix = tostring(preFix)
    local currentBackgroundColor = term.getBackgroundColor()
    local currentTextColor = term.getTextColor()
    local preWrapped = self.wrapped
    local readOut, cursorPos = "", 0
    local displayText = ""
    local event, key
    local y = self.y
    local startX = self.x
    self.wrapped = false
    if type(onChar) ~= "function" then 
        onChar = function(key, readOut, cursorPos)
            readOut = readOut:sub(1, cursorPos) .. key .. readOut:sub(cursorPos + 1)
            cursorPos = cursorPos + 1
            return readOut, cursorPos
        end
    end
    if type(onKey) ~= "function" then
        onKey = function(key, readOut, cursorPos)
            if key == keys.backspace and cursorPos > 0 then
                readOut = readOut:sub(1, cursorPos - 1) .. readOut:sub(cursorPos + 1)
                cursorPos = cursorPos - 1
            elseif key == keys.left and cursorPos > 0 then
                cursorPos = cursorPos - 1
            elseif key == keys.right and cursorPos < #readOut then
                cursorPos = cursorPos + 1
            end
            return readOut, cursorPos
        end
    end
    while key ~= keys.enter do
        term.setCursorBlink(true)
        local displayStart = math.max(1, cursorPos - width + 2)
        local displayEnd = displayStart + width - 1
        local rawDisplay = readOut:sub(displayStart, displayEnd)
        if character then
            displayText = string.rep(character, #rawDisplay)
        else
            displayText = rawDisplay
        end
        if #displayText < width then
            displayText =displayText .. string.rep(" ", width - #displayText)
        end
        displayText = preFix .. displayText
        self.text = {displayText}
        term.setCursorBlink(false)
        self:render()
        term.setCursorBlink(true)
        local relativeCursor = cursorPos - displayStart + 2
        local cursorX = #preFix + startX + math.min(math.max(0, relativeCursor - 1), width)
        term.setCursorPos(cursorX, y)
        event, key = os.pullEvent()
        if event == "char" then
            readOut, cursorPos = onChar(key, readOut, cursorPos)
        elseif event == "key" then
            readOut, cursorPos = onKey(key, readOut, cursorPos)
        end
        if type(cursorPos) ~= "number" then sandbox.data.errFunc() error("ERROR: onKey or onChar returned invalid cursorPos (returned type: '"..type(cursorPos).."') should have been type: 'number'") end
        if type(readOut) ~= "string" then sandbox.data.errFunc() error("ERROR: onKey or onChar did not return a string (returned type: '"..type(readOut).."') should have been type: 'string'") end
        cursorPos = math.floor(cursorPos)
    end
    self.wrapped = preWrapped
    term.setCursorBlink(false)
    term.setCursorPos(1, y + 1)
    term.setTextColor(currentTextColor)
    term.setBackgroundColor(currentBackgroundColor)
    return readOut
end
function sprite:render()
    local sandbox = self.sandbox
    if sandbox.data.monitor then
        sandbox.data.monitor.setCursorPos(1,1)
    else
        term.setCursorPos(1,1)
    end
    local renderSprite = self.sprite or {}
    if self.type == "spriteClone" then
        renderSprite = self.sprite.sprite or {}
    end
    local renderX = self.x or 1
    local renderY = self.y or 1
    renderX = renderX - 1
    renderY = renderY -1
    for i = 1, #renderSprite do
        for j = 1, table.maxn(renderSprite[i]) do
            if isColorValue(renderSprite[i][j]) then
                drawPixel(i + renderX + sandbox.data.renderStartX, j + renderY + sandbox.data.renderStartY, renderSprite[i][j])
                if sandbox.data.screen[i + renderX] then
                    if sandbox.data.screen[i + renderX][j + renderY] and isColorValue(renderSprite[i][j]) then
                        sandbox.data.screen[i + renderX][j + renderY] = renderSprite[i][j]
                    end
                end
            end
        end
    end
end
function hologram:render()
    local sandbox = self.sandbox
    if self.dynamic then
        local renderText = self.text
        local renderTextColor = self.textColor
        local renderTextBackgroundColor = self.textBackgroundColor
        if self.type == "hologramClone" then
            renderText = self.text.text
            renderTextColor = self.textColor.textColor
            renderTextBackgroundColor = self.textBackgroundColor.textBackgroundColor
        end
        if sandbox.data.monitor then
            sandbox.data.monitor.setTextColor(colors.white)
        else
            term.setTextColor(colors.white)
        end
        local renderX = self.x or 1
        local renderY = self.y or 1
        local textColorTable = {}
        if type(renderTextColor) == "table" then
            for i=1,#renderTextColor do
                if (type(renderTextColor[i]) == "table") and #renderTextColor[i] >= 2 then
                    textColorTable[renderTextColor[i][2]] = renderTextColor[i][1]
                end
            end
        end
        local textBackgroundColorTable = {}
        if type(renderTextBackgroundColor) == "table" then
            for i=1,#renderTextBackgroundColor do
                if (type(renderTextBackgroundColor[i]) == "table") and #renderTextBackgroundColor[i] >= 2 then
                    textBackgroundColorTable[renderTextBackgroundColor[i][2]] = renderTextBackgroundColor[i][1]
                end
            end
        end
        local textBackgroundColorSet = false
        local textColorPos = 0
        local textOut = ""
        for i =1, #renderText do
            if sandbox.data.monitor then
                sandbox.data.monitor.setCursorPos(renderX + sandbox.data.renderStartX, renderY + sandbox.data.renderStartY + (i - 1))
            else
                term.setCursorPos(renderX + sandbox.data.renderStartX, renderY + sandbox.data.renderStartY + (i - 1))
            end
            textOut = tostring(renderText[i])
            for j = 1, #renderText[i] do
                if isColorValue(textColorTable[j+textColorPos]) then
                    if sandbox.data.monitor then
                        sandbox.data.monitor.setTextColor(textColorTable[j+textColorPos])
                    else
                        term.setTextColor(textColorTable[j+textColorPos])
                    end
                end
                if isColorValue(textBackgroundColorTable[j+textColorPos]) then
                    if sandbox.data.monitor then
                        sandbox.data.monitor.setBackgroundColor(textBackgroundColorTable[j+textColorPos])
                    else
                        term.setBackgroundColor(textBackgroundColorTable[j+textColorPos])
                    end
                    textBackgroundColorSet = true
                elseif sandbox.data.screen[renderX + (j - 1)] then
                    if isColorValue(sandbox.data.screen[renderX + (j - 1)][renderY + (i - 1)]) and not textBackgroundColorSet then
                        if sandbox.data.monitor then
                            sandbox.data.monitor.setBackgroundColor(sandbox.data.screen[renderX + (j - 1)][renderY + (i - 1)])
                        else
                            term.setBackgroundColor(sandbox.data.screen[renderX + (j - 1)][renderY + (i - 1)])
                        end
                    end
                end
                if sandbox.data.monitor then
                    sandbox.data.monitor.write(string.sub(textOut, j, j))
                else
                    term.write(string.sub(textOut, j, j))
                end
            end
            textColorPos = textColorPos + #textOut
        end
    else
        local renderText = self.text
        local renderTextColor = self.textColor
        local renderTextBackgroundColor = self.textBackgroundColor
        if self.type == "hologramClone" then
            renderText = self.text.text
            renderTextColor = self.text.textColor
            renderTextBackgroundColor = self.text.textBackgroundColor
        end
        local renderX = self.x or 1
        local renderY = self.y or 1
        local textColorTable = {}
        if type(renderTextColor) == "table" then
            for i=1,#renderTextColor do
                if (type(renderTextColor[i]) == "table") and #renderTextColor[i] >= 2 then
                    textColorTable[renderTextColor[i][2]] = renderTextColor[i][1]
                end
            end
        end
        local textBackgroundColorTable = {}
        if type(renderTextBackgroundColor) == "table" then
            for i=1,#renderTextBackgroundColor do
                if (type(renderTextBackgroundColor[i]) == "table") and #renderTextBackgroundColor[i] >= 2 then
                    textBackgroundColorTable[renderTextBackgroundColor[i][2]] = renderTextBackgroundColor[i][1]
                end
            end
        end
        local textBackgroundColorSet = false
        local textColorPos = 0
        local textOut = ""
        for i =1, #renderText do
            if sandbox.data.monitor then
                sandbox.data.monitor.setCursorPos(renderX + sandbox.data.renderStartX, renderY + sandbox.data.renderStartY + (i - 1))
                sandbox.data.monitor.setTextColor(colors.white)
            else
                term.setCursorPos(renderX + sandbox.data.renderStartX, renderY + sandbox.data.renderStartY + (i - 1))
                term.setTextColor(colors.white)
            end
            textOut = tostring(renderText[i])
            for j = 1, #renderText[i] do
                if isColorValue(textColorTable[j]) then
                    if sandbox.data.monitor then
                        sandbox.data.monitor.setTextColor(textColorTable[j+textColorPos])
                    else
                        term.setTextColor(textColorTable[j+textColorPos])
                    end
                end
                if isColorValue(textBackgroundColorTable[j+textColorPos]) then
                    if sandbox.data.monitor then
                        sandbox.data.monitor.setBackgroundColor(textBackgroundColorTable[j+textColorPos])
                    else
                        term.setBackgroundColor(textBackgroundColorTable[j+textColorPos])
                    end
                    textBackgroundColorSet = true
                elseif sandbox.data.screen[renderX + (j - 1)] then
                    if isColorValue(sandbox.data.screen[renderX + (j - 1)][renderY + (i - 1)]) and not textBackgroundColorSet then
                        if sandbox.data.monitor then
                            sandbox.data.monitor.setBackgroundColor(sandbox.data.screen[renderX + (j - 1)][renderY + (i - 1)])
                        else
                            term.setBackgroundColor(sandbox.data.screen[renderX + (j - 1)][renderY + (i - 1)])
                        end
                    end
                end
                if sandbox.data.monitor then
                    sandbox.data.monitor.write(string.sub(textOut, j, j))
                else
                    term.write(string.sub(textOut, j, j))
                end
            end
            textColorPos = textColorPos + #textOut
        end
    end
end
function Frame:renderBackground()
    for i = 1, self.data.width do
        for j = 1, self.data.height do
            if self.data.objects.render.background[i] then
                if isColorValue(self.data.objects.render.background[i][j]) then
                    drawPixel(i + self.data.renderStartX, j + self.data.renderStartY, self.data.objects.render.background[i][j])
                    if not self.data.screen[i] then
                        self.data.screen[i] = {}
                    end
                    self.data.screen[i][j] = self.data.objects.render.background[i][j]
                end
            end
        end
    end
end
function Frame:render()
    self.data.objects.render.subTasks = {}
    local CurX, CurY
    local currentBackgroundColor
    local currentTextColor
    if self.data.monitor then
        CurX, CurY = self.data.monitor.getCursorPos()
        currentBackgroundColor = self.data.monitor.getBackgroundColor()
        currentTextColor = self.data.monitor.getTextColor()
    else
        CurX, CurY = term.getCursorPos()
        currentBackgroundColor = term.getBackgroundColor()
        currentTextColor = term.getTextColor()
    end
    table.insert(self.data.objects.render.subTasks,function()
        for i = 1, self.data.width do
            for j = 1, self.data.height do
                if self.data.objects.render.background[i] then
                    if isColorValue(self.data.objects.render.background[i][j]) then
                        drawPixel(i + self.data.renderStartX, j + self.data.renderStartY, self.data.objects.render.background[i][j])
                        if not self.data.screen[i] then
                            self.data.screen[i] = {}
                        end
                        self.data.screen[i][j] = self.data.objects.render.background[i][j]
                    end
                end
            end
        end
    end)
    if self.data.objects.render.backgroundHolograms.listLen ~= #self.data.objects.render.backgroundHolograms.list then
        self.data.objects.render.backgroundHolograms.renderList = {}
        for i = 1, #self.data.objects.render.backgroundHolograms.list do
            if self.data.objects.render.backgroundHolograms.list[i] ~= nil then
                self.data.objects.render.backgroundHolograms.renderList[self.data.objects.render.backgroundHolograms.list[i][2]] = self.data.objects.render.backgroundHolograms.list[i][1]
                self.data.objects.render.backgroundHolograms.listLen = #self.data.objects.render.backgroundHolograms.list
            end
        end
    end
    if self.data.objects.render.sprites.listLen ~= #self.data.objects.render.sprites.list then
        self.data.objects.render.sprites.renderList = {}
        for i = 1, #self.data.objects.render.sprites.list do
            if self.data.objects.render.sprites.list[i] ~= nil then
                self.data.objects.render.sprites.renderList[self.data.objects.render.sprites.list[i][2]] = self.data.objects.render.sprites.list[i][1]
                self.data.objects.render.sprites.listLen = #self.data.objects.render.sprites.list
            end
        end
    end
    if self.data.objects.render.holograms.listLen ~= #self.data.objects.render.holograms.list then
        self.data.objects.render.holograms.renderList = {}
        for i = 1, #self.data.objects.render.holograms.list do
            if self.data.objects.render.holograms.list[i] ~= nil then
                self.data.objects.render.holograms.renderList[self.data.objects.render.holograms.list[i][2]] = self.data.objects.render.holograms.list[i][1]
                self.data.objects.render.holograms.listLen = #self.data.objects.render.holograms.list
            end
        end
    end
    for i = 1,table.maxn(self.data.objects.render.backgroundHolograms.renderList) do
        if type(self.data.objects.render.backgroundHolograms.renderList[i]) == "table" then
            table.insert(self.data.objects.render.subTasks,function ()
                self.data.objects.render.backgroundHolograms.renderList[i]:render()
            end)
        end
    end
    for i = 1, table.maxn(self.data.objects.render.sprites.renderList) do
        if type(self.data.objects.render.sprites.renderList[i]) == "table" then
            table.insert(self.data.objects.render.subTasks,function ()
                self.data.objects.render.sprites.renderList[i]:render()
            end)
        end
    end
    for i = 1,table.maxn(self.data.objects.render.holograms.renderList) do
        if type(self.data.objects.render.holograms.renderList[i]) == "table" then
            table.insert(self.data.objects.render.subTasks,function ()
                self.data.objects.render.holograms.renderList[i]:render()
            end)
        end
    end
    parallel.waitForAll(table.unpack(self.data.objects.render.subTasks))
    if self.data.monitor then
        self.data.monitor.setTextColor(currentTextColor)
        self.data.monitor.setBackgroundColor(currentBackgroundColor)
        self.data.monitor.setCursorPos(CurX, CurY)
    else
        term.setTextColor(currentTextColor)
        term.setBackgroundColor(currentBackgroundColor)
        term.setCursorPos(CurX, CurY)
    end
end
