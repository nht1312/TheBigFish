# CLAUDE.md

# CÁ LỚN — THE LAST CAST

## Claude Code Development Rules

---

## 1. PROJECT IDENTITY

Project Name:

> CÁ LỚN — THE LAST CAST

Genre:

> First-Person Fishing RPG / Life Story / Narrative Simulation

Core Concept:

> A Life Story Disguised as a Fishing Game.

The game follows an ordinary young person in contemporary Vietnam who gradually discovers fishing, learns the craft, builds relationships, earns money, explores increasingly difficult fishing environments, and eventually confronts the biggest fish of their life.

The game is not primarily about catching fish.

Fishing is the gameplay language used to tell a story about:

* dreams
* persistence
* family
* friendship
* failure
* sacrifice
* growing up
* responsibility
* consequences

---

# 2. SOURCE OF TRUTH

Before implementing gameplay, Claude Code MUST read the relevant documentation.

Primary documentation:

```text
docs/
├── 00-game-overview.md
├── 01-story-bible.md
├── 02-world-building.md
├── 03-characters.md
├── 04-story-arcs.md
├── 05-quests.md
├── 06-random-events.md
├── 07-fishing-system.md
├── 08-fish-ai.md
├── 09-inventory.md
├── 10-economy.md
├── 11-crafting.md
├── 12-map-design.md
├── 13-npc-system.md
├── 14-family-system.md
├── 15-dialogue-system.md
├── 16-progression.md
├── 17-ending-system.md
└── 18-technical-architecture.md
```

Documentation priority:

```text
CLAUDE.md
    ↓
00-game-overview.md
    ↓
01-story-bible.md
    ↓
18-technical-architecture.md
    ↓
specific system documentation
```

When documents conflict:

1. Check `CLAUDE.md`.
2. Check `00-game-overview.md`.
3. Check `01-story-bible.md`.
4. Check `18-technical-architecture.md`.
5. Check the most specific system document.
6. Do not silently invent a new rule.

If the conflict cannot be resolved:

> STOP and ask for clarification.

---

# 3. GOLDEN RULE

Do NOT build the entire game at once.

The project must be developed incrementally.

Development order:

```text
Documentation
↓
Technical Foundation
↓
Vertical Slice
↓
Core Systems
↓
World Expansion
↓
Narrative Expansion
↓
Polish
↓
Optimization
↓
Release
```

Never jump directly from documentation to full-game implementation.

---

# 4. VERTICAL SLICE FIRST

The first playable milestone is defined in:

```text
VERTICAL-SLICE.md
```

Claude Code MUST implement only the systems required for the Vertical Slice before expanding the project.

The Vertical Slice should demonstrate the actual identity of the game.

It must include:

```text
Player movement
↓
Vietnamese environment
↓
Old fisherman
↓
Exploration
↓
Collect primitive fishing materials
↓
Craft primitive fishing rod
↓
Travel to drain
↓
Fishing tutorial
↓
First fish
↓
Giant fish encounter
↓
Rod breaks
↓
Vertical Slice ending
```

The goal is not feature quantity.

The goal is:

> Can a player understand what this game feels like after 15–30 minutes?

---

# 5. DEVELOPMENT PRINCIPLES

## 5.1 Data Driven

Prefer data-driven systems over hardcoded gameplay.

Bad:

```text
if fish == "bigfish"
```

Prefer:

```text
FishDefinition
FishSpecies
FishBehavior
FishStats
```

Story content should also be data-driven.

Dialogue, quests, events, items, fish, NPCs and story states should have unique IDs.

---

# 5.2 Systems Must Be Independent

Avoid creating giant classes.

Do not create:

```text
GameManagerEverything
PlayerManagerEverything
FishingManagerEverything
```

Prefer:

```text
FishingSystem
FishSystem
InventorySystem
QuestSystem
DialogueSystem
RelationshipSystem
SaveSystem
TimeSystem
WeatherSystem
```

Each system should have a clear responsibility.

---

# 5.3 Avoid God Classes

If a class starts handling:

* player movement
* fishing
* inventory
* dialogue
* quests
* economy
* save
* NPCs

split it.

A class should have one clear reason to change.

---

# 5.4 Narrative Is Data

Do not hardcode large amounts of story directly into gameplay code.

Avoid:

```text
if player catches fish:
    show dialogue
    increase relationship
    unlock quest
    change weather
    move NPC
```

Prefer:

```text
Event
→ Conditions
→ Dialogue
→ Effects
```

The narrative layer should be configurable.

---

# 5.5 Unique IDs

Every important entity must have a stable ID.

Examples:

```text
PLAYER
NPC_MOTHER
NPC_OLD_FISHERMAN
NPC_FISH_VENDOR
NPC_SHOP_OWNER
NPC_FISHING_FRIEND

MAP_HOME
MAP_DRAIN
MAP_LAKE
MAP_STREAM
MAP_RIVER
MAP_RESERVOIR
MAP_SEA

ITEM_BAMBOO
ITEM_RUBBER_LINE
ITEM_WIRE_HOOK
ITEM_SHOE_FLOAT
ITEM_BASIC_BAIT

FISH_SMALL_001
FISH_GIANT_DRAIN

QUEST_MAIN_FIRST_FISH
QUEST_MAIN_BROKEN_ROD

EVENT_FIRST_FISHERMAN
EVENT_GIANT_FISH

ENDING_LET_GO
ENDING_KEEP_PULLING
ENDING_TOGETHER
```

Do not change IDs casually after implementation.

---

# 6. STORY RULES

The game must feel like a real life story.

Avoid:

* excessive exposition
* artificial fantasy dialogue
* NPCs existing only for quests
* unrealistic reactions
* constant dramatic events
* player being the center of everyone's life

Prefer:

* environmental storytelling
* natural dialogue
* silence
* small interactions
* humor
* ordinary problems
* realistic consequences
* subtle emotional changes

---

# 7. SHOW, DON'T TELL

Whenever possible:

```text
Show behavior
>
Explain behavior
```

Example:

Instead of:

> "Your mother is worried about you."

Show:

```text
Mother waits near the door.

Mother:
"Về rồi đó hả?"

She looks at the wet clothes.

Mother:
"Đi đâu mà người ướt hết vậy?"
```

The player should understand the emotion from context.

---

# 8. DIALOGUE RULES

Dialogue should be:

* short
* natural
* contextual
* Vietnamese in spirit
* character-specific

Avoid:

```text
"You have discovered an important new quest."
```

Prefer natural conversation.

NPC speech should reflect:

* age
* occupation
* relationship
* mood
* location
* time
* previous events

Do not make every NPC sound like the same writer.

---

# 9. PLAYER AGENCY

Choices should have consequences.

A choice may affect:

```text
relationship
money
items
quests
NPC memory
future dialogue
future events
world state
story progression
```

Do not create meaningless dialogue choices everywhere.

Choices should exist because the player is making a decision.

---

# 10. NO GOOD/BAD MORALITY SYSTEM

Do not create:

```text
Good Ending
Bad Ending
Evil Ending
Hero Ending
```

The final outcomes should represent different consequences of player choices.

Canonical endings:

```text
ENDING_LET_GO
ENDING_KEEP_PULLING
ENDING_TOGETHER
```

Do not label one ending as morally correct.

---

# 11. FAMILY SYSTEM

Mother is a major character.

The relationship should not be represented by a single binary value.

Use multiple dimensions:

```text
Trust
Concern
Understanding
Respect
Conflict
Support
```

Mother's attitude toward fishing should evolve naturally.

Possible progression:

```text
Fishing is dangerous
↓
Fishing is a hobby
↓
Fishing matters to the player
↓
Mother understands the passion
↓
Mother may eventually support the dream
```

Do not make the transformation instant.

---

# 12. FISHING SYSTEM

Fishing is the central gameplay system.

Core sequence:

```text
Prepare
↓
Select bait
↓
Cast
↓
Wait
↓
Fish detects bait
↓
Bite
↓
Hook
↓
Fight
↓
Manage tension
↓
Manage stamina
↓
Fish exhaustion
↓
Land fish
```

Fishing must feel physical.

Important factors:

```text
rod strength
line strength
hook strength
reel power
fish strength
fish stamina
fish behavior
water current
wind
player skill
```

Avoid reducing fishing to:

```text
Press E → wait → receive fish
```

---

# 13. FISH AI

Fish should behave differently.

Supported behavior archetypes:

```text
Aggressive
Passive
Cautious
Erratic
Deep Diver
Surface Runner
Bottom Feeder
```

Fish behavior should influence:

* bite probability
* movement
* escape
* stamina
* line tension
* fight duration

The player should learn fish behavior through experience.

---

# 14. WORLD DESIGN

The world should feel alive even when the player is not interacting with it.

NPCs should:

* have schedules
* move
* work
* eat
* rest
* react to weather
* remember events
* talk to each other

The world should not freeze when the player leaves.

---

# 15. TIME SYSTEM

Use:

```text
Morning
Afternoon
Evening
Night
```

Time should influence:

* NPC schedules
* fishing conditions
* fish activity
* weather
* random events
* dialogue
* shop availability
* family interactions

Do not create unnecessary real-time complexity during the Vertical Slice.

---

# 16. WEATHER

Supported weather:

```text
Sunny
Cloudy
Light Rain
Heavy Rain
Storm
```

Weather should affect gameplay and atmosphere.

Possible effects:

```text
fish activity
water conditions
NPC behavior
movement
visibility
sound
fishing difficulty
random events
```

Weather must not exist only as visual decoration.

---

# 17. ECONOMY

Money should matter.

Primary income:

```text
Fish
Scrap
Quests
Special Events
```

Primary expenses:

```text
Rod
Reel
Line
Hook
Bait
Repair
Travel
Food
Equipment
```

Avoid making money meaningless.

The player should regularly face choices such as:

```text
Save for better rod
vs
Buy bait
vs
Repair equipment
vs
Spend money on something else
```

---

# 18. PROGRESSION

Progression should represent player growth.

Dimensions:

```text
Fishing Skill
Equipment
Knowledge
Map Access
Relationships
Economy
Story
```

Do not rely only on XP and levels.

A player should feel:

> "I know how to fish better now."

Not only:

> "My fishing level increased from 4 to 5."

---

# 19. MAP PROGRESSION

Canonical progression:

```text
Home
↓
Drain
↓
Lake
↓
Stream
↓
River
↓
Reservoir
↓
Sea
↓
Old Drain
```

Each location must introduce something new.

Examples:

```text
Drain
→ basic fishing

Lake
→ larger fish

Stream
→ current

River
→ stronger fish

Reservoir
→ large-scale fishing

Sea
→ advanced fishing

Old Drain
→ final giant fish
```

---

# 20. RANDOM EVENTS

Random events should make the world feel alive.

Examples:

```text
Fall into pond
Lost dog
Rain
Child asks for help
Family argument
Meet another fisherman
Trespassing incident
Gear confiscated
Give fish to struggling family
Stranger asks for help
Empty fishing day
```

Random events must use:

```text
Event ID
Trigger
Location
Time
Weather
Probability
Cooldown
Prerequisites
Participants
Choices
Consequences
Relationship Changes
Rewards
```

Avoid random events that happen so often that they stop feeling random.

---

# 21. SAVE SYSTEM

Save important persistent state.

At minimum:

```text
Player position
Player money
Inventory
Equipment
Fishing skill
Unlocked maps
Quest state
Story state
NPC relationships
NPC memories
Family state
World state
Ending variables
```

Save data must be versioned.

Example:

```text
SaveVersion: 1
```

Future migrations should be possible.

---

# 22. DEBUGGING

During development, provide debug capabilities.

Examples:

```text
give_money 10000
give_item ITEM_BAMBOO 5
set_time 18:00
set_weather rain
set_relationship NPC_MOTHER 80
unlock_map MAP_LAKE
start_quest QUEST_MAIN_FIRST_FISH
spawn_fish FISH_GIANT_DRAIN
```

Debug functionality must not become part of normal gameplay.

---

# 23. PERFORMANCE

Prioritize:

```text
stable frame rate
reasonable memory usage
fast loading
limited unnecessary simulation
```

Do not simulate every NPC at full fidelity when they are far from the player.

Use simulation levels:

```text
Near
Mid
Far
Inactive
```

---

# 24. ASSET RULES

Use consistent naming.

Example:

```text
environment/
    env_home
    env_drain
    env_lake

characters/
    char_mother
    char_old_fisherman

fish/
    fish_tilapia
    fish_carp
    fish_giant_drain

props/
    prop_bamboo
    prop_bucket
    prop_broken_rod
```

Prefer reusable assets.

Do not duplicate assets unnecessarily.

---

# 25. CODE QUALITY

Every implementation should prioritize:

```text
Readability
Maintainability
Testability
Modularity
Performance
```

Before creating a new class, ask:

```text
Does this responsibility already belong somewhere?
```

Before adding a dependency, ask:

```text
Does this module really need this dependency?
```

---

# 26. IMPLEMENTATION WORKFLOW

For every feature:

## Step 1 — Read Documentation

Read the relevant documents.

## Step 2 — Identify Existing Systems

Search the codebase.

Do not duplicate existing systems.

## Step 3 — Design

Define:

```text
data
state
events
dependencies
UI
save requirements
```

## Step 4 — Implement

Implement the smallest working version.

## Step 5 — Test

Test:

```text
happy path
failure path
edge cases
save/load
```

## Step 6 — Validate

Check whether implementation still matches documentation.

## Step 7 — Refactor

Remove:

```text
duplicate code
dead code
temporary hacks
unnecessary dependencies
```

---

# 27. CLAUDE CODE BEHAVIOR

When asked to implement a feature:

1. Read relevant documentation.
2. Inspect existing code.
3. Identify affected systems.
4. Explain implementation plan briefly.
5. Implement incrementally.
6. Run tests/build.
7. Fix errors.
8. Report files changed.
9. Report remaining limitations.

Do not modify unrelated systems.

---

# 28. DO NOT INVENT CANON

Claude Code must not silently invent:

* new main characters
* new major story arcs
* new endings
* new core mechanics
* new map progression
* major relationship rules

If implementation requires a new canonical decision:

```text
STOP
↓
Explain the decision
↓
Ask for confirmation
↓
Update documentation
↓
Implement
```

---

# 29. DOCUMENTATION FIRST

If code and documentation disagree:

Do not blindly change either one.

Determine which is canonical.

If the feature changes the intended design:

```text
Update documentation
↓
Update implementation
↓
Update tests
```

The documentation is part of the project.

---

# 30. MVP RULE

The first goal is not:

> Build the whole game.

The first goal is:

> Prove that the core experience is fun.

The MVP must prove:

```text
Walking feels good
+
World feels Vietnamese
+
Fishing feels physical
+
Fish fight feels exciting
+
Story feels natural
+
Player wants to catch the next fish
```

---

# 31. FINAL DEVELOPMENT PRINCIPLE

Always ask:

> "Does this make the player feel like they are living a fishing story?"

If the answer is no, reconsider the feature.

The project should remain:

> A Life Story Disguised as a Fishing Game.
