# Delta PC implementation

Create a self-contained Luau menu using the blue NewUI screenshot bundled in the supplied Delta APK as the visual reference. The APK is a reference only; this project supplies its own UI and delegates script compilation to the executor that loads it.

The menu opens directly, with no key, account, activation, advertisement or authentication request. It includes an editor, independent tabs, Execute/Clear/Paste/Save actions, a user script library, console, settings and a small reopen button. Use native Roblox UI shapes for icons so asset loading is not required.

1. Test a pure state/execution module: tab isolation, library operations, JSON-safe persistence, malformed state and compile/runtime errors.
2. Implement the responsive menu with guarded clipboard and file capabilities, manual paste fallback, bounded console output and cleanup on re-execution.
3. Bundle a single delta.lua without external UI dependencies. Check all sources with official Luau and exercise UI actions with a headless Roblox API mock.
4. Review the implementation, publish to the user's empty repository, verify the uploaded bytes and provide the raw loader.

Roblox/Xeno cannot run in this Linux environment. Local checks validate Luau and modeled UI interactions, not live injection, rendering, or antivirus status.
