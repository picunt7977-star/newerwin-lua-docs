-- calc_command.lua
-- Команда .calc <выражение> — считает и пишет результат в чат (локально).
-- Пример: .calc (2+3)*4^2/7

commands.register("calc", function(args)
    local expr = table.concat(args, " ")
    if expr == "" then
        chat.print("&7Использование: &f.calc 2+2*3")
        return
    end
    -- пропускаем только цифры, пробелы, точку, скобки и операторы
    if not expr:match("^[%d%s%.%+%-%*/%%%^%(%)]+$") then
        chat.print("&cМожно использовать только числа и + - * / % ^ ( )")
        return
    end
    -- пустое окружение: выражение не видит никаких функций
    local fn = load("return " .. expr, "calc", "t", {})
    if not fn then
        chat.print("&cНе понял выражение: &f" .. expr)
        return
    end
    local ok, result = pcall(fn)
    if ok and type(result) == "number" then
        chat.print("&a" .. expr .. " &7= &f" .. mathf.fmt(result, 4):gsub("%.?0+$", ""))
    else
        chat.print("&cОшибка в выражении: &f" .. expr)
    end
end)
