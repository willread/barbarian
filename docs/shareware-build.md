# Shareware builds

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

Paid-episode assets remain packaged; this mode restricts play rather than serving
as DRM or claiming that those resources cannot be extracted.

