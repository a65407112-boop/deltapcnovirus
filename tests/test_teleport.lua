dofile('tests/roblox_mock.lua')
local start=assert(loadfile('client.lua'))()
local queued={}
queue_on_teleport=function(code) queued[#queued+1]=code end
local ui=start({keyed=false});ui.open();ui.editor.Text='print("travels with me")'
Mock.services.Players.LocalPlayer.OnTeleport:Fire(Enum.TeleportState.Started)
assert(#queued==1,'Queue a loader when teleport starts')
assert(Mock.files['DeltaPC/state-v2.json'],'Persist before leaving')
Mock.services.Players.LocalPlayer.OnTeleport:Fire(Enum.TeleportState.InProgress)
assert(#queued==1,'Do not queue duplicate loaders for one teleport')
local source=queued[1]
ui.close()
local ran=0
Mock.http['https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyless.lua']='return function() end'
-- Capture the target loader request; no external code or network is used.
game.JobId='destination';game.PlaceId=999
Mock.http['https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyless.lua']='_G.teleportedLoaderRan=true'
assert(load(source))()
assert(_G.teleportedLoaderRan,'Queued code must fetch and execute keyless loader')
assert(_G.__DeltaPCTeleportQueued==nil)
ui=start({keyed=true})
Mock.services.Players.LocalPlayer.OnTeleport:Fire(Enum.TeleportState.Started)
assert(#queued==2)
Mock.http['https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyed.lua']='_G.keyedTeleport=true'
game.JobId='another';assert(load(queued[2]))();assert(_G.keyedTeleport)
ui.close()
queue_on_teleport=nil
ui=start({keyed=false})
assert(ui.teleportSupported==false)
ui.close()
print('Teleport: save, queue once, same loader mode, destination execution, unsupported host')
