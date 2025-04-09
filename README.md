# 🐾 K9 Scent Tracking System

A realistic scent-tracking system for canine units in FiveM. This script allows animal ped units (K9s) to track player scent trails, simulating stamina decay, scent blocking, and more. Built with immersion and utility in mind, this system enhances roleplay for law enforcement and animal units.

---
## PREVIEW


https://github.com/user-attachments/assets/b39716cc-91ad-42f0-a63e-227de36a9620


---

## 🚔 Features

- 🔍 **Scent Trail Generation** based on movement and stamina
- 👃 **K9 Vision Mode** with scent markers and optional visual effects
- 🧪 **Scent Drop Chance Logic** influenced by contraband (drugs, weapons)
- 🐾 **Animal Ped Recognition** for authorized tracking
- ❌ **Scent Blocker Item**
- 🧩 **Framework Support**: QBCore
- 📦 **Inventory Support**: OX Inventory and QB Inventory
- 🌐 **Sync Logic**: Only players within scent range receive scent data

---

## ⚙️ Requirements

- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- Either:
  - [OX Inventory](https://github.com/overextended/ox_inventory)
  - OR [QB Inventory](https://github.com/qbcore-framework/qb-inventory)

---

## 🛠️ Installation

1. **Clone or Download** this repository into your `resources` folder
2. ensure clout_k9scent in your server.cfg after QB Core and your Inventory

## 🧪 Commands
**Command  	Description**
/k9track	  Toggle scent vision for K9


## 🐕 Scent Blocking
This system includes a scent blocker item (scent_blocker) usable via inventory systems to prevent scent drops for 60 seconds. You may customize this item in your inventory resource.

## 🛡️ License
Copyright (c) 2025 CreatorBailey

This script is the intellectual property of the author. You are granted permission to use it under the following conditions:

1. You may use this script on personal or public FiveM servers.
2. You may NOT redistribute, reupload, or resell this script.
3. You may NOT modify or republish this script without permission.
4. You must credit the original author if showcased publicly.
5. Commercial use (e.g., use in paid servers or server packages) is not allowed without written permission.

By using this script, you agree to these terms.

For custom use cases or commercial licensing, contact me via Discord or the FiveM forums.

## 👨‍💻 Credits
Developed by Cloutmatic
For support or questions, contact me on the FiveM forums under Gatorsman98 or Join Our New Discord!

https://discord.gg/RQQyRpg2vB


## MIST VERSION ESX

```markdown
# K9 Scent Tracking System (ESX Version)

## Overview
This resource adds an advanced K9 scent tracking system to your ESX server. Police K9 units can track player scents using specialized scent vision, allowing for more immersive and realistic police roleplay. Players leave scent trails based on their movement, stamina, and inventory items.

## Features
- Police officers can transform into K9 dogs and track scent trails
- Players leave scent trails that vary in intensity based on:
  - Movement speed (running leaves stronger scents)
  - Carrying contraband or drugs (increases the chance of leaving scents)
  - Player stamina levels (affects scent size and opacity)
- Special scent blocking items for players to evade K9 tracking
- Compatible with both native ESX inventory and ox_inventory
- Configurable animal models for K9 units
- Visual scent trails only visible to K9 units

## Dependencies
- [es_extended](https://github.com/esx-framework/esx-legacy)
- [ox_inventory](https://github.com/overextended/ox_inventory) (optional, for enhanced inventory support)

## Installation

1. Download the resource
2. Place it in your server's resources folder
3. Add `ensure k9_tracking` to your server.cfg
4. Configure the `config.lua` file to match your server's setup
5. Set up the required items in your inventory system (see below)
6. Restart your server

## Configuration

The main configuration options are in `config.lua`:

### Inventory System
```lua
Config.Inventory = "esx" -- Options: "esx" or "ox" (for ox_inventory)
```

### Debug Mode
```lua
Config.printDebug = false -- Set to true for troubleshooting
```

### Authorized Police Jobs
```lua
Config.AuthorizedPoliceJobs = {
    "police", "bcso", "sahp"
}
```

### Items That Leave Scent Trails
```lua
Config.ScentItems = {
    ['spikestrip'] = {contraband = true,},
    ['oxybox'] = {contraband = false, drug = true},
    ['weapon_spraycan'] = {contraband = true,},
    ['weapon_antidote'] = {contraband = true, drug = false},
}
```

### K9 Animal Models
```lua
Config.AnimalPeds = {
    {model = "ft-aushep" },
    {model = "a_c_chop"},
    -- more models listed in config.lua
}
```

## Required Items

### Add to ox_inventory/data/items.lua:
```lua
['scent_blocker'] = {
    label = 'Scent Blocker',
    weight = 200,
    stack = true,
    close = true,
    description = 'Prevents K9 units from tracking your scent for 60 seconds'
}
```

### Add to ESX items database:
If using standard ESX inventory, add the scent_blocker to your items table in the database:

```sql
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('scent_blocker', 'Scent Blocker', 1, 0, 1);
```

## Usage

### For K9 Officers:
1. Use a K9 model (dog model) from the configured list
2. Use the command `/k9track` to toggle scent vision
3. While scent vision is active, you'll see visual markers showing player scent trails
4. The stronger the scent (larger/more opaque marker), the fresher the trail

### For Players:
- Moving quickly (running) increases chances of leaving scent trails
- Carrying weapons or drugs increases chances of leaving scent trails
- Use a `scent_blocker` item to prevent leaving scent trails for 60 seconds

## Known Issues
- Some stream animal models might not be detected correctly
- Performance impact when many players are leaving scent trails in a condensed area

## Credits
- Original Creator: Cloutmatic
- ESX Adaptation: Your Name Here
- For issues or suggestions, please open an issue on GitHub

## License
This resource is provided as-is with no warranty.
```
