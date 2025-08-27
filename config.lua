Config = {}

-- Клавиша для включения курсора
Config.MouseInteractKey = 'LMENU'

-- Общие настройки отрисовки / проверки луча
Config.Debug = false             -- включи true для отладки (отрисовка лучей/точек)
Config.MouseRayDistance = 6.0    -- можно увеличить, если надо бить дальше

Config.PointDrawDistance = 10.0  -- расстояние, на котором точки видны
Config.PointMarkerScale = 0.15   -- размер маркера
Config.DefaultTargetRadius = 0.25 -- радиус попадания по точке, если не указан

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
