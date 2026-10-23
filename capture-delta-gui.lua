-- Run INSIDE Android Delta with the original editor open.
-- UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw
-- Upstream source/license: https://github.com/luau/UniversalSynSaveInstance
local PIN = "a78cc2db1b41a647f818f004aa5fa3fcc62b27a1"
local UPSTREAM = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/" .. PIN .. "/saveinstance.luau"
local shared = (type(getgenv) == "function" and getgenv()) or _G
local previous = shared.__DeltaGuiCaptureProgress
if type(previous) == "table" and previous.screen and previous.screen.Parent then
    if previous.busy then
        previous.screen.Enabled = true
        return previous
    end
    previous.screen:Destroy()
end

-- Use the hidden GUI's host, while keeping this window outside its screen.
local hiddenRoot, parent
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and typeof(result) == "Instance" then hiddenRoot = result end
end
if hiddenRoot then
    if hiddenRoot:IsA("LayerCollector") then parent = hiddenRoot.Parent
    else parent = hiddenRoot end
end
if not parent then
    local player = game:GetService("Players").LocalPlayer
    parent = player and player:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
end
local function make(class, properties, container)
    local object = Instance.new(class)
    for key, value in properties do object[key] = value end
    object.Parent = container
    return object
end
local colors = {
    text = Color3.fromRGB(235, 240, 250), muted = Color3.fromRGB(153, 166, 190),
    active = Color3.fromRGB(104, 177, 255), ready = Color3.fromRGB(98, 224, 156),
    error = Color3.fromRGB(255, 120, 130), unverified = Color3.fromRGB(255, 203, 110),
}
local screen = make("ScreenGui", {
    Name = "DeltaCaptureStatus", Enabled = true, ResetOnSpawn = false,
    DisplayOrder = 2000000000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parent)
local panel = make("Frame", {
    Name = "Panel", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0),
    Size = UDim2.new(.9, 0, 0, 272), BackgroundColor3 = Color3.fromRGB(21, 27, 39), BorderSizePixel = 0,
}, screen)
make("UISizeConstraint", { MinSize = Vector2.new(260, 272), MaxSize = Vector2.new(440, 272) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
make("UIStroke", { Color = Color3.fromRGB(62, 78, 104), Thickness = 1 }, panel)
local function label(name, y, height, size, color)
    return make("TextLabel", {
        Name = name, BackgroundTransparency = 1, Position = UDim2.fromOffset(16, y),
        Size = UDim2.new(1, -32, 0, height), Font = Enum.Font.Gotham, TextSize = size,
        TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = "",
    }, panel)
end
label("CaptureTitle", 14, 24, 18, colors.text).Text = "Экспорт GUI Delta"
local status = label("CaptureStatus", 49, 26, 17, colors.active)
local details = label("CaptureDetails", 81, 52, 13, colors.muted)
local file = label("CaptureFile", 139, 42, 12, colors.text)
file.Font = Enum.Font.Code
file.Text = "Файл ещё не выбран"
local counter = label("CaptureCounter", 188, 20, 12, colors.muted)
local function button(name, text, x)
    local object = make("TextButton", {
        Name = name, Text = text, Position = UDim2.new(x, x == 0 and 16 or 8, 0, 220),
        Size = UDim2.new(.5, -24, 0, 36), BackgroundColor3 = Color3.fromRGB(40, 55, 78),
        TextColor3 = colors.text, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0,
    }, panel)
    make("UICorner", { CornerRadius = UDim.new(0, 7) }, object)
    return object
end
local copy = button("CaptureCopy", "Копировать путь", 0)
local close = button("CaptureClose", "Скрыть", .5)
local state = { screen = screen, busy = true, started = os.clock(), expected = 0 }
shared.__DeltaGuiCaptureProgress = state
local function size(bytes)
    return bytes < 1024 and tostring(bytes) .. " Б" or string.format("%.1f КБ", bytes / 1024)
end
local function refresh()
    if not screen.Parent then return end
    local text = string.format("Время: %d с", math.floor(os.clock() - state.started))
    if state.actual then text ..= "  ·  " .. size(state.actual) .. " / " .. size(state.expected)
    elseif state.expected > 0 then text ..= "  ·  Ожидается " .. size(state.expected) end
    counter.Text = text
end
local function stage(phase, title, message)
    state.phase = phase
    screen:SetAttribute("CaptureState", phase)
    status.Text, details.Text = title, message
    status.TextColor3 = colors[phase] or colors.active
    refresh()
end
local function finish(phase, title, message)
    state.busy = false
    close.Text = "Закрыть"
    stage(phase, title, message)
end
copy.Activated:Connect(function()
    if not state.fileName then return end
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, state.fileName)
        copy.Text = ok and "Путь скопирован" or "Не удалось скопировать"
    else copy.Text = "Путь указан выше" end
end)
close.Activated:Connect(function()
    if state.busy then screen.Enabled = false
    else
        screen:Destroy()
        if shared.__DeltaGuiCaptureProgress == state then shared.__DeltaGuiCaptureProgress = nil end
    end
end)
stage("starting", "Подготовка…", "Окно покажет, когда файл будет полностью записан и проверен.")
task.spawn(function()
    while state.busy and screen.Parent do refresh(); task.wait(.25) end
end)

local function export()
    task.wait() -- Let the status window render before downloading or serializing.
    assert(type(gethui) == "function", "gethui недоступен. Запусти скрипт внутри Android Delta.")
    assert(type(writefile) == "function", "writefile недоступен: невозможно записать файл.")
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        assert(not (ok and string.find(string.lower(tostring(name)), "xeno", 1, true)),
            "Запусти этот экспорт в Android Delta. Xeno не видит её GUI.")
    end
    stage("searching", "Поиск меню…", "Выбираем экран оригинального редактора Delta.")
    local root = hiddenRoot or gethui()
    assert(typeof(root) == "Instance", "gethui не вернул объект интерфейса.")
    local targets, seen = {}, {}
    local function normalize(text) return (string.gsub(string.lower(text), "[%s_%-]", "")) end
    local function guiRoot(object)
        if root:IsA("LayerCollector") then return root end
        local current = object
        while current.Parent and current.Parent ~= root do
            if current:IsA("LayerCollector") then break end
            current = current.Parent
        end
        return current
    end
    for _, object in root:GetDescendants() do
        local marker = normalize(object.Name)
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            local text = normalize(object.Text)
            if text == "executeclipboard" then marker = text end
        end
        if marker == "executeclipboard" then
            local target = guiRoot(object)
            if target.Name ~= "DeltaPC" and target ~= screen and not seen[target] then
                seen[target] = true
                table.insert(targets, target)
            end
        end
    end
    assert(#targets > 0, "Оригинальный редактор не найден. Открой его в Delta и повтори запуск.")
    local stem = "gethui_dump_" .. os.date("!%Y%m%d_%H%M%S")
    local fileName = stem .. ".rbxm"
    if type(isfile) == "function" then
        local suffix = 1
        while isfile(fileName) do fileName = stem .. "_" .. suffix .. ".rbxm"; suffix += 1 end
    end
    state.fileName, file.Text = fileName, "Workspace Delta:\n" .. fileName
    stage("downloading", "Загрузка экспортера…", "Получаем закреплённую версию UniversalSynSaveInstance.")
    local source = game:HttpGet(UPSTREAM)
    local loader, compileError = loadstring(source, "UniversalSynSaveInstance")
    assert(loader, "Не удалось загрузить экспортер: " .. tostring(compileError))
    local saveGui = loader()
    assert(type(saveGui) == "function", "Экспортер не вернул функцию сохранения.")
    local received = false
    local function writeAndConfirm(data)
        local magic = "<roblox!\137\255\13\10\26\10"
        local ending = "END\0\0\0\0\0\9\0\0\0\0\0\0\0</roblox>"
        assert(type(data) == "string" and #data >= 57 and data:sub(1, 14) == magic and data:sub(-25) == ending,
            "Экспортер вернул неполные данные RBXM. Файл не записан.")
        state.expected = #data
        stage("writing", "Запись файла…", "GUI собран. Записываем готовые данные в workspace Delta.")
        task.wait()
        writefile(fileName, data)
        if type(readfile) ~= "function" then
            finish("unverified", "Запись не подтверждена", "writefile завершился, но readfile недоступен. Автоматическая проверка невозможна.")
            return
        end
        stage("verifying", "Проверка файла…", "Читаем файл обратно и сравниваем все байты с готовой моделью.")
        local started, matches = os.clock(), 0
        while os.clock() - started < 120 do
            local ok, actual = pcall(readfile, fileName)
            state.actual = ok and type(actual) == "string" and #actual or 0
            matches = ok and actual == data and matches + 1 or 0
            refresh()
            if matches >= 2 then
                finish("ready", "Готово ✓", "Файл записан целиком и проверен. Теперь его можно отправить.")
                print("[Delta capture] Verified: " .. fileName .. " (" .. #data .. " bytes)")
                return
            end
            task.wait(.35)
        end
        finish("unverified", "Запись не подтверждена", "За 120 секунд файл не совпал с готовой моделью. Не отправляй его как завершённый.")
    end
    stage("exporting", "Сборка GUI…", "Сохраняем структуру, свойства и ссылки на ресурсы. Скрипты исключены.")
    saveGui({
        mode = "custom", ExtraInstances = targets, IsModel = true, Binary = true,
        CompressionMode = false, FilePath = fileName,
        IgnoreList = { "Script", "LocalScript", "ModuleScript" },
        Decompile = false, DecompileJobless = false, SaveBytecode = false,
        RecoverScriptsFromAssets = false, NilInstances = false, AntiIdle = false,
        ShowStatus = false, SafeMode = false, KillAllScripts = false,
        BoostFPS = false, ShutdownWhenDone = false, CopyToClipboard = false,
        Callback = function(data)
            if received then return end
            received = true
            local ok, err = pcall(writeAndConfirm, data)
            if not ok then finish("error", "Ошибка", tostring(err)); warn(err) end
        end,
    })
    assert(received, "Экспортер не вернул данные модели. Открой F9 для подробностей и повтори запуск.")
end
task.spawn(function()
    local ok, err = pcall(export)
    if not ok then finish("error", "Ошибка", tostring(err)); warn(err) end
end)
return state
