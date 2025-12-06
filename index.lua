local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")

local PLACE = game.PlaceId
local LOCAL = Players.LocalPlayer

local sinsly = {}
sinsly.__index = sinsly
local blacklist = {}

local function fetchServers(cursor)
    local url = "https://games.roblox.com/v1/games/"..PLACE.."/servers/Public?sortOrder=Asc&limit=100"
    if cursor then url = url.."&cursor="..cursor end
    return Http:JSONDecode(game:HttpGet(url))
end

local function serverExists(id)
    local cursor = nil
    repeat
        local data = fetchServers(cursor)
        for _, s in ipairs(data.data) do
            if s.id == id then return true end
        end
        cursor = data.nextPageCursor
    until not cursor
    return false
end

local function pruneBlacklist()
    for id,_ in pairs(blacklist) do
        if not serverExists(id) then
            blacklist[id] = nil
        end
    end
end

function sinsly.new()
    return setmetatable({}, sinsly)
end

function sinsly:currentServer()
    local jid = game.JobId
    print("Current Server JobId:", jid)
    if setclipboard then setclipboard(jid) end
    return jid
end

function sinsly:blacklist()
    blacklist[game.JobId] = true
end

function sinsly:unblacklist(jobid)
    blacklist[jobid] = nil
end

function sinsly:unblacklistAll()
    for id,_ in pairs(blacklist) do
        blacklist[id] = nil
    end
end

function sinsly:bserverlist()
    print("Blacklisted Servers:")
    for id,_ in pairs(blacklist) do
        print(id)
    end
end

function sinsly:rejoin()
    blacklist[game.JobId] = true
    TeleportService:Teleport(PLACE, LOCAL)
end

local function findServers(minPlayers,maxPlayers,fullOnly)
    pruneBlacklist()
    minPlayers = minPlayers or 0
    maxPlayers = maxPlayers or math.huge
    local choices = {}
    local cursor = nil
    repeat
        local data = fetchServers(cursor)
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId then
                local valid = true
                if fullOnly then
                    valid = s.playing >= s.maxPlayers
                else
                    if s.playing < minPlayers then valid = false end
                    if s.playing > maxPlayers then valid = false end
                    if s.playing >= s.maxPlayers then valid = false end
                end
                if valid then table.insert(choices, s) end
            end
        end
        cursor = data.nextPageCursor
    until not cursor
    return choices
end

function sinsly:smallest()
    pruneBlacklist()
    local best = nil
    local cursor = nil
    repeat
        local data = fetchServers(cursor)
        for _, s in ipairs(data.data) do
            if not blacklist[s.id] and s.id ~= game.JobId and s.playing < s.maxPlayers then
                if not best or s.playing < best.playing then
                    best = s
                end
            end
        end
        cursor = data.nextPageCursor
    until not cursor
    if best then
        blacklist[game.JobId] = true
        TeleportService:TeleportToPlaceInstance(PLACE, best.id, LOCAL)
    else
        LOCAL:Kick("No available unblacklisted servers for smallest.")
    end
end

function sinsly:largest()
    pruneBlacklist()
    local best = nil
    local cursor = nil
    repeat
        local data = fetchServers(cursor)
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and not blacklist[s.id] and s.playing < s.maxPlayers then
                if not best or s.playing > best.playing then
                    best = s
                end
            end
        end
        cursor = data.nextPageCursor
    until not cursor
    if best then
        blacklist[game.JobId] = true
        TeleportService:TeleportToPlaceInstance(PLACE, best.id, LOCAL)
    else
        LOCAL:Kick("No available unblacklisted servers for largest.")
    end
end

function sinsly:hop(minPlayers,maxPlayers)
    local servers = findServers(minPlayers,maxPlayers)
    if #servers == 0 then
        LOCAL:Kick("No available unblacklisted servers to hop to.")
        return
    end
    local pick = servers[math.random(1,#servers)]
    blacklist[game.JobId] = true
    TeleportService:TeleportToPlaceInstance(PLACE, pick.id, LOCAL)
end

function sinsly:serverHop(minPlayers,maxPlayers)
    local servers = findServers(minPlayers,maxPlayers)
    if #servers == 0 then
        LOCAL:Kick("No unblacklisted server available in range "..tostring(minPlayers).."–"..tostring(maxPlayers))
        return
    end
    local pick = servers[math.random(1,#servers)]
    blacklist[game.JobId] = true
    TeleportService:TeleportToPlaceInstance(PLACE, pick.id, LOCAL)
end

function sinsly:printServers(minPlayers,maxPlayers,sortMode)
    pruneBlacklist()
    local fullOnly = false
    if minPlayers == "full" then
        fullOnly = true
        minPlayers = 0
        maxPlayers = math.huge
    else
        minPlayers = minPlayers or 0
        maxPlayers = maxPlayers or math.huge
    end

    local allServers = findServers(minPlayers,maxPlayers,fullOnly)
    local cursor = nil
    repeat
        local data = fetchServers(cursor)
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId then
                s._blacklisted = blacklist[s.id] or false
                table.insert(allServers, s)
            end
        end
        cursor = data.nextPageCursor
    until not cursor

    local modes = {
        smallest = function(a,b) return a.playing < b.playing end,
        largest = function(a,b) return a.playing > b.playing end,
        random = function() return math.random() < 0.5 end
    }

    local compareFunc = modes[sortMode] or modes.smallest

    table.sort(allServers, function(a,b)
        if a._blacklisted ~= b._blacklisted then
            return a._blacklisted
        end
        return compareFunc(a,b)
    end)

    local largest = nil
    local smallest = nil
    for _, s in ipairs(allServers) do
        if not largest and s.playing < s.maxPlayers then
            largest = s
        end
        if not smallest then
            smallest = s
        end
        local mark = s._blacklisted and "[BLACKLISTED]" or ""
        print(string.format("ServerID: %s %s | Players: %d/%d", s.id, mark, s.playing, s.maxPlayers))
    end
    if largest then
        print(string.format("Largest server (not full): %s | Players: %d/%d", largest.id, largest.playing, largest.maxPlayers))
    end
    if smallest then
        local mark = blacklist[smallest.id] and "[BLACKLISTED]" or ""
        print(string.format("Smallest server: %s %s | Players: %d/%d", smallest.id, mark, smallest.playing, smallest.maxPlayers))
    end
end

local autoTask = {running = false}

function sinsly:autoHop(intervalOrOff, mode)
    if intervalOrOff == false then
        autoTask.running = false
        return
    end

    intervalOrOff = tonumber(intervalOrOff)
    if not intervalOrOff then return end

    mode = mode or "random" -- "random" or "smallest"

    autoTask.running = true
    task.spawn(function()
        while autoTask.running do
            if mode == "smallest" then
                self:smallest()
            else
                self:hop()
            end
            task.wait(intervalOrOff * 60)
        end
    end)
end

function sinsly:joinScript()
    local jid = game.JobId
    local code = "game:GetService('TeleportService'):TeleportToPlaceInstance("..PLACE..", '"..jid.."', game:GetService('Players').LocalPlayer)"
    print(code)
    if setclipboard then setclipboard(code) end
    return code
end

return sinsly.new()
