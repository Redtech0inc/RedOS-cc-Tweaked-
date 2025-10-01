rosAPI={}

rosAPI.formatting = {

    topLeft = function()
        return 1, 1
    end,

    topRight = function (sizeX)
        local maxX = term.getSize()
        sizeX = sizeX or 1
        return (maxX - sizeX)+1, 1
    end,

    bottomLeft = function (sizeY)
        local _, maxY = term.getSize()
        sizeY = sizeY or 1
        return 1, (maxY - sizeY)+1
    end,

    bottomRight = function (sizeX, sizeY)
        local maxX, maxY = term.getSize()
        sizeX = sizeX or 1
        sizeY = sizeY or 1
        return (maxX - sizeX)+1,  (maxY - sizeY)+1
    end,

    center = function (sizeX, sizeY, roundFunc)
        local maxX, maxY = term.getSize()

        sizeX = sizeX or 1
        sizeY = sizeY or 1

        local posX, posY

        if type(roundFunc) == "function" then
            posX = roundFunc((maxX - sizeX) / 2)+1
            posY = roundFunc((maxY - sizeY) / 2)+1
        else
            posX = math.floor((maxX - sizeX) / 2)+1
            posY = math.floor((maxY - sizeY) / 2)+1
        end

        return posX, posY
    end
}

rosAPI.textutils = {
    wrapText = function (text,x,width)
        x = x or term.getCursorPos()
        width = width or term.getSize()
        width = width- (x - 1)

        text = tostring(text)
        local textTable = {}
        local line = ""
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
        return textTable
    end,

    alignText = {
        center = function (text,roundFunc,y,width)
            local _,currentY = term.getCursorPos()
            y = y or currentY
            local width = width or term.getSize()

            if type(roundFunc) == "function" then
                return roundFunc((width-#text)/2)+1, y
            else
                return math.floor((width-#text)/2)+1, y
            end
        end,

        right = function (text,y,width)
            local _,currentY = term.getCursorPos()
            y = y or currentY
            local width = width or term.getSize()

            return width-#text, y
        end
    },

    animations={
        progressBar = function (bar,x,y,barColor,barCounterColor,waitFunc)
            x = x or 1
            y = y or 1
            barColor = barColor or colors.red
            barCounterColor = barCounterColor or colors.gray
            local currentBackgroundColor = term.getBackgroundColor()
            local currentX, currentY = term.getCursorPos()
            if type(waitFunc) ~= "function" then
                waitFunc = function ()
                    local waitTime = tonumber(tostring(math.random(0,1)) ..".".. tostring(math.random(5,9)))
                    sleep(waitTime)
                end
            end
            for i=1,#bar do
                term.setCursorPos(x,y)
                term.setBackgroundColor(barColor)
                term.write(bar:sub(1,i))
                term.setBackgroundColor(barCounterColor)
                term.write(string.rep(" ",#bar-i))
                waitFunc()
            end
            term.setBackgroundColor(currentBackgroundColor)
            term.setCursorPos(currentX,currentY)
        end,

        spinner  = function (x, y, waitTime, chars, timing)
            local currentX, currentY = term.getCursorPos()
            timing = timing or 0.25
            if timing < 0.1 then timing = 0.1 end

            local text={"-","\\","|","/"}
            if type(chars) == "table" then text = chars end
            local maxLen = 0
            for i=1,#text do
                if #tostring(text[i]) > maxLen then
                    maxLen = #tostring(text[i])
                end
            end

            local function run()
                while true do
                    for i=1,#text do
                        term.setCursorPos(x,y)
                        term.write(tostring(text[i]))
                        sleep(timing)
                    end
                    term.setCursorPos(x,y)
                    term.write(string.rep(" ",maxLen))
                end
            end

            parallel.waitForAny(function ()
                sleep(waitTime)
            end,run)

            term.setCursorPos(x,y)
            term.write(string.rep(" ",maxLen))

            term.setCursorPos(currentX,currentY)
        end
    }
}

rosAPI.getDevice = function ()
    if turtle then
        return "turtle"
    elseif pocket then
        return "pocket"
    else
        return "computer"
    end
end
