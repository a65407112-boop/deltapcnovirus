# Delta captured GUI rebuild

Use the supplied RBXM hierarchy and Assets.zip directly. The user rejected the previous custom desktop layout and explicitly requested the original appearance. Publication to a65407112-boop/deltapcnovirus/main and replacement of the old files are authorized. Keep both keyed.lua and keyless.lua URLs.

The model contains 699 GUI/data objects and an exporter README; no original event handlers are present. Generate public properties, preserve viewport geometry and source visual assets, and wire behavior to original elements. Preserve relative ZIndex ordering with a rank map. Build dynamic tabs, saved rows, hub cards and log lines by cloning source templates. Enable cloned buttons before connecting Activated. The archive's logo.png supplies the draggable launcher because the captured hierarchy has no launcher.

Download only the 16 referenced textures, original Montserrat family JSON and launcher logo. Cache within DeltaPC/assets using content fingerprints, byte count and Adler-32 checks. Register local files with getcustomasset/getsynasset; do not silently substitute symbols. Keep all 74 original archive files in assets/ unchanged. Unavailable native protections are reported honestly; the keyed loader uses the existing local key CHATGPT-MADE-THIS, not a remote Delta license service.

Retain working host execution, independent editor tabs, clipboard handling, upload/search/run/delete, title-click edit and title-right-click AUTO, ScriptBlox search/scroll/actions, consoles, applicable settings, rejoin/server selection, PC keyboard/mouse and touch drag. Save tabs/scripts/settings/launcher in DeltaPC/state-v2.json. Save and queue the same loader when a teleport starts, depending on the host executor's destination reinjection support. Reruns clean up old connections and UI.

Validation uses Lua 5.4 and a Roblox API boundary double, including Active-gated click dispatch. Verify the original archive bytes and that all generated source asset references resolve. A native Roblox runtime is unavailable, so rendered pixel fidelity, actual host font/image rendering, clipboard capabilities and teleport reinjection remain live-client integration checks.

## PC and mobile launcher

Match the supplied launcher screenshots using the existing logo: dark fill, thin accent outline, 40/48/64 UI-pixel sizes, and proportional corners. Treat icon color as border color. Track a single mouse/touch gesture in parent coordinates and convert rendered pointer deltas by the actual display scale. Use core safe insets for bounds; cancel on orientation/focus changes. Do not use a timer to turn a completed drag back into a tap. Expose title-right-click AUTO through a stationary touch hold, and provide touch-appropriate clipboard instructions. Preserve the captured panel layout, source assets, loaders and persisted state.
