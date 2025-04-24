-- Цей скрипт запускає GUI та інтегрує ESP/Aimbot модулі.

-- Load ESP - припускається, що це покращена версія бібліотеки
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/GlibShark/bibaexec/refs/heads/main/game/142823291/esp.lua"))()
-- !!! УВАГА: Видалено старий виклик ESP:Start(), оскільки покращена версія використовує ESP:Enable().

-- Load Aimbot
local RoleAimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/GlibShark/bibaexec/refs/heads/main/game/142823291/aimbot.lua"))()
-- Aimbot вимикаємо за замовчуванням, як було в оригіналі
RoleAimbot:SetEnabled(false)

-- Load Fluent UI та аддони
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Створення головного вікна GUI
local Window = Fluent:CreateWindow({
    Title = "MM2 BE",
    SubTitle = "Gui powered by Fluent",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- Акриловий (розмитий фон)
    Theme = "Dark", -- Темна тема
    MinimizeKey = Enum.KeyCode.LeftControl -- Клавіша для згортання
})

-- Створення вкладок GUI
local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }), -- Вкладка ESP
    Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" }), -- Вкладка Aimbot
    -- Fling вкладку ВИДАЛЕНО звідси
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) -- Вкладка Налаштування
}

-- Отримання посилання на таблицю з опціями Fluent
local Options = Fluent.Options

-- ========== Вкладка ESP ==========
local ESPToggle = Tabs.ESP:AddToggle("ESPEnabled", {
    Title = "Enable ESP",
    Default = true -- За замовчуванням увімкнено
})

-- Обробник зміни стану перемикача ESP
ESPToggle:OnChanged(function(value)
    if value then
        ESP:Enable() -- Викликаємо Enable на ESP модулі
        Fluent:Notify({Title="ESP", Content="ESP Enabled", Duration=3}) -- Повідомлення
    else
        ESP:Disable() -- Викликаємо Disable на ESP модулі
        Fluent:Notify({Title="ESP", Content="ESP Disabled", Duration=3}) -- Повідомлення
    end
end)

-- Кнопка для перезапуску ESP
Tabs.ESP:AddButton({
    Title = "🔁 Restart ESP",
    Description = "Temporarily disables and re-enables ESP",
    Callback = function()
        -- Перевіряємо, чи перемикач ESP увімкнено в UI
        if Options.ESPEnabled.Value then
            -- Викликаємо Disable та Enable. Затримки і цикли не потрібні для покращеної версії.
            ESP:Disable()
            task.wait(0.1) -- Невелика пауза (опціонально, для надійності очищення)
            ESP:Enable()
            -- Повідомлення про успішний перезапуск
            Fluent:Notify({
                Title = "ESP",
                Content = "ESP has been restarted",
                Duration = 4
            })
        else
            -- Якщо перемикач вимкнено, повідомляємо користувача
            Fluent:Notify({
                Title = "ESP is disabled",
                Content = "Enable ESP first",
                Duration = 4
            })
        end
    end
})

-- Оскільки ESP за замовчуванням увімкнено (Default = true), викликаємо Enable при завантаженні GUI.
-- Цей код виконується після завантаження модуля ESP та налаштування toggle,
-- тому він коректно ініціалізує ESP.
if Options.ESPEnabled.Value then
    ESP:Enable()
end


-- ========== Вкладка Aimbot ==========
-- Логіка Aimbot залишилась без змін з твого скрипта, оскільки запит був лише про видалення Fling та адаптацію ESP.
local AimbotToggle = Tabs.Aimbot:AddToggle("AimbotEnabled", {
    Title = "Enable Aimbot",
    Default = false
})

AimbotToggle:OnChanged(function(value)
    RoleAimbot:SetEnabled(value)
end)

local AimbotRange = Tabs.Aimbot:AddSlider("AimbotRange", {
    Title = "Aimbot Range",
    Description = "Max target distance",
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0
})

AimbotRange:OnChanged(function(value)
    RoleAimbot:SetRange(value)
end)

local AimbotSpeed = Tabs.Aimbot:AddSlider("AimbotSpeed", {
    Title = "Aimbot Speed",
    Description = "Target snap speed",
    Default = 15,
    Min = 1,
    Max = 100,
    Rounding = 0
})

AimbotSpeed:OnChanged(function(value)
    RoleAimbot:SetSpeed(value)
end)


-- ========== Вкладка Fling ==========
-- ЦЮ СЕКЦІЮ ПОВНІСТЮ ВИДАЛЕНО. Включно з функцією flingTarget,
-- dropdowns, кнопками та логікою отримання даних про ролі для флінгу.


-- ========== Аддони Fluent UI та Налаштування ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Не ігноруємо налаштування теми Fluent. Якщо треба ігнорувати, залиште рядок:
-- SaveManager:IgnoreThemeSettings()

-- Тут можна вказати опції (зазвичай toggle name string), які SaveManager НЕ має зберігати/завантажувати.
-- Наприклад, "AimbotEnabled" якщо ви хочете щоб аімбот завжди був вимкнений при старті.
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub") -- Папка, де зберігаються налаштування UI (Fluent створює її автоматично)
SaveManager:SetFolder("FluentScriptHub/MM2BE") -- Папка для збереження конфігурацій саме для цього скрипта/гри

InterfaceManager:BuildInterfaceSection(Tabs.Settings) -- Додає секцію інтерфейсу в вкладку Settings
SaveManager:BuildConfigSection(Tabs.Settings) -- Додає секцію конфігурації (збереження/завантаження) в вкладку Settings

-- Вибір початкової вкладки при відкритті GUI
-- Оскільки Fling вкладку видалено (вона була, імовірно, 3-ю), тепер вкладка Settings стане 3-ю,
-- якщо ESP - 1, Aimbot - 2. Можемо залишити SelectTab(1) щоб почати з ESP.
Window:SelectTab(1) -- Вибираємо першу вкладку (ESP)

-- Повідомлення про успішне завантаження GUI
Fluent:Notify({
    Title = "Fluent",
    Content = "GUI has successfully loaded!",
    Duration = 8 -- Тривалість відображення повідомлення
})

-- Завантаження конфігурації при автозавантаженні скрипта
SaveManager:LoadAutoloadConfig()