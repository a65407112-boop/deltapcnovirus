dofile('tests/roblox_mock.lua')
local start=assert(loadfile('client.lua'))()
local ui=start({keyed=false})
ui.open()
ui.editor.Text='_G.tabOne = true'
ui.nodes[416].Activated:Fire();ui.editor.Text='_G.tabTwo = true'
ui.state:saveScript('My script','_G.saved=true',false)
ui.state:setSetting('iconSize','Large')
Mock.flush()
assert(Mock.files['DeltaPC/state-v2.json'],'Executor workspace state must be written')
ui.close()
ui=start({keyed=false});ui.open()
assert(#ui.state.tabs==2 and ui.editor.Text=='_G.tabTwo = true')
assert(ui.state.tabs[1].source=='_G.tabOne = true' and ui.state.settings.iconSize=='Large')
assert(#ui.state.saved==1 and ui.state.saved[1].title=='My script')

Mock.clipboard='_G.clipboardRuns=(_G.clipboardRuns or 0)+1'
ui.nodes[405].Activated:Fire()
assert(_G.clipboardRuns==1)
getclipboard=nil
ui.nodes[405].Activated:Fire()
assert(_G.clipboardRuns==1 and Mock.focused==ui.editor)
Mock.focused=nil
Mock.keys[Enum.KeyCode.LeftControl]=true
Mock.services.UserInputService.InputBegan:Fire({KeyCode=Enum.KeyCode.Return},true)
assert(_G.tabTwo)
Mock.keys[Enum.KeyCode.LeftControl]=false
Mock.services.UserInputService.InputBegan:Fire({KeyCode=Enum.KeyCode.RightShift},false)
assert(not ui.state.opened)
Mock.services.UserInputService.InputBegan:Fire({KeyCode=Enum.KeyCode.RightShift},false)
assert(ui.state.opened)

-- Hub cards with identical titles execute the selected ID, never a fresh title search.
local fetch='https://scriptblox.com/api/script/fetch?mode=free&max=20&page=1'
Mock.http[fetch]=Mock.json({result={totalPages=2,nextPage=2,max=20,scripts={
    {_id='one',slug='first',title='Same title',game={name='Game'},views=1,script='_G.which=1'},
    {_id='two',slug='second',title='Same title',game={name='Game'},views=2,script='_G.which=2'},
}}})
ui.nodes[38].Activated:Fire();Mock.flush()
local card=assert(ui.nodes[66]:FindFirstChild('Hub_2'))
card.Activated:Fire();ui.nodes[89].Activated:Fire();Mock.flush()
assert(_G.which==2)
card.Activated:Fire();ui.nodes[93].Activated:Fire();Mock.flush()
assert(ui.editor.Text=='_G.which=2' and ui.state.page=='Executor')
ui.nodes[38].Activated:Fire();card.Activated:Fire();ui.nodes[101].Activated:Fire();Mock.flush()
assert(Mock.clipboard=='_G.which=2')
card.Activated:Fire();ui.nodes[97].Activated:Fire();Mock.flush()
assert(ui.state.saved[#ui.state.saved].source=='_G.which=2')

-- Unsupported native settings must not claim they enabled protection.
ui.nodes[42].Activated:Fire();ui.nodes[134].Activated:Fire()
assert(ui.nodes[139].Value==false and ui.status.Text:find('requires native Delta',1,true))
ui.nodes[178].Activated:Fire();assert(ui.state.settings.autoExecute)
ui.nodes[250].Activated:Fire()
local dropdown=assert(ui.gui:FindFirstChild('Dropdown'))
local small
for _,b in ipairs(dropdown:GetChildren()) do if b:IsA('TextButton') and b.Text=='Small' then small=b end end
assert(small);small.Activated:Fire();assert(ui.state.settings.iconSize=='Small' and ui.launcher.Size.X.Offset==44)

ui.nodes[50].Activated:Fire()
Mock.services.LogService.MessageOut:Fire('A specific warning',Enum.MessageType.MessageWarning);Mock.flush()
assert(ui.state.logs.roblox[#ui.state.logs.roblox].text=='A specific warning')
ui.nodes[649].Activated:Fire();assert(#ui.state.logs.roblox==0)
ui.close()

-- Missing APIs still permit local editing; compile failures are not swallowed.
readfile=nil;writefile=nil;setfpscap=nil;getclipboard=nil;setclipboard=nil
ui=start({keyed=false});ui.open()
local compiler=loadstring;loadstring=nil
assert(not ui.execute('return 1','unsupported'))
assert(ui.status.Text:find('does not provide loadstring',1,true))
loadstring=compiler
ui.close()
assert(Mock.liveConnections()==0)
print('Features: workspace reload, clipboard, PC keys, hub ID actions, settings, logs, absent APIs')
