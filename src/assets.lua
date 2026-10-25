-- Generated from the original Assets.zip. Do not hand-edit the manifest.
local version="f3d319012d835ead"
local records={
    {name="f1",path="DeltaPC/assets/cd6f59693cc7-f1.json",size=2108,checksum=2691763925},
    {name="i1",path="DeltaPC/assets/c40a4c22cfb7-i1.png",size=33868,checksum=3046439360},
    {name="i11",path="DeltaPC/assets/28011a17d748-i11.png",size=424,checksum=2488710118},
    {name="i12",path="DeltaPC/assets/b9c11eb16c21-i12.png",size=321,checksum=1575454463},
    {name="i14",path="DeltaPC/assets/b3e7a3ed56a1-i14.png",size=343,checksum=3519781344},
    {name="i15",path="DeltaPC/assets/4d5614355763-i15.png",size=235,checksum=1378704181},
    {name="i16",path="DeltaPC/assets/e884b1503c3f-i16.png",size=4055,checksum=1624302980},
    {name="i17",path="DeltaPC/assets/e52207bdb7ad-i17.png",size=297,checksum=4179131902},
    {name="i18",path="DeltaPC/assets/2b89b19066f8-i18.png",size=22555,checksum=2162377493},
    {name="i2",path="DeltaPC/assets/e91b26011619-i2.png",size=701,checksum=1263287605},
    {name="i3",path="DeltaPC/assets/67d0d179ddf3-i3.png",size=353,checksum=4281375705},
    {name="i4",path="DeltaPC/assets/b26a048c1c48-i4.png",size=481344,checksum=2265504967},
    {name="i5",path="DeltaPC/assets/2a7b643b991b-i5.png",size=33091,checksum=2305431098},
    {name="i6",path="DeltaPC/assets/8ad5588574e6-i6.png",size=61819,checksum=847015361},
    {name="i7",path="DeltaPC/assets/dfd428648d0a-i7.png",size=315,checksum=3413543616},
    {name="i8",path="DeltaPC/assets/3611c868e002-i8.png",size=1118,checksum=1864692186},
    {name="i9",path="DeltaPC/assets/eb28b71f78f4-i9.png",size=376,checksum=1766955963},
    {name="logo.png",path="DeltaPC/assets/02c01f53dcce-logo.png",size=91387,checksum=3102393375},
}
-- Included by tools/build_assets.py after the content manifest.
return function(api,httpGet,shared)
    local cached=shared.__DeltaPCAssets
    if type(cached)=='table' and cached.version==version and cached.placeId==game.PlaceId and cached.jobId==game.JobId then
        return function(uri) return cached.uris[uri:match('([^/]+)$')] or uri end
    end
    local register=api('getcustomasset') or api('getsynasset')
    assert(type(register)=='function','Delta textures require getcustomasset (or getsynasset) in your PC executor.')
    local read,write,mkdir=api('readfile'),api('writefile'),api('makefolder')
    assert(type(read)=='function' and type(write)=='function' and type(mkdir)=='function',
        'Delta textures require readfile, writefile and makefolder to cache the supplied assets.')
    pcall(mkdir,'DeltaPC');pcall(mkdir,'DeltaPC/assets')
    local function valid(data,r)
        if type(data)~='string' or #data~=r.size then return false end
        local a,b=1,0
        for i=1,#data do a=(a+data:byte(i))%65521;b=(b+a)%65521 end
        return b*65536+a==r.checksum
    end
    local uris={}
    for _,r in ipairs(records) do
        local ok,data=pcall(read,r.path)
        if not ok or not valid(data,r) then
            data=httpGet('https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/assets/'..r.name)
            assert(valid(data,r),'Delta asset download is damaged or outdated: '..r.name..'. Run the latest loader again.')
            write(r.path,data)
            assert(valid(read(r.path),r),'Delta asset could not be saved: '..r.name)
        end
        local uri=register(r.path)
        assert(type(uri)=='string' and uri~='','Your executor could not register Delta asset: '..r.name)
        uris[r.name]=uri
    end
    shared.__DeltaPCAssets={version=version,uris=uris,placeId=game.PlaceId,jobId=game.JobId}
    return function(uri) return uris[uri:match('([^/]+)$')] or uri end
end
