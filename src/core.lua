-- Pure state for the captured Delta frontend. No executor or network side effects.
local Core = {}
Core.__index = Core
local defaults = {
    autoExecute = false, antiAfk = false, autoClose = true, console = true,
    fpsCap = '60 FPS', iconSize = 'Medium', iconShape = 'Squircle',
    iconColor = 'Blue', theme = 'Default',
}
local choices = {
    fpsCap = {'60 FPS', '120 FPS', 'Max FPS'}, iconSize = {'Small','Medium','Large'},
    iconShape = {'Circle','Squircle','Square'}, iconColor = {'Blue','Green','Purple'},
    theme = {'Default','Light','Amoled'},
}
local function trim(s) return type(s)=='string' and s:match('^%s*(.-)%s*$') or '' end
local function finite(n) return type(n)=='number' and n==n and n>-math.huge and n<math.huge end
local function validSetting(k,v)
    if type(defaults[k])=='boolean' then return type(v)=='boolean' end
    for _,value in ipairs(choices[k] or {}) do if value==v then return true end end
    return false
end
function Core.new(keyed, saved, key)
    local self = setmetatable({locked=keyed==true, opened=false, page='Executor',
        tabs={}, saved={}, settings={}, logs={roblox={},runtime={}}, nextId=0,
        key=type(key)=='string' and key~='' and key or 'CHATGPT-MADE-THIS'},Core)
    for k,v in pairs(defaults) do self.settings[k]=v end
    saved=type(saved)=='table' and saved or {}
    if type(saved.settings)=='table' then
        for k,v in pairs(saved.settings) do if validSetting(k,v) then self.settings[k]=v end end
    end
    local activeIndex=1
    for i,t in ipairs(type(saved.tabs)=='table' and saved.tabs or {}) do
        if i>30 then break end
        if type(t)=='table' and type(t.source)=='string' and type(t.title)=='string' then
            self:addTab(t.title,t.source:sub(1,2000000))
            if t.id==saved.activeTab then activeIndex=#self.tabs end
        end
    end
    if #self.tabs==0 then self:addTab('script1.lua','') end
    self.activeTab=self.tabs[activeIndex].id
    for i,t in ipairs(type(saved.saved)=='table' and saved.saved or {}) do
        if i>200 then break end
        if type(t)=='table' and type(t.source)=='string' and type(t.title)=='string' then
            self:saveScript(t.title,t.source:sub(1,2000000),t.autoExecute==true)
        end
    end
    if type(saved.launcher)=='table' and finite(saved.launcher.x) and finite(saved.launcher.y) then
        self.launcher={x=math.max(0,math.min(1,saved.launcher.x)),y=math.max(0,math.min(1,saved.launcher.y))}
    end
    return self
end
function Core:id() self.nextId=self.nextId+1;return self.nextId end
function Core:open()
    if self.locked then return 'key' end
    self.opened=true;return 'main'
end
function Core:hide() self.opened=false end
function Core:unlock(key)
    if trim(key)~=self.key then return false end
    self.locked=false;return true
end
function Core:addTab(title, source)
    if #self.tabs>=30 then return nil,'Close a tab first (30-tab limit).' end
    local t={id=self:id(),title=trim(title):sub(1,80),source=type(source)=='string' and source or ''}
    if t.title=='' then t.title='script'..t.id..'.lua' end
    table.insert(self.tabs,t);self.activeTab=t.id;return t.id
end
function Core:currentTab()
    for _,t in ipairs(self.tabs) do if t.id==self.activeTab then return t end end
    return self.tabs[1]
end
function Core:selectTab(id)
    for _,t in ipairs(self.tabs) do if t.id==id then self.activeTab=id;return true end end
    return false
end
function Core:updateSource(source) self:currentTab().source=tostring(source or '') end
function Core:removeTab(id)
    for i,t in ipairs(self.tabs) do
        if t.id==id then
            table.remove(self.tabs,i)
            if #self.tabs==0 then self:addTab('script1.lua','')
            elseif self.activeTab==id then self.activeTab=self.tabs[math.min(i,#self.tabs)].id end
            return true
        end
    end
    return false
end
function Core:saveScript(title,source,autoExecute)
    title=trim(title):sub(1,100)
    if title=='' or trim(source)=='' then return nil,'Enter a title and script.' end
    if #source>2000000 then return nil,'Script exceeds 2 MB.' end
    if #self.saved>=200 then return nil,'Saved script limit reached (200).' end
    local item={id=self:id(),title=title,source=source,autoExecute=autoExecute==true}
    table.insert(self.saved,item);return item
end
function Core:deleteScript(id)
    for i,t in ipairs(self.saved) do if t.id==id then table.remove(self.saved,i);return true end end
    return false
end
function Core:filterSaved(query)
    local result={};query=trim(query):lower()
    for _,t in ipairs(self.saved) do if t.title:lower():find(query,1,true) then table.insert(result,t) end end
    return result
end
function Core:setSetting(k,v)
    if not validSetting(k,v) then return false end
    self.settings[k]=v;return true
end
function Core:log(level,text,channel)
    local list=self.logs[channel or 'runtime']
    if not list then return end
    table.insert(list,{level=tostring(level),text=tostring(text):sub(1,5000),time=os.date('%H:%M:%S')})
    if #list>400 then table.remove(list,1) end
end
function Core:snapshot()
    local result={version=2,tabs={},saved={},settings={},activeTab=self.activeTab,launcher=self.launcher}
    for _,t in ipairs(self.tabs) do table.insert(result.tabs,{id=t.id,title=t.title,source=t.source}) end
    for _,s in ipairs(self.saved) do table.insert(result.saved,{id=s.id,title=s.title,source=s.source,autoExecute=s.autoExecute}) end
    for k,v in pairs(self.settings) do result.settings[k]=v end
    return result
end
function Core.clampPosition(x,y,size,width,height)
    local px=width>=size+16 and 8 or 0
    local py=height>=size+16 and 8 or 0
    return math.max(px,math.min(x,math.max(px,width-size-px))),
        math.max(py,math.min(y,math.max(py,height-size-py)))
end
function Core.wasDragged(dx,dy) return dx*dx+dy*dy>36 end
return Core
