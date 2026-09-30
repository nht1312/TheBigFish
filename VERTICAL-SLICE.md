# CÁ LỚN — THE LAST CAST

# Vertical Slice Specification

---

# 1. PURPOSE

The Vertical Slice is the first fully playable representation of the game.

It is NOT the full game.

It is a small but polished section that demonstrates:

* gameplay
* atmosphere
* fishing
* exploration
* narrative
* NPC interaction
* progression
* environmental storytelling

The target playtime is:

> 15–30 minutes.

---

# 2. VERTICAL SLICE GOAL

The player should finish the Vertical Slice thinking:

> "I want to catch that giant fish."

The Vertical Slice should establish:

```text
Interest
↓
Exploration
↓
Improvisation
↓
First Success
↓
Failure
↓
Determination
```

---

# 3. INCLUDED STORY

The Vertical Slice covers the beginning of the game.

Story sequence:

```text
Opening
↓
Meet Old Fisherman
↓
Become Interested in Fishing
↓
Search for Materials
↓
Craft Improvised Rod
↓
Travel to Drain
↓
Learn Fishing
↓
Catch First Fish
↓
Giant Fish Appears
↓
Rod Breaks
↓
Return Home
↓
Vertical Slice Complete
```

---

# 4. PLAYER EXPERIENCE TARGET

The player should experience:

### 0–5 minutes

Curiosity.

```text
Walking
Environment
Old Fisherman
Fishing animation
Fish caught
```

### 5–10 minutes

Exploration.

```text
Search environment
Collect bamboo
Find rubber/string
Find wire
Find float material
Find bait
```

### 10–20 minutes

Fishing.

```text
Craft rod
Travel to drain
Cast
Wait
Bite
Hook
Fight
Catch fish
```

### 20–30 minutes

Excitement + failure.

```text
Large fish appears
Player hooks fish
Fight begins
Improvised rod reaches limit
Rod breaks
Fish escapes
```

---

# 5. VERTICAL SLICE MAPS

Only two primary maps are required.

```text
MAP_HOME
MAP_DRAIN
```

Optional small transitional area:

```text
MAP_PATH_TO_DRAIN
```

Do NOT implement:

```text
Lake
Stream
River
Reservoir
Sea
```

during the first Vertical Slice unless technically required for navigation testing.

---

# 6. MAP_HOME

## Purpose

Introduce:

* player
* mother
* basic environment
* crafting
* inventory
* story context

---

## Environment

The environment should feel like contemporary Vietnam.

Elements may include:

```text
Small house
Concrete path
Plants
Buckets
Plastic containers
Clothesline
Motorbike
Old furniture
Small yard
Local road
Drainage system
Utility poles
```

The environment does not need to be geographically exact.

It must feel believable.

---

# 7. OPENING SEQUENCE

The player starts walking.

Camera:

```text
First Person
```

Movement:

```text
Walk
Look
Sprint
```

No combat.

No complex UI.

---

# 8. OLD FISHERMAN

The player sees an older man fishing near water.

NPC:

```text
NPC_OLD_FISHERMAN
```

The player does not need to interact immediately.

The player may observe him.

The fisherman eventually catches a fish.

The fish reaction should communicate:

```text
surprise
excitement
satisfaction
```

without excessive dialogue.

---

# 9. FIRST STORY TRIGGER

After observing the fisherman:

```text
STORY_PROLOGUE_FISHERMAN
```

State:

```text
FishingPassion += small amount
Knowledge.Fishing += 1
```

The player becomes interested.

---

# 10. RETURN HOME

The player returns home.

Mother interaction introduces:

```text
home
family
daily life
fishing curiosity
```

Mother should not immediately become a major obstacle.

At this point fishing is simply:

> Something the player is curious about.

---

# 11. SEARCH FOR MATERIALS

The player does not own fishing equipment.

The player must improvise.

Required materials:

```text
Bamboo
Rubber/String
Shoe Piece
Wire
Insects/Bait
```

---

# 12. MATERIAL COLLECTION

Required interactions:

### Bamboo

Source:

```text
environment
```

Interaction:

```text
Inspect
Collect
```

Item:

```text
ITEM_BAMBOO
```

---

### Rubber/String

Source:

```text
roadside / discarded object
```

Item:

```text
ITEM_RUBBER_LINE
```

---

### Shoe Piece

Source:

```text
old discarded shoe
```

Item:

```text
ITEM_SHOE_FLOAT
```

---

### Wire

Source:

```text
scrap area
```

Item:

```text
ITEM_WIRE
```

---

### Bait

The player searches soft soil.

Possible bait:

```text
worms
small insects
```

Item:

```text
ITEM_BASIC_BAIT
```

---

# 13. CRAFTING

The player combines materials.

Recipe:

```text
RECIPE_IMPROVISED_ROD
```

Inputs:

```text
ITEM_BAMBOO
ITEM_RUBBER_LINE
ITEM_SHOE_FLOAT
ITEM_WIRE
ITEM_BASIC_BAIT
```

Output:

```text
ITEM_IMPROVISED_ROD
```

---

# 14. CRAFTING PRESENTATION

Do not create a large crafting interface for the Vertical Slice.

Use a simple interaction.

Example:

```text
Sit down
+
materials shown
+
short crafting animation
```

The goal is immersion.

---

# 15. TRAVEL TO DRAIN

After crafting:

```text
QUEST_MAIN_FIRST_FISH
```

Objective:

> Find a place to fish.

The player discovers the large drain.

Map:

```text
MAP_DRAIN
```

---

# 16. DRAIN DESIGN

The drain should feel larger than expected.

Environment:

```text
Concrete
Mud
Grass
Trash
Water
Plants
Small bridges
Drainage structures
Fishing spots
```

The location should communicate:

> This is not a beautiful fishing location.

It is an ordinary place where someone decided to fish.

---

# 17. FIRST FISHING TUTORIAL

The game introduces fishing gradually.

Sequence:

```text
Equip rod
↓
Choose bait
↓
Cast
↓
Wait
↓
Float moves
↓
React
↓
Hook fish
↓
Fish fights
↓
Control tension
↓
Land fish
```

Do not show all instructions simultaneously.

Teach one mechanic at a time.

---

# 18. FISHING HUD

Minimum HUD:

```text
Fish tension
Line condition
Player stamina
Fish stamina
```

Optional:

```text
Bait
Rod condition
```

Avoid excessive HUD.

---

# 19. FIRST FISH

The first fish should be relatively easy.

Example:

```text
FISH_SMALL_COMMON
```

Characteristics:

```text
Low strength
Low stamina
Predictable movement
Short fight
```

The player should have a high chance of success.

---

# 20. FIRST SUCCESS

When the player lands the first fish:

```text
Fish added to inventory
FishingSkill increases
Quest progresses
```

Possible message:

> "You caught your first fish."

Avoid excessive reward popups.

---

# 21. GIANT FISH EVENT

After the first successful catch, the environment changes subtly.

Possible cues:

```text
Water movement
Large splash
Float movement
Shadow
Sound
Water ripple
```

Then:

```text
FISH_GIANT_DRAIN
```

appears.

---

# 22. GIANT FISH DESIGN

The giant fish should NOT be catchable in the Vertical Slice.

It exists to establish the long-term goal.

Stats:

```text
Strength: Extremely High
Speed: High
Stamina: Very High
Aggression: High
```

Behavior:

```text
Sudden acceleration
Deep dive
Long run
Sharp direction changes
```

---

# 23. GIANT FISH FIGHT

Player hooks the giant fish.

The game should temporarily become intense.

Sequence:

```text
Hook
↓
Fish runs
↓
Line tension rises
↓
Player tries to control fish
↓
Rod bends
↓
Rod durability drops
↓
Player struggles
↓
Rod breaks
↓
Fish escapes
```

---

# 24. ROD BREAK EVENT

Canonical event:

```text
EVENT_GIANT_FISH_BREAKS_ROD
```

Consequences:

```text
ITEM_IMPROVISED_ROD destroyed
FISH_GIANT_DRAIN escapes
FishingPassion increases
GiantFishEncountered = true
```

Optional:

```text
Player falls backward
```

Use physical comedy sparingly.

---

# 25. EMOTIONAL RESULT

The player should feel:

```text
Excitement
↓
Frustration
↓
Determination
```

The giant fish becomes the first long-term objective.

The player should naturally think:

> "I need better equipment."

Do not explicitly tell the player:

> "Your next goal is to buy a better rod."

Let the failure communicate it.

---

# 26. VERTICAL SLICE ENDING

After the rod breaks:

```text
Player returns home.
```

Possible final scene:

The player looks at the broken rod.

Mother notices.

Possible dialogue:

```text
Mother:
"Đã nói đừng có nghịch mấy cái này rồi."

Player:
"..."

Mother looks at the broken bamboo.

Mother:
"Mai tính gì?"

Player looks toward the road.

Fade out.
```

The exact dialogue can evolve during implementation.

---

# 27. VERTICAL SLICE SUCCESS CONDITIONS

The Vertical Slice is successful if the following are true.

## Movement

```text
Player movement feels responsive.
Camera feels comfortable.
```

## Environment

```text
World feels Vietnamese.
Environment does not feel like a generic asset demo.
```

## NPC

```text
Old fisherman feels believable.
Mother feels believable.
```

## Crafting

```text
Player understands why the rod is improvised.
```

## Fishing

```text
Casting feels good.
Bite feels exciting.
Fish fight feels physical.
```

## Failure

```text
Rod breaking feels understandable.
Player understands why better equipment is needed.
```

## Narrative

```text
Player understands the dream:
catch the giant fish.
```

---

# 28. OUT OF SCOPE

Do NOT implement during Vertical Slice:

```text
Full economy
Full shop
Full fish market
Multiple large maps
Advanced crafting
Full NPC schedules
Complex reputation
Full family system
Multiple endings
Sea fishing
Advanced weather simulation
Multiplayer
Online features
Character customization
Complex inventory management
Full quest database
```

Build only the minimum architecture necessary to support future expansion.

---

# 29. REQUIRED SYSTEMS

The Vertical Slice requires:

```text
PlayerController
InteractionSystem
InventorySystem
CraftingSystem
FishingSystem
FishSystem
DialogueSystem
QuestSystem
Basic NPCSystem
Basic SaveSystem
Basic TimeSystem
AudioSystem
UI System
```

Systems may initially be simplified.

They must remain expandable.

---

# 30. REQUIRED DATA

Minimum data:

```text
Player
NPC
Item
Recipe
Fish
Quest
Dialogue
Event
Map
```

All important data should use stable IDs.

---

# 31. DEBUG FEATURES

Vertical Slice development should include:

```text
Teleport Home
Teleport Drain
Give Materials
Give Rod
Spawn Small Fish
Spawn Giant Fish
Set Time
Set Weather
Reset Quest
```

These commands are development-only.

---

# 32. TEST CHECKLIST

## Start

* [ ] New game starts correctly
* [ ] Player can move
* [ ] Player can look around
* [ ] Player can sprint

## Story

* [ ] Old fisherman appears
* [ ] Fisherman can fish
* [ ] First story trigger works
* [ ] Mother dialogue works

## Exploration

* [ ] Bamboo can be collected
* [ ] Rubber can be collected
* [ ] Shoe piece can be collected
* [ ] Wire can be collected
* [ ] Bait can be collected

## Crafting

* [ ] Recipe unlocks
* [ ] Materials are consumed
* [ ] Rod is created
* [ ] Rod appears in inventory

## Fishing

* [ ] Rod can be equipped
* [ ] Bait can be selected
* [ ] Cast works
* [ ] Bite works
* [ ] Hook works
* [ ] Fish movement works
* [ ] Line tension works
* [ ] Fish can be landed

## Giant Fish

* [ ] Giant fish event triggers
* [ ] Giant fish can be hooked
* [ ] Giant fish fights differently
* [ ] Rod durability decreases
* [ ] Rod breaks
* [ ] Fish escapes

## End

* [ ] Player can return home
* [ ] Final dialogue plays
* [ ] Vertical Slice completion state is saved

---

# 33. QUALITY BAR

The Vertical Slice should prioritize:

```text
Feel > Feature Count
Atmosphere > Map Size
Fishing Quality > Fish Quantity
Character Believability > Dialogue Quantity
Polish > Content Volume
```

A 20-minute polished experience is more valuable than a 2-hour unfinished prototype.

---

# 34. FINAL VERTICAL SLICE LOOP

The complete experience should feel like:

```text
SEE SOMEONE FISH
        ↓
BECOME CURIOUS
        ↓
SEARCH FOR MATERIALS
        ↓
MAKE A ROD
        ↓
FIND A PLACE
        ↓
LEARN TO FISH
        ↓
CATCH A FISH
        ↓
SEE THE GIANT FISH
        ↓
TRY TO CATCH IT
        ↓
FAIL
        ↓
WANT BETTER EQUIPMENT
        ↓
RETURN HOME
        ↓
"TO BE CONTINUED..."
```

This loop is the foundation of the entire game.
