# Delta GUI implementation plan

> **For agentic workers:** use superpowers:executing-plans to implement task by task.

**Goal:** Replace the old frontend with two working loaders sharing the captured GUI and newly implemented control behavior.

**Architecture:** Generate a public-property skin from the attached RBXM. Bundle it with pure state and a controller; publish all source and tests in one atomic GitHub commit with the existing head as parent.

**Tech Stack:** Lua compatible with Luau and Lua 5.4, Python standard library for conversion/build/testing.

**Spec:** docs/design.md

## Global constraints
- Existing executor supplies loadstring; this does not install native Delta.
- Preserve keyed.lua/keyless.lua URLs; key is CHATGPT-MADE-THIS.
- The original button handlers are absent; the model and all original Assets.zip files are available.
- Never execute external scripts during validation.
- Keep Git history and update main with an expected-head check.

## Review focus
- A drag release must not open the launcher, including touch and screen-edge drops.
- A closing tab must preserve other tabs and always leave an editable tab.
- Unsupported APIs, malformed disk state, HTTP errors and stale searches must not pretend success.
- Re-running a loader must disconnect the old instance's events and prevent late tasks affecting the replacement.
- Missing images, huge captured ZIndex and scale-based scrolling rows must not produce invisible/overlapping controls.

## Task 1: State and generated skin
- [x] Write tests for locked/unlocked transitions, tabs, persistence sanitization, saved items and drag bounds; run red.
- [x] Implement src/core.lua and generate src/skin.lua from the snapshot with tools/build_skin.py.
- [x] Run state tests green and validate serialized properties.

## Task 2: Runtime controller and loaders
- [x] Write controller behavioral tests against an engine double; run red.
- [x] Implement src/controller.lua, tools/build.py and the two loaders.
- [x] Test launcher/input, key gate, navigation, tabs, execution/error handling, persistence, hub selection, settings and cleanup.
- [x] Incorporate PC keyboard/mouse, executor workspace folder and teleport auto-reload refinements; test each.

## Task 3: Verify and publish
- [x] Run the full suite and deterministic build, review final source, resolve material findings.
- [x] Write README with tested behavior, original assets and native limitations and the two loadstrings.
- [ ] Publish a replacement tree atomically to GitHub, preserving parent history.
- [ ] Read the published files and compare their SHA256 to local files.


## Source-fidelity correction (2026-10-24)

Assets.zip is now available. The user explicitly rejected the custom desktop presentation. Replace that presentation with the original supplied geometry and controls, clone its dynamic templates, map all original textures and Montserrat font to cached local custom assets, keep the current functional behavior, and publish both loaders at the same URLs. No redesign or additional design approval is needed. Validate source fidelity, asset integrity, cloned input targets and prior functionality before publication.
