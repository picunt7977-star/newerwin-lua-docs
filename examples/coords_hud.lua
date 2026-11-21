-- coords_hud.lua
-- Перетаскиваемая панель: координаты, направление взгляда и FPS.
-- Позицию панели можно двигать мышью в редакторе HUD.

local showNether = settings.boolean("Координаты ада", true)
local showFps    = settings.boolean("FPS", true)
local textColor  = settings.color("Цвет текста", "#FFFFFFFF")
local accent     = settings.color("Акцент", "#FF7C8CFF")

local pos = drag.create("Координаты", 6, 40, 120, 30)

-- yaw Minecraft: 0 = юг (+Z), 90 = запад, 180 = север, -90 = восток
local function direction(yaw)
    local dirs = { "Юг", "Ю-З", "Запад", "С-З", "Север", "С-В", "Восток", "Ю-В" }
    local i = math.floor(((mathf.wrap_degrees(yaw) + 360 + 22.5) % 360) / 45) + 1
    return dirs[i]
end

event.on("render2d", function()
    if not player.exists() then return end

    local lines = {}
    local x, y, z = player.pos()
    lines[#lines + 1] = string.format("XYZ  %d  %d  %d", math.floor(x), math.floor(y), math.floor(z))

    if showNether.get() then
        local dim = world.dimension()
        if dim == "minecraft:overworld" then
            lines[#lines + 1] = string.format("Ад  %d  %d", math.floor(x / 8), math.floor(z / 8))
        elseif dim == "minecraft:the_nether" then
            lines[#lines + 1] = string.format("Верх  %d  %d", math.floor(x * 8), math.floor(z * 8))
        end
    end

    lines[#lines + 1] = "Взгляд  " .. direction(player.camera_yaw())
    if showFps.get() then
        lines[#lines + 1] = "FPS  " .. window.fps()
    end

    -- размер панели под самую длинную строку
    local w = 0
    for _, s in ipairs(lines) do
        w = math.max(w, render.text_width(s))
    end
    w = w + 14
    local h = #lines * 10 + 6
    pos.size(w, h)

    local px, py = pos.pos()
    render.panel(px, py, w, h)
    render.rect(px, py + 2, 2, h - 4, accent.get())
    for i, s in ipairs(lines) do
        render.text(s, px + 8, py + 4 + (i - 1) * 10, textColor.get())
    end
end)
