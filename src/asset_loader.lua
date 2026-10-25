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
