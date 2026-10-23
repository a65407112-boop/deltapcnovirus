-- Executes the real GUI capture script. Roblox instances, networking and
-- executor storage are adapted; serialization and live rendering are not tested.
local function capture()
-- CAPTURE_GUI_PLACEHOLDER
end

local HEADER = "<roblox!\137\255\13\10\26\10" .. string.rep("\0", 18)
local END = "END\0\0\0\0\0\9\0\0\0\0\0\0\0</roblox>"
local MODEL = HEADER .. "META\0\0\0\0\4\0\0\0\0\0\0\0test" .. END

local function context(config)
    config = config or {}
    local c = { now = 0, queue = {}, objects = {}, files = {}, exports = 0, http = 0, shared = {} }
    local function signal()
        local handlers = {}
        return {
            Connect = function(_, fn) table.insert(handlers, fn); return { Disconnect = function() end } end,
            Fire = function(_, ...) for _, fn in handlers do fn(...) end end,
        }
    end
    local function make(class, name, parent, text)
        local o = { ClassName = class, Name = name or class, Parent = parent, Text = text or "", attributes = {}, Activated = signal() }
        function o:IsA(wanted) return self.ClassName == wanted or (wanted == "LayerCollector" and self.ClassName == "ScreenGui") end
        function o:GetDescendants()
            local result = {}
            local function visit(node)
                for _, child in c.objects do
                    if child.Parent == node then table.insert(result, child); visit(child) end
                end
            end
            visit(self)
            return result
        end
        function o:FindFirstChildOfClass(wanted)
            for _, child in c.objects do if child.Parent == self and child:IsA(wanted) then return child end end
        end
        function o:SetAttribute(key, value) self.attributes[key] = value end
        function o:GetAttribute(key) return self.attributes[key] end
        function o:Destroy() self.Parent = nil; self.destroyed = true end
        table.insert(c.objects, o)
        return o
    end
    local function schedule(fn, ...)
        local thread = coroutine.create(fn)
        local ok, delay = coroutine.resume(thread, ...)
        assert(ok, delay)
        if coroutine.status(thread) ~= "dead" then table.insert(c.queue, { thread = thread, at = c.now + (delay or .01) }) end
        return thread
    end
    function c:advance(seconds)
        local limit = self.now + seconds
        local iterations = 0
        while true do
            table.sort(self.queue, function(a, b) return a.at < b.at end)
            if not self.queue[1] or self.queue[1].at > limit then break end
            local item = table.remove(self.queue, 1)
            self.now = item.at
            local ok, delay = coroutine.resume(item.thread)
            assert(ok, delay)
            if coroutine.status(item.thread) ~= "dead" then
                item.at = self.now + (delay or .01)
                table.insert(self.queue, item)
            end
            iterations += 1
            assert(iterations < 20000, "non-yielding test scheduler")
        end
        self.now = limit
    end
    function c:find(name)
        for i = #self.objects, 1, -1 do
            local o = self.objects[i]
            if o.Name == name and not o.destroyed then return o end
        end
    end
    function c:phase()
        local screen = self:find("DeltaCaptureStatus")
        return screen and screen:GetAttribute("CaptureState")
    end
    local player = make("Player", "Player")
    local playerGui = make("PlayerGui", "PlayerGui", player)
    local host = make("Folder", "HiddenHost")
    local root = make(config.screenRoot and "ScreenGui" or "Folder", "HiddenUI", host)
    local gui = config.screenRoot and root or make("ScreenGui", "OriginalDelta", root)
    make("TextButton", "RandomControlName", gui, "Execute clipboard")
    local other = make("ScreenGui", "OtherMenu", root)
    make("TextButton", "Run", other, "Execute")
    c.gui, c.root, c.playerGui = gui, root, playerGui
    local enums = setmetatable({}, { __index = function(t, key)
        local category = setmetatable({}, { __index = function(_, value) return key .. "." .. value end })
        rawset(t, key, category)
        return category
    end })
    c.env = setmetatable({
        Instance = { new = function(class) return make(class) end },
        Enum = enums,
        Color3 = { fromRGB = function(r, g, b) return { R = r, G = g, B = b } end },
        UDim2 = { new = function(...) return { ... } end, fromOffset = function(...) return { ... } end },
        UDim = { new = function(...) return { ... } end },
        Vector2 = { new = function(...) return { ... } end },
        getgenv = function() return c.shared end,
        gethui = function() return root end,
        identifyexecutor = function() return "Delta" end,
        typeof = function(value) return type(value) == "table" and value.ClassName and "Instance" or typeof(value) end,
        os = { clock = function() return c.now end, date = function() return "20261023_120000" end },
        task = { spawn = schedule, wait = function(delay) return coroutine.yield(delay or .01) end },
        game = {
            GetService = function(_, name)
                if name == "Players" then return { LocalPlayer = player } end
                if name == "CoreGui" then return make("CoreGui") end
                error("unexpected service " .. name)
            end,
            HttpGet = function(_, _url)
                c.http += 1
                if config.networkError then error("network unavailable") end
                return "MOCK_EXPORTER_SOURCE"
            end,
        },
        loadstring = function(source)
            assert(source == "MOCK_EXPORTER_SOURCE")
            return function()
                return function(options)
                    c.exports += 1
                    c.options = options
                    if not config.noCallback then
                        if options.Callback then options.Callback(config.invalidModel and "broken model" or MODEL)
                        else c.files[options.FilePath] = MODEL end
                    end
                end
            end
        end,
        writefile = function(path, data)
            if config.writeError then error("storage full") end
            c.writtenPath = path
            if config.delayed then
                c.files[path] = data:sub(1, 40)
                schedule(function() coroutine.yield(2); c.files[path] = data end)
            elseif config.mismatch then
                c.files[path] = data:sub(1, 48) .. "oops" .. data:sub(53)
            else c.files[path] = data end
        end,
        readfile = function(path) return assert(c.files[path], "file not found") end,
        isfile = function(path) return c.files[path] ~= nil end,
        setclipboard = function(value) c.clipboard = value end,
        print = function() end,
        warn = function() end,
    }, { __index = getfenv(0) })
    if config.noReadfile then c.env.readfile = false end
    if config.noGethui then c.env.gethui = false end
    function c:run()
        setfenv(capture, self.env)
        local ok, err = pcall(capture)
        assert(ok, err)
    end
    return c
end

local count = 0
local function test(name, fn) fn(); count += 1; print("PASS capture GUI: " .. name) end

test("keeps a visible completion window with the verified file path", function()
    local c = context()
    c:run(); c:advance(3)
    local screen = c:find("DeltaCaptureStatus")
    assert(screen and screen.Enabled, "a visible status window is required")
    assert(c:phase() == "ready", "must report verified completion")
    assert(c.files[c.writtenPath] == MODEL)
    assert(string.find(c:find("CaptureFile").Text, c.writtenPath, 1, true))
    c:find("CaptureCopy").Activated:Fire()
    assert(c.clipboard == c.writtenPath)
end)

test("never reports ready while only a prefix has been written", function()
    local c = context({ delayed = true })
    c:run(); c:advance(1)
    assert(c:find("DeltaCaptureStatus"), "must show status while writing")
    assert(c:phase() ~= "ready" and c.files[c.writtenPath] ~= MODEL)
    c:advance(4)
    assert(c:phase() == "ready" and c.files[c.writtenPath] == MODEL)
end)

test("same-size corrupted data is not confirmed", function()
    local c = context({ mismatch = true })
    c:run(); c:advance(125)
    assert(#c.files[c.writtenPath] == #MODEL and c.files[c.writtenPath] ~= MODEL)
    assert(c:phase() == "unverified", "matching the header or size is insufficient")
end)

test("completion requires two consecutive matching readbacks", function()
    local c, reads = context(), 0
    c.env.readfile = function()
        reads += 1
        return reads == 2 and MODEL:sub(1, -2) .. "x" or MODEL
    end
    local function reachRead(number)
        for _ = 1, 1000 do
            if reads >= number then break end
            c:advance(.01)
        end
        assert(reads == number, "expected the next readback")
    end
    c:run()
    reachRead(1)
    assert(c:phase() == "verifying", "one matching read must not report completion")
    reachRead(2)
    assert(c:phase() == "verifying", "a corrupt read must reset confirmation")
    reachRead(3)
    assert(c:phase() == "verifying", "confirmation must restart after a corrupt read")
    reachRead(4)
    assert(c:phase() == "ready")
end)

test("download and storage failures stay visible", function()
    for _, config in { { networkError = true }, { writeError = true }, { noGethui = true } } do
        local c = context(config)
        c:run(); c:advance(3)
        assert(c:phase() == "error" and c:find("DeltaCaptureStatus").Enabled)
        assert(#c:find("CaptureDetails").Text > 0)
    end
end)

test("missing readfile is explicitly unverified", function()
    local c = context({ noReadfile = true })
    c:run(); c:advance(3)
    assert(c.files[c.writtenPath] == MODEL and c:phase() == "unverified")
end)

test("hiding and reopening an active window does not duplicate export", function()
    local c = context({ delayed = true })
    c:run(); c:advance(.5)
    c:find("CaptureClose").Activated:Fire()
    assert(c:find("DeltaCaptureStatus").Enabled == false)
    c:run()
    assert(c:find("DeltaCaptureStatus").Enabled == true)
    c:advance(4)
    assert(c.exports == 1 and c.http == 1 and c:phase() == "ready")
end)

test("status UI is outside the exported screen", function()
    local c = context({ screenRoot = true })
    c:run(); c:advance(3)
    assert(c:phase() == "ready")
    assert(#c.options.ExtraInstances == 1 and c.options.ExtraInstances[1] == c.gui)
    assert(c:find("DeltaCaptureStatus").Parent == c.root.Parent,
        "the status screen should share the original screen's host and stay outside its export")
end)

test("missing or malformed serialized output never claims completion", function()
    for _, config in { { noCallback = true }, { invalidModel = true } } do
        local c = context(config)
        c:run(); c:advance(3)
        assert(c:phase() == "error" and c.writtenPath == nil)
    end
end)

print("Capture GUI checks passed: " .. count)
