--appstore v1.01
--by nobleRadical
-- gets a file from the remote repository.
function getFile(path)
    local RQ = http.get("https://raw.githubusercontent.com/nobleRadical/appstore/main/" .. path)
    HttpCode, HttpMessage = RQ.getResponseCode()
    if HttpCode == 200 then
        return RQ.readAll()
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

command = arg[1]
program = arg[2]

function main()
if not fs.exists("apis/kasutils.lua") then
    print"kasutils is required for most programs. Install?"
    local s = read()
    if s == "n" or s == "no" then
        print"suit yourself..."
    else
        local utilFile = getFile("apis/kasutils.lua")
        if utilFile then
            Lfilewrite("apis/kasutils.lua", utilFile)
        else
            print"Could not connect to server."
        end
    end
end
if command == "install" or command == "update" then
    local remoteFile = getFile(program .. ".lua")
    if not remoteFile then
        if HttpCode ~= 200 then
            printError "Failed to connect to server."
            print("Code " .. tostring(HttpCode))
            print("Reason: " .. tostring(HttpMessage))
        else
            printError "Program not found."
        end
        return
    end
    local remoteVersion = checkVersion(remoteFile)
    local localVersion = checkVersion(Lfileread(program))
    print("Remote version: v" .. tostring(remoteVersion))

    if localVersion then
        print("Local version: v" .. tostring(localVersion))
    else
        print("Not installed on your machine.")
        
    end

    if not localVersion or remoteVersion > localVersion then
        print(not localVersion and "Installing..." or "Updating...")
        Lfilewrite(program .. ".lua", remoteFile)
        print("Program updated.")
    else
        print("Program is already up-to-date.")
    end
elseif command == "check" then
    local remoteFile = getFile(program)
    if not remoteFile then
        if HttpCode ~= 200 then
            printError "Failed to connect to server."
            print("Code: " .. tostring(HttpCode))
            print("Reason: " .. tostring(HttpMessage))
        else
            printError "Program not found."
        end
        return
    end
    local remoteVersion = checkVersion(remoteFile)
    local localVersion = checkVersion(Lfileread(program))
    print("Remote version: v" .. tostring(remoteVersion))

    if localVersion then
        print("Local version: v" .. tostring(localVersion))
    else
        print("Not installed on your machine.")
    end
else
    local progFile = getFile("programs.md")
    if progFile then
        print(progFile)
    else
        print "Cannot connect to server."
        print("Code " .. tostring(HttpCode))
        print("Reason: " .. tostring(HttpMessage))
    end
    printError[[Usage:
appstore install|update program
appstore check program]]
end
end

main()
    



