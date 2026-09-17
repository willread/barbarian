# Version and build number

Edit `version` in the root `version.json` to set the release version, e.g. `1.1.0`.
The `build` field is the shared counter for full and shareware builds.

Each build command increments it once before export. A command exporting both
Windows and web gives both the same number. Separate build commands each get
a new number. Test-only commands do not increment it. Failed export attempts
may consume a number; gaps are normal. Changing the release version does not
reset the counter.

The generated `godot/scripts/build_info.gd` embeds the identity in the game.
A subtle text label appears at the top right, including while paused.
Commit the updated version file and generated build info with completed builds.
