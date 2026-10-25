-- Engine boundary double. It does not simulate Roblox rendering or native execution.
Mock={signals={},queue={},services={},files={},folders={},http={},focused=nil,keys={}}
local function signal(canFire)
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true,fn=fn}
        function c:Disconnect() self.Connected=false;self.fn=nil end
        table.insert(self.listeners,c);return c
    end
    function s:Fire(...)
        if canFire and not canFire() then return end
        local current={table.unpack(self.listeners)}
        for _,c in ipairs(current) do if c.Connected then c.fn(...) end end
    end
    table.insert(Mock.signals,s);return s
end
function Mock.liveConnections()
    local n=0;for _,s in ipairs(Mock.signals) do for _,c in ipairs(s.listeners) do if c.Connected then n=n+1 end end end
    return n
end
local vmt={}
function vmt.__sub(a,b) return Vector2.new(a.X-b.X,a.Y-b.Y) end
function vmt.__add(a,b) return Vector2.new(a.X+b.X,a.Y+b.Y) end
function vmt.__mul(a,b) return Vector2.new(a.X*b,a.Y*b) end
Vector2={new=function(x,y) return setmetatable({X=x or 0,Y=y or 0},vmt) end}
Vector3={new=function(x,y,z) return {X=x or 0,Y=y or 0,Z=z or 0} end}
UDim={new=function(s,o) return {Scale=s or 0,Offset=o or 0} end}
UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end}
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
Color3={new=function(r,g,b) return {R=r,G=g,B=b} end}
Color3.fromRGB=function(r,g,b) return Color3.new(r/255,g/255,b/255) end
Rect={new=function(x,y,w,h) return {Min=Vector2.new(x,y),Max=Vector2.new(w,h)} end}
Font={new=function(family,weight,style) return {Family=family,Weight=weight,Style=style} end}
local categories={}
for name in ('AutomaticSize ZIndexBehavior FontWeight FontStyle Font TextXAlignment TextYAlignment TextTruncate TextDirection BorderMode SizeConstraint ScaleType ResamplerMode FillDirection HorizontalAlignment VerticalAlignment SortOrder AspectType DominantAxis ApplyStrokeMode LineJoinMode ElasticBehavior ScrollBarInset VerticalScrollBarPosition ScrollingDirection ScreenInsets SafeAreaCompatibility UIFlexAlignment ItemLineAlignment StartCorner UserInputType KeyCode MessageType TeleportState'):gmatch('%S+') do categories[name]=true end
local maps={AutomaticSize={None=0,X=1,Y=2,XY=3},UserInputType={MouseButton1=0,Touch=7,MouseMovement=4},
    KeyCode={RightShift=303,LeftControl=306,RightControl=305,Return=13,Escape=27},
    MessageType={MessageOutput=0,MessageInfo=1,MessageWarning=2,MessageError=3}}
Enum=setmetatable({},{__index=function(t,name)
    assert(categories[name],'Unknown Roblox enum category: '..name)
    local values,named={},{}
    local cat=setmetatable({},{__index=function(_,key)
        if key=='GetEnumItems' then return function()
            local list={};for i=0,1000 do
                if not values[i] then values[i]={Name=tostring(i),Value=i,EnumType=name} end
                list[#list+1]=values[i]
            end;return list
        end end
        assert(key~='FromValue','Enum.FromValue is not a Roblox API')
        if not named[key] then
            local value=(maps[name] or {})[key]
            if value then
                values[value]=values[value] or {Name=key,Value=value,EnumType=name};named[key]=values[value]
            else named[key]={Name=key,Value=2000+#named,EnumType=name} end
        end
        return named[key]
    end})
    rawset(t,name,cat);return cat
end})
local kinds={GuiObject={'Frame','TextLabel','TextBox','TextButton','ImageButton','ImageLabel','ScrollingFrame'},
    GuiButton={'TextButton','ImageButton'}}
local eventNames={Activated=true,MouseButton2Click=true,InputBegan=true,InputChanged=true,InputEnded=true,FocusLost=true,Destroying=true,Changed=true,ChildAdded=true}
local methods={}
function methods:IsA(kind)
    if kind=='Instance' or kind==self.ClassName then return true end
    for _,v in ipairs(kinds[kind] or {}) do if v==self.ClassName then return true end end
    return false
end
function methods:GetChildren() return {table.unpack(self._children)} end
function methods:GetDescendants()
    local out={};local function walk(n) for _,c in ipairs(n._children) do out[#out+1]=c;walk(c) end end
    walk(self);return out
end
function methods:FindFirstChild(name,recursive)
    for _,c in ipairs(self._children) do if c.Name==name then return c end end
    if recursive then for _,c in ipairs(self._children) do local hit=c:FindFirstChild(name,true);if hit then return hit end end end
end
function methods:FindFirstChildOfClass(class)
    for _,c in ipairs(self._children) do if c.ClassName==class then return c end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),'Missing child '..name) end
function methods:GetPropertyChangedSignal(key)
    self._signals[key]=self._signals[key] or signal();return self._signals[key]
end
function methods:Destroy()
    for _,c in ipairs(self:GetChildren()) do c:Destroy() end
    self.Parent=nil;self._destroyed=true
    for _,s in pairs(self._signals) do for _,c in ipairs(s.listeners) do c:Disconnect() end end
    for _,s in pairs(self._events) do for _,c in ipairs(s.listeners) do c:Disconnect() end end
end
function methods:CaptureFocus() Mock.focused=self end
function methods:ReleaseFocus() Mock.focused=nil end
function methods:SetAttribute(k,v) self._attributes[k]=v end
function methods:GetAttribute(k) return self._attributes[k] end
function methods:Clone()
    local copy=Instance.new(self.ClassName)
    for k,v in pairs(self._props) do if k~='Parent' then copy[k]=v end end
    for k,v in pairs(self._attributes) do copy:SetAttribute(k,v) end
    for _,child in ipairs(self:GetChildren()) do child:Clone().Parent=copy end
    return copy
end
local function absoluteSize(n)
    if n.ClassName=='ScreenGui' then return Vector2.new(1280,720) end
    local p=n.Parent and n.Parent.AbsoluteSize or Vector2.new(1280,720)
    local size=n._props.Size or UDim2.new()
    return Vector2.new(size.X.Scale*p.X+size.X.Offset,size.Y.Scale*p.Y+size.Y.Offset)
end
local mt={__index=function(n,k)
    if methods[k] then return methods[k] end
    if k=='AbsoluteSize' then return absoluteSize(n) end
    if k=='AbsolutePosition' then
        local p=n.Parent;local pos=n._props.Position or UDim2.new();local anchor=n._props.AnchorPoint or Vector2.new()
        local parentPos=p and p.AbsolutePosition or Vector2.new();local size=p and p.AbsoluteSize or Vector2.new(1280,720)
        local own=n.AbsoluteSize
        return Vector2.new(parentPos.X+pos.X.Scale*size.X+pos.X.Offset-anchor.X*own.X,
            parentPos.Y+pos.Y.Scale*size.Y+pos.Y.Offset-anchor.Y*own.Y)
    end
    if eventNames[k] then
        if not n._events[k] then
            n._events[k]=signal(k=='Activated' and function() return n.Active==true and n.Interactable~=false end or nil)
        end
        return n._events[k]
    end
    if n._props[k]~=nil then return n._props[k] end
    return methods.FindFirstChild(n,k)
end,__newindex=function(n,k,v)
    if k:sub(1,1)=='_' then rawset(n,k,v);return end
    if k=='Parent' then
        local old=n._props.Parent
        if old then for i,c in ipairs(old._children) do if c==n then table.remove(old._children,i);break end end end
        n._props.Parent=v
        if v then table.insert(v._children,n);if v._events.ChildAdded then v._events.ChildAdded:Fire(n) end end
    else
        local old=n._props[k];n._props[k]=v
        if old~=v and n._signals[k] then n._signals[k]:Fire() end
    end
end}
Instance={new=function(kind,parent)
    local n=setmetatable({_props={ClassName=kind,Name=kind,Text='',Visible=true,Active=kind=='TextButton' or kind=='ImageButton',Size=UDim2.new(),
        Position=UDim2.new(),AnchorPoint=Vector2.new(),ZIndex=1,BackgroundTransparency=0},
        _signals={},_events={},_children={},_attributes={}},mt)
    if parent then n.Parent=parent end
    return n
end}
local function queue(fn)
    local h={fn=fn};table.insert(Mock.queue,h);return h
end
task={spawn=function(fn,...) fn(...);return {} end,defer=queue,delay=function(_,fn) return queue(fn) end,
    cancel=function(h) h.cancelled=true end,wait=function() end}
function Mock.flush()
    local loops=0
    while #Mock.queue>0 do
        loops=loops+1;assert(loops<1000,'Scheduler did not settle')
        local q=Mock.queue;Mock.queue={}
        for _,h in ipairs(q) do if not h.cancelled then h.fn() end end
    end
end
local player=Instance.new('Player');player.Name='Tester';player.Idled=signal()
player.OnTeleport=signal()
Instance.new('PlayerGui',player)
player.GetNetworkPing=function() return .03 end
Mock.services.Players={LocalPlayer=player,GetPlayers=function() return {player} end}
Mock.services.UserInputService={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),
    GetFocusedTextBox=function() return Mock.focused end,IsKeyDown=function(_,key) return Mock.keys[key]==true end}
Mock.services.RunService={RenderStepped=signal()}
Mock.services.LogService={MessageOut=signal()}
Mock.services.CoreGui=Instance.new('ScreenGui')
Mock.services.TextService={GetTextSize=function(_,s,size) return Vector2.new(#s*size/2,size) end}
Mock.services.TeleportService={Teleport=function(_,...) Mock.teleport={...} end,TeleportToPlaceInstance=function(_,...) Mock.teleport={...} end}
Mock.services.VirtualUser={CaptureController=function() end,ClickButton2=function() Mock.idleClicks=(Mock.idleClicks or 0)+1 end}
local jsonValues,nextJson={},0
Mock.services.HttpService={
    JSONEncode=function(_,value) nextJson=nextJson+1;local id='json'..nextJson;jsonValues[id]=value;return id end,
    JSONDecode=function(_,value) assert(jsonValues[value],'Malformed JSON fixture');return jsonValues[value] end,
    UrlEncode=function(_,value) return (value:gsub('[^%w%-_%.~]',function(c) return string.format('%%%02X',string.byte(c)) end)) end,
}
function Mock.json(value) return Mock.services.HttpService:JSONEncode(value) end
game={PlaceId=123,JobId='current',GetService=function(_,name) return assert(Mock.services[name],'Unknown service '..name) end,
    IsLoaded=function() return true end,
    HttpGet=function(_,url)
        Mock.lastUrl=url;Mock.requests=Mock.requests or {};Mock.requests[#Mock.requests+1]=url
        local result=Mock.http[url]
        if result~=nil then assert(result~=false,'HTTP unavailable: '..url);return result end
        local name=url:match('^https://raw%.githubusercontent%.com/a65407112%-boop/deltapcnovirus/main/assets/([%w%.]+)$')
        if name then local file=assert(io.open('assets/'..name,'rb'));result=file:read('*a');file:close();return result end
        error('HTTP unavailable: '..url)
    end}
workspace=Instance.new('Workspace');workspace.CurrentCamera=Instance.new('Camera');workspace.CurrentCamera.ViewportSize=Vector2.new(1280,720)
loadstring=load
getgenv=function() return _G end
writefile=function(path,value)
    local parent=path:match('^(.*)/[^/]+$')
    assert(not parent or Mock.folders[parent],'Directory does not exist: '..tostring(parent))
    Mock.files[path]=value
end
readfile=function(path) return assert(Mock.files[path],'File not found') end
makefolder=function(path) Mock.folders[path]=true end
getcustomasset=function(path) assert(Mock.files[path],'Missing local asset');return 'rbxasset://mock/'..path end
getclipboard=function() return Mock.clipboard or '' end
setclipboard=function(text) Mock.clipboard=text end
setfpscap=function(fps) Mock.fps=fps end
warn=function(text) Mock.warning=text end
