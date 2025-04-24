-- esp.lua
local ESPModule = {}

-- Сервіси
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
-- RunService більше не використовується для основного циклу даних/візуалізації.
-- Він був не підходящим для InvokeServer кожного кадру.

local LP = Players.LocalPlayer -- Локальний гравець

-- Внутрішній стан
local enabled = false -- Стан увімкнення/вимкнення ESP
local roles = {} -- Кешовані дані про ролі гравців з сервера
local Murder, Sheriff, Hero -- Кешовані імена гравців з ключовими ролями

-- Підключення (для подій та циклу оновлення)
local playerAddedConnection -- Обробник додавання гравців
local playerRemovingConnection -- Обробник видалення гравців
-- Для CharacterAdded будемо підключатись для КОЖНОГО гравця окремо в onPlayerAdded
local dataUpdateThread -- Потік для періодичного запиту даних з сервера

-- Константи для налаштування
local POLL_INTERVAL = 2 -- Інтервал (у секундах) між запитами даних до сервера. 2 секунди - набагато краще ніж 60 разів на секунду!
local HIGHLIGHT_NAME = "ESP_Highlight" -- Унікальне ім'я для нашого Highlight'а, щоб не конфліктувати
local COLOR_MURDERER = Color3.fromRGB(225, 0, 0) -- Червоний для Вбивці
local COLOR_SHERIFF = Color3.fromRGB(0, 0, 225) -- Синій для Шерифа
local COLOR_HERO = Color3.fromRGB(255, 250, 0)  -- Жовтий для Героя (якщо шериф мертвий)
local COLOR_INNOCENT = Color3.fromRGB(0, 225, 0) -- Зелений для Мирних (за замовчуванням)

-- Допоміжна функція для перевірки, чи гравець вважається живим на основі кешованих даних
local function IsAlive(Player)
	if not Player or not Player:IsA("Player") then return false end -- Перевіряємо, чи це валідний об'єкт гравця
	local data = roles[Player.Name]
	if data then
		return not data.Killed and not data.Dead
	end
	-- Якщо даних по цьому гравцю в таблиці немає, припускаємо, що він не є ключовою роллю,
	-- або дані ще не завантажені/застаріли. Для ESP приймемо, що якщо немає даних про смерть,
	-- то для візуалізації можемо вважати його живим, щоб показати кольор.
	-- АЛЕ в контексті ролей Murder/Sheriff/Hero - перевіряємо по даних.
	-- Тому повертаємо false, якщо немає конкретних даних про життєвий стан.
	return false -- За замовчуванням, якщо немає даних про його статус 'Alive' в roles.
end

-- Функція для створення або отримання існуючого Highlight'а на персонажі
local function GetOrCreateHighlight(Character)
	if not Character or not Character:IsA("Model") then return nil end
	local highlight = Character:FindFirstChild(HIGHLIGHT_NAME)
	if not highlight then
		-- Створюємо новий Highlight, якщо його немає
		highlight = Instance.new("Highlight")
		highlight.Name = HIGHLIGHT_NAME -- Присвоюємо наше унікальне ім'я
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 1 -- Залишаємо обведення прозорим
		-- НЕ встановлюємо parent відразу, спочатку налаштовуємо його
		-- Parent встановлюється після всіх налаштувань, або там, де ця функція викликається.
		-- Краще встановити Parent прямо тут:
		highlight.Parent = Character
	end
	return highlight
end

-- Функція для видалення Highlight'а з персонажа
local function RemoveHighlight(Character)
	if not Character or not Character:IsA("Model") then return end
	local highlight = Character:FindFirstChild(HIGHLIGHT_NAME)
	if highlight then
		highlight:Destroy()
	end
end

-- Оновлює колір Highlight'а одного гравця на основі поточних кешованих даних `roles`
local function UpdatePlayerHighlightColor(Player)
	if not Player or Player == LP or not enabled then return end -- Не оновлюємо для себе і якщо ESP вимкнено

	-- Отримуємо персонажа гравця. Якщо він ще не завантажився, чекаємо 1 кадр або отримуємо CharacterAdded Connection.
	-- Найкраще це робити вже після події CharacterAdded, але якщо гравець є від початку, може знадобитися Wait.
	local Character = Player.Character
	if not Character then
        -- Можна додати короткий wait(0.1) або Character.Added:Wait() тут,
        -- але цей апдейт повинен викликатись ПІСЛЯ того, як CharacterAdded відбудеться.
        -- Для надійності, цю функцію слід викликати з обробника CharacterAdded або після PollPlayerData,
        -- коли всі персонажі імовірно вже завантажені. Перевірка Character на nil достатня.
		return -- Якщо персонажа ще немає, виходимо
	end

	-- Отримуємо або створюємо Highlight
	local highlight = GetOrCreateHighlight(Character)
	if not highlight then
		warn("ESP: Не вдалося створити Highlight для гравця " .. Player.Name)
		return -- Немає сенсу продовжувати, якщо немає Highlight'а
	end

	local roleData = roles[Player.Name] -- Отримуємо дані по гравцю з кешу

	local color = COLOR_INNOCENT -- Колір за замовчуванням

	-- Визначаємо колір на основі кешованих даних ролей та статусу IsAlive
	-- Перевіряємо роль та чи живий гравець (згідно кешованих даних)
	if roleData and IsAlive(Player) then -- Якщо є дані І він живий за цими даними
		if Player.Name == Sheriff then
			color = COLOR_SHERIFF
		elseif Player.Name == Murder then
			color = COLOR_MURDERER
		-- Герой виділяється лише якщо він живий І Шериф не існує АБО Шериф мертвий
		-- Перевіряємо, чи Sheriff (змінна) має ім'я, перш ніж звертатись до Players[Sheriff]
		elseif Player.Name == Hero and (not Sheriff or (Players:FindFirstChild(Sheriff) and not IsAlive(Players[Sheriff]))) then
			color = COLOR_HERO
		end
	end
    -- Гравці, про яких немає даних в `roles`, або мертві за цими даними, отримають або default Innocent колір,
    -- або (краще) з них буде видалено Highlight, якщо вони мертві.
    -- Додамо логіку видалення для мертвих в UpdateAllHighlightColors

	highlight.FillColor = color
    -- Обведення залишається прозорим (1). Якщо треба показати мертвих, можна зробити його видимим?
    -- Наразі просто видаляємо Highlight для мертвих.
end

-- Видаляє Highlight'и з персонажів УСІХ гравців
local function RemoveAllHighlights()
	-- Проходимо по всіх гравцях
	for _, player in Players:GetPlayers() do
		-- Якщо гравець існує і у нього є персонаж, видаляємо Highlight
		if player and player.Character then
			RemoveHighlight(player.Character)
		end
	end
end

-- Оновлює кольори Highlight'ів для ВСІХ гравців. Викликається після оновлення даних `roles`.
local function UpdateAllHighlightColors()
	if not enabled then return end -- Оновлюємо лише якщо ESP увімкнено

	-- Скидаємо кешовані імена ключових ролей перед їх новим отриманням
	Murder, Sheriff, Hero = nil, nil, nil

	-- Проходимо по нових кешованих даних `roles` і знаходимо ключові ролі
	for name, data in pairs(roles) do
		if data.Role == "Murderer" then
			Murder = name
		elseif data.Role == "Sheriff" then
			Sheriff = name
		elseif data.Role == "Hero" then
			Hero = name
		end
	end

	-- Проходимо по всіх гравцях в грі, щоб оновити їхні Highlight'и
	for _, player in Players:GetPlayers() do
		if player == LP or not player:IsA("Player") then continue end -- Пропускаємо себе і невалідні об'єкти

		local Character = player.Character
		if not Character then
            -- Якщо персонажа ще немає, UpdatePlayerHighlightColor повернеться рано, або Highlight
            -- буде створено/оновлено, коли CharacterAdded спрацює. Це OK.
            -- Але тут, у циклі по ВСІХ, ми маємо справу лише з існуючими.
            -- Можемо пропустити гравців без персонажів або почекати, якщо дуже треба.
            -- Краще не чекати тут, а покластися на HandleCharacterAdded.
			-- Перевіримо статус смерті/вбивства за кешованими даними.
			local roleData = roles[player.Name]
			if roleData and (roleData.Killed or roleData.Dead) then
				-- Якщо дані кажуть, що гравець мертвий, і у нього, можливо, був Highlight на попередньому персонажі,
				-- або новий персонаж ще не з'явився і він мертвий...
				-- Просто видаляємо будь-який існуючий Highlight (навіть якщо Character nil, RemoveHighlight безпечний).
				RemoveHighlight(player.Character) -- Ця функція перевіряє на nil.
			end
			continue -- Продовжуємо до наступного гравця, якщо персонажа немає
		end

        -- Перевіряємо статус смерті/вбивства за кешованими даними перед оновленням кольору
        local roleData = roles[player.Name]
        if roleData and (roleData.Killed or roleData.Dead) then
             -- Якщо дані кажуть, що гравець мертвий, видаляємо його Highlight
             RemoveHighlight(Character)
        else
             -- Якщо живий або немає даних (тоді отримає зелений за замовчуванням), оновлюємо колір
             UpdatePlayerHighlightColor(player)
        end
	end
end

-- Періодично запитує дані про ролі з сервера
local function PollPlayerData()
	if not enabled then return end -- Опитуємо лише якщо ESP увімкнено

	local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
	if not remote then
		-- Виводимо попередження, якщо віддаленої функції немає.
		-- Можливо, сервер не запустився, або ім'я RemoteEvent змінилося.
		warn("ESP: 'GetPlayerData' RemoteEvent не знайдено в ReplicatedStorage!")
		-- Залишаємо старі кешовані дані, або очищаємо їх? Краще залишити, щоб ESP не "зникав" повністю при тимчасових збоях.
		return -- Не намагаємось викликати nil об'єкт
	end

	-- Використовуємо pcall для безпечного виклику InvokeServer, оскільки він може видати помилку
	local success, result = pcall(remote.InvokeServer, remote)

	if success then
		if typeof(result) == "table" then
			-- Успішно отримали дані, оновлюємо кеш
			roles = result
			-- І після отримання нових даних, оновлюємо візуалізацію (кольори Highlight'ів)
			UpdateAllHighlightColors()
		else
			-- Сервер відповів, але дані не в тому форматі, що очікується
			warn("ESP: 'GetPlayerData' повернув неочікуваний тип результату: ", typeof(result), " - Очікували table.")
			-- Можемо очистити roles = {} тут, щоб приховати застарілу невірну візуалізацію, але збережемо попередню.
		end
	else
		-- Виклик InvokeServer завершився помилкою
		warn("ESP: Помилка при виклику 'GetPlayerData': ", result)
		-- Залишаємо старі кешовані дані.
	end
end

-- Запускає потік (корутину) для періодичного виклику PollPlayerData
local function StartPollingLoop()
	if dataUpdateThread and dataUpdateThread.Status ~= "dead" then
		-- Якщо потік вже існує і не мертвий, не створюємо новий
		warn("ESP: Цикл опитування даних вже запущено.")
		return
	end

	-- Створюємо новий потік, який буде працювати у фоновому режимі
	dataUpdateThread = task.spawn(function()
		while enabled do -- Цикл продовжується, поки 'enabled' є true
			PollPlayerData() -- Викликаємо функцію опитування
			task.wait(POLL_INTERVAL) -- Чекаємо встановлений інтервал перед наступним запитом
		end
		-- Цей рядок виконається, коли цикл while enabled do завершиться (тобто коли enabled стане false)
		print("ESP: Цикл опитування даних зупинено.")
		dataUpdateThread = nil -- Очищаємо посилання на потік
	end)
     print("ESP: Цикл опитування даних запущено з інтервалом", POLL_INTERVAL, "сек.")
end

-- Зупиняє потік опитування (просто змінюючи прапор `enabled`)
local function StopPollingLoop()
	-- Потік автоматично зупиниться, коли прапор 'enabled' стане false.
	-- Просто переконуємося, що ми його вимкнули.
} -- Фактично, цю функцію можна і не мати, просто змінювати `enabled`.

-- Обробник події Player.CharacterAdded
local function OnCharacterAdded(Character)
    -- Отримуємо гравця з його персонажа
	local player = Players:GetPlayerFromCharacter(Character)
    -- Перевіряємо, чи гравець валідний, це не локальний гравець і ESP увімкнено
	if player and player ~= LP and enabled then
		-- Оскільки це новий персонаж, створюємо або отримуємо Highlight для нього
		-- (Функція GetOrCreateHighlight робить це автоматично)
        GetOrCreateHighlight(Character) -- Просто щоб гарантувати його створення
		-- І одразу оновлюємо колір на основі останніх отриманих даних ролей
		-- (UpdatePlayerHighlightColor перевіряє стан 'enabled')
		UpdatePlayerHighlightColor(player)
	end
end

-- Обробник події Player.CharacterRemoving (коли персонаж видаляється, напр. при смерті)
local function OnCharacterRemoving(Character)
	-- Видаляємо Highlight з цього персонажа, оскільки він більше не існує
	RemoveHighlight(Character) -- Функція безпечна, перевіряє на nil
end


-- Обробник події Players.PlayerAdded
local function OnPlayerAdded(Player)
	if Player == LP then return end -- Пропускаємо себе

	-- Підключаємо обробник CharacterAdded для цього нового гравця.
	-- Він буде викликатись кожен раз, коли у гравця з'являється новий персонаж (перше спавнення, відродження).
	-- connection зберігати не обов'язково тут, воно привязується до інстансу Player і буде прибрано, коли Player видалиться.
	Player.CharacterAdded:Connect(OnCharacterAdded)

	-- Якщо у гравця вже є персонаж в момент його додавання (рідко, але можливо при повільному завантаженні або інших умовах),
	-- обробляємо його одразу. OnCharacterAdded перевіряє, чи ESP увімкнено.
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

    print("ESP: Відстежується новий гравець:", Player.Name)
end

-- Обробник події Players.PlayerRemoving
local function OnPlayerRemoving(Player)
	if Player == LP then return end -- Пропускаємо себе
	-- Коли гравець виходить, видаляємо Highlight з його останнього персонажа.
	-- Навіть якщо Character вже nil, RemoveHighlight є безпечним.
	RemoveHighlight(Player.Character)
    print("ESP: Перестав відстежувати гравця:", Player.Name)
	-- Connections при PlayerAdded до CharacterAdded автоматично відключаються при видаленні гравця.
end


-- Підключає основні обробники подій гравців (PlayerAdded, PlayerRemoving)
local function SetupEventHandlers()
	if playerAddedConnection then
		-- Якщо вже підключено, не підключаємо повторно
		warn("ESP: Обробники подій гравців вже підключено.")
		return
	end

	-- Підключаємо обробники для подій Players сервісу
	playerAddedConnection = Players.PlayerAdded:Connect(OnPlayerAdded)
	playerRemovingConnection = Players.PlayerRemoving:Connect(OnPlayerRemoving)

	-- Також потрібно пройти по ГРАВЦЯМ, які ВЖЕ були в грі при включенні ESP,
	-- та налаштувати CharacterAdded для кожного з них. OnPlayerAdded робить це.
	for _, player in Players:GetPlayers() do
		if player ~= LP then
			-- Викликаємо наш обробник OnPlayerAdded для існуючих гравців.
			-- Це підключить їх CharacterAdded і обробить початковий персонаж, якщо він є.
			OnPlayerAdded(player)
		end
	end
    print("ESP: Обробники подій гравців підключено.")
end

-- Відключає основні обробники подій гравців
local function RemoveEventHandlers()
	if playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
	if playerRemovingConnection then
		playerRemovingConnection:Disconnect()
		playerRemovingConnection = nil
	end
	-- Note: CharacterAdded connections, підключені в OnPlayerAdded, формально залишаються
	-- активними, поки не буде видалено інстанс гравця, АБО ми не збережемо ці connections
	-- і не відключимо їх вручну. Простий спосіб - покладатися на прапор `enabled`
	-- всередині OnCharacterAdded. RemoveAllHighlights подбає про візуальне прибирання.
     print("ESP: Обробники подій гравців відключено (крім CharacterAdded на живих гравцях, вони деактивуються станом enabled).")
end


-- ======= Публічні функції модуля ESP =======

function ESPModule:Enable()
	if enabled then
		warn("ESP: Спроба увімкнути, але ESP вже увімкнено.")
		return -- Вже увімкнено
	end

	print("ESP: Увімкнення...")
	enabled = true

	-- Підключаємо обробники подій гравців/персонажів
	SetupEventHandlers()

	-- Запускаємо цикл періодичного запиту даних з сервера
	StartPollingLoop()

	-- Виконуємо початковий запит даних негайно і оновлюємо Highlight'и для існуючих гравців
	PollPlayerData() -- Цей виклик запустить UpdateAllHighlightColors всередині, якщо буде успішним.

	-- На всякий випадок, пройдемося ще раз по гравцях, щоб оновити (якщо PollPlayerData був повільним)
	-- Це може дублювати частину роботи, але робить активацію надійнішою.
	-- task.wait(0.1) -- Можна додати короткий wait, щоб дані з PollPlayerData точно закешувались перед цим
	-- UpdateAllHighlightColors() -- PollPlayerData вже викликає це.
	-- Якщо викликати тут, буде використовуватися старий roles{} перед першим PollData, якщо PollData повільний.

	print("ESP: Увімкнено!")
end

function ESPModule:Disable()
	if not enabled then
		warn("ESP: Спроба вимкнути, але ESP вже вимкнено.")
		return -- Вже вимкнено
	end

	print("ESP: Вимкнення...")
	enabled = false -- Це зупинить цикл опитування (StartPollingLoop uses while enabled)

	-- Видаляємо основні обробники подій
	RemoveEventHandlers()

	-- Видаляємо всі Highlight'и з усіх персонажів
	RemoveAllHighlights()

	-- Очищаємо кешовані дані (опціонально, але чисто)
	roles = {}
	Murder, Sheriff, Hero = nil, nil, nil

	print("ESP: Вимкнено!")
end

-- Можна залишити функцію Toggle для зручності
-- function ESPModule:Toggle(state)
--     if state then
--         self:Enable()
--     else
--         self:Disable()
--     end
-- end

-- Старі функції Start та Toggle більше не потрібні в цьому вигляді, їх замінюють Enable/Disable

return ESPModule