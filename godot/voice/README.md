# Hero voice lines
Gameplay dialogue now uses one slot per episode/wave (including the boss encounter), consumed when playback starts even if interrupted. Spoken IDs remain unavailable until a new run; pause, area changes and voice resets retain this history. Queued lines expire or are dropped on wave changes without consuming their ID.

September 17 recordings: `waves_coming` can trigger 1.5–3.5 seconds into the second or third wave of an area; `nice_place` can trigger 2–4 seconds after an area starts; `goat_search` is randomly delayed 8–22 seconds during normal waves; `low_health` triggers at 25 HP or below. Timers wait for entry/transition to finish. All share the same dialogue slot; effort, pain, menu and cutscene audio are separate. Source clips and the loudness/envelope bake live in `asset-sources/audio/` and `tools/audio/bake-hero-quips.mjs`.

`knocked_aside` ("You'll pay for that") queues after recovering from a knockdown. Speech waits while Cairn is down. It shares the same single-slot and no-repeat rules.

The random pool also includes `goat_home` ("Just give me my goat, and we can all go home"); selection excludes already-spoken lines. The Warden's introduction is now "Why don't you fall on your sword and save me the trouble?" and replaces his previous recording under the same boss cue.

Add clips and entries to lines.json: file, priority (higher first), cooldown in seconds, fps and a normalized RMS envelope. Call hero_voice.request_line(id, delay, expiry). A single player serializes speech; duplicate requests are ignored and stale queued lines expire. Hero pain and magic override speech, ordinary effort waits while speech is active. Pause freezes speech; death/title clears it. Master sound mute applies. The dinner clip is user-supplied ElevenLabs Maverick audio. Mouth frames follow its 30 Hz amplitude envelope (not phoneme-level lip sync).

## Updated Cairn voice clips
User-provided ElevenLabs Cairn recordings (September 13 filename timestamps) replace dinner and register-unlock and add big-enemy and mana-full. Exact source filenames and transcripts are recorded in lines.json. Encoded as Vorbis at -18 LUFS / -2 dB true peak, with refreshed 30 Hz mouth envelopes.

The first visible living heavy enemy and the first full mana bar each queue a line once per new game. These flags survive area changes, pauses and voice resets; they reset only for a new run. Clips respect Voice/Sound settings and share the existing priority, interruption and no-overlap queue.

The tiny_enemy cue uses the new user-provided Cairn recording and fires once per run when a living swift variant enters the visible play area. It shares the existing voice settings, queue and milestone reset rules.


Each episode boss now queues its own user-supplied Cairn line: champion, king, and saint. These take priority over ordinary quips and trigger once per run when that boss becomes visible. Bosses do not trigger the generic big-enemy line; ordinary heavy enemies retain it. The September 15 recordings use the same loudness and 30 Hz portrait-envelope processing as existing clips.
