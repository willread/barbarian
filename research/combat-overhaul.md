# Combat overhaul

Bone Soldiers have 8 health, variable decisions and a backward hop with a 210–310 tick cooldown. Marauders telegraph a fixed-direction rush, follow with two committed chops, then leave a long recovery window. Brutes scale to 118% with more health; swift variants scale to 90% with faster movement.

Seven randomized mixed encounters precede the solo champion. Chickens are scheduled in encounters 2, 4, 6 and 8 after 5, 7, 6 and 9 seconds respectively. A melee hit cooks the chicken; collecting it restores full health. Wave healing is removed.

Stormcall recharges by 6 per hit and 8 per kill. Its 90-tick cast damages enemies within 420 world units, with depth weighted threefold. Damage starts at tick 20 when the weapon is raised, ends at tick 76, and totals 6.84 per target. Lightning originates at the weapon tip.

Enemy deaths combine a 0.15-second ignition, randomized 0.8–1.3-second engulfment, and 0.6-second silhouette erosion. Equipment drops, blood and scorch marks persist. The player falls in slow motion and remains on the ground with the dropped weapon until restart.

## Fire assets

`bake-fire.py` is our own offline 2D fluid solver: semi-Lagrangian advection, buoyancy, vorticity confinement and pressure projection. It bakes 64-frame fire and separate smoke atlases. Runtime silhouette erosion, ignition points and embers vary per death. This is not an EmberGen or Houdini simulation.

Workflow references:
- https://dev.epicgames.com/documentation/unreal-engine/niagara-flipbook-baker-quick-start-guide-in-unreal-engine
- https://docs.jangafx.com/embergen/pages/getting_started.html
- https://www.sidefx.com/docs/houdini/pyro/shading.html

## Chicken art

Generated with ImageGen as a 4-column, 3-row sheet: eight right-facing cream/russet chicken run poses, crouch, hop and two roast poses. Requested consistent anatomy, painted fantasy shading, isolated silhouettes and no scenery or labels. A targeted background-removal edit retained these poses. The returned neutral checker background is removed by runtime chroma separation.

Source generation: `exec-620144ef-5196-4da4-a994-90f8f6bc3a86.png`; background edit: `exec-f4ec7a90-e2f9-4338-961b-2087b93c8288.png` in the session generated-images directory.

Validation: mechanics, enemy and game test suites; offline canvas renders using actual assets for ignition, engulfment, burn-away, chicken and lightning. No interactive browser playthrough was performed.
