# Music player

http://localhost:3001/music/ — the original comparison layout with all tracks. The old EP2 URL redirects here.

Run the existing `npm run godot:serve` server. The catalog refreshes every 15 seconds without interrupting playback. It discovers music_* audio in godot/audio, godot/audio_options and soundboard, preferring Ogg over duplicate MP3 versions. Source recordings are retained but not listed twice.

For future collections, add finished audio to a music-named subfolder under soundboard or asset-sources/audio. An optional manifest.json with jobs or tracks supplies id, file, name, description, bpm and loop.duration. Other subfolders can opt in with music:true on jobs or type:music on their manifest. No player edits or game export required.

Project default music assignments are labeled; per-user soundboard overrides are not read. Playing or favoriting a track does not change the game.
