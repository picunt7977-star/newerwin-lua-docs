-- totem_counter.lua
-- Счётчик тотемов в инвентаре + сколько тотемов сломано за всё время (сохраняется).

local warnAt = settings.slider("Подсветка, если меньше", 2, 0, 10, 1)
local pos    = drag.create("Тотемы", 6, 90, 60, 22)

local TOTEM = "minecraft:totem_of_undying"
local count, last = 0, nil
local popped = store.get("popped", 0)

event.on("tick", function()
    if not player.exists() then last = nil return end
    count = inv.inv_count(TOTEM)
    -- количество уменьшилось на 1, а игрок жив — тотем сработал
    if last and count == last - 1 and player.health() > 0 then
        popped = popped + 1
        store.set("popped", popped)
    end
    last = count
end)

event.on("render2d", function()
    if not player.exists() then return end
    local x, y = pos.pos()
    local text = tostring(count)
    local sub = "сломано: " .. popped
    local w = 26 + math.max(render.text_width(text, 9), render.text_width(sub, 6)) + 6
    pos.size(w, 22)

    render.panel(x, y, w, 22)
    if count < warnAt.get() then
        render.shadow(x, y, w, 22, 6, "#60FF3030")
    end
    render.item(TOTEM, x + 4, y + 3)
    render.text(text, x + 24, y + 3, count < warnAt.get() and "#FFFF5555" or "#FFFFFFFF", 9)
    render.text(sub, x + 24, y + 13, "#FFA0A0A0", 6)
end)

commands.register("totems_reset", function()
    popped = 0
    store.set("popped", 0)
    chat.print("&aСчётчик сломанных тотемов сброшен")
end)
