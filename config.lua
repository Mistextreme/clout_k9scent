Config = Config or {}

Config.Inventory = "ox" -- Options: "esx" or "ox" (for ox_inventory, ensure you have it installed)
Config.printDebug = false -- Set to true to enable debug prints in the server console for troubleshooting

Config.AuthorizedPoliceJobs = {
    "police","bcso","sahp"
}

Config.ScentItems = {
    ['spikestrip'] = {contraband = true,},
    ['oxybox'] = {contraband = false, drug = true},
    ['weapon_spraycan'] = {contraband = true,},
    ['weapon_antidote'] = {contraband = true, drug = false},
    
}
Config.AnimalPeds = {
    {model = "ft-aushep" },
    {model = "a_c_chop"},
    {model = "ft_kangal"},
    {model = "ft-dobermanv2"},
    {model = "ft-gs"},
    {model = "ft-bs" },
    {model = "golden_r"},
    {model = "k9_husky"},
    {model = "ft-bloodhound"},
    {model = "bernard"  },
    {model = "ft-pterrier" },
    {model = "ft-labrador"  },
    {model = "dane"},
    {model = "k9_female"},
    {model = "k9_male" },
    {model = "ft_malinois"},
    {model = "abdog"},
    {model = "dalmatian"},
    {model = "ft-boxer"},
    {model = "huskyk9_new"  },
    
}

Config.Functions = {
    GetInventoryServer = function(source)
        if Config.Inventory == "ox" then
            return exports.ox_inventory:GetInventoryItems(source)
        elseif Config.Inventory == "esx" then
            local xPlayer = ESX.GetPlayerFromId(source)
            return xPlayer.inventory
        end
    end,
    
    PlayerDataServer = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return {job = {}} end
        
        local PlayerData = {
            identifier = xPlayer.identifier,
            citizenid = xPlayer.identifier,
            bloodtype = xPlayer.get('bloodtype') or "Unknown",
            fingerprint = xPlayer.get('fingerprint') or "Unknown",
            firstname = xPlayer.get('firstName') or "Unknown",
            lastname = xPlayer.get('lastName') or "Unknown",
            job = xPlayer.job.name,
            jobgrade = tostring(xPlayer.job.grade),
            jobtype = "Unknown", -- ESX doesn't have job type by default
        }
        return PlayerData
    end,

    SearchInventoryClient = function(item, results)
        local found = false
        if ox_inventory:Search('count', item) > 0 then found = true end
        if results then found = ox_inventory:Search('slots', item) end
        return found
    end,

    PlayerDataClient = function()
        local xPlayer = ESX.GetPlayerData()
        
        local PlayerData = {
            identifier = xPlayer.identifier,
            citizenid = xPlayer.identifier,
            bloodtype = xPlayer.bloodtype or "Unknown",
            fingerprint = xPlayer.fingerprint or "Unknown",
            firstname = xPlayer.firstName or "Unknown",
            lastname = xPlayer.lastName or "Unknown",
            job = xPlayer.job.name,
            jobgrade = tostring(xPlayer.job.grade),
            jobtype = "Unknown", -- ESX doesn't have job type by default
        }
        return PlayerData
    end,
}
