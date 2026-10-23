# Delta PC

## Capture the original interface

To export the actual loaded Delta menu, use [capture-delta-gui.lua](capture-delta-gui.lua) **inside Android Delta**. Its status window shows the current stage and filename; green **Готово** appears only after the entire written file matches the model byte-for-byte on two read-back checks. Follow the [capture instructions](docs/capture-original.md), then provide the resulting `.rbxm` for the Xeno adaptation. The original APK's [Poppins font descriptor](assets/fonts/Poppins.font.json) is preserved. Live Android export with this status window still needs verification. The earlier [console-only helper](capture-delta.lua) is also available.

## Existing recreated menu

A keyless, independent Roblox menu for Xeno. The blue layout is recreated from the NewUI reference bundled in the supplied Delta APK. It opens straight to the editor.

This is a new frontend: Xeno supplies execution. It does not start Android Delta, port its native engine, or modify the APK's authentication. There is no key screen or activation request in this project. It is not an official Delta or Xeno release.

## Run

Attach Xeno to Roblox, paste this into its editor, and execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/delta.lua"))()
```

You can also open [delta.lua](delta.lua), copy its complete contents and execute them directly. That version does not need a remote UI library or external icon assets.

**Right Ctrl** hides or shows the menu. The blue Delta button also reopens it.

## Included

- Blue translucent panels, a five-icon navigation bar and responsive screen fitting.
- Editor with line numbers and up to 16 independent tabs.
- Execute, Clear, Paste, Save and Execute clipboard.
- Searchable library for up to 64 of your own saved scripts, with Open, Run and Delete.
- Console with script output, compilation errors and runtime errors; capped at 200 lines.
- Menu size and transparency settings, live FPS, ping and clock.
- Re-executing the loader replaces the old UI and retains the current tabs and library.

## Compatibility

Execution uses the `loadstring` function provided by the current executor. The GUI cannot add engine capabilities that the executor does not have.

When `getclipboard` is available, Paste reads it directly. Otherwise it opens a text field: press **Ctrl+V**, then **Insert** or **Execute**. Copy uses `setclipboard` when available and falls back to selecting the text for Ctrl+C.

With `writefile` and `readfile`, tabs, library and settings are automatically saved to `deltapc_state.json` in the executor's workspace. Changes save after a short idle period; **Workspace → Save workspace** saves immediately. Without file access they remain available for the current session, including a rerun of the loader. Closing the client clears memory-only state. Delete a saved script using its Delete button.

Each script is limited to 1 MiB; the complete saved workspace is limited to 12 MiB. Very large scripts display up to 10,000 line numbers. Hiding or removing the menu does not stop scripts already running.

The menu itself sends no telemetry or authentication requests and fetches no script catalog. The one-line loader downloads `delta.lua`; code you choose to execute has its own behavior.

## Development and validation

Sources are in `src/`. `delta.lua` is a generated, self-contained bundle:

```sh
python3 build.py
python3 tests/run.py --luau /path/to/luau
/path/to/luau-compile delta.lua > /dev/null
/path/to/luau-analyze src/core.luau
```

Use the official [Luau CLI](https://github.com/luau-lang/luau). The tests run the state/execution logic and the actual bundled menu with a headless Roblox API adapter. They cover button actions, manual and direct clipboard paths, saved state, errors, missing capabilities, console limits and cleanup on rerun.

Validated locally with Luau 0.743. Live rendering, Xeno attachment and script execution inside the Windows Roblox client have not been tested in this Linux environment.
