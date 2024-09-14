local QBCore = exports['qb-core']:GetCoreObject()
local scentVisionActive = false
local playerScentTrail = {} -- Ensure playerScentTrail is always initialized as a table
local playerColors = {}
local attachedSpheres = {}
local scentLifetime = 300000 -- 5 minutes (in milliseconds)
local windImpactFactor = 1.0
local staminaImpactFactor = 0.1
local scentDropDistance = 10.0 -- Minimum distance player must move before dropping a new scent
local baseDropChance = 0.35 -- Base drop chance (35%)

-- Item detection list with drop chance multiplier
local itemDetectionList = {
    ["weed"] = {r = 0, g = 255, b = 0, dropMultiplier = 1.2},    -- Green sphere for drugs, 20% increased drop chance
    ["coke"] = {r = 255, g = 255, b = 255, dropMultiplier = 1.5},-- White sphere for cocaine, 50% increased drop chance
    ["meth"] = {r = 0, g = 255, b = 255, dropMultiplier = 1.3},  -- Cyan sphere for meth, 30% increased drop chance
    ["weapon"] = {r = 255, g = 0, b = 0, dropMultiplier = 2.0}   -- Red sphere for weapons, 100% increased drop chance
}

-- Generate player color, cached for performance
local function generatePlayerColor(playerId)
    if playerColors[playerId] then return playerColors[playerId] end

    local color = {r = math.random(100, 255), g = math.random(100, 255), b = math.random(100, 255)}
    playerColors[playerId] = color
    return color
end

-- Draw marker for scent trail
local function drawScentMarker(scent, color)
    if scentVisionActive then
        DrawMarker(28, scent.x, scent.y, scent.z - 1.0, 0, 0, 0, 0, 0, 0,
                   scent.size, scent.size, scent.size,
                   color.r, color.g, color.b, scent.opacity, false, false, 2, false, nil, nil, false)
    end
end
local function toggleScentVision()
    scentVisionActive = not scentVisionActive
    if scentVisionActive then
        SetTimecycleModifier("MP_Bull_tost")
        SetTimecycleModifierStrength(0.8)
        QBCore.Functions.Notify("Scent vision activated!", "success")
        TriggerServerEvent('dog:requestPlayerScent') -- Request scent trails from all nearby players
    else
        ClearTimecycleModifier()
        QBCore.Functions.Notify("Scent vision deactivated!", "error")
    end
end


-- Apply environmental effects to scent
local function applyEnvironmentalEffects(scent)
    local windDir, windSpeed = GetWindDirection(), GetWindSpeed()
    scent.x, scent.y = scent.x + (windDir.x * windSpeed * windImpactFactor), scent.y + (windDir.y * windSpeed * windImpactFactor)

    local weatherType = GetPrevWeatherTypeHashName()
    if weatherType == GetHashKey("RAIN") or weatherType == GetHashKey("THUNDER") then
        scent.intensity, scent.lifespan = scent.intensity * 0.5, scent.lifespan * 0.5 -- Decrease intensity and lifespan in rain
    elseif weatherType == GetHashKey("FOG") then
        scent.intensity = scent.intensity * 0.8 -- Slightly reduce intensity in fog
    end

    return scent
end

-- Calculate the chance to drop a scent based on items in the player's inventory
local function calculateDropChance(inventory)
    -- Check if inventory is a table
    if type(inventory) ~= "table" then
        print("[K9] Error: Inventory is not a table!")
        return baseDropChance
    end

    local dropChance = baseDropChance

    -- Loop through the player's inventory and adjust the dropChance based on items
    for _, item in pairs(inventory) do
        if itemDetectionList[item.name] and itemDetectionList[item.name].dropMultiplier then
            -- Multiply the current dropChance by the item's dropMultiplier
            dropChance = dropChance * itemDetectionList[item.name].dropMultiplier
        end
    end

    return dropChance
end
local playerData = nil  -- Declare globally

Citizen.CreateThread(function()
    while not QBCore.Functions.GetPlayerData() do
        print("[K9] Waiting for player data to be loaded...")
        Citizen.Wait(1000)
    end
    playerData = QBCore.Functions.GetPlayerData()
    print("[K9] Player Data Loaded: ", json.encode(playerData))
end)


local function sendPlayerScent()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())

    -- Check if playerData is loaded
    if not playerData or not playerData.inventory then
        print("[K9] Error: Player data or inventory is missing!")
        return
    end

    -- Retrieve and validate inventory
    local inventory = playerData.inventory
    if not inventory or type(inventory) ~= "table" then
        print("[K9] Error: Inventory is not a table or is missing!")
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
        size = 0.2 + staminaImpactFactor * ((100 - stamina) / 100),
        opacity = 50 + 155 * (stamina / 100),
        timestamp = GetGameTimer(),
        intensity = 1.0,
        lifespan = scentLifetime
    }

    print("[K9] Sending scent to server:", json.encode(scent))
    TriggerServerEvent('dog:sharePlayerScent', scent)
end


-- Attach wrist sphere for identification
local function attachWristSphere(playerId)
    local ped = GetPlayerPed(GetPlayerFromServerId(playerId))
    if not DoesEntityExist(ped) then return end

    if attachedSpheres[playerId] then
        attachedSpheres[playerId] = nil
    end

    local wristBone = GetPedBoneIndex(ped, 0xE5F2)
    local color = generatePlayerColor(playerId)

    attachedSpheres[playerId] = {
        ped = ped,
        bone = wristBone,
        color = color
    }

    wristSpheresActive = true -- Activate wrist spheres visibility

    print("[K9] Wrist marker set for player:", playerId)
end

-- Add this new function to render the wrist markers
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if wristSpheresActive then
            for playerId, markerInfo in pairs(attachedSpheres) do
                if DoesEntityExist(markerInfo.ped) then
                    local coords = GetPedBoneCoords(markerInfo.ped, markerInfo.bone)
                    DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03, 0.03, 0.03, markerInfo.color.r, markerInfo.color.g, markerInfo.color.b, 180, false, true, 2, nil, nil, false)
                else
                    attachedSpheres[playerId] = nil
                end
            end
        end
    end
end)

-- Register /k9track command for scent vision
RegisterCommand('k9track', function()
    toggleScentVision()
end, false)

-- Attach sphere to wrist on pressing E near a player
Citizen.CreateThread(function()
    while true do
        Wait(1000) -- Increased wait time to 1000ms
        if IsControlJustReleased(0, 38) then -- E key
            local ped, playerCoords = PlayerPedId(), GetEntityCoords(PlayerPedId())

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                local targetCoords = GetEntityCoords(targetPed)
                if #(playerCoords - targetCoords) < 5.0 then
                    print("[K9] E pressed - attaching wrist sphere.")
                    attachWristSphere(GetPlayerServerId(playerId))
                    QBCore.Functions.Notify("Attached sphere to player wrist!", "success")
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local isRunning = IsPedRunning(ped)
        local currentCoords = GetEntityCoords(ped)

        -- Only drop a scent if the player has moved a certain distance
        if lastScentCoords == nil or #(currentCoords - lastScentCoords) > scentDropDistance then
            if isRunning then
                sendPlayerScent()  -- Only drop scent if needed
                Wait(5000) -- Drop scent more frequently when running
            else
                sendPlayerScent()
                Wait(10000) -- Drop scent less frequently when walking or standing
            end

            lastScentCoords = currentCoords -- Update last scent coordinates
        else
            Wait(1000) -- Add wait to reduce the loop frequency when the player is not moving
        end
    end
end)



-- Clean up old scent trails based on lifespan and draw markers only when scent vision is active
Citizen.CreateThread(function()
    while true do
        Wait(500)  -- Adjust this value to make the loop run less frequently

        if scentVisionActive and playerScentTrail then
            for playerId, scentTrail in pairs(playerScentTrail) do
                -- Skip drawing your own scent trail
                if playerId ~= GetPlayerServerId(PlayerId()) then
                    local color = generatePlayerColor(playerId)

                    -- Process each player's scent trail
                    for _, scent in ipairs(scentTrail) do
                        -- Draw scent markers for other players
                        drawScentMarker(scent, color)
                    end
                end
            end
        end
    end
end)




RegisterNetEvent('dog:receivePlayerScent')
AddEventHandler('dog:receivePlayerScent', function(playerId, scent)
    -- Debug: Print the scent data received from the server
    print("[K9] Client received scent from player", playerId, ":", json.encode(scent))

    -- Ensure the scent is in table format
    if type(scent) ~= "table" then
        print("[K9] Error: Received scent trails are not in table format!")
        return
    end

    playerScentTrail[playerId] = playerScentTrail[playerId] or {}
    table.insert(playerScentTrail[playerId], scent)
end)



-- Client-side event to clear scent trails for a player
RegisterNetEvent('dog:clearScent')
AddEventHandler('dog:clearScent', function(playerId)
    playerScentTrail[playerId] = nil
end)
