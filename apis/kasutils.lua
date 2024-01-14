--kasutils v1.01
--by nobleRadical

-- colorPrint - a utility function that should be
-- part of the standard library. (nobleRadical)
function colorPrint(text, color)
    local oldColor = term.getTextColor()
    term.setTextColor(color)
print(text)
    term.setTextColor(oldColor)
end
    
--colorWrite - colorPrint's cousin.
function colorWrite(text, color)
    local oldColor = term.getTextColor()
    term.setTextColor(color)
write(text)
    term.setTextColor(oldColor)
end
    
--internal function
function _redraw(choices, cursor, startPoint)
    term.setCursorPos(1, startPoint)
    for k, v in ipairs(choices) do
        local char = (cursor == k) and ">" or " "
        print(char..v)
    end
end
        
        
--choice provides the user a list of values to choose from, and returns their choice.
--choices = { string .. }
function choice(choices)
    local _, startPoint = term.getCursorPos()
    local cursor = 1
    local input = nil
    repeat
        _redraw(choices, cursor, startPoint)
        local _, key = os.pullEvent("key")
        if key == keys.up then
            cursor = cursor - 1
            if cursor < 1 then
                cursor = #choices
            end
        elseif key == keys.down then
            cursor = cursor + 1
            if cursor > #choices then
                cursor = 1
            end
        elseif key == keys.enter then
            input = choices[cursor]
        end
    until input
return input
end

-- returns string of path
function fileread(path)
    if fs.exists(path) then
        local fileHnd = fs.open(path, "r")
        local string = fileHnd.readAll()
        fileHnd.close()
        return string
    end
end

-- overwrites file with string
function filewrite(path, string)
    local fileHnd = fs.open(path, "w")
    fileHnd.write(string)
    fileHnd.close()
end

return {colorPrint = colorPrint, colorWrite = colorWrite, choice = choice, fileread = fileread, filewrite = filewrite}