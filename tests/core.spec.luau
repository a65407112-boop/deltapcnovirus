local Core = require("../src/core")
local passed = 0
local function check(name, fn)
    local ok, err = pcall(fn)
    if not ok then error(name .. ": " .. tostring(err), 0) end
    passed += 1
    print("PASS " .. name)
end
local function eq(actual, expected)
    assert(actual == expected, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end

check("independent editor tabs survive selection and closing", function()
    local model = Core.new()
    local first = model:active()
    model:setSource("first")
    local second = assert(model:addTab("Second", "second"))
    eq(model:active().source, "second")
    assert(model:select(first.id))
    eq(model:active().source, "first")
    assert(model:closeTab(first.id))
    eq(model:active().id, second.id)
    assert(model:closeTab(second.id))
    eq(#model.tabs, 1)
    eq(model:active().source, "")
    assert(not model:select(-1))
end)

check("tab limit does not lose the selected source", function()
    local model = Core.new()
    for index = 2, Core.MAX_TABS do assert(model:addTab("Tab " .. index, tostring(index))) end
    local active = model:active()
    assert(not model:addTab("overflow", "lost"))
    eq(model:active(), active)
    eq(#model.tabs, Core.MAX_TABS)
end)

check("save updates a matching title and preserves other scripts", function()
    local model = Core.new()
    local first = assert(model:saveScript("  My script  ", "one"))
    assert(model:saveScript("Other", "other"))
    local updated, action = model:saveScript("my SCRIPT", "two")
    eq(updated.id, first.id)
    eq(action, "updated")
    eq(#model.library, 2)
    eq(model.library[1].source, "two")
    assert(model:deleteScript(first.id))
    eq(#model.library, 1)
    eq(model.library[1].source, "other")
    assert(not model:saveScript("  ", "x"))
    assert(not model:saveScript("Empty", "  \n"))
end)

check("persistent state round trip includes all tabs and settings", function()
    local model = Core.new()
    model:setSource("first\nprint('a')")
    model:addTab("Another", "print('b')")
    model:saveScript("Saved", "print('c')")
    model.settings.scale = 0.9
    model.settings.transparency = 0.22
    local snapshot = model:export()
    local restored = Core.new(snapshot)
    eq(#restored.tabs, 2)
    eq(restored.tabs[1].source, "first\nprint('a')")
    eq(restored:active().title, "Another")
    eq(restored.library[1].source, "print('c')")
    eq(restored.settings.scale, 0.9)
    snapshot.tabs[1].source = "mutated snapshot"
    eq(restored.tabs[1].source, "first\nprint('a')")
    eq(model.tabs[1].source, "first\nprint('a')")
end)

check("malformed persistence cannot supply functions or invalid settings", function()
    for _, input in { false, "bad", 4, {}, { version = 999 }, { tabs = "bad", library = true } } do
        local model = Core.new(input)
        eq(#model.tabs, 1)
        assert(model:active())
    end
    local model = Core.new({
        version = 1,
        tabs = { false, { title = "Okay", source = "okay" }, { title = {}, source = function() end } },
        activeIndex = -100,
        library = { { title = "Good", source = "good" }, { title = "good", source = "duplicate" } },
        settings = { scale = 0 / 0, transparency = 100, surprise = "ignored" },
    })
    eq(#model.tabs, 1)
    eq(model:active().source, "okay")
    eq(#model.library, 1)
    eq(model.settings.scale, 1)
    eq(model.settings.transparency, 0.4)
    eq(model.settings.surprise, nil)
end)

check("execution validates source and compiler availability", function()
    local empty = Core.execute(function() error("should not compile") end, " \n\t", "Tab")
    eq(empty.ok, false)
    eq(empty.phase, "input")
    local missing = Core.execute(nil, "print('hi')", "Tab")
    eq(missing.ok, false)
    eq(missing.phase, "unavailable")
end)

check("compile and runtime failures remain distinct", function()
    local invalid = Core.execute(function() return nil, "syntax issue" end, "bad", "Tab")
    eq(invalid.phase, "compile")
    eq(invalid.message, "syntax issue")
    local thrown = Core.execute(function() error("compiler bridge unavailable", 0) end, "code", "Tab")
    eq(thrown.phase, "compile")
    assert(string.find(thrown.message, "compiler bridge unavailable", 1, true))
    local runtime = Core.execute(function() return function() error("script broke", 0) end end, "code", "Tab")
    eq(runtime.phase, "runtime")
    eq(runtime.message, "script broke")
end)

check("execution uses source and returns actual result", function()
    local receivedSource, receivedName
    local result = Core.execute(function(source, name)
        receivedSource, receivedName = source, name
        return function() return 42 end
    end, "return 42", "My tab")
    eq(result.ok, true)
    eq(result.value, 42)
    eq(receivedSource, "return 42")
    eq(receivedName, "My tab")
end)

print(string.format("%d core tests passed", passed))
