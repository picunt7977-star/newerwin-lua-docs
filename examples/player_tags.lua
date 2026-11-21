-- player_tags.lua
-- Над игроками: ник, HP и расстояние. В мире — рамка вокруг игрока.

local range     = settings.slider("Дальность", 48, 8, 128, 1)
local showBox   = settings.boolean("Рамки в мире", true)
local boxStyle  = settings.mode("Стиль рамки", { "corners", "frame", "gradient" }, "corners")
local friendCol = settings.color("Цвет друзей", "#FF55FF55")
local enemyCol  = settings.color("Цвет остальных", "#FFFF5555")

local targets = {}

-- список игроков собираем раз в тик, а не каждый кадр
event.on("tick", function()
    targets = {}
    if not player.exists() then return end
    for _, p in ipairs(world.players()) do
        if not p.is_self and p.is_alive and p.distance <= range.get() then
            targets[#targets + 1] = p
        end
    end
end)

local function colorFor(p)
    return friends.is(p.name) and friendCol.get() or enemyCol.get()
end

-- позиция между прошлым и текущим тиком, чтобы метки не дёргались
local function lerpPos(p, td)
    return p.prev_x + (p.x - p.prev_x) * td,
           p.prev_y + (p.y - p.prev_y) * td,
           p.prev_z + (p.z - p.prev_z) * td
end

event.on("render3d", function(td)
    if not showBox.get() then return end
    for _, p in ipairs(targets) do
        local x, y, z = lerpPos(p, td)
        render3d.styled_box(x - 0.3, y, z - 0.3, x + 0.3, y + 1.8, z + 0.3, boxStyle.get(), colorFor(p))
    end
end)

event.on("render2d", function(td)
    for _, p in ipairs(targets) do
        local x, y, z = lerpPos(p, td)
        local sx, sy = render.to_screen(x, y + 2.1, z)
        if sx then
            local text = string.format("%s  %.1f HP  %dм", p.name, p.health, math.floor(p.distance))
            local w = render.text_width(text) + 8
            render.round_rect(sx - w / 2, sy - 6, w, 12, 3, "#A0000000")
            render.text_center(text, sx, sy - 3, colorFor(p))
        end
    end
end)

event.on("disable", function() targets = {} end)
