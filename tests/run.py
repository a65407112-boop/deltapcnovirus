"""Run Lua tests with a system Lua 5.4 shared library, without pip dependencies."""
import ctypes
import ctypes.util
from pathlib import Path
import os

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
lib = ctypes.CDLL(ctypes.util.find_library('lua5.4') or 'liblua5.4.so.0')
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.luaL_loadfilex.restype = ctypes.c_int
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_pcallk.restype = ctypes.c_int
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]

tests = sorted(Path('tests').glob('test_*.lua'))
failed = 0
for test in tests:
    state = lib.luaL_newstate()
    lib.luaL_openlibs(state)
    status = lib.luaL_loadfilex(state, str(test).encode(), None)
    if not status:
        status = lib.lua_pcallk(state, 0, 0, 0, 0, None)
    if status:
        print(f'FAIL {test}: {lib.lua_tolstring(state, -1, None).decode()}', flush=True)
        failed += 1
    else:
        print(f'PASS {test}', flush=True)
    lib.lua_close(state)
raise SystemExit(1 if failed else 0)
