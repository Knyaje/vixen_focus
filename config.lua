Config = {}

-- Клавиша для включения курсора
Config.MouseInteractKey = 'LMENU'

-- Какие кости проверять и какие действия доступны
Config.VehicleBones = {
    { bone = 'door_dside_f', doorIndex = 0, label = 'Передняя левая дверь' },
    { bone = 'door_pside_f', doorIndex = 1, label = 'Передняя правая дверь' },
    { bone = 'door_dside_r', doorIndex = 2, label = 'Задняя левая дверь' },
    { bone = 'door_pside_r', doorIndex = 3, label = 'Задняя правая дверь' },
    { bone = 'bonnet', doorIndex = 4, label = 'Капот' },
    { bone = 'boot', doorIndex = 5, label = 'Багажник' },
}

-- дописываем в Config
Config.Debug = false             -- включи true для отладки (отрисовка лучей/точек)
Config.UseCapsule = true         -- использовать StartShapeTestCapsule
Config.CapsuleRadius = 0.55      -- радиус капсулы (по умолчанию)
Config.MouseRayDistance = 6.0    -- можно увеличить, если надо бить дальше
Config.BoneHitTolerance = 1.2    -- допустимая дистанция от точки попадания до реальной кости
-- Фолбек-порог: насколько далеко вперед/back считать капот/багажник
Config.BoneBonnetDist = 1.2
Config.BoneSideThreshold = 1.4

Config.PointDrawDistance = 10.0 -- расстояние, на котором точки видны
Config.PointMarkerScale = 0.15  -- размер маркера

Config.VehicleInteractPoints = {
    ['bonnet'] = {
        label = 'Капот',
        offset = vector3(1.0, 0.0, 0.8),  -- вперед, центр, вверх
        doorIndex = 4
    },
    ['boot'] = {
        label = 'Багажник',
        offset = vector3(-1.0, 0.0, 0.8), -- назад, центр, вверх
        doorIndex = 5
    },
    ['door_fl'] = {
        label = 'Передняя левая дверь',
        offset = vector3(0.5, -0.8, 0.8),
        doorIndex = 0
    },
    ['door_fr'] = {
        label = 'Передняя правая дверь',
        offset = vector3(0.5, 0.8, 0.8),
        doorIndex = 1
    },
    ['door_rl'] = {
        label = 'Задняя левая дверь',
        offset = vector3(-0.5, -0.8, 0.8),
        doorIndex = 2
    },
    ['door_rr'] = {
        label = 'Задняя правая дверь',
        offset = vector3(-0.5, 0.8, 0.8),
        doorIndex = 3
    },
}
