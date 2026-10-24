# Delta captured GUI rebuild

Recreate the user's supplied Delta Android GUI as a Lua frontend for an existing executor. Replace the old client/patch stack in a65407112-boop/deltapcnovirus and retain the two public entrypoints keyed.lua and keyless.lua. The user explicitly authorized replacement and publication.

The RBXM contains 700 instances, including an exporter README, but no original event handlers. Assets.zip was unavailable. Therefore layouts, labels, colors and control groups come from the model; behavior is reconstructed, and unavailable image/font resources use native fallbacks. Exact native Delta behavior and proprietary engine features cannot be recovered from this snapshot.

Approach: a freshly generated skin plus a single lifecycle-owning controller and a small pure state module, bundled into client.lua. This avoids layering another patch onto the rejected implementation or loosely recreating the UI from scratch. Use the existing local demo key CHATGPT-MADE-THIS. This is not a Delta license validator.

Implement launcher drag with click suppression, screen bounds and viewport resize handling; open/close and navigation; independent editor tabs and Execute/Clear/Execute Clipboard; saved-script upload/search/run/delete; ScriptBlox search/page/selection/run/open/save/copy; two searchable consoles; supported settings, honest unavailable native controls; local persistence; cleanup on re-execution. HTTP, clipboard, filesystem and FPS availability must be detected. Do not run third-party code while building or validating. No fake purchase/teleport protections or native RakNet implementation.

Validation: pure-state behavior under Lua 5.4; production controller in a Roblox API test double for lifecycle, input, tabs, execution, key gate, settings and HTTP failure paths; generated property auditing. Actual Roblox rendering and injection require the user's client and are not available here.

User refinements: prioritize PC mouse/keyboard behavior; create an executor-workspace folder and persist user content/settings; autoreload the same keyed/keyless frontend after place or universe teleports using supported executor queue APIs. All are implemented and covered by behavior tests. The user explicitly requested fresh button logic and actual host execution, irrespective of prior repo files.
