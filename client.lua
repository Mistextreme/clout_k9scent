QBCore = exports['qb-core']:GetCoreObject()
local scentVisionActive = false
local playerScentTrail = {} -- Store scent data for each player
local playerColors = {}
local scentLifetime = 300000 -- 5 minutes (in milliseconds)
local staminaImpactFactor = 0.1
local scentDropDistance = 10.0 -- Minimum distance player must move before dropping a new scent
local lastScentCoords = nil
local playerData = nil -- Global variable to store player data
local playerDataLoaded = false
-- Scent block control
local isScentBlocked = false
local scentBlockDuration = 60000 -- 1 minute duration in milliseconds

local attachedSpheres = {} -- Store references to attached spheres for players
-- Wait for player data to be loaded
local function isAuthorizedPolice()
    local job = QBCore.Functions.GetPlayerData().job.name
    for k, v in pairs(Config.AuthorizedPoliceJobs) do
        if v == job then
            return true
        end
    end
    return false
end




local function isAuthAnimal()
    local ped = GetPlayerPed(PlayerId())
    for i = 1, #Config.AnimalPeds do
        if IsPedModel(ped, GetHashKey(Config.AnimalPeds[i].model)) then
            return true
        end
    end
    return false
end

-- Restricted jobs list that shouldn't leave scents
local restrictedJobs = {
    "police",    -- Police jobs don't leave scents
    "medic",     -- Medics don't leave scents
    "bcso",
    "sahp"
}

local function generatePlayerColor(playerId)
    if playerColors[playerId] then return playerColors[playerId] end
    local color = { r = math.random(100, 255), g = math.random(100, 255), b = math.random(100, 255) }
    playerColors[playerId] = color
    return color
end

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
        if Config.printDebug then
            print("[K9] Scent vision toggled on.")
        end
    else
        ClearTimecycleModifier()
        QBCore.Functions.Notify("Scent vision deactivated!", "error")
        if Config.printDebug then
            print("[K9] Scent vision toggled off.")
        end
    end
end

local function isJobRestricted(jobName)
    for _, restrictedJob in ipairs(restrictedJobs) do
        if jobName == restrictedJob then
            return true
        end
    end
    return false
end

local function activateScentBlock()
    isScentBlocked = true
    QBCore.Functions.Notify("Scent blocker activated. You won't leave any scents for 1 minute.", "success")

    -- Disable scent blocking after the duration ends
    SetTimeout(scentBlockDuration, function()
        isScentBlocked = false
        QBCore.Functions.Notify("Scent blocker deactivated. You are now leaving scents again.", "error")
    end)
end

-- Send player's scent to the server, considering restrictions
local function sendPlayerScent()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())

    -- Check player's job before creating a scent
   -- local playerJob = playerData.job and playerData.job.name or ""
    if isAuthorizedPolice() then
        if Config.printDebug then
            print("[K9] Scent creation skipped due to restricted job:")
        end
        return
    end

    -- Check if scent blocking is active
    if isScentBlocked then
        if Config.printDebug then
            print("[K9] Scent creation skipped due to active scent blocking.")
        end
        return
    end

    -- Request server-side inventory check and scent drop chance calculation
    TriggerServerEvent('dog:checkPlayerInventoryForScent', playerCoords, stamina)
end

-- Register a callback from the server for drop chance response
RegisterNetEvent('dog:processScentDrop')
AddEventHandler('dog:processScentDrop', function(playerCoords, stamina)
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
    if Config.printDebug then
        print("[K9] Sending scent to server:", json.encode(scent))
    end
    TriggerServerEvent('dog:sharePlayerScent', scent)
end)


-- Register /k9track command for scent vision
RegisterCommand('k9track', function()
    if  isAuthAnimal() then
    toggleScentVision()
    else
        QBCore.Functions.Notify("Are You An Animal?", "error")
    end

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

function startScentDroppingThread()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local isRunning = IsPedRunning(ped)
            local currentCoords = GetEntityCoords(ped)

            -- Only drop a scent if the player has moved a certain distance or after a delay
            if lastScentCoords == nil or #(currentCoords - lastScentCoords) > scentDropDistance then
                if Config.printDebug then
                    print("[K9] Player has moved significantly. Checking drop chance.")
                end

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
end

-- Draw scent markers for other players if scent vision is active
CreateThread(function()
    while true do
        Wait(0) -- Constantly draw markers when needed

        if scentVisionActive and playerScentTrail then
            for playerId, scentTrail in pairs(playerScentTrail) do
                -- Only allow drawing if the player's job is allowed
                local playerJob = playerData and playerData.job and playerData.job.name or ""
                if playerId ~= GetPlayerServerId(PlayerId()) and isAuthAnimal() then
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
   -- print("[K9] Client received scent from player", playerId, ":", json.encode(scent)) -- Debug: Check data reception

    -- Ensure the scent data is in table format
    if type(scent) == "string" then
        scent = json.decode(scent)
        if not scent then
            if Config.printDebug then
                print("[K9] Error: Failed to decode scent JSON string!")
            end
            return
        end
    end
    if type(playerId) == "table" and scent == nil then
        -- Bulk table received instead (nearby scent trails)
        for id, trail in pairs(playerId) do
            playerScentTrail[id] = playerScentTrail[id] or {}
            for _, s in ipairs(trail) do
                table.insert(playerScentTrail[id], s)
            end
        end
        return
    end

    -- Single scent fallback
    if type(scent) ~= "table" then
        if Config.printDebug then
            print("[K9] Error: Received scent trails are not in table format!")
        end
        return
    end

    -- Store the scent trail data and debug the storing process
    if Config.printDebug then
        print("[K9] Storing scent data for player:", playerId)
    end
    playerScentTrail[playerId] = playerScentTrail[playerId] or {}
    table.insert(playerScentTrail[playerId], scent)
    if Config.printDebug then
        print("[K9] Successfully stored scent data for player:", playerId)
    end
end)


-- Clear scent trails for a player
RegisterNetEvent('dog:clearScent')
AddEventHandler('dog:clearScent', function(playerId)
    playerScentTrail[playerId] = nil
end)

-- Fetch player data once it's available
CreateThread(function()
    while not QBCore.Functions.GetPlayerData() do
        Wait(1000)
    end
    playerData = QBCore.Functions.GetPlayerData()
    if Config.printDebug then
        print("[K9] Player Data Loaded: ", json.encode(playerData))
    end
end)


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.job then
        if not isAuthorizedPolice() then
            startScentDroppingThread()
        else
            if Config.printDebug then
                print("[K9] Scent creation is disabled for authorized police.")
            end
        end
    end
end)
