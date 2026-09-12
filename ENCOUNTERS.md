# Default episode encounter progression

Each run shuffles shield soldiers, archers, and axe marauders. Aqueduct begins with bone soldiers and minotaurs; each later screen unlocks one of the shuffled types. All five types are available in the Keep. Large and fast variants unlock in random order on screens three and four. Archers remain unmodified; at most one living variant is admitted at a time.

Each area has three waves. The Keep has an additional boss encounter (wave 13). Composition is sampled from the cumulative pool, using costs of 1 for bones, 2 for minotaurs, and 3 for specialists. Budgets grow from 6–10 in the aqueduct to 15–19 in the keep. A randomly chosen opening emphasis cannot repeat consecutively. Archer and marauder totals are capped at two per type; shield totals at three; waves have at most nine enemies. Unlocking makes a type available rather than guaranteeing its appearance.

Two or three enemies enter initially. Reinforcements enter at randomized 1.6–3.8 second intervals when living-enemy and specialist-pressure caps permit. Active count caps rise from three to five. Living shields are separately capped at one in area 2, two in area 3, and three in area 4, including offscreen arrivals. Additional shields wait for an existing shield to die. Each arrival independently chooses side, offscreen distance, and lane position, then conforms to the walk polygon. Empty battlefields immediately admit the next reinforcement. Pending enemies prevent premature wave completion.

Chicken opportunities occur in waves 2, 5, 8, and 11. This is a first-playthrough balance baseline; assess duration, pressure spikes, and recovery opportunities through play before increasing enemy health or counts.

Variant tuning: swift enemies are 72% normal size, move at 165% speed, retain 85% health, and deal 65% damage. Brutes are 118% size, move at 68% speed, have 145% health, and deal 135% damage. Damage multipliers apply at hit resolution, leaving player and regular enemy damage unchanged.
