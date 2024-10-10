local QBCore = exports['qb-core']:GetCoreObject()
local scentTrails = {} -- Store player scent trails
local scentUpdateRadius = 500.0 -- Define a radius for nearby scent broadcasting
local scentLifetime = 300000 -- 5 minutes (in milliseconds)
local scentBlockTime = 60000 -- Scent blocking duration (in milliseconds)
local blockedPlayers = {} -- Table to keep track of players using the scent blocker

local scentBlockItem = "scent_blocker" -- Define the item name for scent blocker

-- Function to broadcast scent data to nearby players
local function broadcastScentData(playerId, scent)
    if type(scent) ~= "table" then
        print("[K9] Error: Scent data is not in table format! Skipping broadcast...")
        return
    end

    -- Get the player's position from the scent data
    local scentCoords = vector3(scent.x, scent.y, scent.z)

    -- Loop through all active players to find nearby players
    for _, targetPlayerId in ipairs(GetPlayers()) do
        local targetPed = GetPlayerPed(targetPlayerId)
        local targetCoords = GetEntityCoords(targetPed)

        -- Calculate the distance between the player who left the scent and the target player
        local distance = #(scentCoords - targetCoords)

        -- Only send the scent data to players within a defined radius
        if distance <= scentUpdateRadius then
            -- Debug: Print scent broadcasting information
            print("[K9] Broadcasting scent to player:", targetPlayerId, "from player:", playerId)
            -- Send the scent trail data to the nearby player
            TriggerClientEvent('dog:receivePlayerScent', targetPlayerId, playerId, scent)
        end
    end
end

-- Event to handle when a player shares their scent
RegisterNetEvent('dog:sharePlayerScent')
AddEventHandler('dog:sharePlayerScent', function(scent)
    local playerId = source

    -- Debug: Print the scent data received by the server
    print("[K9] Server received scent from player", playerId, ":", json.encode(scent))

    -- Ensure the scent is in table format
    if type(scent) ~= "table" then
        print("[K9] Error: Scent data is not in table format! Skipping...")
        return
    end

    -- Check if the player is blocked from emitting scent trails
    if blockedPlayers[playerId] and blockedPlayers[playerId] > GetGameTimer() then
        print("[K9] Scent creation blocked for player:", playerId)
        return
    end

    -- Store scent trails for the player
    scentTrails[playerId] = scentTrails[playerId] or {}
    table.insert(scentTrails[playerId], scent)

    -- Broadcast the scent to nearby players
    broadcastScentData(playerId, scent)
end)

-- Event to request nearby players' scent trails when starting scent vision
RegisterNetEvent('dog:requestPlayerScent')
AddEventHandler('dog:requestPlayerScent', function()
    local playerId = source -- The player who requested scent trails
    local ped = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(ped)

    -- Collect nearby players' scent trails within a radius
    local nearbyScentTrails = {}
    for id, trail in pairs(scentTrails) do
        for _, scent in ipairs(trail) do
            local distance = #(vector3(scent.x, scent.y, scent.z) - playerCoords)
            if distance <= scentUpdateRadius then
                -- Add to nearby scent trails to send to the client
                nearbyScentTrails[id] = nearbyScentTrails[id] or {}
                table.insert(nearbyScentTrails[id], scent)
                print("[K9] Adding scent to nearby trails for player:", id) -- Debug: Print nearby scent trail addition
            end
        end
    end

    -- Debug: Print the number of nearby scent trails being sent
    print("[K9] Sending nearby scent trails to player:", playerId)
    -- Send the nearby scent trails to the client who requested it
    TriggerClientEvent('dog:receivePlayerScent', playerId, nearbyScentTrails)
end)

-- Register the scent blocker item with QB-Inventory
QBCore.Functions.CreateUseableItem(scentBlockItem, function(source)
    local playerId = source

    -- Add player to blockedPlayers list with the current time plus scentBlockTime
    blockedPlayers[playerId] = GetGameTimer() + scentBlockTime

    -- Notify the player that they are now blocking scent trails
    TriggerClientEvent('QBCore:Notify', playerId, "You are blocking your scent for 60 seconds.", "success")
    print("[K9] Player", playerId, "is now blocking their scent for 60 seconds.")

    -- Optional: Trigger client-side effects or notifications
    TriggerClientEvent('dog:startScentBlockEffect', playerId)
end)

-- Clean up old scent trails every minute
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Clean up old scent trails every minute
        local currentTime = GetGameTimer()

        -- Remove expired scent trails
        for playerId, trail in pairs(scentTrails) do
            for i = #trail, 1, -1 do
                if (currentTime - trail[i].timestamp) > scentLifetime then
                    table.remove(trail, i) -- Remove scent trail older than the lifespan
                end
            end
        end

        -- Remove expired scent block status
        for playerId, blockTime in pairs(blockedPlayers) do
            if blockTime <= currentTime then
                blockedPlayers[playerId] = nil -- Remove the player from blocked list
                print("[K9] Scent blocking expired for player:", playerId)
                TriggerClientEvent('QBCore:Notify', playerId, "Your scent blocking has ended.", "info")
            end
        end
    end
end)
