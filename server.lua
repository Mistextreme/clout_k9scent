local ESX = exports['es_extended']:getSharedObject()
local function processScent(src, playerCoords, stamina)
    TriggerClientEvent('dog:processScentDrop', src, playerCoords, stamina)
end


RegisterServerEvent('dog:checkPlayerInventoryForScent')
AddEventHandler('dog:checkPlayerInventoryForScent', function(playerCoords, stamina)
    local src = source

    local dropChance = baseDropChance or 0.5
    local rnd = math.random()
    if rnd <= dropChance then
        processScent(src, playerCoords, stamina)
        return
    end
    
    local weaponDropChance, drugDropChance = 0.15, 0.2

    local chanceWithWeapon = math.min(dropChance + weaponDropChance, 1.0)
    local chanceWithDrugs = math.min(dropChance + drugDropChance, 1.0)
    local chanceWithBoth = math.min(dropChance + weaponDropChance + drugDropChance, 1.0)
    
    local shouldDropWeapon = rnd <= chanceWithWeapon
    local shouldDropDrugs = rnd <= chanceWithDrugs
    local shouldDropBoth = rnd <= chanceWithBoth
    if not shouldDropWeapon and not shouldDropDrugs or not shouldDropBoth then
        return
    end

    local weaponList = nil
    if Config.Inventory == "ox" then
        weaponList = exports.ox_inventory:Items()
    end
    
    local inventory = Config.Functions.GetInventoryServer(src)
    if type(inventory) ~= "table" then
        if Config.printDebug then
            print("[K9] Warning: Failed to retrieve inventory or invalid data structure.")
        end
        return
    end
    
    local foundWeapon, foundDrugs = false, false
    for _, item in pairs(inventory) do
        
        if foundWeapon and foundDrugs then
            processScent(src, playerCoords, stamina)
            return
        end
        if type(item) == "table" then -- Ensure item is a table before accessing properties
            -- Check if the item is a weapon
            if item.type == 'weapon' or
               (item.name == 'filled_evidence_bag' and item.inventoryMetadata and item.inventoryMetadata.item and item.inventoryMetadata.item.type == 'weapon') or
               (weaponList and weaponList[item.name] and weaponList[item.name].weapon) then
                if shouldDropWeapon then
                    processScent(src, playerCoords, stamina)
                    return
                end
                foundWeapon = true
            end

            -- Check if the item is a drug (you can customize this based on your list of drugs)
            if Config.ScentItems and Config.ScentItems[item.name] then
                if Config.ScentItems[item.name].drug then
                    if shouldDropDrugs then
                        processScent(src, playerCoords, stamina)
                        return
                    end
                    foundDrugs = true
                end
            end
        else
            if Config.printDebug then
                print("[K9] Warning: Item is not a table. Value:", item) -- Debug print for unexpected values
            end
        end
    end
end)





local scentTrails = {} -- Store player scent trails
local scentUpdateRadius = 500.0 -- Define a radius for nearby scent broadcasting
local scentLifetime = 300000 -- 5 minutes (in milliseconds)
local scentBlockTime = 60000 -- Scent blocking duration (in milliseconds)
local blockedPlayers = {} -- Table to keep track of players using the scent blocker

local scentBlockItem = "scent_blocker" -- Define the item name for scent blocker

-- Function to broadcast scent data to nearby players
local function broadcastScentData(playerId, scent)
    if type(scent) ~= "table" then
            if Config.printDebug then
                print("[K9] Error: Scent data is not in table format! Skipping broadcast...")
            end
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
            if Config.printDebug then
                print("[K9] Broadcasting scent to player:", targetPlayerId, "from player:", playerId)
            end
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
    if Config.printDebug then
        print("[K9] Server received scent from player", playerId, ":", json.encode(scent))
    end
    -- Ensure the scent is in table format
    if type(scent) ~= "table" then
        if Config.printDebug then
            print("[K9] Error: Scent data is not in table format! Skipping...")
        end
        return
    end

    -- Check if the player is blocked from emitting scent trails
    if blockedPlayers[playerId] and blockedPlayers[playerId] > GetGameTimer() then
            if Config.printDebug then
                print("[K9] Scent creation blocked for player:", playerId)
            end
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
                if Config.printDebug then
                    print("[K9] Adding scent to nearby trails for player:", id) -- Debug: Print nearby scent trail addition
                end
            end
        end
    end

    -- Debug: Print the number of nearby scent trails being sent
    if Config.printDebug then
        print("[K9] Sending nearby scent trails to player:", playerId)
    end
    -- Send the nearby scent trails to the client who requested it
    TriggerClientEvent('dog:receivePlayerScent', playerId, nearbyScentTrails)
end)
-- Register the scent blocker item with ESX
if GetResourceState('es_extended') == 'started' then
    ESX.RegisterUsableItem(scentBlockItem, function(source)
        local playerId = source
        blockedPlayers[playerId] = GetGameTimer() + scentBlockTime
        local xPlayer = ESX.GetPlayerFromId(playerId)
        xPlayer.showNotification("You are blocking your scent for 60 seconds.")
        if Config.printDebug then
            print("[K9] Player", playerId, "is now blocking their scent for 60 seconds.")
        end
        TriggerClientEvent('dog:useScentBlocker', playerId)
    end)
end

-- Register the scent blocker item with OX Inventory
if GetResourceState('ox_inventory') == 'started' then
    exports.ox_inventory:CustomUseableItem('scent_blocker', function(source, item, slot)
        local playerId = source
        blockedPlayers[playerId] = GetGameTimer() + scentBlockTime
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = "K9 Scent Blocker",
            description = "You are blocking your scent for 60 seconds.",
            type = "success",
            duration = 5000
        })
        if Config.printDebug then
            print("[K9] Player", playerId, "is now blocking their scent for 60 seconds.")
        end
        TriggerClientEvent('dog:useScentBlocker', playerId)
    end)
end

-- Clean up old scent trails every minute
CreateThread(function()
    while true do
        Wait(60000) -- Clean up old scent trails every minute
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
                if Config.printDebug then
                    print("[K9] Scent blocking expired for player:", playerId)
                end
                local xPlayer = ESX.GetPlayerFromId(playerId)
                if xPlayer then
                    xPlayer.showNotification("Your scent blocking has ended.")
                end
            end
        end
    end
end)
