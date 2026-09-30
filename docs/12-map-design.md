# Map Design

# CÁ LỚN — MAP DESIGN

> Status: Canonical
> Version: 1.0

---

# 1. WORLD MAP STRUCTURE

```text
HOME AREA
    |
    +-- MARKET
    |
    +-- SHOP
    |
    +-- SCRAP YARD
    |
    +-- DRAIN
          |
          +-- LAKE
                |
                +-- STREAM
                      |
                      +-- RIVER
                            |
                            +-- RESERVOIR
                                  |
                                  +-- SEA
```

---

# 2. MAP DESIGN PRINCIPLE

Mỗi map phải có:

1. Identity.
2. Fishing style.
3. Fish ecosystem.
4. NPC ecosystem.
5. Environmental identity.
6. Story events.
7. Random events.
8. Reason to return.

---

# 3. MAP DATA

Mỗi map:

```text
MapID
Name
Type
Size
Terrain
WaterType
Depth
FishingSpots
Fish
NPCs
Resources
Weather
Time
StoryEvents
RandomEvents
UnlockCondition
```

---

# 4. MAP_00_HOME

## Role

Player's home base.

## Features

```text
Home
Neighborhood
Market
Shop
Scrap Yard
Drain Access
```

## Purpose

* tutorial
* preparation
* family
* economy
* social interaction

---

# 5. MAP_01_DRAIN

## Name

The Drain

## Narrative Role

Origin of the journey.

---

## Environment

* concrete
* dirty water
* grass
* mud
* trash
* pipes
* drainage infrastructure

---

## Fishing

Small freshwater fish.

Occasionally medium fish.

Special:

Giant Fish.

---

## Resources

```text
Bait
Scrap
Wire
Bamboo
```

---

## NPCs

* Old Fisherman
* casual fishermen
* neighborhood NPCs

---

## Weather

All normal weather states.

Storm may restrict access.

---

## Story Events

```text
First Fishing
First Fish
Giant Fish Encounter
Final Giant Fish
```

---

# 6. MAP_02_LAKE

## Role

First major fishing area.

---

## Environment

* larger body of water
* vegetation
* fishing platforms
* paths
* small structures

---

## Fish

More species.

Larger fish.

---

## Gameplay

Introduces:

* deeper water
* different fishing spots
* stronger fish
* longer fights

---

## NPCs

* fishermen
* families
* children
* vendors

---

# 7. MAP_03_STREAM

## Role

Introduce moving water.

---

## Environment

* rocks
* shallow water
* vegetation
* uneven terrain

---

## Water

Strong current.

---

## Fishing Challenge

Player must understand:

```text
Current
Position
Fish Movement
Bait Placement
```

---

# 8. MAP_04_RIVER

## Role

Mid-game expansion.

---

## Environment

Large.

Multiple fishing areas.

---

## Features

```text
Deep Areas
Shallow Areas
Vegetation
Rocks
Bridges
Small Boats
```

---

## Fish

Medium and large species.

---

# 9. MAP_05_RESERVOIR

## Role

Late freshwater area.

---

## Environment

Large open water.

---

## Difficulty

High.

---

## Fish

Large species.

Rare species.

---

## Requirements

Better:

```text
Rod
Reel
Line
Hook
Skill
```

---

# 10. MAP_06_SEA

## Role

Largest fishing environment.

---

## Environment

```text
Beach
Rocky Shore
Pier
Deep Water
Boats
Open Sea
```

---

## Systems

May introduce:

```text
Waves
Tide
Wind
Deep Water
Sea Species
```

---

# 11. MAP_07_OLD_DRAIN

Technically same location as first drain.

Narratively:

> It is the place Player remembers.

---

# 12. OLD DRAIN VISUAL CHANGE

Beginning:

```text
Player is inexperienced.
Environment feels large.
```

End:

```text
Player is experienced.
Environment feels familiar.
```

The world has not necessarily changed.

Player has changed.

---

# 13. FISHING SPOTS

Each map contains multiple spots.

Spot data:

```text
SpotID
Depth
WaterType
Current
FishPopulation
AccessDifficulty
RecommendedGear
TimePreference
WeatherPreference
```

---

# 14. FISHING SPOT TYPES

```text
SHALLOW
DEEP
VEGETATION
ROCK
CURRENT
STRUCTURE
OPEN_WATER
```

---

# 15. MAP DISCOVERY

Initially:

Player does not know all fishing spots.

Discovery through:

```text
Exploration
NPC
Friend
Observation
Random Event
```

---

# 16. MAP UNLOCKING

Maps unlock through story/progression.

```text
Drain
→ available immediately

Lake
→ First Gear / Story Progress

Stream
→ Skill / Story Progress

River
→ Progression

Reservoir
→ Advanced Progression

Sea
→ Late Progression
```

Exact conditions:

`TBD`

---

# 17. TRAVEL

Travel can consume:

```text
Time
Money
Stamina
```

But travel should not become repetitive loading.

---

# 18. SAFE AREAS

Each map should have safe zones.

Examples:

* shop
* shelter
* house
* fishing station

---

# 19. DANGER AREAS

Possible dangers:

```text
Deep Water
Strong Current
Slippery Terrain
Storm
Restricted Area
Wildlife
```

---

# 20. MAP STORY EVENTS

Map can have:

```text
Main Story
Side Quest
Character Quest
Random Event
Discovery Event
```

---

# 21. MAP RETURN VALUE

A map should remain useful after unlock.

For example:

Lake:

* rare fish
* cheaper bait
* specific NPC
* unique weather behavior

---

# 22. ENVIRONMENTAL PROGRESSION

Maps can visually change due to:

```text
Weather
Time
Story
NPC Activity
Player Actions
```

---

# 23. MAP DESIGN GOAL

The Player should gradually develop a mental map:

> "Chỗ này có cá gì?"

> "Buổi sáng nên câu ở đâu?"

> "Nếu trời mưa thì đi đâu?"

> "Con cá lớn thường ở khu vực nào?"

---

# 24. WORLD CONNECTIVITY

Maps should feel geographically connected.

Không nên có cảm giác:

```text
CLICK MAP
→ TELEPORT
→ COMPLETELY DIFFERENT WORLD
```

Trừ khi narrative yêu cầu.

---

# 25. MAP SCALE

Không ưu tiên diện tích quá lớn.

Ưu tiên:

```text
Density
Landmarks
Discoverability
Fishing Spots
NPC Activity
Environmental Storytelling
```

---

# 26. MAP LANDMARKS

Mỗi map cần landmark dễ nhớ.

Ví dụ:

```text
Drain:
Large Concrete Pipe

Lake:
Old Fishing Platform

Stream:
Broken Bridge

River:
Large Bridge

Reservoir:
Watch Tower

Sea:
Old Pier
```

---

# 27. MAP MEMORY

Player phải có thể nhớ:

> "Mình từng đứng ở đây."

Đặc biệt quan trọng với:

`MAP_01_DRAIN`.

---

# 28. MAP DESIGN RULE

Mỗi map phải trả lời được:

1. Nơi này khác map khác ở đâu?
2. Tại sao Player muốn đến?
3. Cá ở đây khác gì?
4. Người ở đây khác gì?
5. Gameplay thay đổi thế nào?
6. Có lý do gì để quay lại?

Nếu không trả lời được:

> Map chưa đủ lý do để tồn tại.
