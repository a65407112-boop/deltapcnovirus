# Capture the loaded Delta GUI

The reference video shows a file named `gethui_dump.rbxm`. A runtime export captures the actual loaded interface, including the instance hierarchy, sizes, colors, image references and font properties.

Open the original editor in **Android Delta**, then execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a65407112-boop/deltapcnovirus/main/capture-delta.lua"))()
```

This step runs in Delta on Android or an Android emulator. Xeno runs in a separate Roblox client and cannot access that client's GUI. The capture helper rejects Xeno to prevent exporting the earlier recreated menu by mistake.

The helper finds the GUI containing the original `Execute clipboard` control, exports its containing screen/container, and reports `gethui_dump_YYYYMMDD_HHMMSS.rbxm` in Delta's workspace. Bring that file back for the Xeno adaptation. You can inspect it in Studio using **Insert from File** under the intended GUI parent. It is a model, not a complete place.

The wrapper uses the documented `ExtraInstances`-only mode of [UniversalSynSaveInstance](https://github.com/luau/UniversalSynSaveInstance), pinned to commit `a78cc2db1b41a647f818f004aa5fa3fcc62b27a1`. It excludes Script, LocalScript and ModuleScript objects and disables decompilation and bytecode export. It captures UI structure; event connections and executor behavior need to be connected separately for Xeno.

The original Poppins family descriptor from the provided APK is preserved byte-for-byte in [Poppins.font.json](../assets/fonts/Poppins.font.json). This is the family/face-ID mapping, not embedded font binaries. GUI export preserves font references; resolving Android-local font/image paths on Windows remains part of the adaptation.

UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw

The upstream exporter is downloaded at runtime, not bundled. Its [upstream license](https://github.com/luau/UniversalSynSaveInstance/blob/a78cc2db1b41a647f818f004aa5fa3fcc62b27a1/LICENSE) is also provided in [third_party/UniversalSynSaveInstance-LICENSE](../third_party/UniversalSynSaveInstance-LICENSE).

The helper's Luau syntax and target-selection/error paths were checked locally. Live export inside Android Delta has not been tested in this environment.
