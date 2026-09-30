# CÁ LỚN — THE LAST CAST

# Implementation Roadmap

---

# 1. PURPOSE

This document defines the implementation order for the entire project.

The project must be developed incrementally.

The objective is to avoid:

```text
Feature explosion
Architecture problems
Unfinished systems
Uncontrolled scope
Technical debt
```

---

# 2. DEVELOPMENT PHILOSOPHY

Development priority:

```text
Playable
↓
Stable
↓
Fun
↓
Complete
↓
Polished
↓
Optimized
```

Do not optimize systems before proving they are necessary.

Do not build content before core systems are stable.

---

# 3. DEVELOPMENT PHASES

```text
PHASE 0
Project Foundation

PHASE 1
Core Prototype

PHASE 2
Vertical Slice

PHASE 3
Core Fishing Game

PHASE 4
World & Progression

PHASE 5
Narrative & NPC Expansion

PHASE 6
Full Game Content

PHASE 7
Polish

PHASE 8
Optimization & Release
```

---

# 4. PHASE 0 — PROJECT FOUNDATION

## Goal

Create a clean technical foundation.

---

## Tasks

### Project setup

```text
Initialize repository
Initialize game project
Configure source control
Configure asset folders
Configure development environment
```

---

## Repository

Expected structure:

```text
fishing-rpg/
├── docs/
├── src/
├── assets/
├── tests/
├── tools/
├── config/
├── README.md
├── CLAUDE.md
├── VERTICAL-SLICE.md
└── IMPLEMENTATION-ROADMAP.md
```

---

## Development standards

Set up:

```text
Formatting
Linting
Testing
Build process
Environment configuration
Git workflow
```

---

## Deliverable

A project that:

```text
opens
builds
runs
loads
and can be committed safely
```

---

# 5. PHASE 1 — CORE PROTOTYPE

## Goal

Prove basic player interaction.

---

## Implement

```text
Player
Camera
Movement
Interaction
Basic World
Basic Input
Basic UI
```

---

## Player

Minimum:

```text
Walk
Look
Sprint
```

No advanced animation required initially.

---

## Interaction

Basic interaction types:

```text
Inspect
Collect
Talk
Use
```

---

## Deliverable

Player can walk through a simple environment and interact with objects.

---

# 6. PHASE 2 — VERTICAL SLICE

Reference:

```text
VERTICAL-SLICE.md
```

---

## Goal

Build the complete first playable experience.

---

## Implement

```text
Home
Old Fisherman
Mother
Material Collection
Crafting
Drain
Fishing
First Fish
Giant Fish
Broken Rod
Return Home
```

---

## Priority

### P0

```text
Movement
Fishing
Fish AI
Interaction
Inventory
Crafting
Story trigger
Giant fish event
```

### P1

```text
Dialogue
Basic NPC
Basic save
Audio
UI polish
```

### P2

```text
Environmental detail
Animation polish
Extra ambient events
```

---

## Deliverable

A 15–30 minute playable Vertical Slice.

---

# 7. PHASE 2 EXIT CRITERIA

Do NOT move forward until:

* [ ] Player movement feels stable
* [ ] Fishing loop works
* [ ] Fish fight works
* [ ] Rod breaking works
* [ ] Giant fish encounter works
* [ ] Basic story works
* [ ] Save/load works
* [ ] No critical blocker bugs
* [ ] Performance is acceptable
* [ ] Project can be built from a clean environment

Most importantly:

> The core game is enjoyable enough to justify continuing development.

---

# 8. PHASE 3 — CORE FISHING GAME

## Goal

Expand fishing from prototype to a robust gameplay system.

---

# 9. Fishing Equipment

Implement:

```text
Rod
Reel
Line
Hook
Float
Bait
Accessories
```

Each should have meaningful properties.

---

# 10. Equipment Stats

Example:

```text
RodStrength
RodSensitivity
ReelPower
ReelSpeed
LineStrength
HookStrength
FloatSensitivity
```

---

# 11. Fishing Conditions

Implement:

```text
Water Type
Depth
Current
Wind
Weather
Time
Fish Activity
```

---

# 12. Fish AI Expansion

Implement:

```text
Aggressive
Passive
Cautious
Erratic
Deep Diver
Surface Runner
Bottom Feeder
```

Each behavior should create a different fishing experience.

---

# 13. Fish Species

Initial target:

```text
5–10 species
```

Each species should have:

```text
Appearance
Weight
Strength
Speed
Stamina
Behavior
Preferred Water
Preferred Depth
Preferred Bait
Value
```

---

# 14. Fishing Failure

Implement:

```text
Line Break
Hook Break
Rod Break
Fish Escape
Bait Lost
Equipment Damage
```

Failures must be understandable.

The player should know why they failed.

---

# 15. PHASE 4 — WORLD & PROGRESSION

## Goal

Expand the world beyond the Drain.

Canonical map progression:

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

---

# 16. Lake

Purpose:

```text
First major upgrade
Larger fish
New fishing techniques
New NPCs
```

---

# 17. Stream

Purpose:

```text
Current-based fishing
Moving water
Different fish behavior
```

---

# 18. River

Purpose:

```text
Stronger fish
Deeper water
Longer fights
Higher risk
```

---

# 19. Reservoir

Purpose:

```text
Large-scale fishing
Long travel
Rare fish
Advanced equipment
```

---

# 20. Sea

Purpose:

```text
Major progression milestone
Large fish
Advanced fishing
Weather risk
Boat/coastal mechanics if required
```

Do not add boats automatically.

Only implement them if they support the intended gameplay.

---

# 21. Old Drain

Purpose:

```text
Return to origin
Final challenge
Giant fish
Narrative payoff
```

The player returns with everything they have learned.

---

# 22. PHASE 5 — NPC & NARRATIVE EXPANSION

## Goal

Transform the prototype into a living world.

---

# 23. NPC System

Implement:

```text
Schedules
Needs
Mood
Memory
Relationships
Knowledge
Reactions
```

---

# 24. Core NPCs

Fully implement:

```text
Mother
Old Fisherman
Fish Market Woman
Fishing Shop Owner
Fishing Friend
```

---

# 25. Secondary NPCs

Add:

```text
Scrap Collector
Neighbor
Child
Security Guard
Other Fishermen
Local Residents
Competitors
```

Secondary NPCs should not exist only to provide filler dialogue.

---

# 26. NPC Daily Life

Each important NPC should have:

```text
Morning
Afternoon
Evening
Night
```

Example:

```text
Shop Owner

08:00 → Open shop
12:00 → Lunch
13:00 → Return shop
18:00 → Close
19:00 → Home
```

---

# 27. Dialogue System

Expand:

```text
Conditional Dialogue
Relationship Dialogue
Story Dialogue
Ambient Dialogue
Weather Dialogue
Time Dialogue
Memory Dialogue
```

---

# 28. PHASE 6 — FAMILY & RELATIONSHIP

## Goal

Make relationships mechanically meaningful.

---

# 29. Mother Relationship

Track:

```text
Trust
Concern
Understanding
Respect
Conflict
Support
```

---

# 30. Friend Relationship

Track:

```text
Trust
Friendship
Fishing Knowledge
Reliability
```

The fishing friend can unlock:

```text
Fishing locations
Techniques
Events
Alternative solutions
```

---

# 31. Relationship Consequences

Relationships may influence:

```text
Dialogue
Quest availability
Random events
NPC support
Ending conditions
```

Do not turn relationships into simple:

```text
+10 = friend
-10 = enemy
```

Use context.

---

# 32. PHASE 7 — ECONOMY & PROGRESSION

## Goal

Create a meaningful long-term gameplay loop.

---

# 33. Economy

Implement:

```text
Money
Fish Prices
Scrap Value
Shop Prices
Repair Cost
Travel Cost
Bait Cost
```

---

# 34. Fish Market

Implement:

```text
Sell Fish
Price Variation
Fish Quality
Rare Fish Value
Market Relationship
```

Potential future feature:

```text
Market Demand
```

Only implement if it improves gameplay.

---

# 35. Fishing Shop

Implement:

```text
Rod Purchase
Reel Purchase
Line Purchase
Hook Purchase
Bait Purchase
Equipment Upgrade
Repair
```

---

# 36. Equipment Progression

```text
No Gear
↓
Improvised
↓
Basic
↓
Intermediate
↓
Advanced
↓
Professional
↓
Endgame
```

Each tier must unlock meaningful gameplay capability.

---

# 37. PHASE 8 — QUEST SYSTEM

## Goal

Create the complete quest structure.

---

# 38. Main Quests

Implement the major story path.

Example:

```text
QUEST_PROLOGUE
QUEST_FIRST_FISH
QUEST_BROKEN_ROD
QUEST_FIRST_UPGRADE
QUEST_LAKE
QUEST_STREAM
QUEST_RIVER
QUEST_RESERVOIR
QUEST_SEA
QUEST_RETURN_TO_DRAIN
QUEST_FINAL_FISH
```

Exact IDs should follow `docs/04-story-arcs.md`.

---

# 39. Side Quests

Side quests should reveal:

```text
Characters
Local life
Fishing culture
Family
Friendship
Environment
Humor
```

Avoid generic:

```text
Kill 10 fish
Collect 20 items
```

unless the task has narrative context.

---

# 40. Character Quests

Important NPCs should have personal arcs.

Examples:

```text
Mother
Fishing Friend
Old Fisherman
Shop Owner
Fish Market Woman
```

---

# 41. PHASE 9 — RANDOM EVENTS

## Goal

Make the world unpredictable.

Implement event categories:

```text
Humor
Family
Friendship
Fishing
Weather
Community
Conflict
Discovery
Failure
Generosity
```

---

# 42. Random Event Rules

Every event should define:

```text
EventID
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

---

# 43. Example Events

Implement gradually:

```text
EVENT_FALL_IN_POND
EVENT_LOST_DOG
EVENT_HEAVY_RAIN
EVENT_CHILD_REQUESTS_HELP
EVENT_GIVE_FISH
EVENT_MEET_FRIEND
EVENT_TRESPASSING
EVENT_GEAR_CONFISCATED
EVENT_FAMILY_ARGUMENT
EVENT_STRANGER_REQUEST
```

---

# 44. PHASE 10 — STORY ACTS

Implement story progression:

```text
PROLOGUE
ACT_I
ACT_II
ACT_III
ACT_IV
ACT_V
ACT_VI
EPILOGUE
```

---

# 45. Narrative Progression

The emotional progression should approximately follow:

```text
Wonder
↓
Fun
↓
Failure
↓
Determination
↓
Progress
↓
Humor
↓
Friendship
↓
Conflict
↓
Growth
↓
Nostalgia
↓
Tension
↓
Sacrifice
↓
Reflection
```

Do not force every chapter to contain every emotion.

---

# 46. PHASE 11 — FINAL ARC

## Goal

Build the final return to the original drain.

The player returns with:

```text
Advanced equipment
Fishing experience
Relationships
Knowledge
Personal history
```

The location should feel familiar but changed.

---

# 47. FINAL FISH

The giant fish should be:

```text
Difficult
Memorable
Mechanically different
Narratively meaningful
```

The fight should combine the fishing systems learned throughout the game.

---

# 48. FINAL FAMILY EVENT

Mother eventually participates in the final encounter depending on story conditions.

Possible sequence:

```text
Player fights fish
↓
Fish becomes stronger
↓
Player struggles
↓
Mother helps
↓
Player faces final choice
```

---

# 49. ENDINGS

Canonical endings:

```text
ENDING_LET_GO
ENDING_KEEP_PULLING
ENDING_TOGETHER
```

Do not present:

```text
Good
Bad
True
False
```

---

# 50. ENDING CONDITIONS

Ending outcomes should depend on:

```text
MotherRelationship
FamilyTrust
FishingPassion
FishingSkill
FriendRelationship
Support
StoryState
```

The exact conditions must follow:

```text
docs/17-ending-system.md
```

---

# 51. PHASE 12 — POLISH

## Goal

Turn functional systems into a cohesive game.

---

# 52. Visual Polish

Improve:

```text
Lighting
Materials
Water
Vegetation
Particles
Weather
Character animations
Fish animations
Environmental detail
```

---

# 53. Audio Polish

Implement:

```text
Water
Wind
Insects
Birds
Traffic
Village ambience
Rain
Fishing sounds
Reel
Line tension
Fish splash
Rod break
Footsteps
NPC ambience
Music
```

Audio should be spatial whenever possible.

---

# 54. Animation Polish

Prioritize:

```text
Fishing
Casting
Reeling
Fish struggle
Fish landing
Walking
Interaction
NPC idle
NPC work
Mother
Old fisherman
```

Fishing animation quality is especially important.

---

# 55. UI Polish

Improve:

```text
Inventory
Fishing HUD
Dialogue
Quest UI
Map
Equipment
Save/Load
Settings
```

Avoid excessive UI.

The environment should communicate information whenever possible.

---

# 56. PHASE 13 — PERFORMANCE

## Goal

Prepare the game for target hardware.

---

# 57. Performance Areas

Measure:

```text
CPU
GPU
Memory
Draw Calls
Physics
AI
Loading
Network
```

Network only applies if online features are later introduced.

---

# 58. Optimization Rules

Optimize based on measurements.

Do not optimize based on assumptions.

Prioritize:

```text
Object pooling
LOD
Occlusion
Asset compression
Texture optimization
Audio streaming
NPC simulation levels
Fish simulation levels
World streaming
```

---

# 59. PHASE 14 — QA

## Functional Testing

Test:

```text
Movement
Interaction
Fishing
Fish AI
Inventory
Crafting
Economy
Quests
Dialogue
NPCs
Relationships
Save/Load
Maps
Ending
```

---

# 60. Edge Case Testing

Examples:

```text
Save during fishing
Load during fishing
Save before quest completion
Load after quest completion
Inventory full
Broken rod
No bait
Insufficient money
NPC unavailable
Rain during event
Night during quest
Player leaves quest area
Player abandons fishing
Fish escapes
```

---

# 61. SAVE COMPATIBILITY

Every release candidate must test:

```text
New Save
Existing Save
Old Save
Corrupted Save
Missing Data
Version Migration
```

---

# 62. PHASE 15 — RELEASE CANDIDATE

The game should reach:

```text
Feature Complete
Content Complete
Stable
Optimized
Playable From Start To End
```

No major system should remain experimental.

---

# 63. RELEASE CHECKLIST

## Game

* [ ] Main story complete
* [ ] All maps playable
* [ ] Fishing complete
* [ ] NPCs complete
* [ ] Family system complete
* [ ] Economy complete
* [ ] Progression complete
* [ ] Endings complete

## Technical

* [ ] No critical bugs
* [ ] Save/load stable
* [ ] Performance acceptable
* [ ] Build reproducible
* [ ] Assets packaged correctly

## UX

* [ ] Controls understandable
* [ ] Tutorial understandable
* [ ] UI readable
* [ ] Audio balanced
* [ ] Accessibility options reviewed

---

# 64. PRIORITY SYSTEM

Every feature should receive one priority.

```text
P0 = Required for current milestone
P1 = Important
P2 = Nice to have
P3 = Future idea
```

Do not implement P2/P3 while P0 features remain broken.

---

# 65. FEATURE REQUEST PROCESS

When a new idea appears:

```text
New Idea
↓
Does it support core vision?
↓
Does it improve gameplay?
↓
Does it fit current scope?
↓
Does it conflict with existing design?
↓
Assign Priority
↓
Add to roadmap
```

Do not immediately implement every idea.

---

# 66. TECHNICAL DEBT RULE

Temporary solutions are allowed during prototypes.

However, mark them clearly:

```text
TODO
TECH-DEBT
TEMP
```

Before production milestone:

```text
Search technical debt
↓
Prioritize
↓
Refactor
↓
Remove temporary implementations
```

---

# 67. CLAUDE CODE TASK FORMAT

Large tasks should be broken into small implementation tasks.

Example:

```text
Task:
Implement basic fishing state machine.

Scope:
07-fishing-system.md

Requirements:
IDLE
CASTING
WAITING
BITE
HOOKED
FIGHTING
LANDED
BROKEN

Do not implement:
advanced fish AI
weather effects
economy
multiplayer

Acceptance:
Player can cast.
Fish can bite.
Player can hook.
Fish can fight.
Fish can be landed.
```

---

# 68. MILESTONE STRUCTURE

Each milestone should have:

```text
Goal
Scope
Dependencies
Tasks
Acceptance Criteria
Known Issues
Next Milestone
```

---

# 69. MILESTONE M0

## Foundation

Deliver:

```text
Project
Repository
Build
Basic architecture
Documentation
Development tooling
```

---

# 70. MILESTONE M1

## Player Prototype

Deliver:

```text
First-person controller
Camera
Movement
Interaction
Basic environment
```

---

# 71. MILESTONE M2

## Fishing Prototype

Deliver:

```text
Rod
Cast
Bite
Hook
Fish fight
Line tension
Fish escape
Fish landing
```

---

# 72. MILESTONE M3

## Vertical Slice

Deliver:

```text
Opening
Old fisherman
Material collection
Crafting
Drain
First fish
Giant fish
Broken rod
Mother
Return home
```

---

# 73. MILESTONE M4

## Fishing Expansion

Deliver:

```text
Equipment
Multiple fish
Multiple behaviors
Weather
Water conditions
Fishing upgrades
```

---

# 74. MILESTONE M5

## World Expansion

Deliver:

```text
Lake
Stream
River
Reservoir
Sea
Travel
Map progression
```

---

# 75. MILESTONE M6

## Living World

Deliver:

```text
NPC schedules
NPC memory
Relationships
Family
Random events
Economy
Shop
Fish market
```

---

# 76. MILESTONE M7

## Story Complete

Deliver:

```text
Main story
Side quests
Character quests
Family arc
Friend arc
Final arc
Endings
```

---

# 77. MILESTONE M8

## Polish

Deliver:

```text
Visual polish
Audio polish
Animation polish
UI polish
Performance
Bug fixing
```

---

# 78. MILESTONE M9

## Release Candidate

Deliver:

```text
Complete game
Stable build
Final save system
Final settings
Final assets
Final QA
```

---

# 79. DEFINITION OF DONE

A feature is NOT complete merely because the code compiles.

A feature is complete when:

* [ ] Code implemented
* [ ] Data implemented
* [ ] UI implemented if required
* [ ] Audio implemented if required
* [ ] Save state handled
* [ ] Edge cases handled
* [ ] Tests pass
* [ ] Documentation updated
* [ ] No obvious debug artifacts
* [ ] Feature works in a clean build

---

# 80. FINAL DEVELOPMENT RULE

Always develop from:

```text
Core Experience
        ↓
Systems
        ↓
Content
        ↓
Polish
```

Never:

```text
Content
↓
Content
↓
Content
↓
More Content
↓
Systems break
```

The final product should remain focused on one experience:

> A person learns to fish, grows through fishing, builds relationships through fishing, and eventually discovers that the biggest catch may not be the fish itself.
