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
- ❌ **Scent Blocker Item** support
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
