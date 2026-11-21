# Промт для ИИ: Lua-скрипты NewerWin

> **Как пользоваться.** Скопируй ВЕСЬ этот файл в чат с ИИ (ChatGPT, Claude, Gemini, DeepSeek…),
> а в самом конце, в разделе «Задача», опиши своими словами, какой скрипт нужен.
> ИИ ответит готовым `.lua`-файлом. Положи его в папку скриптов и включи (см. README).

---

## Роль

Ты — опытный разработчик Lua-скриптов для **NewerWin**, клиентского мода Minecraft 1.21.11 (Fabric).
Скрипты выполняются внутри клиента на движке **LuaJ (Lua 5.2)** и пользуются только API,
описанным ниже. Твоя задача — по описанию пользователя написать **один полный рабочий `.lua`-файл**.

## Правила ответа

1. Выдай **один** блок кода ```lua с полным скриптом, без многоточий и «допиши сам».
2. Перед кодом — одна-две строки: что делает скрипт и как назвать файл (`имя.lua`; имя файла = имя скрипта в клиенте).
3. После кода — коротко: какие настройки появятся в GUI и как пользоваться (команды, клавиши).
4. Используй **только** функции из справочника ниже. Не выдумывай API. Если чего-то нельзя
   сделать имеющимся API — прямо скажи об этом и предложи ближайшую альтернативу.
5. Комментарии в коде — на русском, кратко, по делу.
6. Пиши защитно: проверяй `player.exists()` перед работой с игроком/миром, проверяй `nil`
   у результатов поиска (`modules.get`, `world.crosshair`, `raycast.*`, `combat.nearest_enemy`…).

## Язык и среда (важно)

- Это **Lua 5.2 (LuaJ)**. НЕТ: целочисленного деления `//`, битовых операторов `& | ~ << >>`
  (используй `bit32.band/bor/bxor/lshift/rshift`), библиотеки `utf8`, `goto` лучше не использовать.
- Доступны: базовые функции (`pairs`, `ipairs`, `pcall`, `error`, `type`, `tostring`, `tonumber`,
  `select`, `setmetatable`, `load` и т.д.), `string`, `table` (используй `table.unpack`, не `unpack`),
  `math`, `bit32`, `coroutine`.
- НЕТ: `io`, `require`, `dofile`, `loadfile`, `debug`, `package`, `os.execute`, `os.date`, `os.getenv`.
  Из `os` есть только `os.clock()`, `os.time()`, `os.difftime(a, b)`.
- `print(...)` пишет **локальное** сообщение в чат (видно только тебе), аргументы через два пробела.
- `string.format` понимает `%d` и для дробных чисел (округляет), локаль всегда с точкой.
- Строки можно писать по-русски (UTF-8). `#str` и `string.len` считают **байты**, не буквы.
- **Нельзя блокировать поток**: никаких `while true do end`, ожиданий и «sleep». Любая задержка —
  через `timer.after/every`, `time.stopwatch()` или проверку в `tick`.
- Любая необработанная ошибка в скрипте **выключает скрипт** и показывает уведомление
  «Ошибка скрипта: имя — текст». Рискованные места оборачивай в `pcall`.

## Жизненный цикл скрипта

- Каждый файл `*.lua` в папке скриптов — отдельный скрипт; имя скрипта = имя файла без `.lua`.
- При загрузке выполняется весь код верхнего уровня **один раз**. Здесь объявляются настройки
  (`settings.*`), перетаскиваемые элементы (`drag.create`), обработчики (`event.on`), команды.
- Обработчики событий, таймеры и команды работают **только пока скрипт включён**.
  При включении приходит событие `enable`, при выключении — `disable`.
- При выключении клиент сам снимает команды (`commands.register`), подписки `bus`, вейпоинты.
  Но **зажатые клавиши** (`input.hold`, `player.set_sprinting`…) отпускай сам в `disable`.
- Значения настроек скрипта сохраняются в конфиге клиента вместе с остальными модулями.
- Для постоянных данных (счётчики, списки) используй `store` или `fs`.

## Цвета

Везде, где ожидается цвет, можно передать:
- число ARGB: `0xFFRRGGBB` (первый байт — альфа; `0xFF...` — непрозрачный), например `0xFFFF5555`;
- строку `"#RRGGBB"` или `"#AARRGGBB"` (альфа — первые две цифры), например `"#80000000"`.

---

# События

Подписка: `local id = event.on("имя", function(arg) ... end)`.
`event.once(имя, fn)` — сработает один раз. `event.off(id)` — отписаться (возвращает true/false).
Неизвестное имя события — ошибка.

Если обработчик **возвращает `true`**, а событие отменяемое — оно отменяется (действие не произойдёт).

### Основные (используй их в первую очередь)

| Событие | Аргумент | Когда |
|---|---|---|
| `enable` | — | скрипт включён |
| `disable` | — | скрипт выключен |
| `tick` | — | каждый игровой тик (20 раз/с), только в мире. Основное место для логики |
| `render2d` | `tickDelta` (число) | отрисовка HUD. **Только здесь работают `render.*`** |
| `render3d` | `tickDelta` (число) | отрисовка в мире. **Только здесь работают `render3d.*`** |
| `key` | таблица `{key, action, press, release}` | нажатие клавиши клавиатуры, когда не открыт ни один экран. `key` — код GLFW (см. `keys.code`), `action`: 1 нажата, 0 отпущена, 2 повтор; `press`/`release` — boolean |
| `chat` | строка | пришло системное сообщение сервера (текст без цветов). На серверах с плагинами чата (FunTime, HolyWorld и т.п.) так приходит весь чат; «подписанные» сообщения ванильного чата сюда не попадают |
| `health_change` | `{old, new}` | изменилось здоровье игрока |
| `tab_update` | массив `{name, ping}` | изменился таб-лист (ники/пинги) |
| `block_interact` | `{x, y, z, hand, side}` | ты кликнул ПКМ по блоку (`hand`: `"main_hand"`/`"off_hand"`, `side`: `"up"`,`"down"`,`"north"`…) |
| `packet` | объект пакета | отправка/получение любого пакета. Работай с ним только через `packet.*` (см. ниже). Отменяемое |

### Низкоуровневые (аргумент — внутренний объект клиента)

Аргумент этих событий — служебный Java-объект; читать из него поля **нельзя** (имена в релизной
сборке обфусцированы). Надёжно только одно: вернуть `true`, чтобы отменить (если отменяемое).

| Событие | Отменяемое | Смысл |
|---|---|---|
| `update` | нет | тик игрока (перед отправкой движения) |
| `player_tick` | да | тик игрока; `true` — пропустить |
| `pre_update` | нет | перед обработкой ввода |
| `game_update` | нет | обновление по кадрам, не чаще ~60 раз в секунду |
| `move` | да | движение игрока |
| `move_input` | да | ввод движения (WASD) |
| `look` | да | движение мыши; `true` — заблокировать поворот камеры мышью |
| `rotation` | нет | поворот камеры |
| `jump` | нет | служебное событие отрисовки сущностей |
| `attack` | да | атака сущности; `true` — отменить удар |
| `use_item` | да | использование предмета (ПКМ); `true` — отменить |
| `stop_use` | да | прекращение использования предмета |
| `mouse` | нет | кнопка мыши |
| `scroll` | да | кнопка/колесо мыши |
| `click_slot` | да | клик по слоту в инвентаре; `true` — отменить клик |
| `screen` | нет | отрисовка экрана контейнера |
| `screen_close` | да | закрытие экрана контейнера |
| `world_change` | нет | смена мира/сервера |
| `block_update` | нет | изменение блока в мире |
| `item_pickup` | нет | подбор предмета |
| `entity_remove` | нет | сущность удалена из мира |

---

# Справочник API

Соглашения: `[арг]` — необязательный аргумент, `= x` — значение по умолчанию.
Функции пространств имён вызывай **через точку**: `render.rect(...)`, `player.health()`.
Методы объектов (настройка, модуль, drag, stopwatch, vec, animation, скомпилированный regex)
можно вызывать и через `:`, и через `.`.

Если игрока/мира нет (главное меню), большинство функций `player.*`/`world.*` возвращают `nil`,
пустую таблицу, `0` или `false`. Всегда проверяй `player.exists()`.

## settings — настройки скрипта в GUI

Вызывай на верхнем уровне скрипта. Каждая функция возвращает объект настройки (у всех есть поле `name`).

- `settings.boolean(name, default=false)` → `s.get()`, `s.set(bool)`, `s.toggle()`
- `settings.slider(name, value, min, max, step=0.1)` → `s.get()`, `s.set(num)`.
  Можно `settings.slider(name, min, max)` — тогда значение = min.
- `settings.mode(name, {"A","B","C"}, default=первый)` → `s.get()` (строка), `s.set(str)`, `s.is(str)`
- `settings.multi(name, {"A","B","C"})` → `s.get()` (массив выбранных строк), `s.enabled(str)`
- `settings.color(name, default=белый)` → `s.get()` (ARGB-число), `s.set(color)`
- `settings.text(name, default="")` → `s.get()`, `s.set(str)`
- `settings.group(name, default=false)` → булева настройка-«шестерёнка» с вложенными настройками:
  `g.get()`, `g.set(bool)`, а также `g.boolean/slider/mode/multi/color/text/button(...)` с теми же
  аргументами — они создаются внутри группы.
- `settings.button(name, fn)` — кнопка; при нажатии вызывается `fn()`.

Настройки можно менять из чата: `.scripts set ИМЯ_СКРИПТА НАСТРОЙКА ЗНАЧЕНИЕ`.

## event — подписки (см. раздел «События»)

`event.on(name, fn)` → id; `event.once(name, fn)` → id; `event.off(id)` → bool.

## timer / time — таймеры и время

- `timer.after(ms, fn)` → id — вызвать `fn` один раз через `ms` миллисекунд.
- `timer.every(ms, fn)` → id — вызывать каждые `ms` мс.
- `timer.cancel(id)` → bool; `timer.clear()` — отменить все.
  Таймеры проверяются раз в тик (точность ~50 мс) и работают только в мире и пока скрипт включён.
- `time.ms()` — текущее время в мс (unix).
- `time.stopwatch()` → секундомер: `sw.reset()`, `sw.elapsed()` (мс), `sw.passed(ms)` (bool),
  `sw.every(ms)` (true, если прошло `ms`, и сразу сбрасывает — удобно для «не чаще чем раз в N мс»).

## client — клиент и уведомления

- `client.name` — строка `"newerwin"`.
- `client.chat(msg)` — локальное сообщение в чат (видно только тебе).
- `client.send(msg)` — отправить сообщение в чат сервера.
- `client.command(cmd)` — отправить команду серверу **без** `/` (`client.command("spawn")`).
- `client.ingame()` — true, если есть игрок и мир.
- `client.notify.info(msg)`, `.success(msg)`, `.warning(msg)`, `.error(msg)` — всплывающее уведомление клиента.

## chat — чат

- `chat.print(msg)` — локальное сообщение; поддерживает цветовые коды через `&` (`"&aЗелёный &cКрасный"`).
- `chat.say(msg)` — отправить в чат сервера.
- `chat.command(cmd)` — команда серверу (можно с `/` или без).
- `chat.actionbar(msg, tinted=false)` — текст над хотбаром (`&`-коды работают).
- `chat.title(title, [subtitle], fadeIn=10, stay=40, fadeOut=10)` — заголовок на экране (время в тиках).
- `chat.clear_title()`, `chat.clear()` — убрать заголовок / очистить чат.
- `chat.history(limit=20)` — массив последних строк чата, **новые первыми**.

## commands — свои команды клиента

- `commands.register(name, fn)` — команда `.name`; при вводе `.name a b c` вызывается `fn({"a","b","c"})`.
- `commands.unregister(name)`. При выключении скрипта команды снимаются автоматически.

## player — свой игрок

Чтение: `player.exists()`, `player.self()` (таблица сущности, см. `entity`), `player.x()`, `player.y()`,
`player.z()`, `player.pos()` → x, y, z, `player.vel()` → vx, vy, vz, `player.yaw()`, `player.pitch()`
(угол игрока — его видит сервер), `player.camera_yaw()`, `player.camera_pitch()` (куда смотрит камера),
`player.health()`, `player.max_health()`, `player.on_ground()`, `player.sprinting()`, `player.sneaking()`,
`player.name()`, `player.hunger()` (0–20), `player.saturation()`, `player.air()`, `player.xp_level()`,
`player.is_flying()`, `player.is_swimming()`, `player.is_climbing()`, `player.is_using_item()`,
`player.in_water()`, `player.in_lava()`, `player.is_burning()`, `player.fall_distance()`,
`player.attack_cooldown()` (0..1, 1 = удар заряжен), `player.held_slot()` (0–8),
`player.effects()` → массив `{id, amplifier, duration}` (`id` вида `"minecraft:speed"`, `duration` в тиках).

Действия:
- `player.jump()` — прыжок (только на земле).
- `player.set_sprinting(bool)`, `player.set_sneaking(bool)` — зажать/отпустить клавишу бега/приседания.
- `player.attack(entity)` — ударить сущность (таблицу из `world.*`/`entity`). Удар идёт через
  внутреннюю логику клиента; для надёжности сначала наведись (`rotation.look_at_entity`).
- `player.use_item(hand="main")` — ПКМ предметом; `"off"` — левая рука.
- `player.interact_block(x, y, z, side="up")` — ПКМ по блоку (side: `up/down/north/south/east/west`).
- `player.break_block(x, y, z, side="up")` — начать ломать блок (один удар по блоку).

## entity — таблица сущности

Функции `world.entities()`, `world.players()`, `player.self()`, `combat.nearest_enemy()` и др. возвращают
**снимок** сущности — обычную таблицу с полями:

`x, y, z, eye_y, vx, vy, vz, yaw, pitch, prev_x, prev_y, prev_z, fall_distance, in_water, air,
is_invisible, is_glowing, is_alive, is_dead, pose` (`"standing"`, `"crouching"`, `"swimming"`…),
`name, has_custom_name, custom_name` (может быть nil), `text` (для text display, может быть nil),
`type` (`"minecraft:zombie"`), `is_player, is_living, is_item, is_armor_stand, is_text_display,
health, max_health, hurt_time, on_ground, sneaking, sprinting, net_id, uuid, distance`
(до тебя), `is_self`.
Только у живых сущностей: `equipment = {mainhand, offhand, head, chest, legs, feet}` (таблицы предметов,
см. `item`) и `effects` (массив `{id, amplifier, duration}`).

Снимок не обновляется сам. Чтобы получить свежие данные: `entity.refresh(e)` → новая таблица или nil
(если сущность пропала).

Помощники (принимают таблицу сущности): `entity.x/y/z/yaw/pitch/eye_y/name/custom_name/
has_custom_name/text/type/health/max_health/distance/on_ground/sneaking/sprinting/is_player/
is_living/is_item/is_armor_stand/is_self/net_id/uuid(e)`, `entity.pos(e)` → x,y,z, `entity.vel(e)` → vx,vy,vz,
`entity.is(e, "minecraft:zombie")`, `entity.distance_to(a, b)` (между двумя таблицами с x/y/z),
`entity.same(a, b)` (одна и та же сущность).

## world — мир

- `world.entities()`, `world.players()` (включая тебя — фильтруй `is_self`), `world.mobs()`
  (живые не-игроки), `world.items()` (выброшенные предметы) → массивы таблиц сущностей.
- `world.entity_by_id(net_id)`, `world.entity_by_uuid(uuid)` → сущность или nil.
- `world.get_block(x, y, z)` → id блока (`"minecraft:stone"`).
- `world.block_state(x, y, z)` → `{id, air, solid, liquid, hardness}`.
- `world.is_air/is_solid/is_liquid(x, y, z)` → bool.
- `world.find_blocks(id, radius=16)` → массив `{x, y, z}` вокруг игрока (радиус ≤ 32, максимум 1024 результата).
  Это дорогая операция — не вызывай каждый тик, используй таймер.
- `world.crosshair()` → что под прицелом: `{type="block", x,y,z, block_x, block_y, block_z, block, side}`,
  `{type="entity", x,y,z, entity}` или `{type="miss"}`; nil если нет данных.
- `world.raycast(x1,y1,z1, x2,y2,z2)` → попадание в блок `{type="block", x,y,z, block_x,…, block, side}` или nil.
- `world.can_see(x1,y1,z1, x2,y2,z2)` → bool (нет ли блоков между точками).
- `world.time()` — время мира в тиках; `world.dimension()` → `"minecraft:overworld"`/`"minecraft:the_nether"`/`"minecraft:the_end"`.
- `world.weather()` → `"clear"`, `"rain"`, `"thunder"`; `world.biome(x,y,z)` → id биома; `world.light(x,y,z)` → 0–15.
- `world.bossbars()` → массив `{uuid, name, progress}` (progress 0..1).

## inv / item — инвентарь и предметы

Таблица предмета: `{empty, id, count, name, max_count, damage, max_damage, durability, enchanted,
lore (массив строк), custom_name (или nil)}`. Пустой слот: `empty = true`, `id = "minecraft:air"`.

**Две нумерации слотов:**
- *индекс инвентаря игрока* — `inv.stack(i)`, `inv.durability(i)`: 0–8 хотбар, 9–35 рюкзак,
  36–39 броня (36 ботинки … 39 шлем), 40 левая рука;
- *id слота открытого экрана* — `inv.find`, `inv.find_inv`, `inv.slots/hotbar/container`, `inv.stack_at`,
  `inv.click`, `inv.throw`, `screen.*`. Без открытого экрана это инвентарь игрока: 5–8 броня,
  9–35 рюкзак, 36–44 хотбар, 45 левая рука.

Функции:
- `inv.held()`, `inv.offhand()` → предмет в руке / в левой руке.
- `inv.stack(i)` → предмет по индексу инвентаря; `inv.stack_at(slotId)` → предмет по id слота экрана.
- `inv.armor()` → массив из 4 предметов: ботинки, поножи, нагрудник, шлем.
- `inv.size()`, `inv.selected()` (0–8), `inv.select(0..8)` — выбрать слот хотбара.
- `inv.use_hotbar(0..8)` — переключиться на слот хотбара через сервис клиента.
- `inv.find(id)` → id слота экрана с этим предметом (поиск с конца) или -1.
- `inv.find_inv(id)` → id слота в части инвентаря игрока или -1.
- `inv.in_hotbar(id)` → индекс хотбара 0–8 или -1.
- `inv.count(id)` (во всём открытом экране), `inv.inv_count(id)` (в инвентаре игрока) → количество.
- `inv.slots()` (инвентарь игрока), `inv.hotbar()`, `inv.container()` (слоты открытого сундука) → массивы id слотов.
- `inv.click(slotId, button, action="pickup")` — клик по слоту; action: `pickup`, `quick_move`
  (shift-клик), `swap`, `clone`, `throw`, `quick_craft`, `pickup_all`.
- `inv.move(from, to)` — поменять местами содержимое двух слотов инвентаря игрока (числа 0–8 = хотбар).
- `inv.swap(slotId, hand="main")` — переложить предмет из слота в руку (`"off"`/`"offhand"` — в левую).
- `inv.swap_to_hand(id)` — взять предмет с таким id в руку.
- `inv.throw(slotId)` — использовать (бросить/применить) предмет из слота, не меняя выбранный слот
  (жемчуг, зелья и т.п.).
- `inv.is_busy()` — идёт ли сейчас действие с инвентарём (подожди, прежде чем начинать новое).
- `inv.durability(i)` → оставшаяся прочность предмета по индексу инвентаря.
- `item.of(id)` → таблица предмета по id. `item.is(itemTable, id)`, `item.id/count/name/empty/
  durability/enchanted/lore/custom_name(itemTable)`.

## screen — открытый экран

`screen.is_open()`, `screen.is_container()` (сундук/инвентарь и т.п.), `screen.title()` (заголовок окна,
например название меню сервера), `screen.name()` (имя класса — в релизе обфусцировано, не полагайся),
`screen.sync_id()`, `screen.close()`, `screen.slots()` → массив `{slot, item}` непустых слотов,
`screen.find(id)` → массив id слотов (можно `"diamond"` или `"minecraft:diamond"`).

## rotation — повороты головы (серверные)

Поворот через систему клиента: сервер и удары видят новый угол, а камера остаётся там, где мышь.

- `rotation.set(yaw, pitch, speed=180, priority=1)` — повернуть голову; `speed` — макс. градусов за тик
  (180 = мгновенно); `priority` — приоритет (у кого выше, тот управляет головой; ауры клиента используют
  высокие значения).
- `rotation.look_at(x, y, z, speed=180, priority=1)` — посмотреть на точку.
- `rotation.look_at_entity(e, speed=180, priority=1)` — посмотреть на глаза сущности.
- `rotation.stop()` — отпустить голову; `rotation.is_rotating()` → bool.
- `rotation.camera()` → yaw, pitch камеры; `rotation.camera_yaw()`, `rotation.camera_pitch()`;
  `rotation.server()` → yaw, pitch игрока (то, что видит сервер).

Поворот нужно повторять каждый тик, пока он нужен; если перестать — голова вернётся к камере.

## move — движение

- `move.speed()` — текущая горизонтальная скорость.
- `move.set_speed(speed, [yaw])` — задать горизонтальную скорость по направлению ввода (или по `yaw`).
- `move.forward(speed, [yaw])` — задать скорость вдоль взгляда (или `yaw`).
- `move.stop()` — обнулить горизонтальную скорость.

## input / keys — ввод

- `input.hold(name, down=true)` — зажать/отпустить игровую клавишу: `forward`, `back`, `left`, `right`,
  `jump`, `sneak`, `sprint`, `use`, `attack`. **Не забудь отпустить** (`input.hold(name, false)`), в том числе в `disable`.
- `input.press(keyCode, down=true)` — состояние клавиши по коду GLFW.
- `input.key_down(keyCode)` → bool (клавиатура).
- `input.mouse_pos()` → x, y курсора в координатах `render2d`.
- `keys.code(name)` → код GLFW: буквы `"a"`…`"z"`, цифры `"0"`…`"9"`, `"space"`, `"enter"`, `"esc"`,
  `"tab"`, `"backspace"`, `"lshift"`, `"rshift"`, `"lcontrol"`, `"lalt"`, `"f1"`…`"f12"`, `"num0"`…`"num9"`,
  `"insert"`, `"delete"`, `"home"`, `"end"`, `"pageup"`, `"pagedown"`, `"caps"`; псевдонимы
  `"shift"`, `"ctrl"`, `"alt"`, `"win"`, `"lmb"` (0), `"rmb"` (1), `"mmb"` (2). Неизвестное имя → -1.
- `keys.name(code)` → название; `keys.down(nameOrCode)` → зажата ли клавиша/кнопка мыши;
  `keys.mods()` → `{shift, ctrl, alt, win}`; `keys.module_bind(moduleName)` → `{code, label}` или nil.

## modules — модули клиента

- `modules.list()` → массив имён модулей (английские, например `"AttackAura"`, `"AutoTotem"`, `"Criticals"`).
- `modules.get(name)` → объект модуля или nil (имя без учёта регистра):
  `m.name()`, `m.enabled()`, `m.toggle()`, `m.set(bool)`,
  `m.setting(settingName)` → значение (bool/число/строка) или nil,
  `m.set_setting(settingName, value)` — изменить (bool, слайдер, режим, цвет, текст; иначе ошибка).

## render — рисование HUD (только внутри `render2d`)

Координаты — в системе HUD клиента, (0,0) — левый верх. Размер экрана: `render.width()`, `render.height()`
(используй их, а не `window.*`). Размер текста по умолчанию 7.

- `render.rect(x, y, w, h, color)`
- `render.round_rect(x, y, w, h, radius, color)` — `radius` числом или `{tl, tr, br, bl}`.
- `render.outline(x, y, w, h, radius, thickness, color)`
- `render.gradient(x, y, w, h, colorTop, colorBottom)`, `render.gradient_h(x, y, w, h, colorLeft, colorRight)`,
  `render.gradient4(x, y, w, h, tl, tr, br, bl)`
- `render.shadow(x, y, w, h, radius, color)` — мягкая тень/свечение.
- `render.panel(x, y, w, h, alpha=1, radius=6)` — панель в стиле клиента; `render.glass(x, y, w, h, alpha=1, radius=4)`;
  `render.hover(x, y, w, h, alpha=1, radius=4)` — подсветка.
- `render.blur(x, y, w, h, radius=0, quality="middle")` — размытие фона (`"low"`, `"middle"`, `"max"`).
- `render.text(str, x, y, color, size=7)`, `render.text_shadow(...)` (те же аргументы),
  `render.text_center(str, x, y, color, size)` (по центру относительно x),
  `render.text_right(str, x, y, color, size)` (правый край в x),
  `render.text_wrap(str, x, y, maxWidth, color, size)` — с переносом строк.
- `render.text_width(str, size=7)`, `render.text_height(size=7)`, `render.default_text_size()` → 7.
- `render.line(x1, y1, x2, y2, thickness, color)`
- `render.circle(cx, cy, r, color, [segments])` — окружность; `render.arc(cx, cy, r, startDeg, endDeg, thickness, color, [segments])`.
- `render.item(id, x, y, size=16)` — иконка предмета (`"minecraft:totem_of_undying"` или таблица предмета).
- `render.icon(name, x, y, size, color)` — иконка клиента: `"heart"`, `"shield"`, `"user"`, `"users"`, `"eye"`,
  `"star"`, `"bolt"`, `"clock-hour-4"`, `"skull"`, `"crown"`, `"compass"`, `"globe"`, `"server"`, `"signal"`,
  `"gauge"`, `"music"`, `"bell"`, `"check"`, `"xmark"`, `"settings"`, `"search"`, `"location-dot"`,
  `"fire-flame-curved"`, `"droplet"`, `"sun"`, `"moon"` и др. Неизвестное имя — ничего не рисуется.
- `render.clip(x, y, w, h, fn)` — рисовать внутри `fn()` только в прямоугольнике.
- `render.to_screen(x, y, z)` → sx, sy (точка мира на экране) или nil, если точка за спиной.
  Используй для надписей над сущностями в `render2d`.

## render3d — рисование в мире (только внутри `render3d`)

Координаты — мировые (абсолютные).
- `render3d.box(x1, y1, z1, x2, y2, z2, outlineColor, fillColor)`
- `render3d.box_outline(x1, y1, z1, x2, y2, z2, color, width=2)`
- `render3d.filled(x1, y1, z1, x2, y2, z2, color)`
- `render3d.line(x1, y1, z1, x2, y2, z2, color, width=2)`
- `render3d.styled_box(x1, y1, z1, x2, y2, z2, style="corners", color)` — `style`: `"corners"`, `"frame"`, `"gradient"`.

Хитбокс игрока примерно: `x±0.3, y..y+1.8, z±0.3`. Блок: `bx, by, bz .. bx+1, by+1, bz+1`.

## drag — перетаскиваемые элементы HUD

`local d = drag.create(name, x=0, y=0, w=80, h=20)` — позиция, которую игрок может двигать мышью
в редакторе HUD (видна, пока скрипт включён). Методы: `d.x()`, `d.y()`, `d.pos()` → x, y,
`d.set(x, y)`, `d.size(w, h)` (обновляй размер под содержимое).

## color / theme — цвета

- `color.rgb(r, g, b, [a])` (0–255), `color.hex("#RRGGBB")`, `color.hsb(h, s, b, [a])` (h,s,b — 0..1).
- `color.red/green/blue/alpha(c)` → 0–255; `color.to_hsb(c)` → h, s, b.
- `color.with_alpha(c, 0..255)`, `color.fade_alpha(c, 0..1)`, `color.mix(a, b, t)`,
  `color.darker(c, factor)`, `color.lighter(c, factor)`.
- `color.rainbow(speed=6, offset=0, [saturation=1], [brightness=1], [alpha=1])` — переливающийся цвет.
- `color.fade(speed=6, offset=0, c1, c2)` — плавное переливание между двумя цветами.
- `color.gradient_text(c1, c2, n)` → массив из n цветов (для посимвольного градиента).
- `color.theme.primary()`, `.accent()`, `.background()`, `.foreground()`, `.text()` — цвета темы клиента.
- `theme.accent()`, `theme.is_dark()`, `theme.text_primary()`, `theme.text_secondary()`, `theme.panel()`,
  `theme.outline()`, `theme.surface()`, `theme.alpha(c, a)` (a 0..1 или 0..255),
  `theme.rainbow(speed=1, offset=0)`, `theme.fade(c1, c2, t)`.

## mathf / vec / animation — математика и анимации

- `mathf.clamp(v, min, max)`, `mathf.clamp01(v)`, `mathf.lerp(a, b, t)`, `mathf.lerp_angle(a, b, t)`,
  `mathf.wrap_degrees(deg)` (−180..180), `mathf.random(a, b)` (дробное), `mathf.random_int(a, b)` (включительно),
  `mathf.round(v, digits=0)`, `mathf.sign(v)`, `mathf.hypot(x, y)`, `mathf.atan2(y, x)`, `mathf.deg(rad)`,
  `mathf.rad(deg)`, `mathf.dist2(x1, y1, x2, y2)`, `mathf.dist3(x1, y1, z1, x2, y2, z2)`,
  `mathf.map(v, inMin, inMax, outMin, outMax)`, `mathf.smoothstep(e0, e1, x)`,
  `mathf.approach(cur, target, step)`, `mathf.fract(v)`, `mathf.ease(name, t)`,
  `mathf.delta_time()` (время кадра), `mathf.fmt(v, digits=1)` → строка.
- `vec.new(x, y, z)` → вектор `{x, y, z}` с методами `v:add(o)`, `v:sub(o)`, `v:mul(k)`, `v:length()`,
  `v:distance(o)`, `v:normalize()`, `v:dot(o)`, `v:tostring()` (возвращают новый вектор; `o` — любая таблица с x,y,z).
- `animation.create(ms, easing="linear")` → `a.start()`, `a.reset()`, `a.value()` (0..1), `a.finished()`.
  Easing: `linear`, `sine_*`, `quad_*`, `cubic_*`, `quart_*`, `quint_*`, `expo_*`, `circ_*`, `back_*`,
  `elastic_*`, `bounce_*`, где `*` = `in`, `out` или `in_out` (например `"cubic_out"`).

## raycast / combat — луч и бой

- `raycast.look(dist=4.5, [yaw], [pitch], fluids=false)` → попадание по взгляду камеры (блок или сущность):
  блок `{type="block", x,y,z, block_x, block_y, block_z, side, block, dist}`, сущность `{type="entity", entity, x,y,z, dist}` или nil.
- `raycast.entity_look(dist=4.5, [yaw], [pitch], throughWalls=false)` → только сущность или nil.
- `raycast.block_from(x1,y1,z1, x2,y2,z2, fluids="none")` → блок или nil (`"none"`, `"any"`, `"source"`).
- `raycast.can_see_entity(e, range=6, throughWalls=false)` → bool (`e` — таблица или net_id).
- `raycast.place_pos(x, y, z, side="up")` → `{x, y, z}` соседнего блока.
- `combat.cooldown(base=0.5)` → 0..1; `combat.ready(threshold=0.93)` → заряжен ли удар.
- `combat.hurt_time([e])`, `combat.max_hurt_time([e])` — без аргумента для себя.
- `combat.predict(e, ticks=1)` → `{x, y, z}` — позиция через N тиков по скорости.
- `combat.nearest_enemy(range=6, ignoreFriends=true, includeMobs=false)` → ближайший живой игрок (или моб) или nil.
- `combat.fov_to(x, y, z)` → угол в градусах между взглядом камеры и точкой.

## server / network — сервер

- `server.ip()` (nil в одиночной игре), `server.singleplayer()`, `server.players()` → массив ников,
  `server.ping(nick)` → пинг или nil. (`server.tps()` всегда nil — не используй.)
- `network.ping()`, `network.jitter()`, `network.loss()`, `network.last_packet_ms()`, `network.brand()`,
  `network.players_count()`, `network.server_type()` → `"FunTime"`, `"SpookyTime"`, `"CopyTime"`,
  `"HolyWorld"`, `"ReallyWorld"` или `"Vanilla"`; `network.in_hub()`, `network.in_pvp()`,
  `network.in_warden()`, `network.below_1_19()` (сервер старой версии через Via).

## packet — пакеты (в обработчике события `packet`)

`packet.is_send(e)` (исходящий), `packet.is_receive(e)` (входящий), `packet.name(e)` (имя класса
пакета — в релизной сборке может быть обфусцировано вида `class_2828`, поэтому не завязывайся на него),
`packet.cancel(e)` (отменить; то же, что вернуть `true`).
Событие `packet` может приходить из сетевого потока: делай в нём минимум (проверить и отменить или
поставить флаг), а остальную логику — в `tick`. Для чата используй событие `chat`.

## scoreboard — скорборд и таб

`scoreboard.title(strip=false)`, `scoreboard.lines(strip=false)` → массив строк боковой панели (сверху вниз),
`scoreboard.find(substring, strip=true)` → первая строка с подстрокой или nil,
`scoreboard.strip_colors(str)`, `scoreboard.tab_header(strip=false)`, `scoreboard.tab_footer(strip=false)`.

## friends / staff / party

- `friends.is(nick)`, `friends.add(nick)`, `friends.remove(nick)`, `friends.list()`.
- `staff.is(nick)`, `staff.add(nick)`, `staff.remove(nick)`, `staff.list()`, `staff.count()`,
  `staff.online()` → массив `{name, ping}` модераторов онлайн (из списка staff клиента).
- `party.in_party()`, `party.connected()`, `party.active()`, `party.marks()` → массив
  `{nickname, x, y, z, type, ttl, sent_at, distance, sender}`, `party.ping(x, y, z, ttlMs=25000, type=0)` → bool.

## waypoint — точки скрипта

`waypoint.add(name, x, y, z, [color], [dimension])`, `waypoint.remove(name)`, `waypoint.clear()`,
`waypoint.get(name)`, `waypoint.list(currentDimOnly=false)` → массив
`{name, x, y, z, color, dimension, distance, visible, screen_x, screen_y}`.
Точки хранятся в памяти, пока скрипт включён, и **сами не рисуются** — рисуй их в `render2d`
по `screen_x/screen_y` (если `visible`).

## store / fs / json / clipboard — данные

- `store.set(key, value)`, `store.get(key, [default])`, `store.delete(key)`, `store.all()`, `store.clear()` —
  постоянное хранилище скрипта (сохраняется на диск автоматически; значения — числа, строки, bool, таблицы).
- `fs.read(path)` → строка или nil, `fs.write(path, text)` → bool, `fs.append(path, text)`, `fs.exists(path)`,
  `fs.is_dir(path)`, `fs.size(path)`, `fs.mkdir(path)`, `fs.delete(path)`, `fs.list([dir])` → массив имён.
  Пути только относительные, внутри личной папки скрипта.
- `json.encode(value)` → строка, `json.decode(str)` → значение.
- `clipboard.copy(str)`, `clipboard.paste()` → строка.

## sound / options / window / lang

- `sound.play(id, volume=1, pitch=1)` — звук интерфейса (`"minecraft:entity.experience_orb.pickup"`,
  `"minecraft:block.note_block.pling"`…); `sound.play_at(id, x, y, z, volume=1, pitch=1)` — в точке мира.
- Без аргумента возвращают значение, с аргументом — устанавливают и возвращают: `options.fov(30..110)`,
  `options.gamma(0..1)`, `options.sensitivity(0..1)`, `options.view_distance(2..32)`, `options.max_fps(10..260)`,
  `options.bobbing(bool)`, `options.perspective("first"|"third_back"|"third_front"|"next")`.
- `window.fps()`, `window.width()`, `window.height()`, `window.size()`, `window.scale()`, `window.focused()`,
  `window.cursor_locked()`, `window.title(str)`.
- `lang.get(key, [default])` — строка локализации клиента; `lang.locale()` → `"ru_ru"`.

## configs / baritone

- `configs.active()`, `configs.list()`, `configs.exists(name)`, `configs.load(name)` → bool,
  `configs.save([name])` → bool (без имени — сохранить активный).
- `baritone.allowed()` (работает, только если включён модуль Baritone), `baritone.is_pathing()`,
  `baritone.goto_pos(x, y, z)`, `baritone.goto_xz(x, z)`, `baritone.mine("diamond_ore", ...)`,
  `baritone.command("goto 100 64 100")` (команда Baritone без `#`), `baritone.stop()`.

## bus / crypto / regex / tablex — утилиты

- `bus.on(channel, fn)` → id, `bus.once(channel, fn)`, `bus.off(id)`, `bus.emit(channel, ...)` → сколько
  получателей, `bus.channels()` — обмен сообщениями **между скриптами**.
- `crypto.sha256/sha1/md5(str)` → hex, `crypto.hmac_sha256(key, data)`, `crypto.base64_encode/decode(str)`,
  `crypto.hex_encode/decode(str)`, `crypto.crc32(str)`, `crypto.uuid()`.
- `regex` — **регулярные выражения Java** (не шаблоны Lua!), флаги строкой `"imsu"`:
  `regex.test(str, pattern, [flags])` → bool, `regex.match(str, pattern, [flags])` → `{full, start, stop, [1]=группа1, …}` или nil,
  `regex.find_all(str, pattern, [flags])` → массив таких таблиц, `regex.replace(str, pattern, repl, [flags])` (`$1` — группа),
  `regex.split(str, pattern, [limit], [flags])`, `regex.compile(pattern, [flags])` → объект с `test/match/find_all/replace/split`.
- `tablex.keys(t)`, `tablex.values(t)`, `tablex.contains(t, v)`, `tablex.index_of(t, v)`, `tablex.copy(t)`,
  `tablex.deep_copy(t)`, `tablex.merge(dst, src, overwrite=true)`, `tablex.map(t, fn(v, i))`,
  `tablex.filter(t, fn(v, i))`, `tablex.find(t, fn(v, i))`, `tablex.size(t)`, `tablex.is_empty(t)`,
  `tablex.slice(t, from, to)`, `tablex.reverse(t)`.

---

# Частые ошибки — не допускай

- Вызов `render.*` вне `render2d` или `render3d.*` вне `render3d` → ошибка «only available inside».
- Объявление настроек внутри обработчиков/таймеров — настройки создаются только на верхнем уровне.
- Тяжёлые операции (`world.entities()`, `world.find_blocks`) в `render2d` каждый кадр. Собирай данные
  в `tick` (или реже — таймером/`sw.every`) в локальные переменные, а в `render2d` только рисуй.
- Обращение к `player.*` без проверки `player.exists()`.
- Забытые зажатые клавиши после выключения скрипта.
- Спам в чат сервера (`chat.say`/`client.send`) каждый тик — ставь задержки (`sw.every(ms)`).
- Шаблоны Lua в `regex.*` и регулярки Java в `string.find/match` — это разные синтаксисы.
- Использование несуществующих функций (`os.date`, `io.open`, `require`, `wait`, `sleep`, `player.set_yaw`…).

# Шаблон скрипта

```lua
-- Название: пример
-- Что делает: показывает здоровье ближайшего врага

local range = settings.slider("Дистанция", 8, 2, 20, 0.5)
local col   = settings.color("Цвет", "#FF55FFFF")
local pos   = drag.create("Панель", 10, 60, 120, 20)

local target = nil

event.on("tick", function()
    if not player.exists() then target = nil return end
    target = combat.nearest_enemy(range.get())
end)

event.on("render2d", function()
    if not target then return end
    local x, y = pos.pos()
    local text = string.format("%s  %.1f HP", target.name, target.health)
    local w = render.text_width(text) + 12
    pos.size(w, 18)
    render.panel(x, y, w, 18)
    render.text(text, x + 6, y + 5, col.get())
end)

event.on("disable", function() target = nil end)
```

---

# Задача

(Опиши здесь, какой скрипт тебе нужен: что он должен делать, какие настройки нужны,
на какой клавише/команде запускаться, как выглядеть.)
