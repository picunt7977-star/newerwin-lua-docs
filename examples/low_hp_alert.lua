-- low_hp_alert.lua
-- Предупреждает звуком и надписью, когда здоровье падает ниже порога.

local threshold = settings.slider("Порог (сердца)", 4, 1, 10, 0.5)
local useSound  = settings.boolean("Звук", true)
local useTitle  = settings.boolean("Надпись на экране", true)
local cooldown  = settings.slider("Пауза между предупреждениями (с)", 3, 1, 15, 1)

local sw = time.stopwatch()
local warned = false

local function warn(hp)
    if useSound.get() then
        sound.play("minecraft:block.note_block.pling", 1, 0.6)
    end
    if useTitle.get() then
        chat.title("&cЛЕЧИСЬ!", string.format("&7%.1f ❤", hp / 2), 0, 25, 8)
    end
end

event.on("health_change", function(h)
    local limit = threshold.get() * 2 -- сердца -> единицы здоровья
    if h.new <= 0 then
        warned = false
        return
    end
    if h.new < limit and h.new < h.old then
        -- не чаще одного раза в N секунд
        if not warned or sw.passed(cooldown.get() * 1000) then
            warn(h.new)
            warned = true
            sw.reset()
        end
    elseif h.new >= limit then
        warned = false
    end
end)
