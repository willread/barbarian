# Rocks-only foreground

The built-in image-generation tool removed the near-corner twig bushes from the
original foundry painting. Prompt: remove only thin bare sticks, shrubs and dry
grass above the bottom corner rocks; replace them with matching paving. Preserve
the rocks, architecture, lighting, framing and fires. No added objects.

`rocks-only-source.png` retains that generated edit. The ground revision script
copies only the two affected corners into `base.png`, preserving the original
animation regions. Foreground masks now contain only rocks.
