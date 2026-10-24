-- Fresh controller. Core and Skin are prepended by tools/build.py.
return function(config)
    config=type(config)=='table' and config or {}
    local env=(type(getfenv)=='function' and getfenv()) or _G
    local shared=(type(getgenv)=='function' and getgenv()) or _G
    local function api(name) return env[name] or shared[name] end
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
    local nodes,propertyFailures=Skin()
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
        connect(object.Activated,callback)
    end
    local function removeChildren(object)
        for _,child in ipairs(object:GetChildren()) do child:Destroy() end
    end
    local function viewport()
        local camera=workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1280,720)
    end
    local window=make('Frame',gui,{Name='Window',AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1080,660),BackgroundColor3=colors.bg,
        BorderSizePixel=0,Visible=false,ZIndex=10})
    round(window,14)
    local scale=make('UIScale',window,{Scale=1})
    local header=make('Frame',window,{Name='Header',Size=UDim2.new(1,-72,0,40),
        BackgroundTransparency=1,Active=true,ZIndex=12})
    label(header,'DELTA',{Position=UDim2.fromOffset(20,0),Size=UDim2.fromOffset(110,40),
        Font=Enum.Font.GothamBold,TextSize=15})
    label(header,'PC  /  '..(config.keyed and 'KEYED' or 'KEYLESS'),{
        Position=UDim2.fromOffset(113,1),Size=UDim2.fromOffset(200,40),TextColor3=colors.muted,TextSize=11})
    label(header,'Right Shift to hide  ·  Ctrl+Enter to run',{
        Position=UDim2.new(1,-320,0,0),Size=UDim2.fromOffset(300,40),TextXAlignment=Enum.TextXAlignment.Right,
        TextColor3=colors.muted,TextSize=11})
    local pages={Home=545,Executor=367,Scripthub=60,Settings=109,Console=645}
    for _,id in pairs(pages) do
        local p=nodes[id];p.Parent=window;p.AnchorPoint=Vector2.new(0,0)
        p.Position=UDim2.fromOffset(18,50);p.Size=UDim2.new(1,-108,1,-80)
        p.BackgroundTransparency=1;p.Visible=false;p.ZIndex=2
    end
    nodes[366]:Destroy()
    nodes[32].Parent=window;nodes[32].AnchorPoint=Vector2.new(1,0)
    nodes[32].Position=UDim2.new(1,0,0,0);nodes[32].Size=UDim2.new(0,72,1,0)
    nodes[32].Visible=true;nodes[32].ZIndex=15
    for _,child in ipairs(nodes[32]:GetChildren()) do if child:IsA('UIListLayout') then child:Destroy() end end
    -- Exported reserve folders are inert templates; never leave template controls on screen.
    nodes[68]:Destroy();nodes[426]:Destroy();nodes[667]:Destroy()
    for _,id in ipairs({556,569,582,595,608}) do nodes[id]:Destroy() end
    nodes[657]:Destroy();nodes[690]:Destroy();nodes[410]:Destroy();nodes[515]:Destroy()
    local function glyph(parent,text)
        for _,child in ipairs(parent:GetChildren()) do if child.Name=='FallbackGlyph' then child:Destroy() end end
        return label(parent,text,{Name='FallbackGlyph',Font=Enum.Font.Code,TextSize=21,
            TextXAlignment=Enum.TextXAlignment.Center,TextColor3=colors.muted,
            Size=UDim2.fromScale(1,1),ZIndex=8})
    end
    local nav={{34,'Home','⌂'},{46,'Executor','</>'},{38,'Scripthub','▦'},
        {42,'Settings','⚙'},{50,'Console','>_'},{54,'Close','×'}}
    for index,item in ipairs(nav) do
        local b=nodes[item[1]];b.AnchorPoint=Vector2.new(0,0)
        b.Position=UDim2.fromOffset(10,55+(index-1)*72);b.Size=UDim2.fromOffset(52,52)
        b.LayoutOrder=index;b.ZIndex=16;round(b,10)
        for _,child in ipairs(b:GetChildren()) do if child:IsA('ImageLabel') then child.Visible=false end end
        glyph(b,item[3])
        label(b,item[2],{Name='Caption',Position=UDim2.new(-.12,0,1,3),Size=UDim2.new(1.24,0,0,14),
            TextSize=9,TextColor3=colors.muted,TextXAlignment=Enum.TextXAlignment.Center})
    end
    for _,id in ipairs({63,112,548}) do glyph(nodes[id],'⌕') end
    for _,id in ipairs({29,106,628,424}) do glyph(nodes[id],'×') end
    glyph(nodes[418],'+');glyph(nodes[372],'≡')
    -- Native colored backgrounds replace the unavailable Android textures.
    for _,id in ipairs({368,369,517,518,529}) do
        nodes[id].Image='';nodes[id].BackgroundColor3=(id==369) and colors.field or colors.panel
        nodes[id].BackgroundTransparency=(id==517) and 1 or 0;round(nodes[id],10)
    end
    local status=label(window,'Ready',{Name='Status',Position=UDim2.new(0,20,1,-24),
        Size=UDim2.new(1,-110,0,18),TextSize=11,TextColor3=colors.muted,TextTruncate=Enum.TextTruncate.AtEnd})
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
    local function httpGet(url)
        local requestFn=api('request') or api('http_request')
        local synApi=api('syn');local httpApi=api('http')
        if type(requestFn)~='function' and type(synApi)=='table' then requestFn=synApi.request end
        if type(requestFn)~='function' and type(httpApi)=='table' then requestFn=httpApi.request end
        if type(requestFn)=='function' then
            local response=requestFn({Url=url,Method='GET',Headers={Accept='application/json'},Timeout=20})
            assert(type(response)=='table','HTTP response is not a table')
            local code=tonumber(response.StatusCode or response.Status)
            assert(not code or (code>=200 and code<300),'HTTP '..tostring(code))
            assert(response.Success~=false and type(response.Body)=='string','Empty HTTP response')
            return response.Body
        end
        local body=game:HttpGet(url)
        assert(type(body)=='string' and #body>0,'Empty HTTP response');return body
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
    local launcher=button(gui,'',{Name='DeltaLauncher',Size=UDim2.fromOffset(56,56),
        Position=UDim2.new(1,-78,.45,0),BackgroundColor3=colors.accent,ZIndex=50})
    ui.launcher=launcher
    -- Draw the Delta mark using Roblox UI primitives; no remote asset required.
    local mark=make('Frame',launcher,{Name='DeltaMark',BackgroundTransparency=1,
        Position=UDim2.fromScale(.18,.15),Size=UDim2.fromScale(.64,.64),ZIndex=51})
    for _,line in ipairs({{.29,.48,.12,.88,26},{.66,.48,.12,.88,-26},{.48,.84,.8,.12,0}}) do
        local part=make('Frame',mark,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(line[1],line[2]),
            Size=UDim2.fromScale(line[3],line[4]),Rotation=line[5],BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0,ZIndex=52});round(part,2)
    end
    label(launcher,'DELTA',{Position=UDim2.fromScale(0,.76),Size=UDim2.fromScale(1,.17),TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,ZIndex=52})
    local keyPanel=nodes[1];keyPanel.Name='KeyPanel';keyPanel.Parent=gui
    keyPanel.AnchorPoint=Vector2.new(.5,.5);keyPanel.Position=UDim2.fromScale(.5,.5)
    keyPanel.Size=UDim2.fromOffset(370,510);keyPanel.Visible=false;keyPanel.ZIndex=40
    round(keyPanel,12);local keyScale=make('UIScale',keyPanel,{Scale=1})
    nodes[2].AnchorPoint=Vector2.new(.5,.5);nodes[2].Position=UDim2.fromScale(.5,.5)
    nodes[2].Size=UDim2.fromScale(.86,.88)
    nodes[7].Text='Enter the local key to open your Delta PC interface.'
    nodes[23].Text='Independent GUI recreation · Local key'
    nodes[11].Text='';nodes[11].ClearTextOnFocus=false
    nodes[29].Position=UDim2.new(1,-12,0,12);nodes[29].Size=UDim2.fromOffset(25,25)
    nodes[29].AnchorPoint=Vector2.new(1,0)
    ui.keyPanel=keyPanel
    local activePopup,dropdown,copyPopup,copyShade
    local shade=button(window,'',{Name='PopupShade',Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),
        BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.4,Visible=false,ZIndex=30})
    local function closePopup()
        if activePopup then activePopup.Visible=false;activePopup=nil end
        shade.Visible=false
        if dropdown then dropdown:Destroy();dropdown=nil end
        if copyPopup then copyPopup:Destroy();copyPopup=nil end
        if copyShade then copyShade:Destroy();copyShade=nil end
    end
    local function showPopup(popup)
        closePopup();activePopup=popup;shade.Visible=true;popup.Visible=true
    end
    bind(shade,function() if state.settings.autoClose then closePopup() end end)
    for _,id in ipairs({622,82}) do
        local p=nodes[id];p.Parent=window;p.AnchorPoint=Vector2.new(.5,.5)
        p.Position=UDim2.fromScale(.47,.5);p.Size=UDim2.fromOffset(470,id==622 and 480 or 400)
        p.ZIndex=35;p.Visible=false
    end
    nodes[621]:Destroy();nodes[81]:Destroy()
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
        for _,item in ipairs(nav) do nodes[item[1]].BackgroundColor3=item[2]==page and colors.accent or colors.panel end
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
    local drag,headerDrag,suppressClick
    local function launcherSize() return ({Small=44,Medium=56,Large=72})[state.settings.iconSize] end
    local function placeLauncher(x,y)
        local v=viewport();local size=launcherSize()
        x,y=Core.clampPosition(x,y,size,v.X,v.Y)
        launcher.Position=UDim2.fromOffset(x,y)
        state.launcher={x=x/math.max(1,v.X-size),y=y/math.max(1,v.Y-size)}
    end
    local function resize()
        local v=viewport()
        scale.Scale=math.min(1,(v.X-24)/1080,(v.Y-24)/660)
        keyScale.Scale=math.min(1,(v.X-24)/370,(v.Y-24)/510)
        local size=launcherSize();launcher.Size=UDim2.fromOffset(size,size)
        local pos=state.launcher or {x=.94,y=.45}
        placeLauncher(pos.x*(v.X-size),pos.y*(v.Y-size))
        toast.Size=UDim2.fromOffset(math.min(600,math.max(200,v.X-24)),48)
        -- Recenter on viewport changes so the panel cannot remain off-screen.
        window.Position=UDim2.fromScale(.5,.5)
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
    connect(header.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            headerDrag={input=input,start=input.Position,x=window.AbsolutePosition.X+window.AbsoluteSize.X/2,
                y=window.AbsolutePosition.Y+window.AbsoluteSize.Y/2}
        end
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
        if headerDrag and sameMovement(headerDrag,input) then
            local v=viewport();local halfW=window.AbsoluteSize.X/2;local halfH=window.AbsoluteSize.Y/2
            local x=headerDrag.x+input.Position.X-headerDrag.start.X
            local y=headerDrag.y+input.Position.Y-headerDrag.start.Y
            x=math.max(halfW+6,math.min(x,v.X-halfW-6));y=math.max(halfH+6,math.min(y,v.Y-halfH-6))
            window.Position=UDim2.fromOffset(x,y)
        end
    end)
    connect(Input.InputEnded,function(input)
        if drag and (input==drag.input or (input.UserInputType==Enum.UserInputType.MouseButton1
            and drag.input.UserInputType==Enum.UserInputType.MouseButton1)) then
            suppressClick=drag.moved;drag=nil;persist()
            later(.1,function() if not drag then suppressClick=false end end)
        end
        if headerDrag and input==headerDrag.input then headerDrag=nil end
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
    editor.Text='';editor.PlaceholderText='-- Paste your Lua script here\n-- Ctrl+Enter to execute'
    editor.ClearTextOnFocus=false;editor.MultiLine=true;editor.Font=Enum.Font.Code
    editor.TextSize=16;editor.LineHeight=1.2;editor.TextWrapped=false;editor.RichText=false
    editor.TextEditable=true;editor.AutomaticSize=Enum.AutomaticSize.None
    editor.Position=UDim2.fromOffset(42,8);editor.Size=UDim2.new(1,-58,1,-16)
    nodes[513].Active=true;nodes[513].ScrollBarThickness=5;nodes[513].AutomaticCanvasSize=Enum.AutomaticSize.None
    nodes[513].ScrollingDirection=Enum.ScrollingDirection.XY
    nodes[413].AutomaticCanvasSize=Enum.AutomaticSize.X;nodes[413].CanvasSize=UDim2.new()
    nodes[413].Size=UDim2.new(1,-64,0,48);nodes[413].Position=UDim2.fromOffset(5,8);nodes[413].ZIndex=20
    nodes[371].AnchorPoint=Vector2.new(1,0);nodes[371].Position=UDim2.new(1,-10,0,12)
    nodes[371].Size=UDim2.fromOffset(36,36);nodes[371].ZIndex=25
    nodes[372].AnchorPoint=Vector2.new(.5,.5);nodes[372].Position=UDim2.fromScale(.5,.5)
    nodes[372].Size=UDim2.fromScale(.75,.75)
    nodes[415].HorizontalAlignment=Enum.HorizontalAlignment.Left
    nodes[414].PaddingLeft=UDim.new(0,5);nodes[414].PaddingRight=UDim.new(0,5)
    nodes[415].Padding=UDim.new(0,6)
    nodes[421]:Destroy()
    nodes[416].LayoutOrder=10000;nodes[416].Size=UDim2.fromOffset(32,32)
    local lineNumbers=label(nodes[513],'1',{Name='LineNumbers',Position=UDim2.fromOffset(2,8),
        Size=UDim2.fromOffset(30,300),Font=Enum.Font.Code,TextSize=16,TextYAlignment=Enum.TextYAlignment.Top,
        TextXAlignment=Enum.TextXAlignment.Right,TextColor3=colors.muted,LineHeight=1.2})
    local editing=false
    local function measureEditor()
        local count,maxWidth=1,0;local numbers={'1'}
        for line in (editor.Text..'\n'):gmatch('(.-)\n') do maxWidth=math.max(maxWidth,#line) end
        for _ in editor.Text:gmatch('\n') do count=count+1;if count<=5000 then table.insert(numbers,tostring(count)) end end
        lineNumbers.Text=table.concat(numbers,'\n')
        local width=math.max(nodes[513].AbsoluteSize.X/scale.Scale-58,math.min(20000,maxWidth*10+20))
        local height=math.max(nodes[513].AbsoluteSize.Y/scale.Scale-16,count*20+20)
        editor.Size=UDim2.fromOffset(width,height);lineNumbers.Size=UDim2.fromOffset(30,height)
        nodes[513].CanvasSize=UDim2.fromOffset(width+60,height+20)
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
        for i,t in ipairs(state.tabs) do
            local b=button(nodes[413],t.title,{Name='Tab_'..t.id,LayoutOrder=i,Size=UDim2.fromOffset(145,32),
                BackgroundColor3=t.id==state.activeTab and colors.panel or colors.field,TextXAlignment=Enum.TextXAlignment.Left})
            make('UIPadding',b,{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,28)})
            local x=button(b,'×',{Name='Close',Size=UDim2.fromOffset(24,24),Position=UDim2.new(1,0,.5,-12),
                BackgroundTransparency=1,TextSize=18})
            table.insert(tabConnections,connect(b.Activated,function() state:selectTab(t.id);loadTab();persist() end))
            table.insert(tabConnections,connect(x.Activated,function() state:removeTab(t.id);loadTab();persist() end))
        end
    end
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
            and state.page=='Executor' and not activePopup
            and (Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)) then
            local focused=Input:GetFocusedTextBox()
            if not focused or focused==editor then execute(editor.Text,state:currentTab().title) end
        elseif input.KeyCode==Enum.KeyCode.Escape and state.opened and activePopup then closePopup() end
    end)
    -- Saved scripts live in the local frontend workspace; upload never sends them to a server.
    nodes[550].Size=UDim2.new(.77,0,0,24);nodes[550].TextScaled=false;nodes[550].TextSize=15
    nodes[555].VerticalAlignment=Enum.VerticalAlignment.Top;nodes[555].Padding=UDim.new(0,8)
    nodes[554].AutomaticCanvasSize=Enum.AutomaticSize.Y;nodes[554].CanvasSize=UDim2.new();nodes[554].ScrollBarThickness=5
    nodes[634].Text='';nodes[634].PlaceholderText='Script title';nodes[634].ClearTextOnFocus=false
    nodes[639].Text='';nodes[639].PlaceholderText='Paste Lua source or a raw HTTPS URL';nodes[639].ClearTextOnFocus=false
    nodes[639].MultiLine=true;nodes[639].TextSize=14;nodes[639].TextScaled=false;nodes[639].TextWrapped=true
    nodes[626].Text='Save a script to this PC. It will appear on your Home page.'
    local savedConnections={}
    local function renderSaved()
        for _,c in ipairs(savedConnections) do c:Disconnect() end;savedConnections={}
        for _,child in ipairs(nodes[554]:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
        local items=state:filterSaved(nodes[550].Text)
        if #items==0 then label(nodes[554],'No saved scripts. Click UPLOAD to add one.',{Size=UDim2.new(1,0,0,70),
            TextColor3=colors.muted,TextXAlignment=Enum.TextXAlignment.Center}) end
        for i,item in ipairs(items) do
            local row=make('Frame',nodes[554],{Name='Saved_'..item.id,LayoutOrder=i,Size=UDim2.new(1,-8,0,66),
                BackgroundColor3=colors.panel,BorderSizePixel=0});round(row,9)
            label(row,item.title,{Position=UDim2.fromOffset(16,8),Size=UDim2.new(1,-355,0,24),
                Font=Enum.Font.GothamMedium,TextTruncate=Enum.TextTruncate.AtEnd})
            label(row,tostring(#item.source)..' characters',{Position=UDim2.fromOffset(16,35),Size=UDim2.fromOffset(200,18),
                TextSize=11,TextColor3=colors.muted})
            local specs={{'Edit','EDIT',-330},{'Auto',item.autoExecute and 'AUTO: ON' or 'AUTO: OFF',-250},
                {'Delete','DELETE',-165},{'Run','EXECUTE',-85}}
            for _,s in ipairs(specs) do
                local b=button(row,s[2],{Name=s[1],Position=UDim2.new(1,s[3],.5,-16),Size=UDim2.fromOffset(74,32),
                    BackgroundColor3=s[1]=='Run' and colors.accent or colors.field,TextSize=10})
                table.insert(savedConnections,connect(b.Activated,function()
                    if s[1]=='Run' then execute(item.source,item.title)
                    elseif s[1]=='Delete' then state:deleteScript(item.id);renderSaved();persist()
                    elseif s[1]=='Auto' then item.autoExecute=not item.autoExecute;renderSaved();persist()
                    elseif newTab(item.title,item.source) then navigate('Executor') end
                end))
            end
        end
    end
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
    nodes[67].CellSize=UDim2.new(1/3,-12,0,150);nodes[67].CellPadding=UDim2.fromOffset(12,12)
    nodes[67].VerticalAlignment=Enum.VerticalAlignment.Top;nodes[67].HorizontalAlignment=Enum.HorizontalAlignment.Left
    nodes[66].Size=UDim2.new(1,0,.80,-30);nodes[66].Position=UDim2.new(0,0,0,84);nodes[66].AnchorPoint=Vector2.new(0,0)
    nodes[66].AutomaticCanvasSize=Enum.AutomaticSize.Y;nodes[66].CanvasSize=UDim2.new();nodes[66].ScrollBarThickness=5
    nodes[65].TextScaled=false;nodes[65].TextSize=15;nodes[65].Size=UDim2.new(.76,0,0,24)
    local hubInfo=label(nodes[60],'Powered by ScriptBlox.com',{Name='HubStatus',Position=UDim2.new(0,0,1,-24),
        Size=UDim2.new(1,-240,0,24),TextSize=12,TextColor3=colors.muted})
    local search=button(nodes[61],'SEARCH',{Name='Search',AnchorPoint=Vector2.new(1,.5),
        Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(90,30)},function() hubSearch(1) end)
    local prev=button(nodes[60],'PREV',{Name='PreviousPage',Position=UDim2.new(1,-200,1,-30),Size=UDim2.fromOffset(90,28)},function()
        if hub.page>1 then hubSearch(hub.page-1) end
    end)
    local nextButton=button(nodes[60],'NEXT',{Name='NextPage',Position=UDim2.new(1,-98,1,-30),Size=UDim2.fromOffset(90,28)},function()
        if hub.page<hub.total then hubSearch(hub.page+1) end
    end)
    hubSearch=function(page)
        hub.serial=hub.serial+1;local serial=hub.serial
        local query=nodes[65].Text:match('^%s*(.-)%s*$')
        local url='https://scriptblox.com/api/script/'..(query=='' and 'fetch' or 'search')
            ..'?mode=free&max=20&page='..tostring(page)
        if query~='' then url=url..'&q='..Http:UrlEncode(query) end
        hubInfo.Text='Loading scripts...'
        spawn(function()
            local ok,response=pcall(function()
                local payload=Http:JSONDecode(httpGet(url))
                assert(type(payload)=='table' and type(payload.result)=='table',type(payload)=='table' and payload.message or 'Invalid ScriptBlox response')
                assert(type(payload.result.scripts)=='table','ScriptBlox returned no script list')
                return payload.result
            end)
            if ui.destroyed or serial~=hub.serial then return end
            if not ok then hubInfo.Text='Search failed. Press SEARCH to retry.';report('ScriptBlox: '..tostring(response),'Error');return end
            hubLoaded=true;hub.page=page;hub.total=math.max(1,tonumber(response.totalPages) or 1)
            for _,c in ipairs(hubConnections) do c:Disconnect() end;hubConnections={}
            for _,child in ipairs(nodes[66]:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
            nodes[66].CanvasPosition=Vector2.new(0,0)
            local count=0
            for _,item in ipairs(response.scripts) do
                if type(item)=='table' and type(item.title)=='string' then
                    count=count+1
                    local card=button(nodes[66],'',{Name='Hub_'..count,LayoutOrder=count,BackgroundColor3=colors.panel})
                    label(card,item.title,{Position=UDim2.fromOffset(14,14),Size=UDim2.new(1,-28,0,55),
                        Font=Enum.Font.GothamBold,TextSize=15,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
                    local gameName=type(item.game)=='table' and item.game.name or 'Universal'
                    label(card,tostring(gameName),{Position=UDim2.fromOffset(14,76),Size=UDim2.new(1,-28,0,28),
                        TextSize=12,TextColor3=colors.muted,TextTruncate=Enum.TextTruncate.AtEnd})
                    label(card,(item.verified and 'VERIFIED  ·  ' or '')..tostring(item.views or 0)..' views',{
                        Position=UDim2.fromOffset(14,120),Size=UDim2.new(1,-28,0,18),TextSize=11,TextColor3=colors.accent})
                    table.insert(hubConnections,connect(card.Activated,function()
                        hub.selected=item;nodes[85].Text=item.title;nodes[86].Text='Choose what to do with this script.';showPopup(nodes[82])
                    end))
                end
            end
            hubInfo.Text=(count==0 and 'No scripts found. ' or '')..'Page '..page..' / '..hub.total..'  ·  Powered by ScriptBlox.com'
            prev.Active=page>1;nextButton.Active=page<hub.total
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
            p.frame.AnchorPoint=Vector2.new(0,0);p.frame.Position=UDim2.fromScale(channel=='roblox' and 0 or .515,0)
            p.frame.Size=UDim2.fromScale(.485,1);p.frame.ZIndex=2
            p.scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;p.scroll.CanvasSize=UDim2.new();p.scroll.ScrollBarThickness=4
            p.search.Text='';p.search.ClearTextOnFocus=false;p.search.PlaceholderText='Filter logs';p.search.TextSize=12
            p.search.Size=UDim2.new(.65,0,0,24);p.search.Position=UDim2.new(.3,0,.17,0)
            make('UIListLayout',p.scroll,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
            connect(p.search:GetPropertyChangedSignal('Text'),function() renderLogs(channel) end)
            bind(p.clear,function() state.logs[channel]={};renderLogs(channel) end)
        end
        nodes[694].Text='Script execution, errors and frontend messages.'
        renderLogs=function(channel)
            local p=panes[channel];if not p then return end
            for _,child in ipairs(p.scroll:GetChildren()) do if child:IsA('TextLabel') then child:Destroy() end end
            local query=p.search.Text:lower()
            for i,entry in ipairs(state.logs[channel]) do
                if entry.text:lower():find(query,1,true) then
                    label(p.scroll,'['..entry.time..'] '..entry.text,{LayoutOrder=i,Size=UDim2.new(1,-12,0,0),
                        AutomaticSize=Enum.AutomaticSize.Y,Font=Enum.Font.Code,TextSize=12,TextWrapped=true,
                        TextColor3=entry.level=='Error' and colors.error or entry.level=='Warn' and Color3.fromRGB(250,194,108) or colors.text})
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
        nodes[128].VerticalAlignment=Enum.VerticalAlignment.Top;nodes[128].Padding=UDim.new(0,8)
        nodes[127].AutomaticCanvasSize=Enum.AutomaticSize.Y;nodes[127].CanvasSize=UDim2.new();nodes[127].ScrollBarThickness=5
        nodes[114].TextSize=15;nodes[114].TextScaled=false
        local function filter()
            local query=nodes[114].Text:lower()
            for _,row in ipairs(settingsRows) do
                local matches=row.title:lower():find(query,1,true)~=nil
                local enabled=row.key and state.settings[row.key]==true
                row.frame.Visible=matches and (mode=='All' or (mode=='Enabled' and enabled) or (mode=='Disabled' and row.toggle and not enabled))
            end
        end
        local function register(id,title,key,toggle)
            local frame=nodes[id];frame.Size=UDim2.new(1,-8,0,76);frame.LayoutOrder=id;frame.ClipsDescendants=false
            for _,child in ipairs(frame:GetChildren()) do
                if child:IsA('TextLabel') then
                    child.TextScaled=false;child.TextSize=child.Name=='Title' and 15 or 12
                    child.AnchorPoint=Vector2.new(0,0);child.Position=UDim2.fromOffset(16,child.Name=='Title' and 13 or 39)
                    child.Size=UDim2.new(1,-195,0,child.Name=='Title' and 22 or 30);child.TextWrapped=true
                end
            end
            table.insert(settingsRows,{frame=frame,title=title,key=key,toggle=toggle})
            return frame
        end
        local function iconAppearance()
            local palette={Blue=Color3.fromRGB(34,160,255),Green=Color3.fromRGB(46,184,135),Purple=Color3.fromRGB(153,100,241)}
            launcher.BackgroundColor3=palette[state.settings.iconColor]
            local corner=round(launcher,state.settings.iconShape=='Square' and 0 or state.settings.iconShape=='Circle' and 100 or 15)
            if state.settings.iconShape=='Circle' then corner.CornerRadius=UDim.new(.5,0) end
            resize()
        end
        local function applyTheme()
            local name=state.settings.theme
            local bg=name=='Light' and Color3.fromRGB(235,238,244) or name=='Amoled' and Color3.new(0,0,0) or colors.field
            local fg=name=='Light' and Color3.fromRGB(32,38,52) or colors.text
            nodes[369].BackgroundColor3=bg;editor.TextColor3=fg
            editor.PlaceholderColor3=name=='Light' and Color3.fromRGB(90,100,115) or colors.muted
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
        for _,item in ipairs(switches) do
            local frame=register(item[1],item[2],item[3],true);local sw=nodes[item[4]]
            sw.AnchorPoint=Vector2.new(1,.5);sw.Position=UDim2.new(1,-18,.5,0);sw.Size=UDim2.fromOffset(44,24)
            removeChildren(sw);round(sw,12)
            local knob=make('Frame',sw,{Name='Knob',Size=UDim2.fromOffset(18,18),BackgroundColor3=colors.text,BorderSizePixel=0});round(knob,9)
            local function paint()
                local on=item[3] and state.settings[item[3]]==true
                sw.BackgroundColor3=on and colors.accent or Color3.fromRGB(68,73,86)
                knob.Position=UDim2.new(on and 1 or 0,on and -21 or 3,0,3)
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
        local function showDropdown(anchor,values,selected,choose)
            closePopup()
            local p=make('Frame',gui,{Name='Dropdown',Position=UDim2.fromOffset(anchor.AbsolutePosition.X,anchor.AbsolutePosition.Y+anchor.AbsoluteSize.Y+4),
                Size=UDim2.fromOffset(175,#values*38+12),BackgroundColor3=colors.panel,BorderSizePixel=0,ZIndex=80});round(p,8)
            dropdown=p
            local v=viewport()
            p.Position=UDim2.fromOffset(math.max(8,math.min(anchor.AbsolutePosition.X,v.X-183)),
                math.max(8,math.min(anchor.AbsolutePosition.Y+anchor.AbsoluteSize.Y+4,v.Y-#values*38-20)))
            for i,value in ipairs(values) do
                button(p,(value==selected and '•  ' or '')..value,{Position=UDim2.fromOffset(6,6+(i-1)*38),
                    Size=UDim2.fromOffset(163,32),ZIndex=81},function() choose(value);closePopup() end)
            end
        end
        local drops={{217,'FPS Cap','fpsCap',221,223,224,225,{'60 FPS','120 FPS','Max FPS'}},
            {246,'Icon Size','iconSize',250,252,253,254,{'Small','Medium','Large'}},
            {275,'Icon Shape','iconShape',279,281,282,283,{'Circle','Squircle','Square'}},
            {304,'Icon Color','iconColor',308,310,311,312,{'Blue','Green','Purple'}}}
        for _,item in ipairs(drops) do
            register(item[1],item[2],item[3],false)
            nodes[item[7]]:Destroy();nodes[item[6]]:Destroy()
            local b=nodes[item[4]];b.AnchorPoint=Vector2.new(1,.5);b.Position=UDim2.new(1,-16,.5,0);b.Size=UDim2.fromOffset(140,34)
            nodes[item[5]].Text=state.settings[item[3]];nodes[item[5]].TextScaled=false;nodes[item[5]].TextSize=12
            bind(b,function() showDropdown(b,item[8],state.settings[item[3]],function(value)
                if applySetting(item[3],value) then nodes[item[5]].Text=value end
            end) end)
        end
        nodes[375]:Destroy()
        local theme=function() showDropdown(nodes[371],{'Default','Light','Amoled'},state.settings.theme,function(v) applySetting('theme',v) end) end
        bind(nodes[371],theme);bind(nodes[372],theme)
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
            local b=nodes[item[3]];b.AnchorPoint=Vector2.new(1,.5);b.Position=UDim2.new(1,-16,.5,0);b.Size=UDim2.fromOffset(140,34)
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
    -- Optional exact asset IDs or local PNGs can replace fallbacks without touching logic.
    if type(options.Assets)=='table' then
        local map={i1={53},i2={63,112,548},i3={49},i7={37},i9={29,106,628},i12={45},i15={41},i18={57}}
        for asset,ids in pairs(map) do
            local uri=options.Assets[asset]
            if type(uri)=='string' then
                for _,id in ipairs(ids) do if nodes[id] and nodes[id].Parent then nodes[id].Image=uri end end
            end
        end
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
        if shared.__DeltaPC==ui then shared.__DeltaPC=nil end
    end
    shared.__DeltaPC=ui
    connect(gui.Destroying,function() ui.close() end)
    hide()
    if #propertyFailures>0 then report(tostring(#propertyFailures)..' captured properties were unsupported; fallbacks applied.') end
    if type(api('writefile'))~='function' then report('Ready. File saving unavailable; scripts persist for this session.') end
    if not ui.teleportSupported then report('Teleport auto reload unavailable: your executor has no queue_on_teleport.') end
    return ui
end
