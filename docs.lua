sinsly:currentServer()        -- prints & copies JobId
sinsly:bserverlist()          -- prints blacklisted servers
sinsly:printServers()         -- prints all servers not full
sinsly:printServers("full")   -- prints only full servers
sinsly:printServers("largest") -- prints servers sorted largest first
sinsly:printServers(3,10,"smallest") -- prints servers 3-10 players sorted smallest first

sinsly:blacklist()            -- blacklist current server
sinsly:unblacklist("JobIdHere")  -- remove a server from blacklist
sinsly:unblacklistAll()       -- clear all blacklists

sinsly:rejoin()               -- rejoin current server
sinsly:hop()                  -- random server (unblacklisted)
sinsly:hop(2,5)              -- random server 2-5 players (unblacklisted)
sinsly:smallest()             -- hop to smallest server (unblacklisted)
sinsly:largest()              -- hop to largest server not full (unblacklisteed)

sinsly:autoSmallest(5)        -- auto smallest hop every 5 minutes
sinsly:autoHop(10)            -- auto hop every 10 minutes
sinsly:autoHop(false)         -- stop auto hop

sinsly:joinScript()           -- prints & copies join script for current server
