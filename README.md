# STARFALL MYTHOS

A 16-bit top-down tale of first contact, set in the extraterrestrial-mythos
universe. Godot 4.7.2, GDScript, GL Compatibility renderer. Runs out of the
box: open the folder in the Godot 4.7 editor or `godot project.godot`.

Built on the retro-engine template (top-down SNES-style movement, pixel camera,
config-driven tuning). The story layer is a GDScript port of the canon loop
from `IcanBENCHurCAT/extraterrestrial-mythos-rpg`'s `rpg/mythos/` package:
title -> character select -> class scenes -> branch -> Law Trials -> climax ->
one of 10 endings, with the same Player model (TRUST / DIVERGENCE / KNOWLEDGE /
RISK, 0-10), the same PEERHOOD 2d6 dice, and divergence-anchor saves.

## The story (placeholder — Garret's to replace)

**The Vesper Signal.** The survey ship *Meridian* holds station over Vesper, a
dead colony world. Seven days ago, three fragments of something fell burning
through the atmosphere onto the crash field near Camp Halcyon. The fragments
broadcast a signal that rewrites small things first: compass needles, then
memories, then the sky.

You play one of three specialists:

- **Researcher** (KNOWLEDGE +2, TRUST -1) — the spectrometer sings your name.
- **Investigator** (RISK +2, KNOWLEDGE +1) — the footage is dated tomorrow.
- **Operator** (KNOWLEDGE +1, RISK -1) — the dead relay key just handshook.

The branch: broadcast the pattern to every ship in range (Public Disclosure),
lock it under a quarantine council (Build Council), or bury the fragments and
lie (Keep Secret). Then the Law Trials, the climax, and the endings.

Style: night-world 16-bit. Deep indigo skies, teal signal-glow, amber lantern
light. Story beats play as visual-novel scenes; between them you walk the
crash field top-down and step into the signal fragment's glow to continue.

## Architecture

```
scenes/
  title.tscn             # title: begin / resume anchor / dice seed / gallery
  character_select.tscn  # name entry + three classes
  scene_view.tscn        # story renderer: BBCode text + choice buttons + dice
  status_hud.tscn        # overlay: 4 stat bars, inventory, codex
  ending_gallery.tscn    # 10 endings, locked/unlocked
  main.tscn              # explorable crash field (retro-engine world root)
scripts/
  game.gd, config.gd, player.gd, pixel_camera.gd, world.gd, hud.gd
                         # retro-engine layer: input, tuning, movement, camera
  mythos/
    player_state.gd      # autoload MythosState: canon Player model + dice RNG
    dice.gd              # MythosDice: PEERHOOD 2d6 + tiered modifier, seeded
    story_db.gd          # autoload StoryDB: loads story/*.json into one graph
    anchors.gd           # autoload Anchors: save/load user://anchors/
    scene_director.gd    # autoload SceneDirector: routes choices, runs checks
  title.gd, character_select.gd, scene_view.gd, status_hud.gd,
  ending_gallery.gd, signal_fragment.gd
story/                   # ALL story content lives here, as JSON. See STORY_FORMAT.md.
  opening.json           # title scene + crash-field routing table
  researcher.json / investigator.json / operator.json
  branch.json            # the Disclosure / Council / Secret decision
  trials.json            # Law Trials interlude
  climax.json            # the sky opens
  endings.json           # 10 endings
```

Conventions (inherited from retro-engine, still binding):

1. **Config is the only place with magic numbers.**
2. **Entities own their state; systems own the world.** SceneView only renders;
   SceneDirector only routes; story consequences live in JSON data.
3. **Story is data, never code.** To add a scene, write JSON. See STORY_FORMAT.md.

## Controls

- Arrows / WASD: move (crash field). ESC / P: pause.
- Story scenes: click choices. `Status` toggles stats/inventory/codex.
  `Anchor` quick-saves a divergence anchor.

## Adding story

Write JSON per `STORY_FORMAT.md`, drop it in `story/`, and point choices at
your scene ids. Class scenes 2-3 and endings 5-10 are stubbed and waiting.

## License

MIT. Third-party art packs keep their own manifests under
`assets/third-party/` (see `ASSET_SOURCES.md`).
