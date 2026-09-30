# CÁ LỚN — THE LAST CAST

A first-person fishing RPG and life story, set in contemporary Vietnam.
Design documents are in [`docs/`](docs/00-game-overview.md). The development rules are in [`CLAUDE.md`](CLAUDE.md), the milestone plan in [`IMPLEMENTATION-ROADMAP.md`](IMPLEMENTATION-ROADMAP.md), and the current target in [`VERTICAL-SLICE.md`](VERTICAL-SLICE.md).

**Engine:** Godot 4.7 (GDScript). Everything is built from code and JSON data, so there are no hand-edited scenes to merge.

## Running

```bash
tools/dev.sh setup   # once: download portable Godot 4.7.2 into tools/godot/ (or set $GODOT)
tools/dev.sh run     # play
tools/dev.sh test    # unit tests (headless)
tools/dev.sh smoke   # boots the real world and plays the whole Vertical Slice headless
tools/dev.sh shots   # renders review screenshots to build/screenshots/
tools/dev.sh edit    # open the Godot editor
```

### Controls

| | |
|---|---|
| WASD / Shift | walk / sprint |
| E | inspect, collect, talk, craft |
| Tab | what you are carrying |
| 1 | hold / put away the rod · B switch bait |
| Left mouse | hold then release to cast · strike when the float goes under · hold to reel |
| Right mouse | reel in without a fish |
| A / D | pull the rod against the fish's run |
| Q / E, mouse wheel | drag (how easily line pays out) |
| F5 / F9 | save / load · Esc pause |
| F1 / F3 | debug console / debug overlay (debug builds only; type `help`) |

## Graphics

- **Textures and skies** are CC0 assets from [Poly Haven](https://polyhaven.com), listed in `assets/asset_manifest.json`. They're committed to the repo; run `python tools/fetch_assets.py` to fetch them again, and see `assets/CREDITS.md` for sources.
- **Surfaces** use PBR materials with world-space triplanar mapping (`src/world/material_library.gd`). If a texture is missing, the surface falls back to a flat colour.
- **Rendering** uses:
  - an HDRI sky that switches with the weather, and a sun that follows the game clock;
  - AgX tonemapping, SSAO, screen-space reflections on the water, volumetric fog and glow (`src/world/world_lighting.gd`);
  - water from `src/world/shaders/water.gdshader`, and chunked wind-animated grass from `src/world/grass_field.gd`.
- **Quality presets** (`low` / `medium` / `high`) are in `config/graphics.json`. `medium` runs at about 60–75 FPS on a GTX 1050 at 1600×900. `high` adds SDFGI global illumination and denser grass.

## Structure

```text
config/        tuning and new-game setup (JSON)
data/          static game data by collection: items, recipes, fish, quests,
               dialogues, events, npcs, maps, interactables (JSON, stable IDs)
scenes/main.tscn  entry scene
src/
  core/        EventBus, GameState, GameClock (time/weather), DataRegistry,
               ConditionEvaluator, EffectExecutor, GameContext (composition root), Game autoload
  player/      first-person controller
  fishing/     FishingSession (pure simulation), FishingController (input/visuals), outcomes, skill
  fish/        FishSelector, FishBiteAI (approach/nibble/bite), FishFighter (fight AI, archetypes, giant phases)
  inventory/   Inventory + equipment
  crafting/    CraftingSystem
  quests/      QuestSystem (objectives are conditions)
  dialogue/    DialogueSystem (branching, conditions, effects)
  events/      StoryEventSystem (triggers, once/cooldown/probability)
  npc/         RelationshipSystem (multi-dimension + memory), NpcSystem, NPC actors
  save/        SaveSystem (versioned JSON, migration, atomic write)
  world/       WorldScene, greybox WorldBuilder, InteractionSystem, Interactable
  ui/          HUD, fishing HUD, dialogue, inventory, pause, main menu, debug tools
  audio/       placeholder synthesised sounds
  debug/       DebugCommands
tests/         unit tests (run_tests.gd), world smoke test, screenshot tour
assets/        art/audio (empty: the Vertical Slice uses greybox primitives)
```

**Architecture in one paragraph.** The gameplay systems are plain `RefCounted` classes wired together by `GameContext`, and they talk to each other through the `EventBus` (docs/18 §9). Story content is data. An event has a trigger, conditions and effects. A quest objective is a condition. A dialogue node can run effects, for example `FishLanded` → `EVENT_GIANT_FISH` → `set_var fishing.next_fish`. The 3D and UI layer only reads state and forwards input, so all of the game logic can be tested headless.

## Vertical Slice status

All of it is playable from the title screen to "Còn tiếp...". The unit tests cover the story, exploration, crafting, fishing, giant-fish and save items of the checklist in VERTICAL-SLICE §32. `tools/dev.sh smoke` plays the whole slice through the real world nodes. How movement and fishing *feel* still needs hands-on play, which no automated test can judge.

## Implementation decisions (where the docs disagreed or left gaps)

- **IDs.** CLAUDE.md has the highest priority, so its IDs are used (`NPC_MOTHER`, `QUEST_MAIN_FIRST_FISH`, …). The character IDs from docs/03 (`CHAR_MAIN_MOTHER`) and the MQ numbers from docs/05 are stored as reference fields (`character`, `mq`).
- **Rod recipe.** The recipe is bamboo + rubber line + shoe float + wire, with **no bait**. This follows docs/11 and the quest order in docs/05, where the rod comes before the bait. VERTICAL-SLICE §13 also lists bait as an input.
- **Giant fish.** The giant fish is scripted to break the improvised rod (docs/07 §46). In this fight the line and hook can't fail and the fish never tires, so the rod always breaks, whatever the player does with tension or drag. The fight still plays out through the normal fishing simulation.
- **Soft-lock safety.** Materials can be collected again while you have no rod and haven't met the giant yet. Bait can always be dug up again. After the giant, no second bamboo rod can be crafted.
- **Line break on the improvised rod.** A line break costs you the bait and the fish, but not the rod. Line repair is outside the Vertical Slice.
- **Saving.** You can't save during a fight. A save while the float is in the water reels it in first. Autosaves happen after main quests and major story events.
- Weather has no automatic simulation yet: it only changes through story or debug. NPC schedules, economy, shop and family events beyond the two Mother scenes are outside the Vertical Slice.
