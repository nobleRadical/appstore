--appstore v1.06
--by nobleRadical
-- gets a file from the remote repository.
function getFile(path)
    local RQ, reason = http.get("https://raw.githubusercontent.com/nobleRadical/appstore/main/" .. path)
    if RQ then
        return RQ.readAll()
    else
        return nil, reason
    end
end

-- returns string of path
function Lfileread(path)
    if fs.exists(path) then
        local fileHnd = fs.open(path, "r")
        local string = fileHnd.readAll()
        fileHnd.close()
        return string
    else
        return ""
    end
end

-- overwrites file with string
function Lfilewrite(path, string)
    local fileHnd = fs.open(path, "w")
    fileHnd.write(string)
    fileHnd.close()
end

-- returns the version from a properly-formatted program
-- string -> number
function checkVersion(file)
    local _, _, version = string.find(file, "^-- ?%a+ v(%d.%d+)\n")
    if version then
        return tonumber(version)
    end
end

program = arg[1]

function main()
if not fs.exists("apis/kasutils.lua") then
    print"kasutils is required for most programs. Install?"
    local s = read()
    if s == "n" or s == "no" then
        print"suit yourself..."
    else
        installUtils()
    end
end

if program == "kasutils" then
    installUtils()
    print "Installed."
    return
end

local remoteFile, reason = getFile(program .. ".lua")
if not remoteFile then
    printError(reason)
    return
end
local remoteVersion = checkVersion(remoteFile)
local localVersion = checkVersion(Lfileread(program .. ".lua"))
print("Remote version: v" .. tostring(remoteVersion))

if localVersion then
    print("Local version: v" .. tostring(localVersion))
else
    print("Not installed on your machine.")
    
end

if not localVersion or remoteVersion > localVersion then
    print(not localVersion and "Install? Y/N" or "Update? Y/N")
    
    Lfilewrite(program .. ".lua", remoteFile)
    print("Program updated.")
else
    print("Program is already up-to-date.")
end
end

function installUtils()
    local utilFile, reason = getFile("apis/kasutils.lua")
    if not utilFile then
        printError(reason)
        return
    else
        Lfilewrite("apis/kasutils.lua", utilFile)
    end
end

function programs()
    local progFile, reason = getFile("apis/kasutils.lua")
    if not progFile then
        printError(reason)
        return
    else
        print(progFile)
    end
end

function usage()
    printError[[Usage:
appstore <program>]]
end

main()
    



