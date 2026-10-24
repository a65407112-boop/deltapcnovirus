-- Delta PC frontend; uses the executor that is running this loader.
local compiler = loadstring
assert(type(compiler) == "function", "This loader requires an executor with loadstring.")
local ok, source = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/client.lua")
end)
assert(ok and type(source) == "string" and #source > 0, "Cannot download Delta PC: " .. tostring(source))
local chunk, reason = compiler(source, "@DeltaPC/client")
assert(type(chunk) == "function", "Cannot compile Delta PC: " .. tostring(reason))
local start = chunk()
assert(type(start) == "function", "Delta PC download is not a valid client.")
return start({keyed = false})
