local QBCore = exports['qb-core']:GetCoreObject()
local scentVisionActive = false
local playerScentTrail = {} -- Store scent data for each player
local playerColors = {}
local attachedSpheres = {}
local scentLifetime = 300000 -- 5 minutes (in milliseconds)
local windImpactFactor = 1.0
local staminaImpactFactor = 0.1
local scentDropDistance = 10.0 -- Minimum distance player must move before dropping a new scent
local baseDropChance = 0.50 -- Base drop chance (50%)
local lastScentCoords = nil
local playerData = nil -- Global variable to store player data
local wristSpheresActive = false -- Toggle for showing wrist spheres

-- Scent block control
local isScentBlocked = false
local scentBlockDuration = 60000 -- 1 minute duration in milliseconds

-- Item detection list with drop chance multiplier
local itemDetectionList = {
    ["weed"] = {r = 0, g = 255, b = 0, dropMultiplier = 1.2},    -- Green sphere for drugs, 20% increased drop chance
    ["coke"] = {r = 255, g = 255, b = 255, dropMultiplier = 1.5},-- White sphere for cocaine, 50% increased drop chance
    ["meth"] = {r = 0, g = 255, b = 255, dropMultiplier = 1.3},  -- Cyan sphere for meth, 30% increased drop chance
    ["weapon_pistol"] = {r = 255, g = 0, b = 0, dropMultiplier = 2.0}   -- Red sphere for weapons, 100% increased drop chance
}

-- Restricted jobs list that shouldn't leave scents
local restrictedJobs = {
    "police",    -- Police jobs don't leave scents
    "medic",     -- Medics don't leave scents
    "mechanic"   -- Mechanics don't leave scents
}

-- List of jobs that can see scents when using scent vision
local allowedScentJobs = {
    ["police"] = true,   -- Police can see scents
    ["k9unit"] = true,   -- K9 units can see scents
    ["detective"] = true -- Detectives can see scents
}

-- Generate player color, cached for performance
local function generatePlayerColor(playerId)
    if playerColors[playerId] then return playerColors[playerId] end
    local color = { r = math.random(100, 255), g = math.random(100, 255), b = math.random(100, 255) }
    playerColors[playerId] = color
    return color
end

-- Draw marker for scent trail
local function drawScentMarker(scent, color)
    -- Draw the scent marker only when scent vision is active
    if scentVisionActive then
        DrawMarker(28, scent.x, scent.y, scent.z - 1.0, 0, 0, 0, 0, 0, 0,
                   scent.size, scent.size, scent.size,
                   color.r, color.g, color.b, scent.opacity, false, false, 2, false, nil, nil, false)
    end
end

-- Toggle scent vision on/off
local function toggleScentVision()
    scentVisionActive = not scentVisionActive

    if scentVisionActive then
        SetTimecycleModifier("MP_Bull_tost")
        SetTimecycleModifierStrength(0.3)
        QBCore.Functions.Notify("Scent vision activated!", "success")
        TriggerServerEvent('dog:requestPlayerScent') -- Request scent trails from all nearby players
        print("[K9] Scent vision toggled on.")
    else
        ClearTimecycleModifier()
        QBCore.Functions.Notify("Scent vision deactivated!", "error")
        print("[K9] Scent vision toggled off.")
    end
end

-- Check if a job is restricted from creating scents
local function isJobRestricted(jobName)
    for _, restrictedJob in ipairs(restrictedJobs) do
        if jobName == restrictedJob then
            return true
        end
    end
    return false
end

-- Activate scent blocking
local function activateScentBlock()
    isScentBlocked = true
    QBCore.Functions.Notify("Scent blocker activated. You won't leave any scents for 1 minute.", "success")

    -- Disable scent blocking after the duration ends
    Citizen.SetTimeout(scentBlockDuration, function()
        isScentBlocked = false
        QBCore.Functions.Notify("Scent blocker deactivated. You are now leaving scents again.", "error")
    end)
end

-- Calculate the chance to drop a scent based on items in the player's inventory
local function calculateDropChance(inventory)
    -- Check if inventory is a string and decode it
    if type(inventory) == "string" then
        inventory = json.decode(inventory)
    end

    -- Bypass the inventory check and set a default value if inventory is missing or not a table
    if type(inventory) ~= "table" then
        print("[K9] Warning: Inventory is missing or invalid. Using base drop chance.")
        return baseDropChance
    end

    local dropChance = baseDropChance

    -- Loop through the player's inventory and adjust the dropChance based on items
    for _, item in pairs(inventory) do
        if itemDetectionList[item.name] and itemDetectionList[item.name].dropMultiplier then
            dropChance = dropChance * itemDetectionList[item.name].dropMultiplier
        end
    end

    return dropChance
end

-- Send player's scent to the server, considering restrictions
local function sendPlayerScent()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())

    -- Retrieve inventory or set to empty table if missing
    local inventory = playerData and playerData.inventory or {}

    -- Check player's job before creating a scent
    local playerJob = playerData.job and playerData.job.name or ""
    if isJobRestricted(playerJob) then
        print("[K9] Scent creation skipped due to restricted job:", playerJob)
        return
    end

    -- Check if scent blocking is active
    if isScentBlocked then
        print("[K9] Scent creation skipped due to active scent blocking.")
        return
    end

    -- Calculate drop chance based on inventory
    local dropChance = calculateDropChance(inventory)
    if math.random() > dropChance then
        print("[K9] Scent drop skipped due to drop chance.")
        return
    end

    -- Create scent data
    local scent = {
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z + 0.4,
        size = 0.1 + staminaImpactFactor * ((100 - stamina) / 100),
        opacity = 25 + 155 * (stamina / 100),
        timestamp = GetGameTimer(),
        intensity = 1.0,
        lifespan = scentLifetime
    }

    -- Print the scent data and send it to the server
    print("[K9] Sending scent to server:", json.encode(scent))
    TriggerServerEvent('dog:sharePlayerScent', scent)
end

-- Register /k9track command for scent vision
RegisterCommand('k9track', function()
    toggleScentVision()
end, false)

-- Register item use event for scent blocker
RegisterNetEvent('dog:useScentBlocker')
AddEventHandler('dog:useScentBlocker', function()
    if isScentBlocked then
        QBCore.Functions.Notify("Scent blocker is already active!", "error")
        return
    end

    activateScentBlock()
end)

-- Thread to send scent data based on player movement and timing
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local isRunning = IsPedRunning(ped)
        local currentCoords = GetEntityCoords(ped)

        -- Only drop a scent if the player has moved a certain distance or after a delay
        if lastScentCoords == nil or #(currentCoords - lastScentCoords) > scentDropDistance then
            print("[K9] Player has moved significantly. Checking drop chance.")

            if isRunning then
                Wait(5000) -- Drop scent more frequently when running
                sendPlayerScent()
            else
                Wait(10000) -- Drop scent less frequently when walking or standing
                sendPlayerScent()
            end

            
            lastScentCoords = currentCoords -- Update last scent coordinates
        else
            Wait(1000) -- Re-check drop chance after a delay
        end
    end
end)

-- Draw scent markers for other players if scent vision is active
Citizen.CreateThread(function()
    while true do
        Wait(0) -- Constantly draw markers when needed

        if scentVisionActive and playerScentTrail then
            for playerId, scentTrail in pairs(playerScentTrail) do
                -- Only allow drawing if the player's job is allowed
                local playerJob = playerData and playerData.job and playerData.job.name or ""
                if playerId ~= GetPlayerServerId(PlayerId()) and allowedScentJobs[playerJob] then
                    local color = generatePlayerColor(playerId)
                    for _, scent in ipairs(scentTrail) do
                        drawScentMarker(scent, color)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('dog:receivePlayerScent')
AddEventHandler('dog:receivePlayerScent', function(playerId, scent)
    print("[K9] Client received scent from player", playerId, ":", json.encode(scent)) -- Debug: Check data reception

    -- Ensure the scent data is in table format
    if type(scent) == "string" then
        scent = json.decode(scent)
        if not scent then
            print("[K9] Error: Failed to decode scent JSON string!")
            return
        end
    end

    if type(scent) ~= "table" then
        print("[K9] Error: Received scent trails are not in table format!")
        return
    end

    -- Store the scent trail data and debug the storing process
    print("[K9] Storing scent data for player:", playerId)
    playerScentTrail[playerId] = playerScentTrail[playerId] or {}
    table.insert(playerScentTrail[playerId], scent)
    print("[K9] Successfully stored scent data for player:", playerId)
end)


-- Clear scent trails for a player
RegisterNetEvent('dog:clearScent')
AddEventHandler('dog:clearScent', function(playerId)
    playerScentTrail[playerId] = nil
end)

-- Fetch player data once it's available
Citizen.CreateThread(function()
    while not QBCore.Functions.GetPlayerData() do
        Citizen.Wait(1000)
    end
    playerData = QBCore.Functions.GetPlayerData()
    print("[K9] Player Data Loaded: ", json.encode(playerData))
end)
