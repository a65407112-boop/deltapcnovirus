-- Runs the actual capture helper with isolated GUI and exporter adapters.
-- Export serialization and live executor compatibility are not simulated.
local function capture()
-- CAPTURE_PLACEHOLDER
end

local function instance(class, name, parent, text)
    local object = { ClassName = class, Name = name, Parent = parent, Text = text or "", children = {} }
    if parent then table.insert(parent.children, object) end
    function object:IsA(wanted)
        return wanted == self.ClassName or (wanted == "LayerCollector" and self.ClassName == "ScreenGui")
    end
    function object:GetDescendants()
        local result = {}
        local function visit(node)
            for _, child in node.children do table.insert(result, child); visit(child) end
        end
        visit(self)
        return result
    end
    return object
end

local function fixture(rootClass)
    local root = instance(rootClass or "Folder", "HiddenUI")
    local gui = rootClass == "ScreenGui" and root or instance("ScreenGui", "UnpredictableName", root)
    local panel = instance("Frame", "Editor", gui)
    local button = instance("TextButton", "RandomButton", panel, "Execute clipboard")
    button.FontFace = { Family = "rbxasset://original/Poppins.font.json", Weight = "Bold" }
    return root, gui, button
end

local function run(root, config)
    config = config or {}
    local result = { http = 0, gethui = 0, waits = 0, prints = {}, files = config.files or {} }
    local nativeTypeof = typeof
    local env = setmetatable({
        gethui = function() result.gethui += 1; return root end,
        identifyexecutor = function() return config.executor or "Delta" end,
        typeof = function(value)
            return type(value) == "table" and value.ClassName and "Instance" or nativeTypeof(value)
        end,
        writefile = function(path, data) result.files[path] = data end,
        readfile = function(path) return assert(result.files[path], "missing output") end,
        isfile = function(path) return result.files[path] ~= nil end,
        os = { date = function() return "20261023_120000" end },
        print = function(message) table.insert(result.prints, message) end,
        task = { wait = function()
            result.waits += 1
            if config.delayed and result.waits == 2 then
                result.files[result.options.FilePath] = "<roblox!" .. string.rep("\0", 32)
            end
        end },
        game = { HttpGet = function(_, url)
            result.http += 1
            assert(string.find(url, "a78cc2db1b41a647f818f004aa5fa3fcc62b27a1", 1, true))
            return "MOCK_EXPORTER_SOURCE"
        end },
        loadstring = function(source)
            assert(source == "MOCK_EXPORTER_SOURCE")
            if config.compileError then return nil, "test compilation failure" end
            return function()
                if config.badExporter then return {} end
                return function(options)
                    result.options = options
                    if not config.delayed then
                        result.files[options.FilePath] = config.invalidFile and "not a model" or "<roblox!" .. string.rep("\0", 32)
                    end
                end
            end
        end,
    }, { __index = getfenv(0) })
    if config.missing then env[config.missing] = false end
    setfenv(capture, env)
    result.ok, result.value = pcall(capture)
    return result
end

local count = 0
local function test(name, fn)
    fn()
    count += 1
    print("PASS capture: " .. name)
end
local function failed(result, message)
    assert(not result.ok and string.find(tostring(result.value), message, 1, true), tostring(result.value))
end

test("exports original screen once and preserves font references", function()
    local root, gui, button = fixture()
    instance("Frame", "Execute_Clipboard", gui)
    local unrelated = instance("ScreenGui", "OtherMenu", root)
    instance("TextButton", "Run", unrelated, "Execute")
    local previous = instance("ScreenGui", "DeltaPC", root)
    instance("TextButton", "ExecuteClipboard", previous)
    local font = button.FontFace
    local r = run(root)
    assert(r.ok, r.value)
    assert(#r.options.ExtraInstances == 1 and r.options.ExtraInstances[1] == gui)
    assert(r.options.mode == "custom" and r.options.Object == nil and r.options.IsModel and r.options.Binary)
    assert(r.options.Decompile == false and r.options.DecompileJobless == false and r.options.SaveBytecode == false)
    assert(table.concat(r.options.IgnoreList, ",") == "Script,LocalScript,ModuleScript")
    assert(button.FontFace == font and gui.Parent == root)
end)

test("handles gethui returning the screen itself", function()
    local root = fixture("ScreenGui")
    local r = run(root)
    assert(r.ok and #r.options.ExtraInstances == 1 and r.options.ExtraInstances[1] == root)
end)

test("refuses missing original editor without downloading an exporter", function()
    local root = instance("Folder", "HiddenUI")
    local old = instance("ScreenGui", "DeltaPC", root)
    instance("TextButton", "ExecuteClipboard", old)
    local r = run(root)
    failed(r, "original editor not found")
    assert(r.http == 0 and r.options == nil)
end)

test("rejects running in Xeno before reading its GUI", function()
    local r = run(fixture(), { executor = "Xeno" })
    failed(r, "run this in Android Delta")
    assert(r.gethui == 0 and r.http == 0)
end)

test("reports missing capabilities and invalid hidden UI", function()
    for _, capability in { "gethui", "writefile" } do
        local r = run(fixture(), { missing = capability })
        failed(r, "unavailable")
        assert(r.http == 0)
    end
    local r = run("not an instance")
    failed(r, "did not return an Instance")
    assert(r.http == 0)
end)

test("does not report a malformed export as saved", function()
    local r = run(fixture(), { invalidFile = true })
    failed(r, "no valid RBXM file was confirmed")
    for _, message in r.prints do assert(not string.find(message, "Saved:", 1, true)) end
end)

test("waits for delayed export and avoids an existing filename", function()
    local existing = "gethui_dump_20261023_120000.rbxm"
    local r = run(fixture(), { delayed = true, files = { [existing] = "keep original" } })
    assert(r.ok, r.value)
    assert(r.value == "gethui_dump_20261023_120000_1.rbxm" and r.waits == 2)
    assert(r.files[existing] == "keep original")
end)

test("reports invalid exporter responses", function()
    failed(run(fixture(), { compileError = true }), "exporter compilation failed")
    failed(run(fixture(), { badExporter = true }), "exporter returned no function")
end)

test("uses qualified output when readfile is unavailable", function()
    local r = run(fixture(), { missing = "readfile" })
    assert(r.ok, r.value)
    assert(string.find(r.prints[#r.prints], "check Delta's workspace", 1, true))
end)

print("Capture checks passed: " .. count)
