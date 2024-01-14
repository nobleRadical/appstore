--crafter v1.0
--by nobleRadical

assert(fs.exists("apis/kasutils.lua"), [[Requires kasutils. If you have appstore, use
appstore install kasutils to install.]])
kasutils = require "apis.kasutils"


local startup_program = 
[[
print "Crafting...Press t to terminate."
while true do
    turtle.craft()
    local _, key = os.pullEvent("key", 1)
    if key == keys.t then
        break
    end
end
]]

kasutils.filewrite("startup.lua", startup_program)