# STORY_FORMAT.md — writing story data for Starfall Mythos

Story content is JSON in `story/`. `StoryDB` loads every `*.json` file
(except `endings.json`, which holds the endings table) into one scene graph.
No code changes are needed to add scenes, choices, checks, or endings.

## Scene

```json
{
  "id": "researcher_1",
  "title": "THE SPECTROMETER SINGS",
  "text": "BBCode text. {name} becomes the player's callsign.\nNewlines work.",
  "choices": [ ... ]
}
```

`text` supports RichTextLabel BBCode: `[b]`, `[i]`, `[color=#...]`.

## Choice

```json
{
  "text": "Record it raw. All of it.",
  "next": "field",
  "effects": { "KNOWLEDGE": 1, "DIVERGENCE": 1, "bond": 1,
               "factions": { "halcyon": 1 } },
  "gives": "tomorrow_footage",
  "codex": "The four-note phrase"
}
```

- `next`: a scene id, or the special value `"field"` (returns to the
  explorable crash field). Omit it if the choice only applies effects.
- `effects`: stat deltas for TRUST / DIVERGENCE / KNOWLEDGE / RISK
  (clamped 0-10), plus optional `bond` and per-faction `factions` deltas.
- `gives`: an inventory item id (string or array of strings).
- `codex`: a journal entry (deduplicated automatically).
- `ending`: an ending id from `endings.json`. Unlocks it and shows it.
  (Used by climax choices.)

## PEERHOOD dice check

```json
{
  "text": "Trace the handshake.",
  "check": {
    "stat": "KNOWLEDGE",
    "perfect": "operator_1_perfect",
    "messy": "field",
    "break": "field",
    "band_effects": {
      "perfect": {},
      "messy": {},
      "break": { "DIVERGENCE": 1 }
    }
  }
}
```

Rolls 2d6 + modifier (stat 7+ -> +2, 4+ -> +1, else +0). 10+ routes to
`perfect`, 7-9 to `messy`, 6- to `break`. `band_effects` apply the
consequence of the band before routing, so outcomes stay in data.
The RNG is seeded (`MythosState.dice_seed`, set on the title screen),
so runs are reproducible.

## Crash-field routing

`opening.json` holds a `field_beats` scene: a routing table mapping each
role to the story beat the signal fragment triggers in the explorable
world. Point roles at your class scenes 2-3 when you write them.

## Endings

`endings.json`:

```json
{ "endings": [
  { "id": "ending_broadcast",
    "title": "THE BROADCAST",
    "text": "BBCode epilogue text." }
] }
```

Endings found are stored on the player and shown unlocked in the gallery.

## Checklist for a new story beat

1. Add the scene JSON with a unique `id`.
2. Point at least one existing choice's `next` at it (or add it to
   `field_beats`).
3. Every choice must lead somewhere playable — no dead ends except
   `ending` choices, which the director handles.
