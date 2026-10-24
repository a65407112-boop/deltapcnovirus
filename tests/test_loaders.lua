dofile('tests/roblox_mock.lua')
local f=assert(io.open('client.lua'));local bundle=f:read('*a');f:close()
local url='https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/client.lua'
Mock.http[url]=bundle
local ui=assert(loadfile('keyless.lua'))()
assert(not ui.state.locked);ui.close()
ui=assert(loadfile('keyed.lua'))()
assert(ui.state.locked);ui.close()
Mock.http[url]='<html>Rate limited</html>'
local ok,err=pcall(assert(loadfile('keyless.lua')))
assert(not ok and err:find('Cannot compile Delta PC',1,true))
print('Loaders: both modes use the built client; bad downloads fail clearly')
