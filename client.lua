local mouseEnabled = false
local screen = { x = 0.5, y = 0.5, w = 1920, h = 1080 }
local hoveredPoint = nil
local hoveredVeh = nil

-- включение/выключение мыши
local function toggleMouse(state)
    mouseEnabled = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(state)
    SendNUIMessage({ action = 'toggle', state = state })
    if state then
        CreateThread(function()
            while mouseEnabled do
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 1, true)  -- LookLeftRight
                DisableControlAction(0, 2, true)  -- LookUpDown
                DisableControlAction(0, 14, true) -- wheel up
                DisableControlAction(0, 15, true) -- wheel down
                Wait(0)
            end
        end)
    end
end

RegisterCommand('+vehMouse', function() toggleMouse(true) end)
RegisterCommand('-vehMouse', function() toggleMouse(false) end)
RegisterKeyMapping('+vehMouse', 'Vehicle mouse interact', 'keyboard', Config.MouseInteractKey)

-- NUI: движение мыши
RegisterNUICallback('mouseMove', function(data, cb)
    screen.w, screen.h = data.w, data.h
    screen.x, screen.y = data.x / data.w, data.y / data.h

    if not mouseEnabled then
        hoveredPoint, hoveredVeh = nil, nil
        return cb(1)
    end

    local camPos, camTo = getMouseRay()
    local camDir = (camTo - camPos); if #camDir > 0 then camDir = camDir / #camDir end
    local closestPoint = nil
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local point = getPointUnderMouse(veh, camPos, camDir)
            if point then closestPoint = point end
        end
    end
    hoveredPoint = closestPoint
    hoveredVeh = closestPoint and closestPoint.veh or nil
    cb(1)
end)

-- получить ближайшую точку к лучу мышки
function getPointUnderMouse(vehicle, camPos, camDir)
    local closestPoint = nil
    local closestDist = 0.2 -- максимально допустимое расстояние до луча
    for name, point in pairs(Config.VehicleInteractPoints) do
        local worldPos
        local boneIndex = GetEntityBoneIndexByName(vehicle, point.bone or "")
        if boneIndex and boneIndex ~= -1 then
            worldPos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
        else
            worldPos = GetOffsetFromEntityInWorldCoords(vehicle, point.offset)
        end

        local toPoint = worldPos - camPos
        local proj = dot3(toPoint, camDir)
        local closest = camPos + camDir * proj
        local dist = #(worldPos - closest)

        if dist < closestDist then
            closestDist = dist
            closestPoint = {
                name = name,
                label = point.label,
                doorIndex = point.doorIndex,
                pos = worldPos,
                veh = vehicle
            }
        end
    end
    return closestPoint
end

-- скалярное произведение
function dot3(a,b) return a.x*b.x + a.y*b.y + a.z*b.z end


-- NUI: клик
RegisterNUICallback('mouseClick', function(_, cb)
    if hoveredPoint and hoveredVeh then
        openVehicleMenu(hoveredVeh, hoveredPoint)
    end
    cb(1)
end)

-- луч от камеры
function getMouseRay()
    local camPos = GetFinalRenderedCamCoord()
    local camRot = GetFinalRenderedCamRot(2)

    -- координаты мыши относительно центра экрана (-1..1)
    local relX = (screen.x - 0.5) * 2
    local relY = (0.5 - screen.y) * 2 -- Y вверх

    local fov = math.rad(GetGameplayCamFov())
    local aspect = screen.w / screen.h

    -- направление камеры
    local yaw = math.rad(camRot.z)
    local pitch = math.rad(camRot.x)

    local forward = vec3(
        -math.sin(yaw) * math.cos(pitch),
         math.cos(yaw) * math.cos(pitch),
         math.sin(pitch)
    )

    local right = vec3(math.cos(yaw), math.sin(yaw), 0)
    local up = vec3(0,0,1)

    -- смещение с учётом FOV и aspect ratio
    local adjusted = forward + right * relX * math.tan(fov/2) * aspect + up * relY * math.tan(fov/2)
    if #adjusted > 0 then adjusted = adjusted / #adjusted end

    local distance = Config.MouseRayDistance or 6.0
    return camPos, camPos + adjusted * distance
end

function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vec3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end

-- меню для точки
function openVehicleMenu(vehicle, point)
    local options = {
        {
            title = 'Открыть '..point.label,
            onSelect = function() SetVehicleDoorOpen(vehicle, point.doorIndex, false, false) end
        },
        {
            title = 'Закрыть '..point.label,
            onSelect = function() SetVehicleDoorShut(vehicle, point.doorIndex, false) end
        }
    }
    lib.registerContext({ id = 'veh_ctx', title = point.label, options = options })
    lib.showContext('veh_ctx')
end

-- отрисовка всех точек на определённой дистанции + отладка луча мышки
CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local vehicles = GetGamePool('CVehicle')

        for _, veh in ipairs(vehicles) do
            if #(playerCoords - GetEntityCoords(veh)) <= (Config.PointDrawDistance or 10.0) then
                for _, point in pairs(Config.VehicleInteractPoints) do
                    local boneIndex = GetEntityBoneIndexByName(veh, point.bone or "")
                    local worldPos
                    if boneIndex and boneIndex ~= -1 then
                        worldPos = GetWorldPositionOfEntityBone(veh, boneIndex)
                    else
                        worldPos = GetOffsetFromEntityInWorldCoords(veh, point.offset)
                    end

                    DrawMarker(28, worldPos.x, worldPos.y, worldPos.z + 0.05, 0,0,0, 0,0,0,
                        Config.PointMarkerScale or 0.15,
                        Config.PointMarkerScale or 0.15,
                        Config.PointMarkerScale or 0.15,
                        0,200,255,180, false, false, 2, false, nil, nil, false)
                    drawText3D(worldPos, point.label, 0.35, 255,255,255,220)
                end
            end
        end

        -- отладка мышки
        if mouseEnabled then
            local from, to = getMouseRay()
            DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, 255, 0, 0, 255)
            DrawMarker(28, to.x, to.y, to.z, 0,0,0, 0,0,0, 0.2,0.2,0.2, 255,0,0,150, false, false, 2, false, nil, nil, false)
        end
    end
end)

-- drawText3D
function drawText3D(coords, text, scale, r,g,b,a)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(coords - vec3(px,py,pz))
    if not scale then scale = 0.35 end
    local fov = (1 / GetGameplayCamFov()) * 100
    local scaleMult = (1 / dist) * 2 * fov * scale
    if onScreen then
        SetTextScale(0.0, scaleMult)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(r or 255, g or 255, b or 255, a or 215)
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end
