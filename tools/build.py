from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
pieces=['-- Delta PC frontend: generated bundle. Edit src/ and run python tools/build.py.\n']
for name in ('core','skin'):
    pieces.append('local '+name.capitalize()+' = (function()\n'+(ROOT/'src'/f'{name}.lua').read_text()+'\nend)()\n')
pieces.append((ROOT/'src/controller.lua').read_text())
(ROOT/'client.lua').write_text('\n'.join(pieces))
for keyed,name in [(True,'keyed'),(False,'keyless')]:
    (ROOT/f'{name}.lua').write_text('''-- Delta PC frontend; uses the executor that is running this loader.
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
return start({keyed = '''+str(keyed).lower()+'''})
''')
print('Built client.lua, keyed.lua and keyless.lua')
