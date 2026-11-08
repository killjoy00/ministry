# The Ministry of Coincidences - Art Direction (locked for prototype)

> The universe has paperwork. Its citizens, fortunately, do not know this.

## What we are making

A miniature **storybook town seen from a mysterious mid-century civil service office**. Warmly illustrated rather than photorealistic: imperfect shapes, ink outlines, soft flat colors, dusty wool coats, gold-foil details, outdated government seals, and impossible creatures treated with serene official dignity.

The playable case should feel like a **physical dossier** with miniature scenes, not a web dashboard or generic Godot UI. Events are illustrated incidents on slips of paper. Bureaucratic stamps are visually distinct objects. Gerald is a recurring visual protagonist, not merely a name in a text field.

## Visual rules

- **Original illustrations:** Hand-authored SVG files under `assets/` (town, Gerald, seal, illustrated incidents and seals). No scraped art, image hotlinks or third-party asset packs.
- **Main view:** Header resembles a Ministry sign; case file has Gerald's portrait and a little town diorama; incoming incidents carry icon illustrations; decisions use stamped metal/ink controls; the chronicle resembles a ledger.
- **Palette:** deep teal ink `#1d363c`, emerald-gray `#426e60`, warm document stock `#f1e2c4`, ivory `#fff7e7`, brass `#c49a58`, burgundy ink `#7e454c`.
- **Typography:** clear readable printed labels; deadpan, specific language. Use decorative serif treatments later only if they preserve 1280x800 legibility. No tiny screens of densely packed text.
- **Motion later:** animated window lights, goose head tilts, falling paper, ink impressions, and a small town that visibly changes as cascades unfold. Do not let motion obscure causal text.
- **Composition:** illustrations must remain visible on the first screen *and* case result screen. Important action buttons stay on screen at 1280x800, with controller focus always visible.
- **Humor:** ministerial seriousness applied to absurd incidents. A goose's mayoral ambitions deserve a gilt-framed official portrait.

## Current prototype and next visual milestone

This first revision supplies authored SVG town/character/seal art and a rebuilt UI while leaving the rules engine untouched. It is **not** the final illustrated town simulation or commercial-quality hand-painted artwork. Next milestone: townsfolk, animated consequences per day, stamp press animations, and interactive geographic event locations. Replace flat placeholders only when equivalent functional controls remain accessible on Steam Deck.

Art is part of the definition of done. CI runs `tests/art_smoke.gd` to ensure required illustrations are bundled in actual Godot scenes.

## AI-assisted illustrated production pass — November 8, 2026

Additional pre-generated artwork (not live-generated content) lives under `assets/illustrated/` as optimized local WebP textures. The source portraits, Oddford landscape, event-card artwork and collectible seals are from the consistent storybook art direction. Character crops were cleaned to avoid contact-sheet neighbors and loaded as six individual portraits; six narrative incidents and four rubber stamp designs are each bound to in-game controls. The result screen also uses an illustration. All shipped asset content must be disclosed as pre-generated AI-assisted in Steam's Content Survey (see `docs/STEAM_RELEASE_GUIDE.md`). Keep future animations consistent with the character and Oddford designs. Do not replace the images with generic flat UI placeholders.
