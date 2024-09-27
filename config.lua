Config = {}

Config.Locale = 'de'

Config.AllowedGroups = {'superadmin', 'admin'}

Config.Commands = {
    startWaterRising = 'startTsunami',
    startWaterDropping = 'startWaterDropping',
    stopWaterRising = 'stopTsunami',
    resetWaterLevel = 'resetWaterLevel',
    setWaterLevel = 'setWaterLevel', -- /setWaterLevel <WaterLevel> // Example: /setWaterLevel 50
}

Config.UseNoNPCs = false -- Set true if you use a Script for No NPCs // Set false otherwise

Config.WaterLevelMax = 50.0 -- How high the Water is rising until it stops // MaxWaterLevel = 250.0
Config.WaterLevelRising = 0.05 -- How many Meters the Water is rising per RefreshTime
Config.WaterLevelDropping = 0.05 -- How many Meters the Water is dropping per RefreshTime

Config.StayAtMax = 10 -- How long the Water should stay at MaxWaterHeight // in minutes
Config.RefreshTime = 100 -- Changes on how fast the water is rising or dropping. If number is lower it is faster but lower performance

Config.Notification = function(source, message, typ)
    if IsDuplicityVersion() then -- serverside
        exports.msk_core:Notification(source, 'Tsunami', message, typ, 5000)
    else -- clientside
        exports.msk_core:Notification('Tsunami', message, typ, 5000)
    end
end

-- This function is serverside
Config.TsunamiAlert = function(source, message)
    Wait(10000) -- Wait 10 seconds before starting the alert

    exports.yseries:CellBroadcast(source, 'Tsunami Alert', message)
end

Translation = {
    ['de'] = {
        ['no_permission'] = 'Du hast keine Berechtigung diesen Befehl auszuführen!',
        ['start_tsunami_alert'] = 'Es wurde ein Tsunami gesichtet, bitte begeben Sie sich umgehend an einen erhöhten Ort oder steigen Sie in ein Boot!',
    },
    ['en'] = {
        ['no_permission'] = 'You don\'t have permission to execute this Command!',
        ['start_tsunami_alert'] = 'A tsunami has been sighted, please move to a higher place immediately or get on a boat!',
    },
}