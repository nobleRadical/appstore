--twitter v1.01
--by nobleRadical

assert(fs.exists("apis/kasutils.lua"), [[Requires kasutils. If you have appstore, use
appstore install kasutils to install.]])
kasutils = require "apis.kasutils"

-- Connect to the internet.
peripheral.find("modem", rednet.open)


-- Load twitter log from file, or an empty log.
function load()
local twitterLog = nil
local fileHnd = fs.open(".twitterlog", "r")
if fileHnd ~= nil then
twitterLog = textutils.unserialise(fileHnd.readAll())
fileHnd.close()
else
twitterLog = {["version"] = 0, ["posts"] = {}}
end
return twitterLog
end
-- save twitter log.
function save(twitterLog)
local fileHnd = fs.open(".twitterlog", "w")
fileHnd.write(textutils.serialise(twitterLog, { compact = true }))
fileHnd.close()
end

twitterLog = load()

-- log file structure:
-- log.version :: number
-- log.posts :: array[posts]
--     post :: table
--     post.author :: string
--     post.author_id :: number (computer's ID)
--     post.contents :: string


--utility function
function addPost(log, post)
table.insert(log.posts, post)
log.version = log.version + 1
end
--
function getLatestPost(log)
local pst = table.remove(log.posts)
if pst ~= nil then
table.insert(log.posts, pst)
return {author=pst.author, contents=pst.contents, author_id=pst.author_id}
else
return {author="Nobody", contents="Nobody's posted yet.", author_id=0}
end
end
--
function displayPost(post)
kasutils.colorWrite(post.author, colors.lightBlue)
kasutils.colorWrite("#" .. tostring(post.author_id), colors.red)
print(post.contents)
end
--
function postEditor(post)
print("Author: @"..post.author)
print("Message: ")
local hnd = fs.open(".tempBuffer", "w")
hnd.write(post.contents or "")
hnd.close()
local maxX, maxY = term.getSize()
local x, y = term.getCursorPos()
local oldTerm = term.current()
print(y)
local win = window.create(oldTerm, 1, y, maxX, maxY-y)
term.redirect(win)
shell.run("edit .tempBuffer")
term.redirect(oldTerm)
local hnd = fs.open(".tempBuffer", "r")
post.contents = hnd.readAll()
hnd.close()
term.setCursorPos(x, y)
end


--coroutine of the main loop
--manages GET and POST requests from other computers
function recv_handler()
while true do
    local id, message = rednet.receive("twitter")
    if message.type == "GET" then
        rednet.send(id, twitterLog, "twitter")
    elseif message.type == "POST" then
        if twitterLog.version <= message.payload.version then
        twitterLog = message.payload
         save(twitterLog)
        end
    end
end
end
--Send a POST request.
function network_POST(log)
rednet.broadcast({ type="POST", payload=log}, "twitter")
end
--Send a GET request, and return the most recent response.
function network_GET()
rednet.broadcast({ type="GET" }, "twitter")
local messages = {}
while true do
local id, message = rednet.receive("twitter", 1)
if id == nil then break end
table.insert(messages, message)
end
table.sort(messages, function(one, two)
return one.version > two.version end)

return messages[1]
end

--update the twitterlog against the network.
function updateTwitterLog()
local tempLog = network_GET()
if tempLog and tempLog.version > twitterLog.version then
twitterLog = tempLog
save(twitterLog)
end 
end
updateTwitterLog()

--coroutine of the main loop
--manages the UI and user input
function client()    
    --intro babble
    print("Welcome to Twitter!")
    print("latest post:")
    local latestPost = getLatestPost(twitterLog)
    displayPost(latestPost)
       
    --command list, backed by later function defs
    local commands = {
    ["new post"] = newpost,
    ["log in"] = login,
    ["more posts"] = listposts,
    ["exit"] = exit,
    }

    loggedInUser = nil -- for saving a login
    --seperate keys vs values of commands
    local commandkeys = {}
    for k, _ in pairs(commands) do
    table.insert(commandkeys, k)
    end
    table.sort(commandkeys)
while true do
    print(" ")
    print(" ")
    kasutils.colorPrint("Choose an action.", colors.blue)
    local input = kasutils.choice(commandkeys)
    if commands[input] ~= nil then
   
        term.clear()
        term.setCursorPos(1, 1)
        local code, val = pcall(commands[input])
        if not code then
        printError(val)
        sleep(2)
        end
        if val == "exit" then
        break
        end
   
    else
        kasutils.colorPrint("Invalid command.", colors.red)
        sleep(0.5)
        term.clear()
        term.setCursorPos(1,1)
    end    
   
end
end

--define commands
function newpost()
local currentUser = login()

print("Access granted. Hello, "..currentUser)
term.clear()
term.setCursorPos(1,1)

local post_to_add = { author = currentUser, contents = nil}
print("New Post")
postEditor(post_to_add)
print(post_to_add.contents)

if post_to_add.contents:find("^%s*$") then
    print("Post empty. Cancelled.")
    return
end
addPost(twitterLog, post_to_add)
save(twitterLog)
network_POST(twitterLog)
end
--

--
function listposts()
local posts = twitterLog.posts
local maxPointer = table.getn(posts)
local pointer = maxPointer
while true do
term.clear()
term.setCursorPos(1,1)
print("Post "..tostring(pointer).." / "..tostring(maxPointer))
displayPost(posts[pointer])
print(" ")
print("< or > to navigate. q to exit.")
local _, key = os.pullEvent("key")
if key == keys.left then
pointer = pointer-1
if pointer < 1 then pointer=maxPointer end
elseif key == keys.right then
pointer = pointer+1
if pointer > maxPointer then pointer=1 end
elseif key == keys.q then
break
end

end
end
--
function login()
if loggedInUser ~= nil then
print("Logged in as "..loggedInUser..". Continue?")
if kasutils.choice{"yes", "no"} == "yes" then return loggedInUser end end
print "Provide your username."
local currentUser = read()
print("Logged in as @"..currentUser..". Stay logged in?")
if kasutils.choice{"yes", "no"} == "yes" then
loggedInUser = currentUser
else
loggedInUser = nil
end
return currentUser
end
--
function exit()
kasutils.colorPrint("Goodbye!", colors.yellow)
sleep(0.5)
term.clear()
term.setCursorPos(1, 1)
return "exit"
end


parallel.waitForAny(recv_handler, client)
