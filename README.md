# Cairn

Godot dark-fantasy brawler. Browser and Windows builds.

- `npm run godot:test` runs gameplay and asset regression checks.
- `npm run godot:build` exports Web and Windows.
- `npm run build:steam-shareware` exports the Steam demo; its store link is stubbed until `APP_ID` is set in `godot/scripts/steam_store.gd`. Double-click `build-steam-shareware.cmd` for the same build.
- `npm run dev` serves the local web build at http://localhost:3001/.
- F8 opens the live sound lab.

Godot tooling and generated assets on this machine live in `E:/Cairn-build-tools`. See `godot/README.md` for setup.

The retired web game is preserved in Git history (`checkpoint/pre-godot-port`). `asset-sources/` retains useful source artwork/fonts, and `tools/asset-bake-source/` contains only helpers required by asset preparation and mechanics parity tests. The old React web app and browser runtime have been removed.

Audio source recordings and prompts are retained under `soundboard/`; external resources are recorded in `EXTERNAL_RESOURCES.md`. Credentials must remain in ignored local environment files.
