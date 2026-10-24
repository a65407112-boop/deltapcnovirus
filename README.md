# Delta PC GUI

A fresh Lua frontend based on the supplied Delta GUI snapshot, with newly written button logic. It uses the executor running the loader to compile and execute Lua. This is an independent recreation, not native Delta or its license service.

## Loadstrings

**Without a key**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyless.lua"))()
```

**With a local key**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/keyed.lua"))()
```

Key: **`CHATGPT-MADE-THIS`**. This is a local demo gate, not server-side authentication or a Delta key bypass. Both versions start with a floating Delta icon.

## PC controls

| Control | Action |
| --- | --- |
| Click the floating icon | Open the GUI or key panel |
| Drag the icon with the mouse | Move it; releasing a drag does not open the GUI |
| Drag the top header | Move the main window within the screen |
| Right Shift | Open / hide when a text field is not focused |
| Ctrl+Enter | Run the active editor tab |
| Execute | Compile and run the active tab through the host executor's `loadstring` |
| Clear | Clear the active tab only |
| Execute Clipboard | Run clipboard text if the host provides clipboard reading; otherwise paste with Ctrl+V |
| + / tab / × | Add, switch and close tabs; at most 30 tabs |
| Home → Upload | Save Lua source or load a raw HTTPS source URL into the local saved-script list |
| Saved script actions | Edit, execute, delete or mark for Auto Execute |
| Script Hub | Search ScriptBlox, change pages, then execute / open / save / copy the selected script |
| Console | Search and clear Roblox logs and frontend execution messages separately |

Touch dragging is supported too. Window scaling follows the viewport. Script compile/runtime errors are visible in the status bar and console. Re-running a loader cleans up the previous frontend's listeners and UI.

## Executor workspace saving

The frontend creates **`DeltaPC/`** inside the invoking executor's workspace and writes:

```text
DeltaPC/state-v2.json
```

This stores editor tabs and their source, the selected tab, saved scripts, settings, and icon position. Changes are saved after a short debounce, and state is flushed when the frontend closes or a teleport starts. Both loaders share the same saved workspace. Script text is stored inside the JSON file, not as separate `.lua` files.

Saving requires working `makefolder` / `writefile`; restoring requires `readfile`. Without those APIs the frontend remains usable for the current session and reports the limitation. It does not upload saved scripts to GitHub or ScriptBlox.

Auto Execute runs only your saved scripts marked **AUTO: ON**, and only when the **Auto Execute** setting is enabled. It runs once after the interface is unlocked/opened in a session. It does not scan unrelated executor folders.

## Teleport auto reload

When Roblox starts teleporting, the frontend saves its state and queues the same GitHub loader in the destination. It supports `queue_on_teleport`, `queueonteleport`, `syn.queue_on_teleport`, and `fluxus.queue_on_teleport` when supplied by the host. The destination loader waits for the game to load. Duplicate lifecycle events do not queue extra copies.

This depends on the executor supporting teleport queuing and reinjection in the destination place/universe. If that API is missing, the UI reports it. The keyed version remains keyed after teleport and requests the local key again. Your tabs and saved scripts restore from the workspace.

## Settings and compatibility

- FPS cap uses `setfpscap`; the saved cap is reapplied when supported.
- Icon size, shape and color apply to the draggable launcher.
- Default, Light and AMOLED change the editor theme.
- Console logging, popup auto-close and saved-script auto-execution are controlled by their switches.
- Anti AFK uses host-accessible VirtualUser input. Native idle-kick bypasses are not implemented.
- Rejoin, Small Server and Serverhop call Roblox teleport APIs; availability depends on current Roblox/server restrictions and HTTP access.
- Anti Scam, Disable Robux, RakNet and Verify Teleports are native Delta features. Their captured rows explain that they are unavailable here; toggling them does not claim protection that is not implemented.

The supplied RBXM contains 700 objects including an exporter README, but no original event handlers. `Assets.zip` was not accessible in the workspace. Native shapes, symbols and bundled Roblox fonts replace Android-local textures/fonts. The hierarchy, colors and control groups come from the snapshot, with PC sizing and layout corrections. Exact original graphics and native behavior are not claimed.

## Source and validation

| File | Purpose |
| --- | --- |
| `src/core.lua` | State, key gate, tabs, settings and saved-script validation |
| `src/skin.lua` | Generated captured GUI, with portable public properties |
| `src/controller.lua` | Input, actions, execution, persistence, network and teleport lifecycle |
| `client.lua` | Generated runtime bundle shared by both loaders |
| `tools/build.py` | Rebuild the bundle and loaders |
| `tools/build_skin.py` | Regenerate the skin from the supplied uncompressed RBXM |
| `docs/asset-map.json` | Android image names mapped to captured node IDs |
| `tests/` | Lua behavior tests and the engine boundary double |

```bash
python tools/build.py
python tests/run.py
```

The test runner requires a system Lua 5.4 shared library. Seven test files cover real source execution, key modes, loaders, tabs, clipboard handling, workspace round trips, mouse/touch drag, viewport clamping, selected ScriptBlox actions, stale results, API failure handling, settings, logs, cleanup and teleport queue code.

**Test boundary:** these are Lua tests with a Roblox API double. Live Roblox rendering, injection, cross-universe teleport/reinjection and live service responses were not tested in this environment. Use a harmless script such as `print("Delta PC test")` for the first live check.

Reference material: [Roblox GUI input](https://create.roblox.com/docs/reference/engine/classes/GuiButton), [teleport lifecycle](https://create.roblox.com/docs/reference/engine/enums/TeleportState), [ScriptBlox search](https://docs.scriptblox.com/docs/scripts/search), [ScriptBlox API documentation](https://docs.scriptblox.com/), [RBXM format](https://dom.rojo.space/binary.html), and the supplied snapshot itself. Delta's [official site](https://deltaexploits.gg/) does not provide the original handlers contained in a running client.
