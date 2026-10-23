-- Delta-style GUI compatibility patch. Works on the existing captured client.
-- It does not provide a scripting engine; it uses the invoking executor's loadstring.
return function(ui, keyed)
    assert(type(ui) == 'table' and ui.gui and ui.state, 'GUI did not initialize')
    local screen, state = ui.gui, ui.state
    local HttpService = game:GetService('HttpService')
    local RunService = game:GetService('RunService')
    local connections={}
    local function connect(sig, cb)
        local c=sig:Connect(cb)
        table.insert(connections,c)
        return c
    end
    local function child(root, name)
        return root and root:FindFirstChild(name,true)
    end
    local function make(kind,parent,properties)
        local item=Instance.new(kind)
        for property,value in pairs(properties) do
            pcall(function()item[property]=value end)
        end
        item.Parent=parent
        return item
    end
    local function rounded(item,n)
        make('UICorner',item,{CornerRadius=UDim.new(0,n)})
    end
    local white=Color3.fromRGB(236,246,255)
    local muted=Color3.fromRGB(152,195,237)
    local navy=Color3.fromRGB(17,34,59)
    local family='rbxasset://fonts/families/GothamSSm.json'
    local function useFont(element)
        if element:IsA('TextLabel') or element:IsA('TextButton') or element:IsA('TextBox') then
            local weight=Enum.FontWeight.Regular
            pcall(function()weight=element.FontFace.Weight end)
            if element.Name~='CapturedEditor' and element.Name~='ConsoleInput' then
                pcall(function()element.FontFace=Font.new(family,weight,Enum.FontStyle.Normal) end)
            end
        end
    end
    for _,element in ipairs(screen:GetDescendants()) do
        useFont(element)
        if element:IsA('ImageLabel') or element:IsA('ImageButton') then
            if type(element.Image)=='string' and element.Image:find('rbxasset://',1,true)
                and not element.Image:find('rbxasset://textures/',1,true) then
                element.Image=''
            end
        end
    end
    -- Replace missing Android glyphs with a consistent built-in navigation icon set.
    local sidebar=screen:FindFirstChild('Sidebar')
    for _,info in ipairs({{'Home','H'},{'Scripthub','S'},{'Settings','⚙'},{'Executor','</>'},{'Console','>_'},{'ToggleUI','×'}}) do
        local button=sidebar and sidebar:FindFirstChild(info[1])
        if button then
            local icon=button:FindFirstChildOfClass('ImageLabel')
            if icon then
                icon.Image=''
                make('TextLabel',icon,{Name='BuiltInGlyph',Text=info[2],Size=UDim2.fromScale(1,1),
                    BackgroundTransparency=1,TextColor3=muted,Font=Enum.Font.GothamBold,
                    TextScaled=true,TextSize=22,ZIndex=math.max(20,icon.ZIndex+1)})
            end
        end
    end
    local originalIcon=screen:FindFirstChild('CustomReopen')
    if originalIcon then originalIcon.Visible=false end
    local launcher=make('ImageButton',screen,{Name='DeltaNativeLauncher',Image='',
        BackgroundColor3=navy,AutoButtonColor=true,BorderSizePixel=0,
        Size=UDim2.fromOffset(55,55),Position=UDim2.new(1,-70,.47,0),
        ZIndex=2000,Visible=true})
    rounded(launcher,16)
    make('UIStroke',launcher,{Thickness=2,Color=Color3.fromRGB(77,172,248)})
    make('UIGradient',launcher,{Rotation=125,Color=ColorSequence.new(
        Color3.fromRGB(11,29,59),Color3.fromRGB(20,105,174))})
    local logo=make('Frame',launcher,{Name='DeltaLogo',AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.47),Size=UDim2.fromScale(.7,.7),
        BackgroundTransparency=1,ZIndex=2001})
    for _,v in ipairs({{.18,.13,.16,.75,-25},{.52,.13,.16,.75,-25},{.16,.7,.7,.12,0}}) do
        local segment=make('Frame',logo,{BackgroundColor3=white,BorderSizePixel=0,
            Position=UDim2.fromScale(v[1],v[2]),Size=UDim2.fromScale(v[3],v[4]),
            Rotation=v[5],ZIndex=2002})
        rounded(segment,2)
    end
    make('TextLabel',launcher,{Text='DELTA',BackgroundTransparency=1,
        Position=UDim2.new(0,0,1,-13),Size=UDim2.new(1,0,0,11),
        TextSize=9,TextColor3=white,Font=Enum.Font.GothamBold,ZIndex=2003})
    local views={Home=true,Scripthub=true,Settings=true,Executor=true,Console=true}
    local keyPanel=screen:FindFirstChild('D1')
    local unlocked=not keyed
    local function switchMain(open)
        state.opened=open
        if sidebar then sidebar.Visible=open end
        for name in pairs(views) do
            local pane=screen:FindFirstChild(name)
            if pane and pane:IsA('Frame') then pane.Visible=open and state.page==name end
        end
        local toggle=sidebar and sidebar:FindFirstChild('ToggleUI')
        if toggle then toggle.Visible=open end
        local overlay=screen:FindFirstChild('DarkOverlay')
        if overlay then overlay.Visible=false end
        if originalIcon then originalIcon.Visible=false end
        launcher.Visible=not open
    end
    if keyPanel then keyPanel.Visible=false end
    switchMain(false)
    local function openLauncher()
        if not unlocked then
            if keyPanel then
                keyPanel.Visible=true
                launcher.Visible=false
            end
        else
            switchMain(true)
        end
    end
    connect(launcher.Activated,openLauncher)
    if keyed and keyPanel then
        local closeKey=make('TextButton',keyPanel,{Name='DeltaKeyClose',Text='×',TextColor3=white,
            TextSize=26,Font=Enum.Font.GothamBold,BackgroundTransparency=1,
            Size=UDim2.fromOffset(40,40),Position=UDim2.new(1,-42,0,0),ZIndex=2100})
        connect(closeKey.Activated,function()
            keyPanel.Visible=false
            launcher.Visible=true
        end)
    end
    -- Keep the launcher in sync with the existing GUI's own Close button.
    connect(RunService.RenderStepped,function()
        if not screen.Parent then return end
        if originalIcon then originalIcon.Visible=false end
        if keyed and not unlocked and state.opened then unlocked=true end
        launcher.Visible=not state.opened and not (keyPanel and keyPanel.Visible)
    end)
    local function status(label,message,color)
        if not label or not label.Parent then return end
        label.Text=tostring(message):sub(1,250)
        label.TextColor3=color or muted
    end
    local editorPane=screen:FindFirstChild('Executor')
    local source=child(editorPane,'CapturedEditor')
    local executeButton=child(editorPane,'Execute')
    local output=editorPane and make('TextLabel',editorPane,{Name='ExecuteStatus',
        BackgroundColor3=navy,BackgroundTransparency=.1,BorderSizePixel=0,
        Position=UDim2.new(.03,0,1,-25),Size=UDim2.new(.94,0,0,22),
        Text='Ready to execute',Font=Enum.Font.Code,TextSize=12,
        TextColor3=muted,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=150})
    if output then rounded(output,5) end
    local function execute(code,title)
        title=tostring(title or 'script')
        if type(code)~='string' or code:match('^%s*$') then
            status(output,'Empty script',Color3.fromRGB(255,192,109));return false
        end
        local fn=type(loadstring)=='function' and loadstring or nil
        if not fn and type(getgenv)=='function' then
            local ok,genv=pcall(getgenv)
            if ok and type(genv)=='table' and type(genv.loadstring)=='function' then fn=genv.loadstring end
        end
        if not fn then
            status(output,'Executor does not expose loadstring',Color3.fromRGB(255,130,130))
            warn('[Delta GUI] Missing loadstring provided by executor')
            return false
        end
        local compiled,chunk,syntaxError=pcall(fn,code)
        if not compiled or type(chunk)~='function' then
            local err=compiled and syntaxError or chunk
            status(output,'Compile error: '..tostring(err),Color3.fromRGB(255,130,130))
            warn('[Delta GUI] Compile error: '..tostring(err));return false
        end
        status(output,'Running '..title,muted)
        task.spawn(function()
            local ok,reason=pcall(chunk)
            if ok then status(output,'Completed '..title,Color3.fromRGB(126,229,168))
            else
                status(output,'Runtime error: '..tostring(reason),Color3.fromRGB(255,130,130))
                warn('[Delta GUI] Runtime error: '..tostring(reason))
            end
        end)
        return true
    end
    if executeButton and source then
        local blocker=make('TextButton',executeButton,{Name='WorkingExecute',Text='',
            AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,
            Size=UDim2.fromScale(1,1),ZIndex=math.max(120,executeButton.ZIndex+30)})
        connect(blocker.Activated,function()
            execute(source.Text,'editor')
        end)
    end
    -- Make ScriptBlox cards readable and capable of scrolling on all screens.
    local hubPane=screen:FindFirstChild('Scripthub')
    local holder=child(hubPane,'Holder')
    local savedCards={}
    if holder then
        local grid=holder:FindFirstChildOfClass('UIGridLayout')
        if grid then
            grid.CellSize=UDim2.new(.31,0,0,145)
            grid.CellPadding=UDim2.new(.028,0,0,12)
        end
        holder.AutomaticCanvasSize=Enum.AutomaticSize.Y
        holder.ScrollBarThickness=5
        local function styleCard(card)
            if not card:IsA('ImageButton') or not card.Name:match('^ScriptBlox_') then return end
            card.Image=''
            card.BackgroundColor3=Color3.fromRGB(33,54,80)
            card.BackgroundTransparency=0
            local pane=card:FindFirstChild('Overlay')
            local heading=pane and pane:FindFirstChild('Title')
            if heading then
                local title=heading:FindFirstChild('Title')
                local description=heading:FindFirstChild('Paragraph')
                if title then
                    title.TextScaled=false;title.TextWrapped=true;title.TextSize=14
                    title.TextXAlignment=Enum.TextXAlignment.Left
                    title.Size=UDim2.new(1,0,0,41)
                    title.Position=UDim2.fromScale(0,0)
                    useFont(title)
                end
                if description then
                    description.TextScaled=false;description.TextSize=11
                    description.Size=UDim2.new(1,0,0,25)
                    description.TextXAlignment=Enum.TextXAlignment.Left
                    useFont(description)
                end
            end
        end
        for _,c in ipairs(holder:GetChildren()) do styleCard(c) end
        connect(holder.ChildAdded,styleCard)
    end
    local popup=child(hubPane,'Popup')
    local popupRun=child(popup,'Button1')
    local popupTitleRow=popup and popup:FindFirstChild('Title')
    local popupTitle=popupTitleRow and popupTitleRow:FindFirstChild('Title')
    local hubInput=child(hubPane,'Input')
    local function getText(url)
        local last='No HTTP API'
        local api=type(request)=='function' and request
            or type(http_request)=='function' and http_request
            or (type(syn)=='table' and type(syn.request)=='function' and syn.request)
        if api then
            local ok,result=pcall(api,{Url=url,Method='GET'})
            if ok and type(result)=='table' and type(result.Body)=='string' and (not result.StatusCode or result.StatusCode<400) then return result.Body end
            last=tostring(result)
        end
        local ok,result=pcall(function()return game:HttpGet(url)end)
        if ok and type(result)=='string' then return result end
        last=tostring(result)
        error('ScriptBlox HTTP: '..last)
    end
    local function runSelected()
        local name=popupTitle and popupTitle.Text or ''
        if name=='' or name=='Select Your Option' then
            status(output,'Select a ScriptBlox card first',Color3.fromRGB(255,192,109))
            return
        end
        status(output,'Loading ScriptBlox source: '..name)
        task.spawn(function()
            local ok,code=pcall(function()
                local url='https://scriptblox.com/api/script/search?q='..HttpService:UrlEncode(name)..'&max=20&mode=free'
                local payload=HttpService:JSONDecode(getText(url))
                local list=payload and payload.result and payload.result.scripts or {}
                for _,item in ipairs(list) do
                    if item.title==name then
                        if type(item.script)=='string' and item.script~='' then return item.script end
                        if type(item._id)=='string' then
                            local raw=getText('https://scriptblox.com/api/script/raw/'..item._id)
                            if type(raw)=='string' and raw~='' then return raw end
                        end
                    end
                end
                error('Selected script was not found in ScriptBlox search')
            end)
            if not ok then
                status(output,'ScriptBlox: '..tostring(code),Color3.fromRGB(255,130,130))
                warn('[Delta GUI] ScriptBlox: '..tostring(code));return
            end
            if popup then popup.Visible=false end
            local shade=child(hubPane,'DarkOverlay')
            if shade then shade.Visible=false end
            execute(code,name)
        end)
    end
    if popupRun then
        local overlay=make('TextButton',popupRun,{Name='WorkingHubExecute',Text='',
            BackgroundTransparency=1,AutoButtonColor=false,
            Size=UDim2.fromScale(1,1),ZIndex=math.max(150,popupRun.ZIndex+30)})
        connect(overlay.Activated,runSelected)
    end
    ui.launcher=launcher
    ui.execute=execute
    local previousClose=ui.close
    ui.close=function()
        for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
        previousClose()
    end
    return ui
end
