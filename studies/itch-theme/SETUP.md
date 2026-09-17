# Cairn itch.io page setup

Use the loose files in E:/Cairn-build-tools/itch-page-assets. No ZIP extraction
or custom CSS access is required.

## 1. Edit game

- Title: Cairn
- Short description: A dark fantasy arcade brawler. Heavy steel, old magic, and a world in ruins.
- Classification: Games
- Kind: Downloadable for the Windows page shown in the default mockup.
- Genre: Action
- Suggested tags: Fantasy, Beat 'em up, Singleplayer, Controller
- Description: open description.html in a text editor, copy its source, and paste
  into the description editor's HTML (<> ) view. Do not upload it as a game file.
- Screenshots: upload screenshots/01-aqueduct.jpg, 02-foundry.jpg, then 03-keep.jpg.
- Save as Draft while setting up; choose release status and pricing to match the
  actual release. No price or release date is implied by the mockup.

## 2. Save & view page, then Edit Theme

| Control | Value |
| --- | --- |
| BG | #101213 |
| BG2 | #101213 |
| BG2 Alpha (More options) | 0.68 / 68% opacity |
| Text | #DED8CA |
| Link | #D2AC70 |
| Buttons | #795735 |
| Headers | #E0BD83 |
| Body font | Libre Baskerville |
| Body size | 17px, or nearest available size |
| Header font | Cinzel |
| Screenshots | Sidebar |
| Banner image | cairn-header.png |
| Background image | cairn-stone-background.jpg |
| Background placement | Center top |
| Background repeat | No repeat |
| Background size | Cover / fill, if provided |

The desired panel opacity is 68%, which is 32% transparency if the UI labels the
control that way. Keep the banner as PNG: converting to JPEG flattens the jagged
transparent edge and ruins the blend. The logo is already included in the header;
do not upload it again as an additional heading image. Leave custom CSS empty.

The header is 2172 × 724 (3:1). Use it at the full content-column width, with its
aspect ratio preserved and no cropping. This size is our asset size, not an itch.io
required size. The stone background is 1600 × 1600 (561 KB JPEG; stones about half the prior displayed size). Screenshots are 1920 × 1080.

The mockup uses a 960px panel and zero header padding. Standard-editor spacing,
background sizing controls and font-size increments have not been verified on
your account. Use full-width/no inset banner placement if the editor offers it;
otherwise keep the native spacing. Do not assume the preview CSS can be pasted
into the description to force these dimensions. The jagged blend is in the PNG
itself and remains functional with the native layout.

## 3. Trailer and game files

Optional trailer: upload trailer/cairn-first-cut.mp4 to YouTube or Vimeo and put
its publicly accessible URL in the trailer field. A local MP4 path cannot be used
in that field. This is the existing 30-second first cut, not a new final trailer.

Upload the approved Windows distribution separately and mark it for Windows.
Game binaries are not in this kit. The current single executable location is
E:/Cairn-build-tools/build/windows/Cairn.exe; confirm the intended release build
before distribution. Packaging/executable dependencies were not audited here.

For browser play instead, select HTML5 and upload a separate Godot web export ZIP
with index.html at its root. Keep Screenshots explicitly set to Sidebar. Configure
click-to-play in the embed options. The theme kit is not that web export.

## 4. Remaining page content

- Listing cover: separate from the header; use 315:250 aspect ratio, such as
  630 × 500. This kit does not include a listing cover. Do not stretch the banner.
- Confirm pricing, release status, credits, contact link and system requirements.
- Screenshots are staged native gameplay frames from the prior trailer, not
  fresh captures of the latest build.
- Review at desktop and phone widths, and as a logged-out visitor before publishing.

## Sources

- https://itch.io/docs/creators/design — theme controls, alpha, fonts and trailers
- https://itch.io/docs/creators/getting-started — listing assets and page setup
- https://itch.io/docs/creators/html5 — browser game upload requirements

The included theme-settings.json is a reference sheet, not an importable theme.
No files from the local preview application are needed on itch.io.
