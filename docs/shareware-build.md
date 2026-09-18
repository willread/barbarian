# Shareware builds

## Steam shareware

Double-click `build-steam-shareware.cmd` beside the other two build scripts, or run
`npm.cmd run build:steam-shareware` (`godot:build:steam-shareware` is an alias).
It accepts `-- --web` or `-- --windows`, and defaults to both platforms.
It uses the same output paths, artwork and episode restrictions as ordinary
shareware; only the purchase link changes. The generated **Web Steam Shareware**
and **Windows Steam Shareware** presets add the `steam_shareware` feature.

The Steam link is currently stubbed: the purchase button opens nothing.
Before release, set `APP_ID` in `godot/scripts/steam_store.gd` to the **full game's**
Steam App ID, then rebuild. The link will open that game's Steam store page,
where players can wishlist before launch or purchase afterward. The build prints
a reminder while the ID is blank. Ordinary shareware continues to link to itch.io.

## Ordinary shareware

Double-click `build-shareware.cmd` in the project folder, beside `build.cmd`.
It builds both browser and Windows shareware editions and keeps the window open
to show the result. Close any running Cairn windows first.

Build both web and Windows editions:

```powershell
npm.cmd run build:shareware
```

The dedicated entry point is `tools/godot/build-shareware.mjs`. You can also
run `node tools/godot/build-shareware.mjs` directly; the existing
`godot:build:shareware` command remains available. All three accept the same
platform flags and always select the shareware export presets.

Choose a platform:

```powershell
npm.cmd run godot:build:shareware -- --web
npm.cmd run godot:build:shareware -- --windows
```

The dedicated **Web Shareware** and **Windows Shareware** export presets set
Godot's `shareware` feature. The ordinary `npm.cmd run godot:build` creates the
full edition, with every episode available and no upgrade screen on quit.

Both modes use the usual local output locations. The Windows version always
replaces `E:/Cairn-build-tools/build/windows/Cairn.exe`; close it before building.
There are no alternate Windows build folders. The web output is
`E:/Cairn-build-tools/build/web/index.html`, served at `http://localhost:3001/`.
Thus the last build determines which edition the local preview runs.

## Shareware behavior

- Episode 1 is playable, including its opening and death retries.
- Episodes 2 and 3 are slightly faded. Selecting either opens the upgrade
  screen instead of the difficulty menu. Direct episode startup is guarded too.
- Quit and the native window close button open the same screen. Its secondary
  button becomes QUIT GAME; Escape/controller B cancels quitting.
- The main menu adds SHAREWARE EDITION below the Cairn logo.
- BUY THE FULL GAME opens `https://maxforcegames.itch.io/`, the creator page
  supplied by the user. The page is not published or modified by this build.

The screen is a modal: gameplay and underlying menu animations stop until it
closes. Keyboard, mouse, D-pad and left-stick navigation are supported. Stone
button highlights animate independently of the paused game.

## Artwork and validation

`godot/art/shareware/upgrade.png` preserves the approved image layout, with two
text areas cleared using the built-in image-generation tool. The game draws
the revised feature copy and context-sensitive secondary button over these.
The new source image was referenced from the approved concept; its edit prompt
requested only removal of the old feature line and BACK TO GAME text, retaining
all artwork, frames and other lettering.

`godot/tests/shareware.gd` checks locked-episode routing, modal cleanup, quit,
Episode 1 access and full-edition access. Export checks verify the edition flag
in the actual pack. `--shareware-capture` writes screenshots under the build-tools folder.

## Smaller shareware package

`tools/godot/shareware-assets.mjs` regenerates the shareware preset exclusions
on every build. Episode 2–3 backgrounds, enemies, bosses, effects, world metadata,
boss voice clips, epilogue and music are omitted from the exported pack. The
upgrade screen keeps its embedded episode illustrations. Shared combat effects,
episode 1's enemies and boss, and unlockable weapon art remain available.

The music player shows only the menu and episode 1 tracks in shareware. Unused
audio audition variants are excluded; selected sounds and impact pools come from
`audio_defaults.json`. Shareware ignores local soundboard overrides so a developer's
saved selections cannot request excluded audio. The audio debug menu is disabled
in both editions. Full-edition resources and source artwork remain in the project.

Shareware web exports also remove the known generated preview directories from
the web output (background/controls studies, episode 2 music, soundboard and trailer).
No source study folders are removed.

`godot/tests/shareware_assets.gd` runs against each exported pack, checking removed
assets, all 13 episode 1 waves, four backgrounds, active sounds and the two-track
music player. The September 16 build reduced the web game-data pack from
271,095,580 bytes to 142,079,616 bytes (47.6%). This comparison excludes the engine
runtime and external web splash images; it is not the total download size.

