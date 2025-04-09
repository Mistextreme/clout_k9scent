fx_version 'bodacious'
game 'gta5'

author 'Cloutmatic'
description 'K9 Tracking Script (ESX Version)'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

shared_script 'config.lua' -- shared config for both client and server
dependencies {
    'es_extended'
}
