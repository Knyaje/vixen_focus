local mouseEnabled = false
local screen = { x = 0.5, y = 0.5, w = 1920, h = 1080 }

local targets = {}
local hoveredTarget = nil
local lastId = 0
local vehicleTargets = {}

-- internal util to register targets
local function addTarget(data)
    lastId = lastId + 1
    data.id = lastId
    data.radius = data.radius or Config.DefaultTargetRadius
    targets[lastId] = data
    return lastId
end

exports('addTargetPoint', function(coords, opts)
    opts = opts or {}
    return addTarget({
        type = 'point',
        coords = coords,
        label = opts.label,
        options = opts.options,
        radius = opts.radius
    })
end)

exports('addTargetEntity', function(entity, opts)
    opts = opts or {}
    return addTarget({
        type = 'entity',
        entity = entity,
        offset = opts.offset,
        label = opts.label,
        options = opts.options,
        radius = opts.radius
    })
end)

exports('addTargetBone', function(entity, bone, opts)
    opts = opts or {}
    return addTarget({
        type = 'bone',
        entity = entity,
        bone = bone,
        offset = opts.offset,
        label = opts.label,
        options = opts.options,
        radius = opts.radius
    })
end)

exports('removeTarget', function(id)
    targets[id] = nil
end)

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
RegisterKeyMapping('+vehMouse', 'Mouse interact', 'keyboard', Config.MouseInteractKey)

-- helpers
local function dot3(a,b) return a.x*b.x + a.y*b.y + a.z*b.z end

local function getTargetPosition(target)
    if target.type == 'point' then
        return target.coords
    elseif target.type == 'entity' then
        if target.offset then
            return GetOffsetFromEntityInWorldCoords(target.entity, target.offset)
        end
        return GetEntityCoords(target.entity)
    elseif target.type == 'bone' then
        local boneIndex = GetEntityBoneIndexByName(target.entity, target.bone or '')
        if boneIndex ~= -1 then
            return GetWorldPositionOfEntityBone(target.entity, boneIndex)
        elseif target.offset then
            return GetOffsetFromEntityInWorldCoords(target.entity, target.offset)
        else
            return GetEntityCoords(target.entity)
        end
    end
end

local function isPointOnRay(worldPos, camPos, camDir, radius)
    radius = radius or Config.DefaultTargetRadius
    local toPoint = worldPos - camPos
    local proj = dot3(toPoint, camDir)
    if proj < 0 then return end
    local closest = camPos + camDir * proj
    local dist = #(worldPos - closest)
    if dist <= radius then
        return proj
    end
end

-- NUI: движение мыши
RegisterNUICallback('mouseMove', function(data, cb)
    screen.w, screen.h = data.w, data.h
    screen.x, screen.y = data.x / data.w, data.y / data.h

    if not mouseEnabled then
        hoveredTarget = nil
        return cb(1)
    end

    local camPos, camTo = getMouseRay()
    local camDir = (camTo - camPos); if #camDir > 0 then camDir = camDir / #camDir end

    hoveredTarget = nil
    local closest = Config.MouseRayDistance

    for id, target in pairs(targets) do
        if not target.entity or DoesEntityExist(target.entity) then
            local pos = getTargetPosition(target)
            if pos then
                local proj = isPointOnRay(pos, camPos, camDir, target.radius)
                if proj and proj < closest then
                    closest = proj
                    hoveredTarget = target
                    hoveredTarget.pos = pos
                end
            end
        end
    end

    cb(1)
end)

-- NUI: клик
RegisterNUICallback('mouseClick', function(_, cb)
    if hoveredTarget then
        local ctxId = 'target_' .. hoveredTarget.id
        lib.registerContext({ id = ctxId, title = hoveredTarget.label or 'Интеракция', options = hoveredTarget.options or {} })
        lib.showContext(ctxId)
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

-- отрисовка всех точек + отладка луча мышки
CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for id, target in pairs(targets) do
            local pos = getTargetPosition(target)
            if pos and #(playerCoords - pos) <= Config.PointDrawDistance then
                DrawMarker(28, pos.x, pos.y, pos.z + 0.05, 0,0,0, 0,0,0,
                    Config.PointMarkerScale, Config.PointMarkerScale, Config.PointMarkerScale,
                    0,200,255,180, false, false, 2, false, nil, nil, false)
                if target.label then
                    drawText3D(pos, target.label, 0.35, 255,255,255,220)
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

-- автоматическая регистрация точек на транспорте
local function registerVehicleTargets(veh)
    vehicleTargets[veh] = {}
    for name, point in pairs(Config.VehicleInteractPoints) do
        local id = addTarget({
            type = 'bone',
            entity = veh,
            offset = point.offset,
            bone = point.bone,
            label = point.label,
            radius = Config.DefaultTargetRadius,
            options = {
                {
                    title = 'Открыть '..point.label,
                    onSelect = function() SetVehicleDoorOpen(veh, point.doorIndex, false, false) end
                },
                {
                    title = 'Закрыть '..point.label,
                    onSelect = function() SetVehicleDoorShut(veh, point.doorIndex, false) end
                }
            }
        })
        vehicleTargets[veh][#vehicleTargets[veh]+1] = id
    end
end

CreateThread(function()
    while true do
        Wait(1000)
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) and not vehicleTargets[veh] then
                registerVehicleTargets(veh)
            end
        end
        for veh, ids in pairs(vehicleTargets) do
            if not DoesEntityExist(veh) then
                for _, id in ipairs(ids) do targets[id] = nil end
                vehicleTargets[veh] = nil
            end
        end
    end
end)
