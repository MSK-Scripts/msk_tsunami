local CurrentWaterLevel = 0.0
local IsWaterLevelRising, IsWaterLevelDropping, IsWaterLevelStaying = false, false, false
local IsWaterLevelModified = false

if Config.WaterLevelMax > 250.0 then
    Config.WaterLevelMax = 250.0
end

for i = 1, #Config.AllowedGroups do
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.AllowedGroups[i], Config.Commands.startWaterRising))
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.AllowedGroups[i], Config.Commands.startWaterDropping))
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.AllowedGroups[i], Config.Commands.stopWaterRising))
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.AllowedGroups[i], Config.Commands.resetWaterLevel))
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.AllowedGroups[i], Config.Commands.setWaterLevel))
end

local isPlayerAllowed = function(source, command)
    return IsPlayerAceAllowed(source, ('command.%s'):format(command))
end

local Round = function(num, decimal)
    assert(num and tonumber(num), 'Parameter "num" has to be a number on function MSK.Math.Round')
    assert(not decimal or decimal and tonumber(decimal), 'Parameter "decimal" has to be a number on function MSK.Math.Round')
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end

StartWaterLevelRising = function(maxWaterLevel)
    local maxWaterLevel = maxWaterLevel or Config.WaterLevelMax

    if IsWaterLevelModified and not IsWaterLevelStaying then 
        if IsWaterLevelRising then return
        elseif IsWaterLevelDropping then
            StopWaterLevelDropping()
        end
    end

    IsWaterLevelModified = true
    IsWaterLevelStaying = false
    IsWaterLevelRising = true
    TriggerClientEvent('msk_tsunami:startWaterLevelRising', -1, CurrentWaterLevel)
    
    CreateThread(function()
        Config.TsunamiAlert(-1, Translation[Config.Locale]['start_tsunami_alert'])
    end)
    
    CreateThread(function()
        while IsWaterLevelRising do
            UpdateWaterLevel(CurrentWaterLevel += Config.WaterLevelRising)
            Wait(Config.RefreshTime)
        end
    end)
end
exports('StartWaterLevelRising', StartWaterLevelRising)

StartWaterLevelDropping = function()
    if not IsWaterLevelModified then return end

    if IsWaterLevelModified and not IsWaterLevelStaying then 
        if IsWaterLevelDropping then return
        elseif IsWaterLevelRising then
            StopWaterLevelRising()
        end
    end

    IsWaterLevelModified = true
    IsWaterLevelStaying = false
    IsWaterLevelDropping = true
    TriggerClientEvent('msk_tsunami:startWaterLevelDropping', -1, CurrentWaterLevel)

    CreateThread(function()
        while IsWaterLevelDropping do
            UpdateWaterLevel(CurrentWaterLevel -= Config.WaterLevelDropping)
            Wait(Config.RefreshTime)
        end
    end)
end
exports('StartWaterLevelDropping', StartWaterLevelDropping)

StopWaterLevelRising = function()
    if not IsWaterLevelModified then return end
    IsWaterLevelRising = false
    IsWaterLevelStaying = true
    TriggerClientEvent('msk_tsunami:stopWaterLevelRising', -1, CurrentWaterLevel)

    SetTimeout(Config.StayAtMax * 1000 * 60, function()
        if not IsWaterLevelStaying then return end
        StartWaterLevelDropping()
    end)
end
exports('StopWaterLevelRising', StopWaterLevelRising)

StopWaterLevelDropping = function()
    if not IsWaterLevelModified then return end
    IsWaterLevelDropping = false
    IsWaterLevelStaying = true
    TriggerClientEvent('msk_tsunami:stopWaterLevelDropping', -1, CurrentWaterLevel)
end
exports('StopWaterLevelDropping', StopWaterLevelDropping)

ResetWaterLevel = function()
    if IsWaterLevelRising then 
        StopWaterLevelRising() 
    elseif IsWaterLevelDropping then 
        StopWaterLevelDropping()
    end

    CurrentWaterLevel = 0.0
    IsWaterLevelModified = false
    IsWaterLevelStaying = false
    IsWaterLevelRising = false
    IsWaterLevelDropping = false

    TriggerClientEvent('msk_tsunami:resetWaterLevel', -1)
end
exports('ResetWaterLevel', ResetWaterLevel)

UpdateWaterLevel = function(waterLevel)
    if not IsWaterLevelModified then return end
    CurrentWaterLevel = waterLevel

    if IsWaterLevelRising and CurrentWaterLevel >= Config.WaterLevelMax then 
        CurrentWaterLevel = Config.WaterLevelMax
        TriggerClientEvent('msk_tsunami:updateWaterLevel', -1, CurrentWaterLevel)
        StopWaterLevelRising()
        return 
    end

    if IsWaterLevelDropping and CurrentWaterLevel <= 0.0 then
        CurrentWaterLevel = 0.0
        ResetWaterLevel()
        return
    end

    TriggerClientEvent('msk_tsunami:updateWaterLevel', -1, CurrentWaterLevel, IsWaterLevelStaying)
end
exports('UpdateWaterLevel', UpdateWaterLevel)

RegisterCommand(Config.Commands.startWaterRising, function(source, args, rawCommand)
    local src = source
    local maxWaterLevel = args[1]

    if src and src > 0 and not isPlayerAllowed(src, Config.Commands.startWaterRising) then 
        return Config.Notification(src, Translation[Config.Locale]['no_permission'], 'error')
    end

    StartWaterLevelRising(maxWaterLevel)
end)

RegisterCommand(Config.Commands.startWaterDropping, function(source, args, rawCommand)
    local src = source

    if src and src > 0 and not isPlayerAllowed(src, Config.Commands.startWaterDropping) then 
        return Config.Notification(src, Translation[Config.Locale]['no_permission'], 'error')
    end

    StartWaterLevelDropping()
end)

RegisterCommand(Config.Commands.stopWaterRising, function(source, args, rawCommand)
    local src = source

    if src and src > 0 and not isPlayerAllowed(src, Config.Commands.stopWaterRising) then 
        return Config.Notification(src, Translation[Config.Locale]['no_permission'], 'error')
    end

    StopWaterLevelRising()
end)

RegisterCommand(Config.Commands.resetWaterLevel, function(source, args, rawCommand)
    local src = source

    if src and src > 0 and not isPlayerAllowed(src, Config.Commands.resetWaterLevel) then 
        return Config.Notification(src, Translation[Config.Locale]['no_permission'], 'error')
    end

    ResetWaterLevel()
end)

RegisterCommand(Config.Commands.setWaterLevel, function(source, args, rawCommand)
    local src = source
    local waterLevel = args[1]
    if not waterLevel then return end
    waterLevel = Round(waterLevel, 1)

    if src and src > 0 and not isPlayerAllowed(src, Config.Commands.setWaterLevel) then 
        return Config.Notification(src, Translation[Config.Locale]['no_permission'], 'error')
    end

    IsWaterLevelModified = true
    IsWaterLevelStaying = true
    UpdateWaterLevel(waterLevel)
end)

AddEventHandler('playerJoining', function(playerId)
    if not IsWaterLevelModified then return end
    TriggerClientEvent('msk_tsunami:updateWaterLevel', playerId, CurrentWaterLevel, IsWaterLevelStaying, IsWaterLevelRising, IsWaterLevelDropping)
end)