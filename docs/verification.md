# Verification record

2026-10-25. Target: PC and touch-mobile Roblox executor frontend using the supplied Delta GUI and Assets.zip.

The generated skin reconstructs 699 GUI/data objects from the uploaded RBXM. All 74 asset files were compared byte-for-byte with their archive entries. All 16 captured Image references and the Montserrat font family resolve to original files; the supplied logo supplies the otherwise absent launcher. No exported Script source is executed. The runtime asset manifest contains 18 files with fingerprinted cache paths, byte sizes and Adler-32 checksums.

`python tools/build_assets.py`, `python tools/build.py`, and `python tests/run.py` pass. Ten suites cover:

- `test_mobile.lua`: screenshot-based launcher styling, scaled/inset parent drag coordinates, single-finger ownership, immediate movement, delayed release activation, safe bounds, orientation/focus cancellation, mobile title hold versus scrolling, and clipboard fallback wording.
- `test_assets.lua`: all original texture/font registrations, nested workspace cache, cache reuse, destination re-registration after teleport, same-size corruption repair, invalid downloads, missing APIs, and preserving the prior UI when asset bootstrap fails.
- `test_fidelity.lua`: original sidebar/page geometry, both editor images, Montserrat and line spacing, original menu texture/proportions, retained toggle/dropdown templates, source layer ordering, arrow/ellipsis click targets, original tab switching/closing and saved-row templates.
- `test_core.lua`: key modes, tab state, saved-script validation, malformed persistence, drag bounds, bounded logs and settings.
- `test_runtime.lua`: navigation, actual Lua execution/errors, tabs, PC drag/click distinction, keyed UI, saved-script buttons and cleanup.
- `test_features.lua`: filesystem round trips, clipboard, keyboard shortcuts, selected ScriptBlox actions, supported settings and logs.
- `test_loaders.lua`: both entrypoint modes and invalid downloads.
- `test_regressions.lua`: tab limits, restored FPS, menu layers, locked clipboard fallback and nested plus button.
- `test_teleport.lua`: save before transfer, queue once, destination loader execution, same key mode and unsupported hosts.
- `test_boundaries.lua`: touch identity, screen clamping, folder creation, reversed HTTP completion order and HTTP errors.

Code review found that source tab/card templates retained Active=false and that nested dropdown arrows needed their own click handlers. Interactive clones now use the same enabling/binding function as original controls, every arrow/ellipsis has a handler, and the engine double now gates Activated events on Active/Interactable. The tests cover these regressions. Asset registration is repeated in a new place/job while reusing validated bytes from disk.

No live Roblox client is available in this environment. These tests establish Lua/controller behavior and source-property fidelity, not rendered pixel equivalence, native font/image rendering, executor injection, live API uptime, or actual cross-universe reinjection. Unsupported native Delta protections are reported explicitly. The key is a local gate, and teleport reinjection remains the invoking executor's responsibility.

## Launcher and mobile correction

User screenshots showed that the launcher needed a dark background with a blue outline, a smaller medium size and an inset logo. The original logo image remains unchanged; this correction changes the UI properties around it. Screenshot color/size measurements informed these properties; no claim of live pixel-equivalent rendering is made.

Regression scenarios reproduced coordinate jumps when the host GUI has a nonzero origin or scale, active-touch replacement by a second finger, and a drag becoming a tap after the old timed suppression expired. The controller now uses local start coordinates, converts pointer deltas by the displayed scale, tracks one pointer through release/cancel and retains the gesture result until a new gesture. GuiService inset rectangles constrain the launcher in its own coordinate space.

Mobile AUTO uses a 0.55-second title hold; movement, release, focus loss and row removal cancel the pending action. Existing PC gestures, execution, file persistence and teleport suites also pass after the correction. Actual hardware touch latency and on-screen keyboard integration remain untested here.

Review also caught double-counting the full-screen inset during safe-area conversion. The corrected code subtracts only the GUI absolute origin from the core-safe rectangle. A negative-origin regression checks exact bounds at both corners and passed after the fix; all ten suites pass.
