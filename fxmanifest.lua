fx_version 'cerulean'
game 'gta5'

name 'veh_mouse_interact'
description 'Mouse interact for vehicle parts (based on ox_target)'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js'
}