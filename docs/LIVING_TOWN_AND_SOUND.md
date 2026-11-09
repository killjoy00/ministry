# Living Oddford and original music

## What is playable
- **VIEW ODDFORD** now opens an interactive illustrated town with six locations. Select one using D-pad/A (or mouse), see a truly eligible incident and choose **Inspect This Incident** to return to that exact pending case action.
- Advancing a day opens a **skippable visual replay** of the incidents actually recorded by the deterministic simulation, including linked causes, public support gains and reality corrections. Administrative notes are not misrepresented as physical happenings.
- Rain, wind and flying paper, lost letters, sandwich mishaps, newspaper surprises and celebrations get light procedural animations over the illustrated town.
- **LB/RB** steps through recorded incidents, **Y** skips, **B** returns. This view never changes simulation outcomes.
- Approving a stamp plays a rubber-stamp sound and animates the illustrated seal.
- The game features a newly composed **16-bar 3/4 Oddford Waltz**, synthesized fully offline with a music-box melody, accordion-like harmony and soft waltz bass. It is original code-generated music, with no samples, copyrighted recordings, streaming or AI model at runtime.
- Toggle music with **Start** (controller) or **M** (keyboard), or the footer control. Adjust volume with the footer **−/+** or keyboard **−/=**. Settings persist locally.

## Scope and verification
Run `godot --headless --path . --script res://tests/living_town_smoke.gd`. The test checks real event origins, town inspection, replay/skip, music mute/volume/non-silent synthesis, and a seven-day case. Existing 1280×800, illustration, smoke and balance checks remain required.

This is an interactive *event diorama*, not a physics-based town with autonomous walking NPCs. The music is procedurally generated at 22.05 kHz and audio-hardware performance, accessibility and suspend/resume still require physical Steam Deck testing. No Deck Verified claim is made.
