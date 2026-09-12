# CAIRN — 30-second first cut

## Research
- [Derek Lieu: the first shot](https://www.derek-lieu.com/blog/2022/8/1/the-first-shot-of-the-game-trailer): open with understandable interaction. The slam opens this cut; branding closes it.
- [Derek Lieu: genre and hook](https://www.derek-lieu.com/blog/2022/10/24/how-to-hook-the-audience-and-how-quickly-to-do-it): establish the game before escalating. Melee leads to crowd control and lightning.
- [Steamworks trailers](https://partner.steamgames.com/doc/store/trailer): gameplay first. Actual engine footage with HUD; no invented features, launch dates or availability claims.
- [Godot Movie Maker](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html): offline capture delivers consistent frames and audio.

## Timeline
0–4s aqueduct slam / axe finishes; 4–8s gate sword / minotaur / archer; 8–12s foundry charge; 12–16s spin and attempted dive / marauder; 16–21s keep magic and burning deaths; 21–26s boss exchange; 26–30s CAIRN end card.

## Staging and production
Live game mechanics with staged positions, initial AI pauses and mana. Ordinary enemies start partially wounded (4 HP) to show finishes. Damage values and reactions are unchanged; the boss has normal health. This is staged footage, not an uninterrupted normal playthrough. Some follow-up moves are interrupted by live enemies.

Uses existing artwork, accepted music_game-2 guitars, captured game SFX, slam_boom closing hit and licensed Cinzel font. No paid generation or new downloaded assets. Contact sheet inspected for framing, action and environment variety. Full subjective audio/video approval remains with the user.

Output: E:/Cairn-build-tools/trailer/cairn-first-cut.mp4 — native 1920×1080 capture, 30 fps, exactly 30 seconds, H.264/AAC, about 17 MB. Audio measured -17.9 dB mean and -1.1 dB peak. Earlier takes and contact sheets remain in that folder outside Git.

Reproduce from repository root with tools/trailer/capture.ps1, then `node tools/trailer/edit.mjs`. Capture temporarily changes viewport overrides and restores them in finally. No separate game build or publishing. The capture script is unused during normal gameplay. The first captured frame can emit an existing empty HUD polygon warning; the edit trims the initial 0.1 seconds.
