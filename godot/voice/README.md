# Hero voice lines
Add clips and entries to lines.json: file, priority (higher first), cooldown in seconds, fps and a normalized RMS envelope. Call hero_voice.request_line(id, delay, expiry). A single player serializes speech; duplicate requests are ignored and stale queued lines expire. Hero pain and magic override speech, ordinary effort waits while speech is active. Pause freezes speech; death/title clears it. Master sound mute applies. The dinner clip is user-supplied ElevenLabs Maverick audio. Mouth frames follow its 30 Hz amplitude envelope (not phoneme-level lip sync).

## Updated Cairn voice clips
User-provided ElevenLabs Cairn recordings (September 13 filename timestamps) replace dinner and register-unlock and add big-enemy and mana-full. Exact source filenames and transcripts are recorded in lines.json. Encoded as Vorbis at -18 LUFS / -2 dB true peak, with refreshed 30 Hz mouth envelopes.

The first visible living heavy enemy and the first full mana bar each queue a line once per new game. These flags survive area changes, pauses and voice resets; they reset only for a new run. Clips respect Voice/Sound settings and share the existing priority, interruption and no-overlap queue.

The tiny_enemy cue uses the new user-provided Cairn recording and fires once per run when a living swift variant enters the visible play area. It shares the existing voice settings, queue and milestone reset rules.


Each episode boss now queues its own user-supplied Cairn line: champion, king, and saint. These take priority over ordinary quips and trigger once per run when that boss becomes visible. Bosses do not trigger the generic big-enemy line; ordinary heavy enemies retain it. The September 15 recordings use the same loudness and 30 Hz portrait-envelope processing as existing clips.
