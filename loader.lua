-- Run this in Xeno after attaching to Roblox.
local source = game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/delta.lua")
local chunk, err = loadstring(source, "DeltaPC")
assert(chunk, err)
return chunk()
