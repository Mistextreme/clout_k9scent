Config = Config or {}

Config.Inventory = "qb" -- Options: "qb" or "ox" (for ox_inventory, ensure you have it installed)
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
        elseif Config.Inventory == "qb" then
            local Player = QBCore.Functions.GetPlayer(source)
            return Player.PlayerData.items
        end -- ✅ closes if properly
    end, -- ✅ closes function
    

    PlayerDataServer = function(source)
        local PlyData = QBCore.Functions.GetPlayer(source)
        if not PlyData then return {job = {}} end
        PlyData = PlyData.PlayerData
        local PlayerData = {
            identifier = PlyData.citizenid,
            citizenid = PlyData.citizenid,
            bloodtype = PlyData.metadata.bloodtype,
            fingerprint = PlyData.metadata.fingerprint,
            firstname = PlyData.charinfo.firstname,
            lastname = PlyData.charinfo.lastname,
            job = PlyData.job.name,
            jobgrade = tostring(PlyData.job.grade.level),
            jobtype = PlyData.job.type,
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
        local PlyData = QBCore.Functions.GetPlayerData()
        local PlayerData = {
            identifier = PlyData.citizenid,
            citizenid = PlyData.citizenid,
            bloodtype = PlyData.metadata.bloodtype,
            fingerprint = PlyData.metadata.fingerprint,
            firstname = PlyData.charinfo.firstname,
            lastname = PlyData.charinfo.lastname,
            job = PlyData.job.name,
            jobgrade = tostring(PlyData.job.grade.level),
            jobtype = PlyData.job.type,
        }
        return PlayerData
    end,
}
