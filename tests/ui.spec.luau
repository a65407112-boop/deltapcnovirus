-- Headless Roblox API adapter. Runs the actual bundled menu and fires its
-- input signals. This does not test live Roblox rendering or Xeno injection.
local function signal()
    local listeners = {}
    return {
        Connect = function(_, fn)
            local connection = { Connected = true }
            connection.Disconnect = function(self) self.Connected = false end
            table.insert(listeners,{ fn = fn, connection = connection })
            return connection
        end,
        Fire = function(_, ...)
            local snapshot = table.clone(listeners)
            for _, item in snapshot do if item.connection.Connected then item.fn(...) end end
        end,
        Count = function()
            local count = 0
            for _, item in listeners do if item.connection.Connected then count += 1 end end
            return count
        end,
    }
end
local function vector(x,y) return { X=x,Y=y } end
local function dim(scale,offset) return { Scale=scale,Offset=offset } end
local function size(xs,xo,ys,yo) return { X=dim(xs,xo),Y=dim(ys,yo) } end
local objects = {}
local methods, meta = {}, {}
local function make(className)
    local object = setmetatable({ _class = className, _props = { Name=className,Visible=true,
        Text="",Size=size(0,100,0,100),TextSize=14 }, _children={},_signals={},_destroyed=false },meta)
    table.insert(objects,object)
    return object
end
function methods:GetPropertyChangedSignal(name)
    local key = "Property:"..name
    if not self._signals[key] then self._signals[key] = signal() end
    return self._signals[key]
end
function methods:GetChildren() return table.clone(self._children) end
function methods:FindFirstChild(name)
    for _, child in self._children do if child.Name == name then return child end end
end
function methods:FindFirstChildOfClass(name)
    for _, child in self._children do if child._class == name then return child end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name.." not found") end
function methods:CaptureFocus() self._focused = true end
function methods:ReleaseFocus() self._focused = false end
function methods:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self._signals.Destroying then self._signals.Destroying:Fire() end
    for _, child in self:GetChildren() do child:Destroy() end
    self.Parent = nil
end
meta.__index = function(self,key)
    if methods[key] then return methods[key] end
    if key == "AbsoluteSize" then
        if self._class == "ScreenGui" then return vector(1920,1080) end
        local parentSize = if self.Parent then self.Parent.AbsoluteSize else vector(1920,1080)
        local value = self._props.Size
        return vector(parentSize.X*value.X.Scale+value.X.Offset,parentSize.Y*value.Y.Scale+value.Y.Offset)
    elseif key == "TextBounds" then
        local count,longest = 0,0
        for single in string.gmatch(self.Text.."\n","(.-)\n") do count+=1; longest=math.max(longest,#single) end
        return vector(longest*self.TextSize*.6,count*self.TextSize*1.2)
    elseif key == "Activated" or key == "Destroying" then
        if not self._signals[key] then self._signals[key] = signal() end
        return self._signals[key]
    end
    if self._props[key] ~= nil then return self._props[key] end
    return self:FindFirstChild(key)
end
meta.__newindex = function(self,key,value)
    if string.sub(key,1,1)=="_" then rawset(self,key,value); return end
    local old = self._props[key]
    if key == "Parent" then
        if old then
            local index = table.find(old._children,self)
            if index then table.remove(old._children,index) end
        end
        if value then table.insert(value._children,self) end
    end
    self._props[key] = value
    if old ~= value and self._signals["Property:"..key] then self._signals["Property:"..key]:Fire() end
end
local services = {}
services.UserInputService = { InputBegan=signal() }
services.RunService = { Heartbeat=signal() }
services.LogService = { MessageOut=signal() }
services.Workspace = make("Workspace")
services.Workspace.CurrentCamera = make("Camera")
services.Workspace.CurrentCamera.ViewportSize = vector(1920,1080)
services.Stats = {Network={ServerStatsItem={["Data Ping"]={GetValue=function() return 42 end}}}}
local player = make("Player")
player.Name,player.DisplayName,player.UserId = "TestPlayer","Test Player",123
local playerGui = make("PlayerGui"); playerGui.Parent = player
services.Players = { LocalPlayer=player }
local coreGui = make("CoreGui")
local encoded,storage,queue = {},{},{}
local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}; for key,item in value do copy[key] = clone(item) end
    return copy
end
services.HttpService = {
    JSONEncode=function(_,value)
        local token="json:"..tostring(#encoded+1)
        table.insert(encoded,clone(value)); return token
    end,
    JSONDecode=function(_,text)
        local index = tonumber(string.match(text,"^json:(%d+)$"))
        if not index or not encoded[index] then error("Invalid JSON") end
        return clone(encoded[index])
    end,
}
local env = {}
local enum = setmetatable({}, {__index=function(self,key)
    local group=setmetatable({}, {__index=function(_,name) return key.."."..name end})
    rawset(self,key,group); return group
end})
local scriptEnvironment = setmetatable({
    game={GetService=function(_,name) return assert(services[name],name) end},
    Instance={new=make},
    UDim={new=dim},UDim2={new=size,fromOffset=function(x,y) return size(0,x,0,y) end,
        fromScale=function(x,y) return size(x,0,y,0) end},
    Vector2={new=vector},Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end},
    Enum=enum,getgenv=function() return env end,
    task={
        spawn=function(fn) fn() end,defer=function(fn) fn() end,
        delay=function(_,fn) table.insert(queue,fn) end,
    },
    print=function(...)
        local parts={}; for _,v in {...} do table.insert(parts,tostring(v)) end
        services.LogService.MessageOut:Fire(table.concat(parts,"\t"),enum.MessageType.MessageOutput)
    end,
}, {__index=getfenv(0)})
scriptEnvironment.getfenv = function() return scriptEnvironment end
env.gethui = function() return coreGui end
env.readfile = function(path) return assert(storage[path],"File not found") end
env.writefile = function(path,data) storage[path]=data end
local compileCalls = 0
env.loadstring = function(source,name)
    compileCalls += 1
    local fn,err = loadstring(source,name)
    if fn then setfenv(fn,scriptEnvironment) end
    return fn,err
end

local function launch()
-- BUNDLE_PLACEHOLDER
end
setfenv(launch,scriptEnvironment)

local function find(name)
    for index=#objects,1,-1 do
        local object=objects[index]
        if not object._destroyed and object.Name == name then return object end
    end
    error("UI object not found: "..name,2)
end
local function click(name) find(name).Activated:Fire() end
local function flush()
    local callbacks=queue; queue={}
    for _,fn in callbacks do fn() end
    services.RunService.Heartbeat:Fire(1)
end
local count=0
local function check(name,fn)
    local ok,err=pcall(fn)
    if not ok then error(name..": "..tostring(err),0) end
    count+=1; print("PASS "..name)
end
local function contains(text,part) return string.find(text,part,1,true) ~= nil end
local controller

check("menu opens directly with working executor and no key prompt",function()
    controller=launch()
    assert(find("Root").Visible)
    assert(controller.Gui.Parent == coreGui)
    assert(find("editorPage").Visible)
    find("EditorBox").Text = "deltaTestExecuted = 41 + 1; print('script output')"
    click("ExecuteButton")
    assert(scriptEnvironment.deltaTestExecuted == 42)
    assert(compileCalls == 1)
    click("ConsoleToggle"); flush()
    assert(contains(find("ConsoleText").Text,"script output"))
end)
check("tab clicks preserve each tab's text and closing selects another",function()
    local original=controller.Model:active().id
    click("NewTabButton")
    local second=controller.Model:active().id
    find("EditorBox").Text="return 'second'"
    click("Tab_"..original)
    assert(contains(find("EditorBox").Text,"deltaTestExecuted"))
    click("Tab_"..second)
    assert(find("EditorBox").Text == "return 'second'")
    click("CloseTab_"..second)
    assert(controller.Model:active().id == original)
end)
check("manual clipboard fallback inserts exactly the pasted text",function()
    click("PasteButton")
    assert(find("ModalOverlay").Visible)
    find("DialogInput").Text="manualPasteWorked = true"
    click("DialogConfirm")
    assert(find("EditorBox").Text == "manualPasteWorked = true")
    assert(not find("ModalOverlay").Visible)
    click("ExecuteButton")
    assert(scriptEnvironment.manualPasteWorked)
    click("ExecuteClipboardButton")
    find("DialogInput").Text="clipboardExecutionWorked = true"
    click("DialogConfirm")
    assert(scriptEnvironment.clipboardExecutionWorked)
end)
check("save, filter, open and run use real library content",function()
    find("EditorBox").Text="libraryRunCount = (libraryRunCount or 0) + 1"
    click("SaveButton")
    find("DialogInput").Text="Saved script"
    click("DialogConfirm")
    assert(#controller.Model.library==1)
    local saved=controller.Model.library[1]
    click("Nav_library")
    click("LibraryRun_"..saved.id)
    assert(scriptEnvironment.libraryRunCount==1)
    find("LibrarySearch").Text="missing"
    assert(#find("LibraryList"):GetChildren()==1)
    find("LibrarySearch").Text="saved"
    click("LibraryOpen_"..saved.id)
    assert(controller.Model:active().title=="Saved script")
    assert(find("editorPage").Visible)
    flush()
    assert(storage["deltapc_state.json"])
end)
check("compile and runtime failures appear in the console",function()
    find("EditorBox").Text="local = invalid syntax"
    click("ExecuteButton"); flush()
    assert(contains(find("StatusLabel").Text,"compile:"))
    assert(find("ConsoleDrawer").Visible)
    find("EditorBox").Text="error('intentional failure',0)"
    click("ExecuteButton"); flush()
    assert(contains(find("ConsoleText").Text,"intentional failure"))
    assert(contains(find("StatusLabel").Text,"runtime:"))
end)
check("hide, reopen and keyboard shortcut stay usable",function()
    click("HideMenu")
    assert(not find("Root").Visible and find("ReopenMenu").Visible)
    click("ReopenMenu")
    assert(find("Root").Visible)
    services.UserInputService.InputBegan:Fire({KeyCode=enum.KeyCode.RightControl},false)
    assert(not find("Root").Visible)
    services.UserInputService.InputBegan:Fire({KeyCode=enum.KeyCode.RightControl},false)
    assert(find("Root").Visible)
end)
check("rerunning retains current tabs and disconnects the old session",function()
    find("EditorBox").Text="latestUnsavedText = true"
    local old=controller
    local listeners=services.RunService.Heartbeat:Count()
    controller=launch()
    assert(old.Gui._destroyed)
    assert(find("EditorBox").Text=="latestUnsavedText = true")
    assert(services.RunService.Heartbeat:Count()==listeners)
    assert(services.LogService.MessageOut:Count()==1)
    local aliveScreens=0
    for _,object in objects do
        if object._class=="ScreenGui" and not object._destroyed then aliveScreens+=1 end
    end
    assert(aliveScreens==1)
end)
check("console cap and live counters use real signals",function()
    for index=1,250 do services.LogService.MessageOut:Fire("message "..index,enum.MessageType.MessageOutput) end
    click("ConsoleToggle"); flush()
    local text=find("ConsoleText").Text
    assert(contains(text,"message 250"))
    assert(not contains(text,"message 1\n"))
    local lines=0; for _ in string.gmatch(text,"[^\n]+") do lines+=1 end
    assert(lines<=200)
    assert(find("PingChip"):FindFirstChild("Label").Text=="42 ms")
end)
check("settings and cleared text are saved and restored after destroy",function()
    click("Nav_settings"); click("ScaleDown"); click("TransparencyUp")
    assert(controller.Model.settings.scale < 1)
    click("Nav_editor"); click("ClearButton"); flush()
    assert(find("EditorBox").Text=="")
    controller.Destroy()
    assert(services.RunService.Heartbeat:Count()==0)
    controller=launch()
    assert(find("EditorBox").Text=="")
    assert(controller.Model.settings.scale < 1)
end)
check("direct clipboard capability and file errors degrade safely",function()
    controller.Destroy()
    env.getclipboard=function() return "directClipboardWorked = true" end
    env.writefile=function() error("disk unavailable",0) end
    controller=launch()
    click("PasteButton")
    assert(find("EditorBox").Text=="directClipboardWorked = true")
    assert(not find("ModalOverlay").Visible)
    click("ExecuteClipboardButton")
    assert(scriptEnvironment.directClipboardWorked)
    flush()
    assert(contains(find("StatusLabel").Text,"Workspace save failed"))
    click("SaveButton"); find("DialogInput").Text="Retry saved script"; click("DialogConfirm")
    assert(contains(find("StatusLabel").Text,"to library"))
    assert(not contains(find("StatusLabel").Text,"in workspace"))
    flush()
    assert(contains(find("StatusLabel").Text,"Workspace save failed"))
end)
check("missing compiler and file capabilities still allow session editing",function()
    controller.Destroy()
    env.loadstring=false; scriptEnvironment.loadstring=false
    env.writefile=false; env.readfile=false
    env.getclipboard=false
    env.gethui=function() error("CoreGui unavailable",0) end
    controller=launch()
    assert(controller.Gui.Parent==playerGui)
    assert(contains(find("StatusLabel").Text,"loadstring unavailable"))
    find("EditorBox").Text="return 42"
    click("ExecuteButton")
    assert(contains(find("StatusLabel").Text,"unavailable:"))
    click("SaveButton"); find("DialogInput").Text="Session script"; click("DialogConfirm")
    assert(#controller.Model.library==1)
    assert(contains(find("StatusLabel").Text,"for this session"))
    controller=launch()
    assert(controller.Model.library[1].title=="Session script")
    click("Nav_library")
    click("LibraryDelete_"..controller.Model.library[1].id)
    assert(#controller.Model.library==0)
    flush()
end)
controller.Destroy()
assert(services.RunService.Heartbeat:Count()==0)
assert(services.LogService.MessageOut:Count()==0)
assert(services.UserInputService.InputBegan:Count()==0)
print(string.format("%d UI integration tests passed",count))
