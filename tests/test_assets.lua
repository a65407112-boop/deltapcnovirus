dofile('tests/roblox_mock.lua')
local build=assert(loadfile('src/assets.lua'))()
local function api(name) return _G[name] end
local function http(url) return game:HttpGet(url) end
local shared={}
local resolve=build(api,http,shared)
assert(#Mock.requests==18,'Load all 16 original textures, original font and supplied launcher logo')
assert(Mock.folders['DeltaPC/assets'],'Create nested executor workspace asset folder')
local uri=resolve('rbxasset://92086d2ee80b185556345bee4b2809f6/i6')
assert(uri:match('i6%.png$'),'Register a local PNG, not an Android URI or an HTTP Image property')
assert(resolve('f1'):match('f1%.json$'),'Register original Montserrat family JSON')
assert(resolve('rbxasset://fonts/families/GothamSSm.json')=='rbxasset://fonts/families/GothamSSm.json')
local count=#Mock.requests
build(api,http,{});assert(#Mock.requests==count,'A new session reuses validated disk cache')
local register=getcustomasset;local registrations=0
getcustomasset=function(path) registrations=registrations+1;return register(path) end
local oldJob=game.JobId;game.JobId='after-teleport'
build(api,http,shared)
assert(registrations==18 and #Mock.requests==count,'Register assets again in the destination without redownloading them')
game.JobId=oldJob;getcustomasset=register
-- Same-sized corrupted downloads/cache must be detected, not just nonempty or PNG headers.
local file=uri:match('^rbxasset://mock/(.+)$')
local bytes=Mock.files[file];Mock.files[file]=bytes:sub(1,-2)..string.char((bytes:byte(-1)+1)%256)
build(api,http,{});assert(#Mock.requests==count+1 and Mock.files[file]==bytes,'Repair corrupt cached texture')
Mock.files[file]=nil
local url='https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/assets/i6'
Mock.http[url]='<!doctype html>rate limit'
local ok,err=pcall(build,api,http,{})
assert(not ok and err:find('asset download is damaged',1,true),'Reject bad download before registering any placeholder')
Mock.http[url]=nil
local original=getcustomasset;getcustomasset=nil
ok,err=pcall(build,api,http,{})
assert(not ok and err:find('require getcustomasset',1,true),'Explain missing PC asset support')
getcustomasset=original
-- Failed replacement leaves the existing UI alive until assets are ready.
local start=assert(loadfile('client.lua'))()
local ui=start({keyed=false});local assetCache=_G.__DeltaPCAssets
_G.__DeltaPCAssets=nil;getcustomasset=nil
ok=pcall(start,{keyed=false});assert(not ok and not ui.destroyed)
getcustomasset=original;_G.__DeltaPCAssets=assetCache;ui.close()
print('Assets: all supplied mappings, local registration, disk cache, corruption repair, bad HTTP and missing APIs')
