dofile('tests/roblox_mock.lua')
local start=assert(loadfile('client.lua'))()
local ui=start({keyed=false});ui.open()
for i=2,30 do ui.nodes[416].Activated:Fire() end
local active=ui.state.activeTab
ui.state:saveScript('Overflow','print(31)');ui.renderSaved()
local saved=ui.state.saved[1]
ui.nodes[554]:FindFirstChild('Saved_'..saved.id).Edit.Activated:Fire()
assert(#ui.state.tabs==30 and ui.state.activeTab==active,'Every entrypoint must preserve the 30-tab limit')
ui.state:setSetting('fpsCap','120 FPS');ui.close()
Mock.fps=nil
ui=start({keyed=false})
assert(Mock.fps==120,'Restored FPS settings must actually be applied')
ui.open()
local strip,menu=ui.nodes[413],ui.nodes[371]
assert(strip.Position.X.Offset+strip.Size.X.Offset<0 or strip.Size.X.Scale<.9,'Tab strip must reserve space for theme menu')
assert(menu.ZIndex>strip.ZIndex,'Theme menu must be above tab strip')
ui.close()
setclipboard=nil;toclipboard=nil
ui=start({keyed=true});ui.open();ui.nodes[18].Activated:Fire()
local copy=ui.gui:FindFirstChild('CopyText',true)
assert(copy,'Key-screen clipboard fallback must exist')
local current=copy
while current and current~=ui.gui do
    assert(not current:IsA('GuiObject') or current.Visible,'Copy popup must not have a hidden parent')
    current=current.Parent
end
ui.close()

-- The nested + button must create a tab when its center is clicked.
readfile=nil;writefile=nil
ui=start({keyed=false});ui.open()
ui.nodes[418].Activated:Fire()
assert(#ui.state.tabs==2,'Clicking the + icon itself must add a tab')
ui.close()
print('Regressions: tab limits, restored FPS, menu overlap, locked copy, nested add-tab')
