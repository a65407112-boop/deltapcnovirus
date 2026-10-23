-- State and execution logic. No Roblox services, remote requests, or key gate.
local Core = {}
Core.__index = Core
Core.MAX_TABS = 16
Core.MAX_SCRIPTS = 64
Core.MAX_SOURCE = 1024 * 1024
Core.DEFAULT_SOURCE = '-- Delta PC | Xeno frontend\n-- Paste your Luau below, then click Execute.\n\nprint("Delta PC is ready")'

local function trim(value)
    return (string.gsub(string.gsub(value, "^%s+", ""), "%s+$", ""))
end

local function titleOf(value: any): string?
    if type(value) ~= "string" then return nil end
    value = trim(string.gsub(value, "[%c]", " "))
    if value == "" or #value > 96 then return nil end
    return value
end

local function validSource(value)
    return type(value) == "string" and #value <= Core.MAX_SOURCE
end

local function setting(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value then return fallback end
    return math.clamp(value, minimum, maximum)
end

local function errorText(value)
    local ok, text = pcall(tostring, value)
    return if ok then text else "Unknown error"
end

function Core.new(snapshot)
    local self = setmetatable({
        tabs = {}, library = {}, activeId = 0, nextId = 1,
        settings = { scale = 1, transparency = 0.12 },
    }, Core)
    if type(snapshot) == "table" and snapshot.version == 1 then
        if type(snapshot.tabs) == "table" then
            for index = 1, math.min(#snapshot.tabs, Core.MAX_TABS) do
                local tab = snapshot.tabs[index]
                if type(tab) == "table" and titleOf(tab.title) and validSource(tab.source) then
                    self:addTab(titleOf(tab.title), tab.source)
                end
            end
        end
        if #self.tabs > 0 then
            local selected = math.floor(setting(snapshot.activeIndex, 1, 1, #self.tabs))
            self.activeId = self.tabs[selected].id
        end
        if type(snapshot.library) == "table" then
            local titles = {}
            for index = 1, math.min(#snapshot.library, Core.MAX_SCRIPTS) do
                local item = snapshot.library[index]
                if type(item) == "table" and titleOf(item.title) and validSource(item.source) then
                    local title = titleOf(item.title)
                    if title and not titles[string.lower(title)] and trim(item.source) ~= "" then
                        self:saveScript(title, item.source)
                        titles[string.lower(title)] = true
                    end
                end
            end
        end
        if type(snapshot.settings) == "table" then
            self.settings.scale = setting(snapshot.settings.scale, 1, 0.75, 1)
            self.settings.transparency = setting(snapshot.settings.transparency, 0.12, 0, 0.4)
        end
    end
    if #self.tabs == 0 then self:addTab("New tab", Core.DEFAULT_SOURCE) end
    return self
end

function Core:active()
    for _, tab in self.tabs do
        if tab.id == self.activeId then return tab end
    end
    return self.tabs[1]
end

function Core:addTab(title, source)
    if #self.tabs >= Core.MAX_TABS then return nil, "Maximum of 16 tabs reached" end
    source = source or ""
    if not validSource(source) then return nil, "Script is too large" end
    local tab = { id = self.nextId, title = titleOf(title) or "New tab", source = source }
    self.nextId += 1
    table.insert(self.tabs, tab)
    self.activeId = tab.id
    return tab
end

function Core:select(id)
    for _, tab in self.tabs do
        if tab.id == id then self.activeId = id; return true end
    end
    return false
end

function Core:closeTab(id)
    for index, tab in self.tabs do
        if tab.id == id then
            table.remove(self.tabs, index)
            if #self.tabs == 0 then
                self:addTab("New tab", "")
            elseif self.activeId == id then
                self.activeId = self.tabs[math.min(index, #self.tabs)].id
            end
            return true
        end
    end
    return false
end

function Core:setSource(source)
    if not validSource(source) then return false, "Script exceeds the 1 MiB limit" end
    self:active().source = source
    return true
end

function Core:renameActive(title)
    title = titleOf(title)
    if not title then return false, "Use a name between 1 and 96 bytes" end
    self:active().title = title
    return true
end

function Core:saveScript(title, source)
    local cleanTitle = titleOf(title)
    if not cleanTitle then return nil, "Enter a name between 1 and 96 bytes" end
    if not validSource(source) then return nil, "Script exceeds the 1 MiB limit" end
    if trim(source) == "" then return nil, "The editor is empty" end
    for _, item in self.library do
        if string.lower(item.title) == string.lower(cleanTitle) then
            item.title, item.source = cleanTitle, source
            return item, "updated"
        end
    end
    if #self.library >= Core.MAX_SCRIPTS then return nil, "Library is full (64 scripts)" end
    local item = { id = self.nextId, title = cleanTitle, source = source }
    self.nextId += 1
    table.insert(self.library, item)
    return item, "saved"
end

function Core:deleteScript(id)
    for index, item in self.library do
        if item.id == id then table.remove(self.library, index); return true end
    end
    return false
end

function Core:export()
    local snapshot = { version = 1, tabs = {}, library = {}, activeIndex = 1,
        settings = { scale = self.settings.scale, transparency = self.settings.transparency } }
    for index, tab in self.tabs do
        table.insert(snapshot.tabs, { title = tab.title, source = tab.source })
        if tab.id == self.activeId then snapshot.activeIndex = index end
    end
    for _, item in self.library do
        table.insert(snapshot.library, { title = item.title, source = item.source })
    end
    return snapshot
end

function Core.execute(compiler, source, chunkName)
    if not validSource(source) or trim(source) == "" then
        return { ok = false, phase = "input", message = "Paste a script into the editor first" }
    end
    if type(compiler) ~= "function" then
        return { ok = false, phase = "unavailable", message = "loadstring is unavailable. Run the menu through your executor." }
    end
    local compiled, fn, compileError = pcall(compiler, source, chunkName or "DeltaPC")
    if not compiled or type(fn) ~= "function" then
        return { ok = false, phase = "compile", message = errorText(if compiled then compileError or "Compiler returned no function" else fn) }
    end
    local ran, value = pcall(fn)
    if not ran then return { ok = false, phase = "runtime", message = errorText(value) } end
    return { ok = true, phase = "complete", value = value }
end

return Core
