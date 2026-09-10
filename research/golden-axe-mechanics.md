# Golden Axe Mega Drive: direct code analysis

Initial findings from the supplied World ROM. This is a mechanics reference for original implementation in Ashen Axe, not a complete reconstruction of the game. Addresses below are ROM offsets / 68000 addresses; RAM addresses are explicitly labeled. Numerical units refer to original game coordinates and simulation updates, before any scaling for our artwork.

## Identity and method

- Input: `C:\Users\will\Downloads\Golden Axe (World).zip`, member `Golden Axe (World).gen`.
- Size: 524,288 bytes; product `GM 00054018-00`; header checksum `ED02`; region `JUE`.
- SHA-256: `f141e79401280c89eb2ce49f9130d15250c68ae590ff6d5546fc19b493d07905`.
- Direct Motorola 68000 disassembly using Capstone, starting at known entry points and following branch targets. Linear sweeps alone are insufficient because data tables decode as plausible instructions.
- Deterministic Genesis Plus GX/libretro harness, NTSC-U setting, used to validate the interpretation through RAM observations. Core initially reports 59.92274340431231 frames/second. Millisecond conversions should remain secondary to update counts.
- The ROM, full assembly dump, emulator binaries, save states, and captures remain under ignored `work/golden-axe/`. This document contains findings, not transplanted game code.

## Located systems

| System | Address | Evidence |
|---|---|---|
| Reset entry | `0x000ABE` | ROM reset vector |
| Main game-mode dispatch | `0x000BB2`, table `0x000BB8` | Indexed call to mode handler |
| Gameplay handler | `0x001116` | Initialization and per-update work |
| Gameplay update calls | `0x00114C` | Calls player/object update at `0x00B662` |
| Controller reader | `0x003282–0x0032FA` | Hardware port reads, remapping, edge detection |
| Player/object dispatch | `0x00B662–0x00B76C` | Two players, eight subsequent object slots, other objects |
| Player behavior | `0x006BB6` | Substate dispatch table at `0x006D68` |
| Position integration | `0x00B3B2–0x00B416` | Long-word velocities added to position fields |
| Animation sequencing | `0x0085BE`, `0x008642` | Frame index, duration countdown, frame pointers |

Player records are RAM `0xFFD000` and `0xFFD080`, with 128-byte stride. Important offsets: horizontal position `+0x1C`, projected vertical position `+0x18`, ground-depth coordinate `+0x20`, height/terrain coordinate `+0x24`, horizontal velocity `+0x2C`, ground-depth velocity `+0x30`, vertical velocity `+0x34`, behavior substate `+0x42`, animation frame index `+0x14`. Positions and velocities use 16.16 fixed point. The height field has an offset/wrap convention; do not interpret its signed integer directly as height above ground.

## Controls

RAM `0xFFC176` holds P1 buttons; `0xFFC177` holds newly pressed buttons. P2 uses `0xFFC178/179`. The reader computes new presses as `(previous XOR current) AND current` at `0x0032F0–0x0032F8`.

The default remapping table at `0x017194` maps A to magic (`0x40`), C to jump (`0x20`), B to attack (`0x10`). Direction masks are up `1`, down `2`, left `4`, right `8`; Start is `0x80`. Player movement reads held buttons; normal action initiation reads press edges. Magic handling starts at `0x00710C`; normal jump at `0x0070F0`; attack selection at `0x006F6E`.

## Movement and jump findings

| Behavior | Extracted value | Code evidence | Validation |
|---|---|---|---|
| Horizontal walk limit | ±1.5 units/update | `0x0071B4`, `0x007238` | Rightward RAM trace: velocities 0.5, 1.0, 1.5, 1.5 |
| Ground acceleration | 0.5 units/update² | `0x0071E0`, `0x007264` | Same trace |
| Ground release deceleration | 0.5 units/update² | `0x006EC8–0x006EDA` | Static analysis; single-step release from 0.5 observed reaching zero |
| Ground-depth movement | ±1.0 units/update | `0x007166`, `0x007190` | Downward coordinate changes +1 per update |
| Diagonal correction | Horizontal integration reduced by 0.5 toward zero on the tested walking path | `0x00B3DA–0x00B406` | Right+down displacements: x 0, 0.5, 1.0, then 1.0; depth +1 each update |
| Double-tap timer | Loaded with `0x10` (16), decremented on updates without a horizontal press | `0x006F08–0x006F4E` | Short right/release/right sequence enters running; exact acceptance boundary still to test |
| Run speed target | ±4.0 units/update | `0x0075D0`, `0x0075EA` | Reaches 4.0 in double-tap trace, accelerating by 0.5 |
| Normal jump launch velocity | −5.5 units/update | `0x0070FC`, transferred at `0x00746C` | Observed −5.5 then −5.25 |
| Running jump launch velocity | −7.0 units/update | `0x007636` | Static analysis only |
| Jump gravity | +0.25 units/update² | `0x0074D6` | Normal-jump RAM trace |
| Falling-speed threshold | +8.0 units/update | `0x0074C6–0x0074DC` | Static analysis; general falling edge cases not tested |
| Air steering increment | 0.0625 units/update² | `0x007566`, `0x00758A` | Static analysis only; held-direction limit logic also runs |

Normal standing-jump validation on flat stage-one ground: peak projected rise **63.25 units**, first return to neutral behavior at sampled update **49** after the pre-input sample. Input sets jump state on update 1, initialization occurs on update 2, first upward displacement on update 3. These counts include state transitions and landing handling; they are not a claim of 49 airborne updates.

## Animation implications

Ax Battler's selected animation table is `0x03A340`, confirmed in player RAM. The walk sequence referenced by offset 0 points to `0x03A438`: four frames, duration field 10. The run sequence at offset `0x18` points to `0x03A4B8`: four frames, duration field 8. The sequencer at `0x0085BE` decrements a countdown and advances the frame index. At steady state, these imply 40-update walk and 32-update run cycles. Transition phases can differ because callers initialize/reset counters.

The standing pose selected through offset `0x54` points to `0x03A62C`, with one frame. Our realistic breathing idle can add visual motion while preserving the original gameplay state. More painted in-between frames should sample these animation phases without changing movement speed, action locks, or damage timing.

## What remains unresolved

- Attack selection at `0x006F6E` is contextual: it tests target categories and distances, including thresholds `0x1C` and `0x2C`. Those values are not yet verified as universal weapon reach or active hit windows.
- Exact attack startup, active frames, recovery, combo continuation, hit reactions, and cancellation rules require tracing the selected animation and collision paths.
- Enemy update dispatch is located, but skeleton-specific identity, AI state transitions, approach distances, and attack scheduling are not yet decoded.
- Mounted behavior, other heroes, bosses, terrain transitions, PAL behavior, and double-tap boundary cases are outside this initial validated set.

Do not claim full Golden Axe fidelity from these findings alone. First adapt the confirmed movement model with a fixed simulation step and artwork scale; then add combat and AI only as their code paths are decoded and checked.

## Local reproduction

`work/golden-axe/show-code.py START END` disassembles a selected hexadecimal range. `work/golden-axe/inspect-mechanics.py` restores a prepared stage-one state and writes frame-by-frame data to `work/golden-axe/traces/mechanics-validation.json`. It requires the locally installed emulator core, supplied ROM, and prepared `after-b` save state; it is a local research harness, not yet a portable test suite. The earlier story-screen sample was unsuitable for movement testing and was replaced by the playable state.
