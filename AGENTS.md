# Project workflow

- Commit completed changes as you go, at each finished iteration. Do not leave completed agent changes uncommitted.
- Include only task-related changes in commits; preserve unrelated user files and edits.
- Keep previews local unless the user explicitly asks to publish. Provide the local preview link after game changes.

- The user authorizes including TODO.MD (todo.md) in commits alongside other changes, including their edits to that file.

- The native Godot project in godot/ is the current game implementation. The retired web game is preserved in Git history; retain asset-sources/ and tools/asset-bake-source/ for asset baking and parity checks. Use npm run godot:build and npm run godot:test for native work; npm build also runs the Godot export.
- Automatic builds should build the full version. Build shareware only when the user explicitly requests it.
- On this machine, Godot tooling, imports and exports live on E:/Cairn-build-tools because C: had insufficient space. Do not delete unrelated files to make room.

- Never commit `.env` files or credentials. Never print their values. Keep `core.hooksPath=.githooks` enabled; the pre-commit guard blocks environment files and locally configured secrets in staged content.

- Keep a single Windows build at E:/Cairn-build-tools/build/windows/Cairn.exe. If the executable is locked, ask the user to close it; do not create alternate build folders.
