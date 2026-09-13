# Score HUD directions — mockups only

Three imagegen concept directions derived from the current gameplay HUD. No runtime changes. Typography in the concept image is illustrative, not an exact rendering of the font binaries.

- A: Cinzel Bold, carved classical serif. https://fonts.google.com/specimen/Cinzel
- B: Oswald Semibold, condensed forged numerals. Recommended for clear score reading and a complementary weight to Anton. https://fonts.google.com/specimen/Oswald
- C: Rajdhani Bold, squared angular numerals, lighter material treatment. https://fonts.google.com/specimen/Rajdhani

All three use SIL Open Font License 1.1; verified against google/fonts main/ofl/{cinzel,oswald,rajdhani}/OFL.txt. No font binaries added to the game. Review panel hierarchy, texture, spacing and font direction before implementation.

Image generated with OpenAI imagegen, 2026-09-12, using a native game capture as visual reference.
Progression preview: progression-v1.gif and progression-v1.mp4 capture the actual Godot HUD at 30 fps, with scripted hits and kill bonuses building from 1x to 10x. The timer is held full to isolate rank effects. Capture script: capture-progression.gd (writes temporary frames on E:). No gameplay changes.
