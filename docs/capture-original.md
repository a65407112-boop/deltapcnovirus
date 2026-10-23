# Capture the loaded Delta GUI

The reference video shows a file named `gethui_dump.rbxm`. A runtime export captures the actual loaded interface, including the instance hierarchy, sizes, colors, image references and font properties.

Open the original editor in **Android Delta**, then execute the version with a status window:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/capture-delta-gui.lua"))()
```

The window shows searching, downloading, assembling, writing and verifying stages, elapsed time, the filename and the read-back byte count. **Green “Готово” means the complete file was read back twice and matched the serialized model byte-for-byte.** Red means an error. Amber means the write was not confirmed; do not treat that file as finished. There is no estimated percentage during serialization.

The GUI version uses the exporter's `Callback` to receive the complete model before calling `writefile`. It checks the RBXM signature and final END chunk, then compares all read-back bytes with those original data. Verification waits up to 120 seconds after writing. If `readfile` is unavailable, the result stays unverified.

The window stays open after completion. **Копировать путь** copies the filename. **Скрыть** hides an active window without cancelling the export; running the same loader again reopens it without starting a second export. **Закрыть** removes the finished window. The status screen is kept outside the captured GUI screen.

The original [console-only helper](../capture-delta.lua) remains available unchanged.

This step runs in Delta on Android or an Android emulator. Xeno runs in a separate Roblox client and cannot access that client's GUI. The capture helper rejects Xeno to prevent exporting the earlier recreated menu by mistake.

The helper finds the GUI containing the original `Execute clipboard` control, exports its containing screen/container, and reports `gethui_dump_YYYYMMDD_HHMMSS.rbxm` in Delta's workspace. Bring that file back for the Xeno adaptation. You can inspect it in Studio using **Insert from File** under the intended GUI parent. It is a model, not a complete place.

The wrapper uses the documented `ExtraInstances`-only mode of [UniversalSynSaveInstance](https://github.com/luau/UniversalSynSaveInstance), pinned to commit `a78cc2db1b41a647f818f004aa5fa3fcc62b27a1`. It excludes Script, LocalScript and ModuleScript objects and disables decompilation and bytecode export. It captures UI structure; event connections and executor behavior need to be connected separately for Xeno.

The original Poppins family descriptor from the provided APK is preserved byte-for-byte in [Poppins.font.json](../assets/fonts/Poppins.font.json). This is the family/face-ID mapping, not embedded font binaries. GUI export preserves font references; resolving Android-local font/image paths on Windows remains part of the adaptation.

UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw

The upstream exporter is downloaded at runtime, not bundled. Its [upstream license](https://github.com/luau/UniversalSynSaveInstance/blob/a78cc2db1b41a647f818f004aa5fa3fcc62b27a1/LICENSE) is also provided in [third_party/UniversalSynSaveInstance-LICENSE](../third_party/UniversalSynSaveInstance-LICENSE).

The helper's Luau syntax and target-selection/error paths were checked locally. Live export inside Android Delta has not been tested in this environment.
