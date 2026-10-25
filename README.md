# Delta PC GUI

Lua frontend built from the supplied Delta GUI hierarchy and the original textures/font in `Assets.zip`, with newly written button logic. It uses the executor running the loader to compile and execute Lua. This is an independent recreation, not native Delta or its license service.

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
| Right Shift | Open / hide when a text field is not focused |
| Ctrl+Enter | Run the active editor tab |
| Execute | Compile and run the active tab through the host executor's `loadstring` |
| Clear | Clear the active tab only |
| Execute Clipboard | Run clipboard text if the host provides clipboard reading; otherwise paste with Ctrl+V |
| + / tab / × | Add, switch and close tabs; at most 30 tabs |
| Home → Upload | Save Lua source or load a raw HTTPS source URL into the local saved-script list |
| Saved script actions | Original EXECUTE / DELETE buttons; click the title to edit; right-click the title to toggle AUTO |
| Script Hub | Enter a search or click its search icon; scroll for more results; execute / open / save / copy the selected script |
| Console | Search and clear Roblox logs and frontend execution messages separately |

Touch dragging is supported too. The panels use the original viewport-relative layout. Script compile/runtime errors appear in a temporary notification and the console. Re-running a loader cleans up the previous frontend's listeners and UI.

## Executor workspace saving

The frontend creates **`DeltaPC/`** inside the invoking executor's workspace and writes:

```text
DeltaPC/state-v2.json
DeltaPC/assets/<content-fingerprint>-<original-name>.png
DeltaPC/assets/<content-fingerprint>-f1.json
```

This stores editor tabs and their source, the selected tab, saved scripts, settings, and icon position. Changes are saved after a short debounce, and state is flushed when the frontend closes or a teleport starts. Both loaders share the same saved workspace. Script text is stored inside the JSON file, not as separate `.lua` files.

First launch requires `makefolder`, `writefile`, `readfile`, and `getcustomasset` (or `getsynasset`) to load the original graphics on PC. The 18 required files are cached; byte length and checksum are checked before registration. Missing asset APIs or damaged downloads produce a specific error instead of replacement icons. Already registered assets can be reused within the same session. It does not upload saved scripts to GitHub or ScriptBlox.

Auto Execute runs only your saved scripts marked **AUTO**, and only when the **Auto Execute** setting is enabled. It runs once after the interface is unlocked/opened in a session. It does not scan unrelated executor folders.

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

The supplied RBXM contains 700 objects including an exporter README, but no original event handlers. `src/skin.lua` reconstructs its 699 GUI/data objects. All 74 original files from `Assets.zip` are preserved under `assets/`; the runtime uses the 16 referenced images, Montserrat `f1`, and the supplied `logo.png` for the draggable launcher. The captured hierarchy has no launcher object.

The original editor wallpaper, sidebar icons, Montserrat font, relative panel positions, rounded controls, popup layouts and dropdowns are retained. Tabs, saved scripts, hub cards and console lines clone the captured templates. The custom desktop frame, added navigation captions, replacement glyphs and extra permanent toolbar have been removed. Source ZIndex values are mapped to ordered small integers without collapsing layers. Dynamic scroll entries use viewport-derived pixel sizes to prevent canvas growth from resizing their controls. The key panel moves from its captured closed position to its open right edge.

This restores the provided GUI assets and structure; its native executor implementation and remote licensing are not contained in these files. The keyed loader uses the local key described above. `OldUI.png` and `NewUI.png` are reference images from the archive, not images used to fake a working interface.

## Source and validation

| File | Purpose |
| --- | --- |
| `src/core.lua` | State, key gate, tabs, settings and saved-script validation |
| `src/skin.lua` | Generated captured GUI, with portable public properties |
| `src/asset_loader.lua` / generated `src/assets.lua` | Original asset cache, integrity checks and customasset registration |
| `assets/` | Unmodified files from the supplied archive |
| `src/controller.lua` | Input, actions, execution, persistence, network and teleport lifecycle |
| `client.lua` | Generated runtime bundle shared by both loaders |
| `tools/build.py` | Rebuild the bundle and loaders |
| `tools/build_skin.py` | Regenerate the skin from the supplied uncompressed RBXM |
| `tools/build_assets.py` | Generate content fingerprints and checksums |
| `docs/asset-map.json` / `docs/asset-manifest.json` | Source image mapping and runtime cache metadata |
| `tests/` | Lua behavior tests and the engine boundary double |

```bash
# Only when changing the source snapshot:
# python tools/build_skin.py /path/to/the/supplied.rbxm
python tools/build_assets.py
python tools/build.py
python tests/run.py
```

The test runner requires a system Lua 5.4 shared library. Nine test files cover asset integrity/caching, original styling/templates, enabled click targets, real source execution, key modes, loaders, tabs, clipboard handling, workspace round trips, mouse/touch drag, viewport clamping, selected ScriptBlox actions, stale results, API failure handling, settings, logs, cleanup and teleport queue code.

**Test boundary:** these are Lua tests with a Roblox API double. Live Roblox rendering, injection, cross-universe teleport/reinjection and live service responses were not tested in this environment. Use a harmless script such as `print("Delta PC test")` for the first live check.

Reference material: [Roblox fonts](https://create.roblox.com/docs/reference/engine/datatypes/Font), [custom asset registration](https://docs.sunc.io/Filesystem/getcustomasset/), [Roblox GUI input](https://create.roblox.com/docs/reference/engine/classes/GuiButton), [teleport lifecycle](https://create.roblox.com/docs/reference/engine/enums/TeleportState), [ScriptBlox search](https://docs.scriptblox.com/docs/scripts/search), [ScriptBlox API documentation](https://docs.scriptblox.com/), [RBXM format](https://dom.rojo.space/binary.html), and the supplied snapshot itself. Delta's [official site](https://deltaexploits.gg/) does not provide the original handlers contained in a running client.
