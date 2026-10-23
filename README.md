# Delta Captured GUI (two loaders)

Independent, custom GUI created from the supplied .rbxm dump. Not official Delta or an OpenAI product.

## Start with the Delta icon, no key

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyless.lua"))()
```

## Start with the Delta icon, joke key enabled

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyed.lua"))()
```

Key: `CHATGPT-MADE-THIS` (local check; no external login).

Both loaders fetch the original captured layout in `client.lua` and the compatibility enhancements in `patch.lua`. The UI starts hidden, with a Delta-inspired launcher icon. The icon hides when the GUI opens and reappears on closing. The patch adds native sidebar icon fallbacks for Android-only images, consistent fonts, a visible execution status and a repaired Execute action, and improves ScriptBlox card visibility and selected-script execution. The ScriptBlox API requires a working HTTP request implementation from your executor.

**Important:** This is a frontend, not an independent script engine. It depends on the invoking executor's `loadstring` implementation. Running untrusted scripts can be unsafe and Roblox may restrict exploit tools.

The exported original PNGs are referenced by Android-local `rbxasset://<hash>/iN` paths, which cannot load in a separate executor. Native fallback symbols are used until those files can be republished through supported Roblox asset IDs. This preserves the main GUI layout but not all exact decorative images.

The ChatGPT-inspired credits mention [chatgpt.com](https://chatgpt.com) as ChatGPT's website, not this project's official site. Script Hub attribution remains **Powered by ScriptBlox.com**.

Automated mock-runtime checks cover both startup modes, icon transitions, Lua execution, and compilation errors. Live injection and networking were not verified.
