fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_tsunami'
description 'Tsunami'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/**/*.*',
}

server_scripts {
    'server/**/*.*',
}

files {
	'flood.xml',
	'water.xml'
}

data_file 'WATER_FILE' 'flood.xml'
data_file 'WATER_FILE' 'water.xml'