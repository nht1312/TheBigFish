# Story Arcs
# CÁ LỚN — STORY ARCS

> Status: Canonical
> Version: 1.0

---

# 1. STORY STRUCTURE

```text
PROLOGUE
ARC 01 — FIRST CAST
ARC 02 — FIRST FAILURE
ARC 03 — LEARNING TO FISH
ARC 04 — FIRST MONEY
ARC 05 — BETTER GEAR
ARC 06 — NEW WATER
ARC 07 — FRIENDSHIP
ARC 08 — CONSEQUENCES
ARC 09 — GROWING WORLD
ARC 10 — FAMILY
ARC 11 — DISTANT WATERS
ARC 12 — RETURN
ARC 13 — THE GIANT FISH
ARC 14 — THE CHOICE
EPILOGUES
```

---

# 2. PROLOGUE — THE OLD FISHERMAN

## Purpose

Introduce fishing.

## Trigger

Game starts.

## Sequence

```text
Player walks
↓
Sees river
↓
Sees fisherman
↓
Fisherman catches fish
↓
Player observes
↓
Player becomes interested
```

## End Condition

Player decides to try fishing.

---

# 3. ARC 01 — NOTHING TO FISH WITH

## Objective

Player needs to find equipment.

## Required Materials

```text
Bamboo
Rubber/String
Wire
Improvised Float
Bait
```

## Gameplay

Player explores nearby area.

---

# 4. ARC 02 — FIRST ROD

Player crafts an improvised fishing rod.

Components:

```text
Bamboo
String/Rubber
Wire
Shoe Piece / Improvised Float
```

---

# 5. ARC 03 — FIRST BAIT

Player learns that bait is required.

Player searches soft soil.

Possible bait:

```text
Worm
Insect
Small Larva
```

---

# 6. ARC 04 — FIRST FISHING TRIP

Location:

`MAP_01_DRAIN`

Objectives:

1. Reach fishing spot.
2. Equip rod.
3. Select bait.
4. Cast.
5. Wait.
6. Detect bite.
7. Hook fish.
8. Fight fish.
9. Land fish.

---

# 7. ARC 05 — FIRST FISH

Player catches first fish.

Narrative purpose:

> Give Player the first feeling of achievement.

---

# 8. ARC 06 — THE GIANT

After first successful catch:

Special event triggers.

Water changes.

Large movement appears.

Player hooks giant fish.

Fight begins.

Primitive rod cannot handle tension.

Rod breaks.

Fish escapes.

---

# 9. ARC 07 — THE PROMISE

Player decides:

> "Mình sẽ bắt lại nó."

This becomes the long-term narrative goal.

---

# 10. ARC 08 — LEARNING TO EARN

Player needs money.

Activities:

```text
Collect Scrap
Sell Scrap
Sell Fish
Complete Small Tasks
Help NPCs
```

---

# 11. ARC 09 — FIRST REAL GEAR

Player buys first proper fishing equipment.

Possible:

```text
Rod
Reel
Line
Hooks
Float
Bait
```

---

# 12. ARC 10 — FIRST LAKE

Player unlocks the first proper lake.

New fish.

New fishing conditions.

New NPCs.

New risks.

---

# 13. ARC 11 — THE FISHING FRIEND

Player meets Friend.

Relationship develops through shared fishing.

---

# 14. ARC 12 — THE ILLEGAL POND

Friend takes Player to a pond.

Player does not know it is prohibited.

Authority catches them.

Consequences:

```text
Fishing gear confiscated
Money loss
Relationship impact
Temporary fishing restriction
```

---

# 15. ARC 13 — THE WORLD OPENS

Player gradually unlocks:

```text
Lake
↓
Stream
↓
River
↓
Reservoir
↓
Sea
```

Each area introduces:

* new fish
* new mechanics
* new NPCs
* new story events
* stronger gear requirements

---

# 16. ARC 14 — FAMILY CONFLICT

Mother notices Player spending more time fishing.

Possible conflicts:

```text
Player returns late
Player spends money
Player skips responsibilities
Player gets injured
Player travels too far
```

---

# 17. ARC 15 — LIFE EVENTS

Player encounters events unrelated to fishing.

Examples:

### Giving Fish

Player sees a struggling family.

Choice:

```text
SELL FISH
KEEP FISH
GIVE FISH
```

---

### Falling Into Pond

Player falls into water.

Possible consequence:

* embarrassment
* NPC reaction
* temporary restriction

---

### Rain

Player gets caught in rain.

Possible consequences:

* fishing becomes harder
* equipment affected
* NPC dialogue changes

---

# 18. ARC 16 — GROWING SKILL

Player becomes increasingly skilled.

The game should not communicate this only through numerical stats.

Show progression through:

* better casts
* better fish control
* better understanding of water
* better bait selection
* better equipment

---

# 19. ARC 17 — RETURN TO THE ORIGIN

After late-game progression:

Old Drain becomes accessible.

Player returns.

Environment should visually resemble the beginning.

But Player has changed.

---

# 20. ARC 18 — FINAL FISH

Giant Fish appears.

Player begins the final fight.

Fight has multiple phases.

---

# 21. PHASE 1

Fish behaves normally.

Player controls tension.

---

# 22. PHASE 2

Fish becomes aggressive.

Line tension increases.

Player stamina decreases.

---

# 23. PHASE 3

Fish makes a final escape attempt.

Player becomes exhausted.

---

# 24. MOTHER ARRIVES

Mother appears.

Possible dialogue:

> "Đưa đây mẹ kéo với."

Exact dialogue remains TBD.

---

# 25. FINAL EVENT

Mother helps.

Both pull.

Fish approaches.

Mother slips.

---

# 26. FINAL CHOICE

Choice A:

```text
LET GO
```

Player saves Mother.

Fish escapes.

Choice B:

```text
KEEP PULLING
```

Player continues fighting fish.

Mother's fate depends on implementation.

Choice C:

```text
TOGETHER
```

Only available if conditions are satisfied.

Friend helps stabilize the rod.

Player saves Mother.

---

# 27. ARC COMPLETION

After final choice:

Gameplay transitions to epilogue.

No immediate "YOU WIN" message.

Allow emotional decompression.

---

# 28. STORY PACING

Recommended rhythm:

```text
Gameplay
↓
Small Story
↓
Gameplay
↓
Funny Event
↓
Gameplay
↓
Emotional Event
↓
Progression
↓
Major Story
```

Không được để:

```text
CUTSCENE
CUTSCENE
CUTSCENE
DIALOGUE
CUTSCENE
```

liên tục quá lâu.

---

# 29. STORY STATE

Story progress được lưu bằng:

```text
StoryChapter
StoryArc
MajorEventsCompleted
MajorChoices
UnlockedMaps
CharacterRelationships
FinalChoice
```
