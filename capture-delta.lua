-- Run INSIDE Android Delta after its original editor is loaded.
-- UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw
-- Upstream source/license: https://github.com/luau/UniversalSynSaveInstance
-- This wrapper selects the loaded GUI; it does not recreate the menu.
local PIN = "a78cc2db1b41a647f818f004aa5fa3fcc62b27a1"
local UPSTREAM = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/" .. PIN .. "/saveinstance.luau"

assert(type(gethui) == "function", "Delta capture: gethui is unavailable. Run this inside Delta.")
assert(type(writefile) == "function", "Delta capture: workspace file writing is unavailable.")
if type(identifyexecutor) == "function" then
    local ok, name = pcall(identifyexecutor)
    assert(not (ok and string.find(string.lower(tostring(name)), "xeno", 1, true)),
        "Delta capture: run this in Android Delta, not Xeno. Xeno cannot see another client's GUI.")
end

local root = gethui()
assert(typeof(root) == "Instance", "Delta capture: gethui did not return an Instance.")
local targets, seen = {}, {}
local function normalize(text)
    return (string.gsub(string.lower(text), "[%s_%-]", ""))
end
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
        if target.Name ~= "DeltaPC" and not seen[target] then
            seen[target] = true
            table.insert(targets, target)
        end
    end
end
assert(#targets > 0, "Delta capture: original editor not found. Open Delta's editor and run again.")

-- Keep a previous export when rerunning in the same second.
local stem = "gethui_dump_" .. os.date("!%Y%m%d_%H%M%S")
local fileName = stem .. ".rbxm"
if type(isfile) == "function" then
    local counter = 1
    while isfile(fileName) do
        fileName = stem .. "_" .. counter .. ".rbxm"
        counter += 1
    end
end

print("[Delta capture] Exporting " .. #targets .. " GUI root(s) to " .. fileName)
local source = game:HttpGet(UPSTREAM)
local loader, compileError = loadstring(source, "UniversalSynSaveInstance")
assert(loader, "Delta capture: exporter compilation failed: " .. tostring(compileError))
local saveGui = loader()
assert(type(saveGui) == "function", "Delta capture: exporter returned no function.")
saveGui({
    mode = "custom",
    ExtraInstances = targets,
    IsModel = true,
    Binary = true,
    CompressionMode = false,
    FilePath = fileName,
    IgnoreList = { "Script", "LocalScript", "ModuleScript" },
    Decompile = false,
    DecompileJobless = false,
    SaveBytecode = false,
    NilInstances = false,
    AntiIdle = false,
    ShowStatus = false,
    SafeMode = false,
    KillAllScripts = false,
    BoostFPS = false,
    ShutdownWhenDone = false,
})
if type(readfile) == "function" then
    local confirmed = false
    for attempt = 1, 16 do
        local ok, data = pcall(readfile, fileName)
        if ok and type(data) == "string" and #data >= 32 and string.sub(data, 1, 8) == "<roblox!" then
            confirmed = true
            break
        end
        task.wait(.25)
    end
    assert(confirmed, "Delta capture: no valid RBXM file was confirmed. Check the executor console.")
    print("[Delta capture] Saved: " .. fileName)
else
    print("[Delta capture] Export finished; check Delta's workspace for " .. fileName)
end
return fileName
