# Quests

# CÁ LỚN — QUEST SYSTEM

> Status: Canonical
> Version: 1.0

---

# 1. QUEST PHILOSOPHY

Quest không nên khiến thế giới có cảm giác như:

> "Mọi người đang đứng yên chờ Player đến nhận nhiệm vụ."

Quest nên xuất phát từ:

* nhu cầu
* tình huống
* mối quan hệ
* câu chuyện
* môi trường

---

# 2. QUEST TYPES

```text
MAIN
SIDE
CHARACTER
DISCOVERY
EVENT
```

---

# 3. QUEST STATES

```text
LOCKED
AVAILABLE
ACTIVE
COMPLETED
FAILED
CANCELLED
EXPIRED
```

---

# 4. QUEST DATA

Mỗi quest có:

```text
QuestID
Title
Type
Description
StartCondition
Prerequisites
Objectives
Location
NPCs
Rewards
FailureCondition
TimeLimit
Consequences
NextQuest
```

---

# 5. MAIN QUEST LIST

## MQ_001 — THE FISHERMAN

Trigger:

Opening.

Objective:

Observe fisherman.

---

## MQ_002 — FIND MATERIALS

Objective:

Find bamboo.

Find string.

Find wire.

Find float material.

---

## MQ_003 — MAKE YOUR FIRST ROD

Objective:

Craft improvised rod.

---

## MQ_004 — FIND BAIT

Objective:

Find usable bait.

---

## MQ_005 — FIRST CAST

Objective:

Reach drain.

---

## MQ_006 — FIRST CATCH

Objective:

Catch first fish.

---

## MQ_007 — THE GIANT

Objective:

Fight giant fish.

Outcome:

Rod breaks.

---

## MQ_008 — GET BACK UP

Objective:

Earn money.

---

## MQ_009 — FIRST REAL GEAR

Objective:

Purchase proper fishing equipment.

---

## MQ_010 — THE LAKE

Objective:

Unlock lake.

---

## MQ_011 — NEW FRIEND

Objective:

Meet fishing friend.

---

## MQ_012 — WRONG POND

Objective:

Go fishing with friend.

Outcome:

Gear confiscated.

---

## MQ_013 — KEEP GOING

Objective:

Recover from setback.

---

## MQ_014 — THE RIVER

Objective:

Unlock river.

---

## MQ_015 — FARTHER

Objective:

Reach reservoir.

---

## MQ_016 — THE SEA

Objective:

Reach sea.

---

## MQ_017 — HOME

Objective:

Resolve major family progression.

---

## MQ_018 — RETURN

Objective:

Return to original drain.

---

## MQ_019 — THE LAST CAST

Objective:

Fight giant fish.

---

## MQ_020 — THE CHOICE

Objective:

Make final decision.

---

# 6. SIDE QUEST TYPES

Examples:

### Help NPC

Find an item.

Deliver something.

Assist NPC.

---

### Fishing Challenge

Catch:

* specific fish
* specific weight
* specific species
* specific condition

---

### Collection

Find:

* materials
* lost objects
* fishing equipment

---

### Family Task

Help at home.

Deliver item.

Return before certain time.

---

# 7. CHARACTER QUESTS

Each important character should have a quest chain.

Examples:

```text
Mother
Shop Owner
Fish Vendor
Friend
Old Fisherman
```

---

# 8. QUEST CONSEQUENCES

Quest completion can affect:

```text
Money
Items
Relationships
Story Progress
Map Access
NPC Availability
Future Events
Dialogue
```

---

# 9. FAILURE

Quest failure should not always mean Game Over.

Examples:

```text
Miss deadline
→ quest expires

Lose item
→ need replacement

Fail fishing challenge
→ retry later

Break promise
→ relationship decreases
```

---

# 10. QUEST WITHOUT QUEST MARKER

Some activities should have no obvious quest UI.

Example:

Player notices an old man struggling with a basket.

Player can:

```text
Ignore
Help
Talk
```

This can become a hidden event.

---

# 11. QUEST DISCOVERY

Quest can be discovered through:

```text
Dialogue
Observation
Exploration
NPC behavior
Environmental clues
Previous actions
Random events
```

---

# 12. QUEST DESIGN RULE

Every quest should answer:

1. Why does this matter?
2. Why now?
3. Why does Player care?
4. What changes after completion?

If no answer exists:

> Quest should not exist.
