-- chat_watch.lua
-- Присылает уведомление, когда в чате встречается одно из слов.
-- Слова задаются через запятую. Регистр не важен, кириллица поддерживается.

local words   = settings.text("Слова (через запятую)", "аукцион,продам")
local doSound = settings.boolean("Звук", true)

local function splitWords()
    local list = {}
    for w in string.gmatch(words.get(), "[^,]+") do
        w = w:gsub("^%s+", ""):gsub("%s+$", "")
        if w ~= "" then list[#list + 1] = w end
    end
    return list
end

event.on("chat", function(text)
    for _, w in ipairs(splitWords()) do
        -- \Q...\E — искать слово буквально; флаги i+u — без учёта регистра для любой раскладки
        if regex.test(text, "\\Q" .. w .. "\\E", "iu") then
            client.notify.info("Чат: " .. text)
            if doSound.get() then
                sound.play("minecraft:entity.experience_orb.pickup", 1, 1.2)
            end
            return
        end
    end
end)
