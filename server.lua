local scentTrails = {} -- Store player scent trails
local scentUpdateRadius = 100.0 -- Define a radius for nearby scent broadcasting
local scentLifetime = 300000 -- 5 minutes (in milliseconds)
-- Function to broadcast scent data to nearby players
local function broadcastScentData(playerId, scent)
    if type(scent) ~= "table" then
        print("[K9] Error: Scent data is not in table format!")
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
            -- Send the scent trail data to the nearby player
            TriggerClientEvent('dog:receivePlayerScent', targetPlayerId, playerId, scent)
        end
    end
end

RegisterNetEvent('dog:sharePlayerScent')
AddEventHandler('dog:sharePlayerScent', function(scent)
    local playerId = source

    -- Debug: Print the scent data received by the server
    print("[K9] Server received scent from player", playerId, ":", json.encode(scent))

    -- Ensure the scent is in table format
    if type(scent) ~= "table" then
        print("[K9] Error: Scent data is not in table format!")
        return
    end

    -- Store scent trails
    scentTrails[playerId] = scentTrails[playerId] or {}
    table.insert(scentTrails[playerId], scent)

    -- Broadcast the scent to nearby players
    TriggerClientEvent('dog:receivePlayerScent', -1, playerId, scent)
end)


-- Optional: Event to request all nearby players' scent trails when starting scent vision
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
            end
        end
    end

    -- Send the nearby scent trails to the client who requested it
    TriggerClientEvent('dog:receivePlayerScent', playerId, nearbyScentTrails)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Clean up old scent trails every minute
        local currentTime = GetGameTimer()

        for playerId, trail in pairs(scentTrails) do
            for i = #trail, 1, -1 do
                if (currentTime - trail[i].timestamp) > scentLifetime then
                    table.remove(trail, i) -- Remove scent trail older than the lifespan
                end
            end
        end
    end
end)

