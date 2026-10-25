-- Behavior for the supplied Delta GUI. Core, Assets and Skin are bundled by tools/build.py.
return function(config)
    config=type(config)=='table' and config or {}
    local env=(type(getfenv)=='function' and getfenv()) or _G
    local shared=(type(getgenv)=='function' and getgenv()) or _G
    local function api(name) return env[name] or shared[name] end
    local function httpGet(url)
        local requestFn=api('request') or api('http_request')
        local synApi=api('syn');local httpApi=api('http')
        if type(requestFn)~='function' and type(synApi)=='table' then requestFn=synApi.request end
        if type(requestFn)~='function' and type(httpApi)=='table' then requestFn=httpApi.request end
        if type(requestFn)=='function' then
            local response=requestFn({Url=url,Method='GET',Headers={Accept='*/*'},Timeout=20})
            assert(type(response)=='table','HTTP response is not a table')
            local code=tonumber(response.StatusCode or response.Status)
            assert(not code or (code>=200 and code<300),'HTTP '..tostring(code))
            assert(response.Success~=false and type(response.Body)=='string','Empty HTTP response')
            return response.Body
        end
        local body=game:HttpGet(url)
        assert(type(body)=='string' and #body>0,'Empty HTTP response');return body
    end
    local asset=Assets(api,httpGet,shared)
    local previous=shared.__DeltaPC
    if type(previous)=='table' and type(previous.close)=='function' then pcall(previous.close) end
    local Services={}
    for _,name in ipairs({'Players','UserInputService','RunService','HttpService','LogService','TeleportService','TextService'}) do
        Services[name]=game:GetService(name)
    end
    local Players,Input,Run,Http=Services.Players,Services.UserInputService,Services.RunService,Services.HttpService
    local player=Players.LocalPlayer
    assert(player,'Run Delta PC after joining a Roblox experience.')
    local options=type(shared.DeltaPCConfig)=='table' and shared.DeltaPCConfig or {}
    local diskPath='DeltaPC/state-v2.json'
    local stored
    if type(api('readfile'))=='function' then
        local ok,data=pcall(function() return Http:JSONDecode(api('readfile')(diskPath)) end)
        if ok and type(data)=='table' then stored=data end
    end
    local state=Core.new(config.keyed,stored,options.Key)
    local nodes,propertyFailures=Skin(asset)
    local gui=nodes[0]
    gui.Name='DeltaPC';gui.ResetOnSpawn=false;gui.DisplayOrder=1000
    gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    pcall(function() gui.ScreenInsets=Enum.ScreenInsets.None end)
    local ui={gui=gui,nodes=nodes,state=state,destroyed=false,propertyFailures=propertyFailures,
        placeId=game.PlaceId,jobId=game.JobId}
    local connections,tasks={},{}
    local function connect(signal,callback)
        local c=signal:Connect(function(...) if not ui.destroyed then return callback(...) end end)
        table.insert(connections,c);return c
    end
    local function spawn(callback)
        -- task.defer ensures the handle is recorded before any work can complete.
        local handle
        handle=task.defer(function()
            if not ui.destroyed then
                local ok,err=pcall(callback)
                if not ok and not ui.destroyed then warn('[Delta PC] '..tostring(err)) end
            end
            if handle then tasks[handle]=nil end
        end)
        tasks[handle]=true;return handle
    end
    local function later(seconds,callback)
        local handle
        handle=task.delay(seconds,function()
            if handle then tasks[handle]=nil end
            if not ui.destroyed then callback() end
        end)
        tasks[handle]=true;return handle
    end
    local colors={bg=Color3.fromRGB(24,25,33),panel=Color3.fromRGB(38,41,50),
        field=Color3.fromRGB(29,31,40),text=Color3.fromRGB(235,239,248),
        muted=Color3.fromRGB(149,160,182),accent=Color3.fromRGB(34,160,255),
        error=Color3.fromRGB(255,117,128),good=Color3.fromRGB(111,220,167)}
    local function make(kind,parent,props)
        local object=Instance.new(kind)
        for key,value in pairs(props or {}) do object[key]=value end
        object.Parent=parent;return object
    end
    local function round(object,radius)
        local corner=object:FindFirstChildOfClass('UICorner') or make('UICorner',object,{})
        corner.CornerRadius=UDim.new(0,radius or 8);return corner
    end
    local function label(parent,text,props)
        local object=make('TextLabel',parent,{Name='Label',BackgroundTransparency=1,BorderSizePixel=0,
            Text=text,TextSize=14,TextColor3=colors.text,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromScale(1,1),ZIndex=5})
        for key,value in pairs(props or {}) do object[key]=value end
        return object
    end
    local function button(parent,text,props,callback)
        local object=make('TextButton',parent,{Name=text,BackgroundColor3=colors.field,BorderSizePixel=0,
            Text=text,TextColor3=colors.text,TextSize=12,Font=Enum.Font.GothamMedium,
            AutoButtonColor=true,Active=true,Size=UDim2.fromOffset(90,32),ZIndex=6})
        for key,value in pairs(props or {}) do object[key]=value end
        round(object,6)
        if callback then connect(object.Activated,callback) end
        return object
    end
    local function bind(object,callback)
        object.Active=true;object.AutoButtonColor=true
        pcall(function() object.Interactable=true end)
        return connect(object.Activated,callback)
    end
    local function viewport()
        local camera=workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1280,720)
    end
    -- A transparent visibility group leaves the source geometry in viewport coordinates.
    local window=make('Frame',gui,{Name='CapturedUI',Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=10})
    local pages={Home=545,Executor=367,Scripthub=60,Settings=109,Console=645}
    for _,id in pairs(pages) do nodes[id].Parent=window;nodes[id].Visible=false end
    nodes[32].Parent=window;nodes[32].Visible=true
    nodes[366].Parent=window
    -- Dynamic entries are clones of the source templates, not separately designed controls.
    for id,node in pairs(nodes) do node:SetAttribute('DeltaNode',id) end
    local templateIds={68,426,667,421,556}
    for _,id in ipairs(templateIds) do nodes[id].Parent=nil end
    for _,id in ipairs({569,582,595,608,657,690}) do nodes[id]:Destroy() end
    local function cloneTemplate(id,parent)
        local object=nodes[id]:Clone();local parts={[id]=object}
        for _,child in ipairs(object:GetDescendants()) do
            local sourceId=child:GetAttribute('DeltaNode')
            if sourceId then parts[sourceId]=child end
        end
        object.Visible=true;object.Parent=parent
        return object,parts
    end
    local nav={{34,'Home'},{46,'Executor'},{38,'Scripthub'},
        {42,'Settings'},{50,'Console'},{54,'Close'}}
    local status={Text='Ready'} -- Internal feedback; the original GUI has no extra status bar.
    ui.status=status
    local renderLogs=function() end
    local toast=label(gui,'',{Name='Toast',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-20),
        Size=UDim2.fromOffset(600,42),BackgroundColor3=colors.panel,BackgroundTransparency=.05,
        TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=true,Visible=false,ZIndex=100})
    round(toast,10)
    local toastToken=0
    local function report(message,kind)
        if ui.destroyed then return end
        message=tostring(message)
        status.Text=message;status.TextColor3=kind=='Error' and colors.error or colors.muted
        state:log(kind or 'Info',message,'runtime');renderLogs('runtime')
        if kind=='Error' or not state.opened or state.page~='Executor' then
            toastToken=toastToken+1;local token=toastToken
            toast.Text=message:sub(1,220);toast.Visible=true
            later(5,function() if token==toastToken then toast.Visible=false end end)
        end
    end
    local savedToken=0
    local diskWarning=false
    local function persistNow()
        local write,folder=api('writefile'),api('makefolder')
        if type(write)~='function' then return false end
        local ok,err=pcall(function()
            if type(folder)=='function' then pcall(folder,'DeltaPC') end
            write(diskPath,Http:JSONEncode(state:snapshot()))
        end)
        if not ok and not diskWarning then diskWarning=true;report('Saving unavailable: '..tostring(err),'Error') end
        return ok
    end
    local function persist()
        savedToken=savedToken+1;local token=savedToken
        later(.6,function() if token==savedToken then persistNow() end end)
    end
    local function execute(source,title)
        if ui.destroyed or state.locked then return false end
        if type(source)~='string' or source:match('^%s*$') then report('The script is empty.','Error');return false end
        local compiler=api('loadstring') or loadstring
        if type(compiler)~='function' then report('Your executor does not provide loadstring.','Error');return false end
        local ok,chunk,reason=pcall(compiler,source,'@DeltaPC/'..tostring(title or 'editor'))
        if not ok or type(chunk)~='function' then
            report('Compile error: '..tostring(ok and reason or chunk),'Error');return false
        end
        report('Running '..tostring(title or 'script')..'...')
        -- User scripts own their lifetime. Destroying the frontend does not cancel them.
        task.spawn(function()
            local success,result=pcall(chunk)
            if ui.destroyed then return end
            if success then report('Completed '..tostring(title or 'script'))
            else report('Runtime error: '..tostring(result),'Error') end
        end)
        return true
    end
    ui.execute=execute
    local launcher=make('ImageButton',gui,{Name='DeltaLauncher',Size=UDim2.fromOffset(56,56),
        Position=UDim2.new(1,-78,.45,0),BackgroundColor3=colors.accent,BorderSizePixel=0,
        Image=asset('logo.png'),ScaleType=Enum.ScaleType.Fit,ZIndex=50})
    round(launcher,15);ui.launcher=launcher
    local keyPanel=nodes[1];keyPanel.Name='KeyPanel';keyPanel.Parent=gui
    -- The capture records the closed position (x=1.3). The open panel is right-aligned.
    keyPanel.Position=UDim2.fromScale(1,.5);keyPanel.Visible=false;keyPanel.ZIndex=40
    nodes[7].Text='Enter the local key to open this interface.'
    nodes[23].Text='Local key version'
    nodes[11].Text='';nodes[11].ClearTextOnFocus=false
    ui.keyPanel=keyPanel
    local activePopup,dropdown,copyPopup,copyShade
    local function closePopup()
        if activePopup then activePopup.Visible=false;activePopup=nil end
        nodes[621].Visible=false;nodes[81].Visible=false
        if dropdown then
            dropdown.Visible=false
            local row=dropdown.Parent
            if row then row.ZIndex=row:GetAttribute('RestingZ') or row.ZIndex end
            dropdown=nil
        end
        if copyPopup then copyPopup:Destroy();copyPopup=nil end
        if copyShade then copyShade:Destroy();copyShade=nil end
    end
    local function showPopup(popup)
        closePopup();activePopup=popup;popup.Visible=true
        nodes[popup==nodes[622] and 621 or 81].Visible=true
    end
    for _,id in ipairs({621,81}) do
        nodes[id].Active=true
        connect(nodes[id].InputBegan,function(input)
            if state.settings.autoClose and (input.UserInputType==Enum.UserInputType.MouseButton1
                or input.UserInputType==Enum.UserInputType.Touch) then closePopup() end
        end)
    end
    nodes[622].Visible=false;nodes[82].Visible=false
    local function copy(text)
        local clipboard=api('setclipboard') or api('toclipboard')
        if type(clipboard)=='function' then
            local ok,err=pcall(clipboard,text)
            if ok then report('Copied to clipboard.');return true end
            report('Clipboard error: '..tostring(err),'Error');return false
        end
        closePopup()
        copyShade=button(gui,'',{Name='CopyShade',Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),
            BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.4,ZIndex=85},closePopup)
        local p=make('Frame',gui,{Name='CopyText',AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(520,320),BackgroundColor3=colors.panel,
            BorderSizePixel=0,ZIndex=90});round(p,10)
        copyPopup=p
        local v=viewport();make('UIScale',p,{Scale=math.min(1,(v.X-24)/520,(v.Y-24)/320)})
        label(p,'Select text and press Ctrl+C',{Position=UDim2.fromOffset(20,12),Size=UDim2.new(1,-80,0,28)})
        local box=make('TextBox',p,{Name='Text',Position=UDim2.fromOffset(20,52),Size=UDim2.new(1,-40,1,-72),
            Text=text,ClearTextOnFocus=false,MultiLine=true,TextSize=14,Font=Enum.Font.Code,
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
            TextColor3=colors.text,BackgroundColor3=colors.field,BorderSizePixel=0,ZIndex=91})
        button(p,'×',{Position=UDim2.new(1,-45,0,8),Size=UDim2.fromOffset(32,32),ZIndex=92},closePopup)
        box:CaptureFocus();box.SelectionStart=1;box.CursorPosition=#text+1
        return false
    end
    local hubSearch=function() end
    local hubLoaded=false
    local function navigate(page)
        if state.locked or not pages[page] then return end
        closePopup();state.page=page
        for name,id in pairs(pages) do nodes[id].Visible=state.opened and name==page end
        for _,item in ipairs(nav) do nodes[item[1]].BackgroundColor3=item[2]==page and nodes[58].Value or nodes[59].Value end
        if page=='Scripthub' and not hubLoaded then hubSearch(1) end
    end
    local autoExecuted=false
    local function open()
        if state:open()=='key' then keyPanel.Visible=true;launcher.Visible=false;return end
        keyPanel.Visible=false;window.Visible=true;launcher.Visible=false;navigate(state.page)
        if not autoExecuted then
            autoExecuted=true
            if state.settings.autoExecute then
                for _,item in ipairs(state.saved) do if item.autoExecute then execute(item.source,item.title) end end
            end
        end
    end
    local function hide()
        state:hide();window.Visible=false;keyPanel.Visible=false;launcher.Visible=true;closePopup();persist()
        for _,id in pairs(pages) do nodes[id].Visible=false end
    end
    ui.open=open;ui.hide=hide
    for _,item in ipairs(nav) do
        bind(nodes[item[1]],function() if item[2]=='Close' then hide() else navigate(item[2]) end end)
    end
    bind(nodes[29],hide)
    local function submitKey()
        if state:unlock(nodes[11].Text) then nodes[11].Text='';open();report('Unlocked.')
        else nodes[7].Text='Incorrect key. Try again.';report('Incorrect local key.','Error') end
    end
    bind(nodes[14],submitKey)
    bind(nodes[18],function() nodes[7].Text='Local key: '..state.key;copy(state.key) end)
    connect(nodes[11].FocusLost,function(enter) if enter then submitKey() end end)
    bind(nodes[24],function() copy('https://discord.gg/deltax') end)
    bind(nodes[26],function() copy('https://discord.gg/deltax') end)
    -- Launcher dragging has one global listener pair, and retains suppression through release.
    local drag,suppressClick
    local function launcherSize() return ({Small=44,Medium=56,Large=72})[state.settings.iconSize] end
    local function placeLauncher(x,y)
        local v=viewport();local size=launcherSize()
        x,y=Core.clampPosition(x,y,size,v.X,v.Y)
        launcher.Position=UDim2.fromOffset(x,y)
        state.launcher={x=x/math.max(1,v.X-size),y=y/math.max(1,v.Y-size)}
    end
    local function resize()
        local v=viewport()
        local size=launcherSize();launcher.Size=UDim2.fromOffset(size,size)
        local pos=state.launcher or {x=.94,y=.45}
        placeLauncher(pos.x*(v.X-size),pos.y*(v.Y-size))
        toast.Size=UDim2.fromOffset(math.min(600,math.max(200,v.X-24)),48)
    end
    connect(launcher.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            suppressClick=false
            drag={input=input,start=input.Position,x=launcher.AbsolutePosition.X,y=launcher.AbsolutePosition.Y,moved=false}
        end
    end)
    bind(launcher,function()
        if suppressClick or (drag and drag.moved) then return end
        open()
    end)
    local function sameMovement(info,input)
        return input==info.input or (info.input.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseMovement)
    end
    connect(Input.InputChanged,function(input)
        if drag and sameMovement(drag,input) then
            local dx,dy=input.Position.X-drag.start.X,input.Position.Y-drag.start.Y
            drag.moved=drag.moved or Core.wasDragged(dx,dy)
            if drag.moved then suppressClick=true;placeLauncher(drag.x+dx,drag.y+dy) end
        end
    end)
    connect(Input.InputEnded,function(input)
        if drag and (input==drag.input or (input.UserInputType==Enum.UserInputType.MouseButton1
            and drag.input.UserInputType==Enum.UserInputType.MouseButton1)) then
            suppressClick=drag.moved;drag=nil;persist()
            later(.1,function() if not drag then suppressClick=false end end)
        end
    end)
    local cameraConnection
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        if workspace.CurrentCamera then cameraConnection=connect(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),resize) end
        resize()
    end
    connect(workspace:GetPropertyChangedSignal('CurrentCamera'),watchCamera)
    watchCamera()
    -- Editor: one TextBox, separate source for each tab, and one execution handler per action.
    local editor=nodes[514];ui.editor=editor
    editor.Text='';editor.ClearTextOnFocus=false;editor.MultiLine=true
    editor.TextWrapped=false;editor.RichText=false;editor.TextEditable=true
    editor.AutomaticSize=Enum.AutomaticSize.None
    nodes[513].Active=true;nodes[513].AutomaticCanvasSize=Enum.AutomaticSize.None
    nodes[513].ScrollingDirection=Enum.ScrollingDirection.XY
    nodes[413].AutomaticCanvasSize=Enum.AutomaticSize.None
    local editing=false
    local function measureEditor()
        local count,maxWidth=1,0
        for line in (editor.Text..'\n'):gmatch('(.-)\n') do maxWidth=math.max(maxWidth,#line) end
        for _ in editor.Text:gmatch('\n') do count=count+1 end
        local v=nodes[513].AbsoluteSize
        local width=math.max(v.X*.98820245,math.min(40000,maxWidth*editor.TextSize+20))
        local height=math.max(v.Y*.97169548,count*editor.TextSize*editor.LineHeight+16)
        -- Convert source scale coordinates to viewport pixels before enlarging the scroll canvas.
        editor.Position=UDim2.fromOffset(v.X*.011494522,v.Y*.012946978+3)
        editor.Size=UDim2.fromOffset(width,height)
        nodes[513].CanvasSize=UDim2.fromOffset(width+v.X*.011494522+8,height+v.Y*.012946978+12)
    end
    local renderTabs
    local function loadTab()
        editing=true;editor.Text=state:currentTab().source;editing=false
        nodes[513].CanvasPosition=Vector2.new(0,0);measureEditor();renderTabs()
    end
    local tabConnections={}
    renderTabs=function()
        for _,c in ipairs(tabConnections) do c:Disconnect() end;tabConnections={}
        for _,child in ipairs(nodes[413]:GetChildren()) do if child.Name:match('^Tab_') then child:Destroy() end end
        local size=nodes[413].AbsoluteSize
        local tabWidth=size.X*.23816878
        local gap=size.X*.01
        nodes[415].Padding=UDim.new(0,gap)
        nodes[416].LayoutOrder=10000
        nodes[416].Size=UDim2.new(0,size.X*.05266,.61546,0)
        nodes[413].CanvasSize=UDim2.fromOffset(math.max(size.X,#state.tabs*(tabWidth+gap)+size.X*.08),0)
        for i,t in ipairs(state.tabs) do
            local b,parts=cloneTemplate(421,nodes[413])
            b.Name='Tab_'..t.id;b.LayoutOrder=i;b.Size=UDim2.new(0,tabWidth,.8693818,0)
            b.BackgroundTransparency=t.id==state.activeTab and 0 or .6
            parts[423].Text=t.title;parts[424].Name='Close'
            table.insert(tabConnections,bind(b,function() state:selectTab(t.id);loadTab();persist() end))
            table.insert(tabConnections,bind(parts[424],function() state:removeTab(t.id);loadTab();persist() end))
        end
    end
    connect(nodes[413]:GetPropertyChangedSignal('AbsoluteSize'),renderTabs)
    connect(editor:GetPropertyChangedSignal('Text'),function()
        if not editing then state:updateSource(editor.Text);persist();measureEditor() end
    end)
    connect(nodes[513]:GetPropertyChangedSignal('AbsoluteSize'),measureEditor)
    local function newTab(title,source)
        local id,err=state:addTab(title,source)
        if not id then report(err,'Error');return false end
        loadTab();persist();return true
    end
    local addEmpty=function() newTab(nil,'') end
    bind(nodes[416],addEmpty);bind(nodes[418],addEmpty)
    bind(nodes[397],function() state:updateSource(editor.Text);execute(editor.Text,state:currentTab().title) end)
    bind(nodes[401],function() editor.Text='';state:updateSource('');persist() end)
    bind(nodes[405],function()
        local read=api('getclipboard') or api('readclipboard')
        if type(read)~='function' then
            report('Clipboard reading is unavailable. Paste with Ctrl+V, then Execute.','Error');editor:CaptureFocus();return
        end
        local ok,text=pcall(read)
        if not ok or type(text)~='string' then report('Could not read clipboard.','Error');return end
        execute(text,'clipboard')
    end)
    loadTab()
    connect(Input.InputBegan,function(input,processed)
        if input.KeyCode==Enum.KeyCode.RightShift and not processed and not Input:GetFocusedTextBox() then
            if state.opened or keyPanel.Visible then hide() else open() end
        elseif input.KeyCode==Enum.KeyCode.Return and state.opened and not state.locked
            and state.page=='Executor' and not activePopup and not copyPopup
            and (Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)) then
            local focused=Input:GetFocusedTextBox()
            if not focused or focused==editor then execute(editor.Text,state:currentTab().title) end
        elseif input.KeyCode==Enum.KeyCode.Escape and (activePopup or dropdown or copyPopup) then closePopup() end
    end)
    -- Saved scripts live in the local frontend workspace; upload never sends them to a server.
    nodes[554].AutomaticCanvasSize=Enum.AutomaticSize.None
    nodes[634].Text='';nodes[634].PlaceholderText='Script title';nodes[634].ClearTextOnFocus=false
    nodes[639].Text='';nodes[639].PlaceholderText='Paste Lua source or a raw HTTPS URL';nodes[639].ClearTextOnFocus=false
    nodes[639].MultiLine=true;nodes[639].TextScaled=false;nodes[639].TextWrapped=true
    nodes[626].Text='Save a script to this PC. It will appear on your Home page.'
    local savedConnections={}
    local function renderSaved()
        for _,c in ipairs(savedConnections) do c:Disconnect() end;savedConnections={}
        for _,child in ipairs(nodes[554]:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
        local items=state:filterSaved(nodes[550].Text)
        local h=nodes[554].AbsoluteSize.Y;local rowHeight=h*3*.046236556
        local gap=h*3*.005;nodes[555].Padding=UDim.new(0,gap)
        nodes[554].CanvasSize=UDim2.fromOffset(0,math.max(h,#items*(rowHeight+gap)))
        for i,item in ipairs(items) do
            local row,parts=cloneTemplate(556,nodes[554]);row.Name='Saved_'..item.id;row.LayoutOrder=i
            row.Size=UDim2.new(.9979484,0,0,rowHeight);parts[558].Text=item.title
            parts[560].Name='Run';parts[563].Name='Delete'
            parts[566].Visible=item.autoExecute==true;parts[568].Text='AUTO'
            -- The original row has Execute/Delete only. Title click edits; right-click marks AUTO.
            local title=parts[558]
            local edit=make('TextButton',row,{Name='Edit',Text='',BackgroundTransparency=1,
                Position=title.Position,Size=title.Size,AnchorPoint=title.AnchorPoint,ZIndex=title.ZIndex+1})
            table.insert(savedConnections,bind(parts[560],function() execute(item.source,item.title) end))
            table.insert(savedConnections,bind(parts[563],function() state:deleteScript(item.id);renderSaved();persist() end))
            table.insert(savedConnections,bind(edit,function() if newTab(item.title,item.source) then navigate('Executor') end end))
            table.insert(savedConnections,connect(edit.MouseButton2Click,function()
                item.autoExecute=not item.autoExecute;renderSaved();persist()
            end))
        end
    end
    connect(nodes[554]:GetPropertyChangedSignal('AbsoluteSize'),renderSaved)
    ui.renderSaved=renderSaved
    connect(nodes[550]:GetPropertyChangedSignal('Text'),renderSaved)
    bind(nodes[551],function() nodes[634].Text='';nodes[639].Text='';showPopup(nodes[622]) end)
    bind(nodes[628],closePopup)
    local saving=false
    bind(nodes[640],function()
        if saving then return end
        local title,source=nodes[634].Text,nodes[639].Text
        local function save(code)
            local item,err=state:saveScript(title,code)
            if not item then report(err,'Error');return end
            closePopup();renderSaved();persist();report('Saved '..item.title)
        end
        if source:match('^https://%S+$') then
            saving=true
            spawn(function()
                local ok,result=pcall(httpGet,source);saving=false
                if ui.destroyed then return end
                if ok then save(result) else report('Cannot load script URL: '..tostring(result),'Error') end
            end)
        else save(source) end
    end)
    renderSaved()
    -- ScriptBlox: retain the selected object by ID; never search by its display title again.
    local hub={page=1,total=1,serial=0,selected=nil,busy=false,loaded=false}
    local hubConnections={}
    nodes[66].AutomaticCanvasSize=Enum.AutomaticSize.None
    local hubCount=0
    local function sizeHub()
        local v=nodes[66].AbsoluteSize
        local cellW,cellH=v.X*.313,v.Y*.3
        local gapX,gapY=v.X*.03,v.Y*.03
        nodes[67].CellSize=UDim2.fromOffset(cellW,cellH);nodes[67].CellPadding=UDim2.fromOffset(gapX,gapY)
        local columns=math.max(1,math.floor((v.X+gapX)/(cellW+gapX)))
        nodes[66].CanvasSize=UDim2.fromOffset(0,math.max(v.Y,math.ceil(hubCount/columns)*(cellH+gapY)))
    end
    connect(nodes[66]:GetPropertyChangedSignal('AbsoluteSize'),sizeHub);sizeHub()
    -- Search on Enter and load further pages near the bottom; no added toolbar.
    local searchTap=make('TextButton',nodes[63],{Name='Search',Text='',BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),ZIndex=nodes[63].ZIndex+1})
    bind(searchTap,function() hubSearch(1) end)
    connect(nodes[66]:GetPropertyChangedSignal('CanvasPosition'),function()
        local scroll=nodes[66]
        if not hub.busy and hub.page<hub.total and scroll.CanvasPosition.Y+scroll.AbsoluteSize.Y>=scroll.CanvasSize.Y.Offset-50 then
            hubSearch(hub.page+1,true)
        end
    end)
    hubSearch=function(page,append)
        hub.serial=hub.serial+1;local serial=hub.serial
        local query=nodes[65].Text:match('^%s*(.-)%s*$')
        local url='https://scriptblox.com/api/script/'..(query=='' and 'fetch' or 'search')
            ..'?mode=free&max=20&page='..tostring(page)
        if query~='' then url=url..'&q='..Http:UrlEncode(query) end
        hub.busy=true
        report('Loading scripts...')
        spawn(function()
            local ok,response=pcall(function()
                local payload=Http:JSONDecode(httpGet(url))
                assert(type(payload)=='table' and type(payload.result)=='table',type(payload)=='table' and payload.message or 'Invalid ScriptBlox response')
                assert(type(payload.result.scripts)=='table','ScriptBlox returned no script list')
                return payload.result
            end)
            if ui.destroyed or serial~=hub.serial then return end
            hub.busy=false
            if not ok then report('ScriptBlox: '..tostring(response),'Error');return end
            hubLoaded=true;hub.page=page;hub.total=math.max(1,tonumber(response.totalPages) or 1)
            if not append then
                for _,c in ipairs(hubConnections) do c:Disconnect() end;hubConnections={}
                for _,child in ipairs(nodes[66]:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
                nodes[66].CanvasPosition=Vector2.new(0,0);hubCount=0
            end
            local count=hubCount
            for _,item in ipairs(response.scripts) do
                if type(item)=='table' and type(item.title)=='string' then
                    count=count+1
                    local card,parts=cloneTemplate(69,nodes[66]);card.Name='Hub_'..count;card.LayoutOrder=count
                    parts[74].Text=type(item.game)=='table' and tostring(item.game.name or 'Universal') or 'Universal'
                    parts[75].Text=item.title;parts[76].Visible=item.verified==true
                    parts[80].Text=tostring(item.views or 0)..' Views'
                    -- Keep the captured card; request the actual game's thumbnail from Roblox.
                    local gameId=type(item.game)=='table' and tonumber(item.game.gameId)
                    card.Image=gameId and ('rbxthumb://type=GameIcon&id='..tostring(gameId)..'&w=512&h=512') or ''
                    table.insert(hubConnections,bind(card,function()
                        hub.selected=item;nodes[85].Text=item.title;nodes[86].Text='Choose what to do with this script.';showPopup(nodes[82])
                    end))
                end
            end
            hubCount=count;sizeHub()
            if count==0 then report('No scripts found.') end
        end)
    end
    ui.searchHub=hubSearch
    connect(nodes[65].FocusLost,function(enter) if enter then hubSearch(1) end end)
    bind(nodes[106],closePopup)
    local function selectedAction(action)
        if hub.busy or not hub.selected then return end
        local selected=hub.selected
        hub.busy=true;nodes[86].Text='Loading script...'
        spawn(function()
            local ok,source=pcall(function()
                if type(selected.script)=='string' and selected.script~='' then return selected.script end
                local id=selected.slug or selected._id
                assert(type(id)=='string' and id~='','Selected script has no ID')
                return httpGet('https://scriptblox.com/api/script/raw/'..Http:UrlEncode(id))
            end)
            hub.busy=false
            if ui.destroyed then return end
            if not ok or type(source)~='string' or source:match('^%s*$') then
                nodes[86].Text='Could not load script. Try again.';report('ScriptBlox source error: '..tostring(source),'Error');return
            end
            if action=='execute' then closePopup();execute(source,selected.title)
            elseif action=='open' then if newTab(selected.title,source) then closePopup();navigate('Executor') end
            elseif action=='save' then
                local item,err=state:saveScript(selected.title,source)
                if item then closePopup();renderSaved();persist();report('Saved '..item.title) else report(err,'Error') end
            elseif action=='copy' then closePopup();copy(source) end
        end)
    end
    for _,item in ipairs({{89,'execute'},{93,'open'},{97,'save'},{101,'copy'}}) do
        bind(nodes[item[1]],function() selectedAction(item[2]) end)
    end
    bind(nodes[524],function() nodes[65].Text='Infinite Yield';navigate('Scripthub');hubSearch(1) end)
    -- Two independent searchable logs. Roblox logs come from LogService, execution feedback from us.
    do
        local panes={roblox={frame=nodes[646],scroll=nodes[656],search=nodes[662],clear=nodes[649]},
            runtime={frame=nodes[679],scroll=nodes[689],search=nodes[695],clear=nodes[682]}}
        for channel,p in pairs(panes) do
            p.scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;p.scroll.CanvasSize=UDim2.new()
            p.search.Text='';p.search.ClearTextOnFocus=false
            make('UIListLayout',p.scroll,{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder})
            connect(p.search:GetPropertyChangedSignal('Text'),function() renderLogs(channel) end)
            bind(p.clear,function() state.logs[channel]={};renderLogs(channel) end)
        end
        nodes[694].Text='Script execution, errors and frontend messages.'
        renderLogs=function(channel)
            local p=panes[channel];if not p then return end
            for _,child in ipairs(p.scroll:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
            local query=p.search.Text:lower()
            for i,entry in ipairs(state.logs[channel]) do
                if entry.text:lower():find(query,1,true) then
                    local id=({Error=668,Warn=670,Info=674})[entry.level] or 672
                    local row=cloneTemplate(id,p.scroll);row.LayoutOrder=i
                    local content=row:FindFirstChild('Content');content.Text='['..entry.time..'] '..entry.text
                    content.TextWrapped=true;content.AutomaticSize=Enum.AutomaticSize.Y
                    content.Size=UDim2.new(.98,0,0,20);row.AutomaticSize=Enum.AutomaticSize.Y
                end
            end
        end
        local logDirty=false
        connect(Services.LogService.MessageOut,function(message,kind)
            if not state.settings.console then return end
            local level=kind==Enum.MessageType.MessageError and 'Error' or kind==Enum.MessageType.MessageWarning and 'Warn' or 'Info'
            state:log(level,message,'roblox')
            if not logDirty then logDirty=true;later(.15,function() logDirty=false;renderLogs('roblox') end) end
        end)
    end
    -- Settings preserve the captured rows, with fixed heights suitable for PC scrolling.
    do
        local settingsRows={}
        local mode='All'
        nodes[127].AutomaticCanvasSize=Enum.AutomaticSize.None
        local function sizeSettings()
            local h=nodes[127].AbsoluteSize.Y;local gap=h*4*.005
            nodes[128].Padding=UDim.new(0,gap)
            local total=0
            for _,row in ipairs(settingsRows) do
                local height=h*4*row.height
                row.frame.Size=UDim2.new(1,0,0,height)
                if row.frame.Visible then total=total+height+gap end
            end
            nodes[127].CanvasSize=UDim2.fromOffset(0,math.max(h,total))
        end
        local function filter()
            local query=nodes[114].Text:lower()
            for _,row in ipairs(settingsRows) do
                local matches=row.title:lower():find(query,1,true)~=nil
                local enabled=row.key and state.settings[row.key]==true
                row.frame.Visible=matches and (mode=='All' or (mode=='Enabled' and enabled) or (mode=='Disabled' and row.toggle and not enabled))
            end
            sizeSettings()
        end
        local function register(id,title,key,toggle)
            local frame=nodes[id];frame.ClipsDescendants=false
            frame:SetAttribute('RestingZ',frame.ZIndex)
            table.insert(settingsRows,{frame=frame,title=title,key=key,toggle=toggle,height=frame.Size.Y.Scale})
            return frame
        end
        connect(nodes[127]:GetPropertyChangedSignal('AbsoluteSize'),sizeSettings)
        local originalEditor={background=nodes[369].BackgroundColor3,color=editor.TextColor3,placeholder=editor.PlaceholderColor3,
            image=nodes[368].ImageTransparency,overlay=nodes[369].ImageTransparency,alpha=nodes[369].BackgroundTransparency}
        local function iconAppearance()
            local palette={Blue=Color3.fromRGB(34,160,255),Green=Color3.fromRGB(46,184,135),Purple=Color3.fromRGB(153,100,241)}
            launcher.BackgroundColor3=palette[state.settings.iconColor]
            local corner=round(launcher,state.settings.iconShape=='Square' and 0 or state.settings.iconShape=='Circle' and 100 or 15)
            if state.settings.iconShape=='Circle' then corner.CornerRadius=UDim.new(.5,0) end
            resize()
        end
        local function applyTheme()
            local name=state.settings.theme
            local bg=name=='Light' and Color3.fromRGB(235,238,244) or name=='Amoled' and Color3.new(0,0,0) or originalEditor.background
            local fg=name=='Light' and Color3.fromRGB(32,38,52) or originalEditor.color
            nodes[369].BackgroundColor3=bg;editor.TextColor3=fg
            editor.PlaceholderColor3=name=='Light' and Color3.fromRGB(90,100,115) or originalEditor.placeholder
            nodes[368].ImageTransparency=name=='Default' and originalEditor.image or 1
            nodes[369].ImageTransparency=name=='Default' and originalEditor.overlay or 1
            nodes[369].BackgroundTransparency=name=='Default' and originalEditor.alpha or 0
        end
        local function applySetting(key,value)
            if key=='fpsCap' then
                local setter=api('setfpscap')
                if type(setter)~='function' then report('FPS cap is not supported by your executor.','Error');return false end
                local ok,err=pcall(setter,({['60 FPS']=60,['120 FPS']=120,['Max FPS']=0})[value])
                if not ok then report('FPS cap: '..tostring(err),'Error');return false end
            elseif key=='antiAfk' and value then
                local ok=pcall(function() return game:GetService('VirtualUser'):CaptureController() end)
                if not ok then report('Anti AFK is not available in this executor.','Error');return false end
            end
            if not state:setSetting(key,value) then return false end
            if key:match('^icon') then iconAppearance() end
            if key=='theme' then applyTheme() end
            persist();filter();return true
        end
        local switches={{129,'Anti Scam',nil,134,139},{140,'Disable Robux',nil,145,150},
            {151,'RakNet',nil,156,161},{162,'Verify Teleports',nil,167,172},
            {173,'Auto Execute','autoExecute',178,183},{184,'Anti AFK','antiAfk',189,194},
            {195,'Auto Close','autoClose',200,205},{206,'Console','console',211,216}}
        local onStyle={background=nodes[134].BackgroundColor3,position=nodes[136].Position,anchor=nodes[136].AnchorPoint,color=nodes[136].BackgroundColor3}
        local offStyle={background=nodes[156].BackgroundColor3,position=nodes[158].Position,anchor=nodes[158].AnchorPoint,color=nodes[158].BackgroundColor3}
        for _,item in ipairs(switches) do
            local frame=register(item[1],item[2],item[3],true);local sw=nodes[item[4]]
            local knob=sw:FindFirstChild('ImageButton')
            local function paint()
                local on=item[3] and state.settings[item[3]]==true
                local style=on and onStyle or offStyle
                sw.BackgroundColor3=style.background;knob.Position=style.position
                knob.AnchorPoint=style.anchor;knob.BackgroundColor3=style.color
                nodes[item[5]].Value=on==true
            end
            if not item[3] then frame.Desc.Text='Native Delta feature · unavailable in this frontend.'
            elseif item[3]=='autoExecute' then frame.Desc.Text='Run saved scripts marked AUTO when this UI opens.'
            elseif item[3]=='antiAfk' then frame.Desc.Text='Send idle input while this frontend is active.' end
            bind(sw,function()
                if not item[3] then report(item[2]..' requires native Delta support.','Error');return end
                if applySetting(item[3],not state.settings[item[3]]) then paint() end
            end)
            paint()
        end
        local function wireDropdown(anchor,panel,key,choices,title)
            local row=panel.Parent;row:SetAttribute('RestingZ',row.ZIndex)
            local function paint()
                if title then title.Text=state.settings[key] end
                for _,choice in ipairs(choices) do nodes[choice[2]].Checked.Visible=state.settings[key]==choice[1] end
            end
            local function toggle()
                local wasOpen=panel.Visible
                closePopup()
                if not wasOpen then
                    dropdown=panel;panel.Visible=true;row.ZIndex=30;paint()
                end
            end
            bind(anchor,toggle)
            for _,child in ipairs(anchor:GetChildren()) do
                if child:IsA('GuiButton') then bind(child,toggle) end
            end
            for _,choice in ipairs(choices) do
                local function choose()
                    if applySetting(key,choice[1]) then paint();closePopup() end
                end
                bind(nodes[choice[2]],choose);bind(nodes[choice[2]].Checked,choose)
            end
            paint();return toggle
        end
        local drops={{217,'FPS Cap','fpsCap',221,223,225,{{'120 FPS',227},{'60 FPS',234},{'Max FPS',240}}},
            {246,'Icon Size','iconSize',250,252,254,{{'Small',256},{'Medium',263},{'Large',269}}},
            {275,'Icon Shape','iconShape',279,281,283,{{'Circle',285},{'Squircle',292},{'Square',298}}},
            {304,'Icon Color','iconColor',308,310,312,{{'Green',314},{'Blue',321},{'Purple',327}}}}
        for _,item in ipairs(drops) do
            register(item[1],item[2],item[3],false)
            wireDropdown(nodes[item[4]],nodes[item[6]],item[3],item[7],nodes[item[5]])
        end
        wireDropdown(nodes[371],nodes[375],'theme',{{'Default',377},{'Light',383},{'Amoled',389}})
        local function teleport(small)
            report('Finding a server...')
            spawn(function()
                local ok,err=pcall(function()
                    local data=Http:JSONDecode(httpGet('https://games.roblox.com/v1/games/'..tostring(game.PlaceId)..'/servers/Public?sortOrder='..(small and 'Asc' or 'Desc')..'&limit=100'))
                    assert(type(data)=='table' and type(data.data)=='table','Invalid server list')
                    local candidates={}
                    for _,server in ipairs(data.data) do
                        if server.id~=game.JobId and tonumber(server.playing) and tonumber(server.maxPlayers) and server.playing<server.maxPlayers then
                            table.insert(candidates,server)
                        end
                    end
                    assert(#candidates>0,'No other available server was found')
                    local chosen=candidates[small and 1 or math.random(1,#candidates)]
                    if not ui.destroyed then persistNow();Services.TeleportService:TeleportToPlaceInstance(game.PlaceId,chosen.id,player) end
                end)
                if not ok and not ui.destroyed then report('Server search: '..tostring(err),'Error') end
            end)
        end
        for _,item in ipairs({{333,'Join Discord',338},{341,'Rejoin',346},{349,'Small Server',354},{357,'Serverhop',362}}) do
            register(item[1],item[2],nil,false)
            local b=nodes[item[3]]
            bind(b,function()
                if item[2]=='Join Discord' then copy('https://discord.gg/deltax')
                elseif item[2]=='Rejoin' then
                    persistNow()
                    local ok,err=pcall(function()
                        if game.JobId~='' then Services.TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,player)
                        else Services.TeleportService:Teleport(game.PlaceId,player) end
                    end)
                    if not ok then report('Rejoin failed: '..tostring(err),'Error') end
                else teleport(item[2]=='Small Server') end
            end)
        end
        for _,item in ipairs({{118,'Enabled'},{121,'Disabled'},{124,'All'}}) do
            bind(nodes[item[1]],function() mode=item[2];filter() end)
        end
        connect(nodes[114]:GetPropertyChangedSignal('Text'),filter)
        connect(player.Idled,function()
            if not state.settings.antiAfk then return end
            local ok,err=pcall(function()
                local virtual=game:GetService('VirtualUser');virtual:CaptureController();virtual:ClickButton2(Vector2.new(0,0))
            end)
            if not ok then report('Anti AFK: '..tostring(err),'Error') end
        end)
        applyTheme();iconAppearance();filter()
        if type(api('setfpscap'))=='function' then
            applySetting('fpsCap',state.settings.fpsCap)
        elseif stored and stored.settings and stored.settings.fpsCap then
            report('Saved FPS cap cannot be applied: this executor has no setfpscap.','Error')
        end
    end
    -- Live status uses measured data rather than numbers left in the capture.
    do
        local elapsed,frames=0,0
        connect(Run.RenderStepped,function(dt)
            frames=frames+1;elapsed=elapsed+dt
            if elapsed<1 then return end
            nodes[540].Text=string.format('<font color="#4FA4F2">%d</font> FPS',math.floor(frames/elapsed+.5))
            nodes[542].Text=tostring(#Players:GetPlayers())..' players'
            local ok,ping=pcall(function() return player:GetNetworkPing()*1000 end)
            nodes[541].Text=ok and string.format('%.0f MS Ping',ping) or 'Ping unavailable'
            frames=0;elapsed=0
        end)
    end
    local parented=false
    local hidden=api('gethui')
    if type(hidden)=='function' then
        local ok,parent=pcall(hidden)
        if ok and parent then parented=pcall(function() gui.Parent=parent end) end
    end
    if not parented then parented=pcall(function() gui.Parent=game:GetService('CoreGui') end) end
    if not parented then gui.Parent=player:WaitForChild('PlayerGui') end
    -- Requeue this frontend at a place/universe transfer. The host executor owns reinjection.
    do
        local queue=api('queue_on_teleport') or api('queueonteleport')
        for _,name in ipairs({'syn','fluxus'}) do
            local host=api(name)
            if type(queue)~='function' and type(host)=='table' then queue=host.queue_on_teleport end
        end
        ui.teleportSupported=type(queue)=='function'
        if ui.teleportSupported then
            local loader=config.keyed and 'keyed.lua' or 'keyless.lua'
            local queuedSource=string.format([=[
local shared=(type(getgenv)=='function' and getgenv()) or _G
shared.__DeltaPCTeleportQueued=nil
if not game:IsLoaded() then game.Loaded:Wait() end
local old=shared.__DeltaPC
if type(old)=='table' and not old.destroyed and old.placeId==game.PlaceId and old.jobId==game.JobId
    and old.gui and old.gui.Parent then return end
local ok,err=pcall(function()
    local source=game:HttpGet(%q)
    local chunk,reason=loadstring(source,'@DeltaPC/teleport')
    assert(chunk,reason)
    chunk()
end)
if not ok then warn('[Delta PC] Teleport reload failed: '..tostring(err)) end
]=],'https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/'..loader)
            connect(player.OnTeleport,function(teleportState)
                if teleportState~=Enum.TeleportState.Started and teleportState~=Enum.TeleportState.InProgress then return end
                state:updateSource(editor.Text);persistNow()
                if shared.__DeltaPCTeleportQueued then return end
                local ok,err=pcall(queue,queuedSource)
                if ok then shared.__DeltaPCTeleportQueued=true
                else report('Teleport reload could not be queued: '..tostring(err),'Error') end
            end)
        end
    end
    function ui.close()
        if ui.destroyed then return end
        state:updateSource(editor.Text);persistNow();ui.destroyed=true;hub.serial=hub.serial+1
        for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        for handle in pairs(tasks) do pcall(task.cancel,handle) end
        tasks={};gui:Destroy()
        for _,id in ipairs(templateIds) do nodes[id]:Destroy() end
        if shared.__DeltaPC==ui then shared.__DeltaPC=nil end
    end
    shared.__DeltaPC=ui
    connect(gui.Destroying,function() ui.close() end)
    hide()
    if #propertyFailures>0 then report(tostring(#propertyFailures)..' captured properties were unsupported by this Roblox client; inspect ui.propertyFailures.') end
    if type(api('writefile'))~='function' then report('Ready. File saving unavailable; scripts persist for this session.') end
    if not ui.teleportSupported then report('Teleport auto reload unavailable: your executor has no queue_on_teleport.') end
    return ui
end
