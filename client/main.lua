local CurrentWaterLevel = 0.0
local IsWaterLevelRising, IsWaterLevelDropping, IsWaterLevelStaying = false, false, false
local IsWaterLevelModified = false

LoadWater = function(file)
    local success = LoadWaterFromPath(GetCurrentResourceName(), ('%s.xml'):format(file))

    if not success then
        print(('^1Failed to load ^3%s.xml^0! ^3Does the file exist within the resource?^0'):format(file))
    end

    return success
end

SetPedPopulation = function(population)
    if Config.UseNoNPCs then return end
    SetPedPopulationBudget(population)
    SetVehiclePopulationBudget(population)
end

StartWaterLevelRising = function(waterLevel)
    CurrentWaterLevel = waterLevel or 0.0
    local success = LoadWater('flood')
    if not success then return end
    IsWaterLevelModified = true
    IsWaterLevelStaying = false
    IsWaterLevelRising = true
    SetPedPopulation(0)
end
RegisterNetEvent('msk_tsunami:startWaterLevelRising', StartWaterLevelRising)

StartWaterLevelDropping = function(waterLevel)
    IsWaterLevelModified = true
    IsWaterLevelStaying = false
    IsWaterLevelDropping = true
    SetPedPopulation(0)
end
RegisterNetEvent('msk_tsunami:startWaterLevelDropping', StartWaterLevelDropping)

StopWaterLevelRising = function(waterLevel)
    IsWaterLevelRising = false
    IsWaterLevelStaying = true
end
RegisterNetEvent('msk_tsunami:stopWaterLevelRising', StopWaterLevelRising)

StopWaterLevelDropping = function(waterLevel)
    IsWaterLevelDropping = false
    IsWaterLevelStaying = true
end
RegisterNetEvent('msk_tsunami:stopWaterLevelDropping', StopWaterLevelDropping)

ResetWaterLevel = function()
    if IsWaterLevelRising then 
        StopWaterLevelRising() 
    end

    -- LoadWater('water')
    ResetWater() -- Resets the water to the games default water.xml
    SetPedPopulation(3)

    CurrentWaterLevel = 0.0
    IsWaterLevelModified = false
    IsWaterLevelStaying = false
    IsWaterLevelRising = false
    IsWaterLevelDropping = false

    local allVehicles = GetGamePool('CVehicle')
    for i = 1, #allVehicles do
        SetVehicleGravity(allVehicles[i], true)
    end
end
RegisterNetEvent('msk_tsunami:resetWaterLevel', ResetWaterLevel)

UpdateWaterLevel = function(waterLevel, staying, rising, dropping)
    if not IsWaterLevelModified then 
        local success = LoadWater('flood')
        if not success then return end
    end

    CurrentWaterLevel = waterLevel
    SetPedPopulation(0)

    -- This is for player joins the server while Tsunami is active or for Command setWaterLevel
    if staying or rising or dropping then
        IsWaterLevelModified = true

        if staying then
            IsWaterLevelStaying = true
        elseif rising then
            IsWaterLevelRising = true
        elseif dropping then
            IsWaterLevelDropping = true
        end
    end

    local waterQuadCount = GetWaterQuadCount()
    for i = 1, waterQuadCount do
        local success, waterQuadLevel = GetWaterQuadLevel(i)

        if success then
            SetWaterQuadType(i, 0)
            SetWaterQuadLevel(i, CurrentWaterLevel)
            SetWaterQuadNoStencil(i, true)
            SetWaterQuadIsInvisible(i, false)
            SetWaterQuadHasLimitedDepth(i, false)
            SetWaterQuadAlpha(i, 26, 26, 26, 26)
        end
    end

    UpdatePedsAndVehicles()
end
RegisterNetEvent('msk_tsunami:updateWaterLevel', UpdateWaterLevel)

local UpdatedPedsAndVehicles = false
UpdatePedsAndVehicles = function(everyFrame)
    if everyFrame then
        if UpdatedPedsAndVehicles then return end
        UpdatedPedsAndVehicles = true

        SetTimeout(Config.RefreshTime, function()
            UpdatedPedsAndVehicles = false
        end)
    end

    local allPeds = GetGamePool('CPed')
    for i = 1, #allPeds do
        local ped = allPeds[i]
        local pedCoords = GetEntityCoords(ped)
        local waterQuadIndex = GetWaterQuadAtCoords_3d(pedCoords.x, pedCoords.y, pedCoords.z)

        if waterQuadIndex ~= -1 then
            if IsPedInAnyVehicle(ped, false) and not IsPedInAnyBoat(ped) and not IsPedInAnySub(ped) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                TaskLeaveVehicle(ped, vehicle, 4160)
            end

            if not IsPedInAnyVehicle(ped, false) then
                SetPedConfigFlag(ped, 60, false) -- IsStanding
                SetPedConfigFlag(ped, 65, true) -- IsSwimming
                SetEnableScuba(ped, true) -- Enables diving motion when underwater. 
                SetPedWetnessHeight(ped, 100)
                SetPedPathPreferToAvoidWater(ped, true)
            end
        end
    end

    local allVehicles = GetGamePool('CVehicle')
    for i = 1, #allVehicles do
        local vehicle = allVehicles[i]
        local vehicleCoords = GetEntityCoords(vehicle)
        local waterQuadIndex = GetWaterQuadAtCoords_3d(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)

        if waterQuadIndex ~= -1 then
            SetVehicleGravity(vehicle, false)
        else
            SetVehicleGravity(vehicle, true)
        end
    end
end

CreateThread(function()
    while true do
        local sleep = 250
        
        if IsWaterLevelModified then
            sleep = 1
            local playerPed = PlayerPedId()            
            local playerCoords = GetEntityCoords(playerPed)
            local waterQuadIndex = GetWaterQuadAtCoords_3d(playerCoords.x, playerCoords.y, playerCoords.z)
            local _, waterHeight = GetWaterHeight(playerCoords.x, playerCoords.y, playerCoords.z)

            if waterQuadIndex ~= -1 then
                if IsPedInAnyVehicle(playerPed, false) and not IsPedInAnyBoat(playerPed) and not IsPedInAnySub(playerPed) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    TaskLeaveVehicle(playerPed, vehicle, 4160)
                end

                if not IsPedInAnyVehicle(playerPed, false) then
                    SetPedConfigFlag(playerPed, 60, false) -- IsStanding
                    SetPedConfigFlag(playerPed, 65, true) -- IsSwimming
                    SetEnableScuba(playerPed, true) -- Enables diving motion when underwater. 
                    SetPedWetnessHeight(playerPed, 100)
                end
            end

            if IsWaterLevelStaying then
                UpdatePedsAndVehicles(true)
            end
        end
        
        Wait(sleep)
    end
end)