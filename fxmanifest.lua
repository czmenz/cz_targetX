fx_version 'cerulean'
game 'gta5'

name 'cz_targetX'
author 'Czmenz'
version '1.0.0'
description '3D World Dynamic Exportable Targets'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/keylabels.lua',
    'client/main.lua'
}

server_scripts {
    'server/update_checker.lua',
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

exports {
    'AddTarget',
    'RemoveTarget',
    'UpdateTarget'
}

server_exports {
    'AddTarget',
    'RemoveTarget',
    'UpdateTarget'
}
