# Technical Architecture

# CÁ LỚN — TECHNICAL ARCHITECTURE

> Status: Technical Foundation
> Version: 1.0
> Scope: System Architecture, Data Architecture, Runtime Architecture

---

# 1. ARCHITECTURE GOAL

Technical architecture phải phục vụ Game Design.

Không được để:

```text
Technology
↓
Dictates Game
```

Mà phải là:

```text
Game Design
↓
System Requirements
↓
Technical Architecture
↓
Implementation
```

---

# 2. CORE ARCHITECTURE PRINCIPLES

## Principle 01 — Data Driven

Các nội dung thay đổi thường xuyên nên nằm trong data.

Ví dụ:

* fish
* item
* NPC
* quest
* dialogue
* event
* map
* recipe

Không hard-code tất cả vào gameplay logic.

---

# 3. Principle 02 — Systems Are Independent

Fishing không được biết quá nhiều về:

* UI
* Dialogue
* Quest
* NPC

Thay vào đó dùng event/state communication.

---

# 4. Principle 03 — Narrative Is Data

Story state phải được lưu như data.

Ví dụ:

```text id="1yqk5m"
StoryChapter
MajorEvents
Choices
Relationships
UnlockedMaps
```

---

# 5. Principle 04 — Save Everything Important

Nếu một action có ảnh hưởng lâu dài:

> Phải có khả năng save.

---

# 6. HIGH-LEVEL ARCHITECTURE

```text id="2ovw1g"
GAME
│
├── CORE
│   ├── Game State
│   ├── Time
│   ├── Weather
│   ├── Event Bus
│   └── Game Loop
│
├── WORLD
│   ├── Maps
│   ├── Water
│   ├── Environment
│   └── World State
│
├── PLAYER
│   ├── Movement
│   ├── Camera
│   ├── Interaction
│   ├── Inventory
│   └── Progression
│
├── FISHING
│   ├── Fishing Controller
│   ├── Rod
│   ├── Reel
│   ├── Line
│   ├── Hook
│   └── Fishing State
│
├── FISH
│   ├── Fish Entity
│   ├── Fish AI
│   └── Fish Database
│
├── NPC
│   ├── NPC Controller
│   ├── Schedule
│   ├── Mood
│   ├── Relationship
│   └── Memory
│
├── QUEST
│   ├── Quest Manager
│   └── Quest State
│
├── DIALOGUE
│   ├── Dialogue Manager
│   └── Dialogue Data
│
├── ECONOMY
│   ├── Money
│   ├── Market
│   └── Prices
│
├── CRAFTING
│   ├── Recipe Manager
│   └── Crafting
│
├── EVENTS
│   ├── Story Events
│   └── Random Events
│
├── FAMILY
│   ├── Relationship
│   └── Family State
│
├── SAVE
│   ├── Save Manager
│   └── Save Data
│
└── UI
    ├── HUD
    ├── Inventory
    ├── Dialogue
    ├── Quest
    └── Menus
```

---

# 7. CORE LAYER

Core layer quản lý:

```text id="lx5i6p"
Game Loop
Game State
Time
Weather
Event Bus
Save/Load
Global State
```

Core không chứa game-specific behavior nếu không cần thiết.

---

# 8. GAME STATE

Global Game State:

```text id="q2x0q4"
CurrentMap
CurrentTime
CurrentWeather
PlayerState
StoryState
WorldState
NPCState
QuestState
EconomyState
FamilyState
```

---

# 9. EVENT BUS

Các system giao tiếp thông qua event.

Ví dụ:

```text id="0k8j7d"
FishLanded
FishSold
QuestCompleted
RelationshipChanged
MapUnlocked
ItemObtained
ItemLost
WeatherChanged
StoryEventTriggered
```

---

# 10. EXAMPLE EVENT FLOW

Player catches fish:

```text id="j6x3b2"
Fishing System
      ↓
FishLanded Event
      ↓
Event Bus
      ↓
Inventory System
      ↓
Fish added
      ↓
Quest System
      ↓
Check quest
      ↓
Relationship System
      ↓
Check relevant event
```

---

# 11. PLAYER SYSTEM

Player system chịu trách nhiệm:

```text id="n7h5x1"
Movement
Interaction
Camera
Input
Stamina
Fishing
Inventory Access
```

Không nên để Player class chứa toàn bộ game logic.

---

# 12. PLAYER STATE

```text id="v2m5y6"
Position
Rotation
Health
Stamina
Money
FishingSkill
CurrentEquipment
Inventory
CurrentQuest
CurrentInteraction
```

---

# 13. FISHING SYSTEM ARCHITECTURE

```text id="w1m8j2"
FishingController
│
├── CastController
├── BiteDetector
├── HookController
├── FishFightController
├── TensionController
├── ReelController
├── RodController
└── LandingController
```

---

# 14. FISH SYSTEM

Fish entity:

```text id="8c5n2a"
FishController
FishState
FishStats
FishAI
FishEnvironment
FishTarget
```

---

# 15. FISH AI

AI state machine:

```text id="x3r7p8"
IDLE
↓
SEARCH
↓
APPROACH
↓
INSPECT
↓
BITE
↓
HOOKED
↓
FIGHT
↓
ESCAPE
↓
REST
↓
EXHAUST
```

---

# 16. NPC ARCHITECTURE

```text id="j9h2c4"
NPCController
│
├── ScheduleController
├── MovementController
├── MoodController
├── RelationshipController
├── MemoryController
├── DialogueController
└── EventController
```

---

# 17. QUEST ARCHITECTURE

```text id="a8s4v5"
QuestManager
│
├── QuestDatabase
├── QuestState
├── ObjectiveTracker
├── RequirementChecker
└── RewardHandler
```

---

# 18. QUEST OBJECTIVE TYPES

```text id="c7n6b3"
ReachLocation
CatchFish
CatchSpecificFish
CollectItem
TalkToNPC
GiveItem
SellItem
CraftItem
BuyItem
CompleteEvent
MakeChoice
```

---

# 19. DIALOGUE ARCHITECTURE

```text id="e3q6t8"
DialogueManager
│
├── DialogueDatabase
├── ConditionEvaluator
├── ChoiceHandler
├── EffectHandler
└── DialogueState
```

---

# 20. CONDITION SYSTEM

Một condition có thể kiểm tra:

```text id="r8u2p1"
Story
Quest
Relationship
Inventory
Time
Weather
Location
Money
Item
PreviousChoice
EventState
```

---

# 21. EFFECT SYSTEM

Dialogue / Quest / Event có thể tạo effects:

```text id="x9w4m7"
GiveItem
RemoveItem
AddMoney
RemoveMoney
ModifyRelationship
ModifyFamilyState
StartQuest
CompleteQuest
UnlockMap
TriggerEvent
SetStoryState
SetMemory
```

---

# 22. INVENTORY ARCHITECTURE

```text id="m6n8q0"
InventoryManager
│
├── ItemDatabase
├── InventoryState
├── EquipmentManager
├── WeightManager
└── ItemTransaction
```

---

# 23. ITEM DATABASE

Items nên được data-driven.

Ví dụ:

```text id="d5k7x2"
ItemID:
ROD_IMPROVISED

Category:
FishingGear

Strength:
Low

Durability:
20

Value:
0
```

---

# 24. ECONOMY ARCHITECTURE

```text id="p3j8v6"
EconomyManager
│
├── Wallet
├── Market
├── PriceManager
├── Shop
└── TransactionManager
```

---

# 25. TRANSACTION SYSTEM

Mọi giao dịch:

```text id="u7q1w5"
BUY
SELL
GIVE
REWARD
PAY
```

đi qua transaction system.

---

# 26. CRAFTING ARCHITECTURE

```text id="k2s6n4"
CraftingManager
│
├── RecipeDatabase
├── RequirementChecker
├── MaterialConsumer
└── OutputGenerator
```

---

# 27. FAMILY SYSTEM ARCHITECTURE

```text id="f8m3r1"
FamilyManager
│
├── Trust
├── Concern
├── Understanding
├── Respect
├── Conflict
└── Support
```

---

# 28. RELATIONSHIP SYSTEM

Relationship system phải có API generic:

```text id="p6z9y3"
GetRelationship()
ModifyRelationship()
SetRelationshipState()
GetMemory()
AddMemory()
```

---

# 29. EVENT SYSTEM

Event Manager:

```text id="h4k7s2"
EventManager
│
├── EventDatabase
├── TriggerEvaluator
├── ConditionEvaluator
├── EventExecutor
├── CooldownManager
└── EventHistory
```

---

# 30. EVENT TRIGGER

Event có thể trigger bởi:

```text id="v5x8q1"
Location
Time
Weather
PlayerAction
Quest
Story
Relationship
RandomChance
```

---

# 31. STORY SYSTEM

Story Manager:

```text id="n3c7m9"
StoryManager
│
├── ChapterState
├── ArcState
├── MajorEvents
├── Choices
└── EndingState
```

---

# 32. WORLD STATE

World State lưu:

```text id="y8r2k5"
UnlockedMaps
ChangedObjects
NPCState
CompletedEvents
CurrentWeather
Time
MarketState
```

---

# 33. TIME SYSTEM

Time manager:

```text id="q4j6v8"
CurrentDay
CurrentHour
CurrentMinute
TimeScale
DayPhase
```

Day phases:

```text id="n5m9p3"
Morning
Afternoon
Evening
Night
```

---

# 34. WEATHER SYSTEM

Weather state:

```text id="x7c1h4"
CurrentWeather
Intensity
Duration
Forecast
```

States:

```text id="u2w6s8"
Sunny
Cloudy
LightRain
HeavyRain
Storm
```

---

# 35. WEATHER EVENTS

Weather changes can trigger:

```text id="a9e3r7"
NPC Behavior
Fishing Behavior
Fish Behavior
Random Events
Dialogue
World Visuals
```

---

# 36. SAVE SYSTEM

Save must preserve all important state.

---

# 37. SAVE DATA

```text id="g6k2n8"
Player
Inventory
Equipment
Money
FishingSkill
Story
Quests
NPCs
Relationships
Family
World
Maps
Weather
Time
Events
Ending
```

---

# 38. SAVE SLOT

Recommended:

```text id="t1v5q9"
Autosave
Manual Save
Checkpoint Save
```

---

# 39. AUTOSAVE

Autosave after:

* major quest
* major event
* map unlock
* important choice
* fishing milestone
* entering final sequence

---

# 40. SAVE VERSIONING

Save data phải có:

```text id="r4m8x6"
SaveVersion
```

Nếu data schema thay đổi:

```text id="e7y2k1"
Old Save
↓
Migration
↓
New Save
```

---

# 41. DATA ARCHITECTURE

Nên phân tách:

```text id="s2q6v9"
STATIC DATA
+
RUNTIME STATE
```

---

# 42. STATIC DATA

Ví dụ:

```text id="j4k8n2"
Fish Definitions
Item Definitions
NPC Definitions
Quest Definitions
Dialogue Definitions
Recipe Definitions
Map Definitions
Event Definitions
```

---

# 43. RUNTIME STATE

Ví dụ:

```text id="c5m9r3"
Current Fish
Current NPC Position
Player Inventory
Quest Progress
Relationships
Story Choices
World Changes
```

---

# 44. DATA ID RULE

Mọi data entity phải có unique ID.

Ví dụ:

```text id="h8p2w5"
FISH_CARP_COMMON
ITEM_ROD_IMPROVISED
NPC_MOTHER
QUEST_MQ_001
EVENT_FAMILY_001
DIALOGUE_MOTHER_001
MAP_01_DRAIN
```

---

# 45. ASSET ORGANIZATION

Conceptual structure:

```text id="m3x7q1"
assets/
├── environments/
├── characters/
├── fish/
├── props/
├── sounds/
├── music/
├── animations/
├── materials/
├── textures/
└── ui/
```

---

# 46. ENVIRONMENT ASSETS

```text id="v6n2s8"
Home
Market
Drain
Lake
Stream
River
Reservoir
Sea
```

---

# 47. FISH ASSETS

Mỗi fish:

```text id="p1r5k9"
Model
Texture
Animation
Behavior Config
Audio
VFX
```

---

# 48. NPC ASSETS

```text id="q8m4x2"
Model
Animations
Clothing
Voice / Audio
Dialogue
```

---

# 49. AUDIO ARCHITECTURE

Audio categories:

```text id="t6y3h8"
Ambient
Water
Weather
Fishing
NPC
UI
Music
Special Events
```

---

# 50. AUDIO STATES

Ví dụ khi fishing:

```text id="b7w2p4"
Normal Water
+
Wind
+
Reel
+
Line Tension
+
Fish Splash
```

Audio phải phản ánh trạng thái gameplay.

---

# 51. UI ARCHITECTURE

UI gồm:

```text id="x5n9c3"
HUD
Inventory
Equipment
Fishing HUD
Dialogue
Quest
Map
Shop
Crafting
Save
Settings
```

---

# 52. FISHING HUD

Fishing HUD chỉ hiển thị thông tin cần thiết:

```text id="g2m6r8"
Tension
Stamina
Fish State
Reel State
```

Không nên biến fishing thành dashboard.

---

# 53. DEBUG UI

Development build cần:

```text id="p9k4v1"
Current Map
Time
Weather
FPS
Player Position
Fishing State
Fish State
Tension
Quest State
Story State
NPC State
```

---

# 54. DEBUG COMMANDS

Nên có command để:

```text id="w3x7n5"
Give Item
Set Money
Set Time
Set Weather
Teleport
Unlock Map
Start Quest
Complete Quest
Trigger Event
Set Relationship
Set Story State
Spawn Fish
```

---

# 55. TESTING STRATEGY

Testing gồm:

```text id="r8m2k6"
Unit Test
System Test
Integration Test
Gameplay Test
Save/Load Test
Performance Test
```

---

# 56. UNIT TEST

Test logic:

* tension calculation
* fish stamina
* inventory transaction
* economy
* relationship
* quest condition
* dialogue condition

---

# 57. INTEGRATION TEST

Ví dụ:

```text id="s4q8v2"
Catch Fish
↓
FishLanded
↓
Inventory
↓
Sell
↓
Money
↓
Quest
↓
Relationship
```

---

# 58. SAVE/LOAD TEST

Test:

```text id="j7x3m9"
Save
↓
Close Game
↓
Load
↓
Verify State
```

Đặc biệt:

* inventory
* relationships
* quests
* story choices
* map unlocks

---

# 59. PERFORMANCE

Các hệ thống cần chú ý:

```text id="n6p2w8"
Fish AI
NPC AI
Water
Environment
Particles
Audio
Physics
```

---

# 60. SIMULATION LEVELS

Không phải tất cả NPC/fish phải chạy full simulation.

Có thể có:

```text id="q1v5s7"
FULL SIMULATION
REDUCED SIMULATION
BACKGROUND SIMULATION
DISABLED
```

---

# 61. NPC DISTANCE OPTIMIZATION

NPC gần Player:

```text id="a8m4k2"
Full AI
Animation
Interaction
```

NPC xa:

```text id="c6x9p3"
Schedule Simulation
No full movement
```

---

# 62. FISH DISTANCE OPTIMIZATION

Fish không gần Player không cần chạy full AI.

Có thể simulate bằng:

```text id="u7r2n5"
Population State
Fish Density
Activity Level
```

---

# 63. SYSTEM DEPENDENCY RULE

Dependency direction:

```text id="f3k8w1"
CORE
 ↓
SYSTEMS
 ↓
PRESENTATION
```

Không:

```text id="x9m4q6"
UI
 ↓
Core
```

---

# 64. RECOMMENDED MODULE BOUNDARIES

```text id="v2h7p9"
Core
Player
World
Fishing
Fish
NPC
Quest
Dialogue
Inventory
Economy
Crafting
Family
Events
Progression
Save
UI
```

Mỗi module phải có responsibility rõ ràng.

---

# 65. FOLDER STRUCTURE

Conceptual source structure:

```text id="g5n8x2"
src/
├── core/
│   ├── game/
│   ├── state/
│   ├── events/
│   ├── time/
│   ├── weather/
│   └── save/
│
├── player/
│   ├── controller/
│   ├── movement/
│   ├── interaction/
│   └── camera/
│
├── fishing/
│   ├── controller/
│   ├── equipment/
│   ├── tension/
│   ├── casting/
│   ├── hook/
│   └── landing/
│
├── fish/
│   ├── entities/
│   ├── ai/
│   ├── behaviors/
│   └── database/
│
├── inventory/
├── economy/
├── crafting/
├── npc/
├── dialogue/
├── quests/
├── events/
├── family/
├── progression/
├── world/
└── ui/
```

---

# 66. DATA FOLDER

Static game data:

```text id="h3m7q9"
data/
├── fish/
├── items/
├── npcs/
├── quests/
├── dialogues/
├── recipes/
├── maps/
├── events/
└── endings/
```

---

# 67. CONFIGURATION

Global configuration:

```text id="r5x2n8"
config/
├── fishing
├── economy
├── progression
├── weather
├── time
└── gameplay
```

---

# 68. CODE STYLE

Code phải ưu tiên:

* readable
* modular
* testable
* explicit
* small classes/functions
* meaningful names

---

# 69. AVOID

Không tạo:

```text id="m8q4s1"
GodClass
```

Ví dụ:

```text
GameManager
```

không được chứa:

* fishing
* inventory
* dialogue
* NPC
* economy
* quests
* family
* save

tất cả trong một class.

---

# 70. GAME STATE MANAGEMENT

Global state phải có boundary.

Không để mọi component sửa trực tiếp state.

Ưu tiên:

```text id="w7n3p6"
Action
↓
System
↓
State Change
↓
Event
↓
Other Systems React
```

---

# 71. EXAMPLE — SELL FISH

```text id="v4k8m2"
Player
↓
Sell Request
↓
Economy System
↓
Validate Fish
↓
Remove Fish
↓
Add Money
↓
FishSold Event
↓
Quest System
↓
Relationship System
```

---

# 72. EXAMPLE — MAP UNLOCK

```text id="x2p6r9"
Quest Completed
↓
Progression System
↓
Check Unlock Condition
↓
Map Unlock
↓
World State Updated
↓
Dialogue Updated
```

---

# 73. EXAMPLE — MOTHER EVENT

```text id="n5w8q3"
Player returns late
↓
Family System
↓
Concern ↑
↓
Event Trigger
↓
Mother Dialogue
↓
Player Choice
↓
Trust / Conflict updated
↓
Memory stored
```

---

# 74. EXAMPLE — GIANT FISH

```text id="s9m3v7"
Fish Bite
↓
Hook
↓
Fishing Fight
↓
Fish AI
↓
Tension Controller
↓
Rod / Line
↓
Player Stamina
↓
Fish State
↓
Rod Break
↓
Story Event
↓
Giant Fish Escapes
```

---

# 75. FINAL ENCOUNTER ARCHITECTURE

Final encounter phải là kết hợp:

```text id="q6x1n4"
Fishing System
+
Fish AI
+
Player Stamina
+
Mother NPC
+
Family System
+
Friend Relationship
+
Story System
+
Ending System
```

---

# 76. ENDING FLOW

```text id="u3p7m5"
Final Fight
↓
Mother Falls
↓
Ending Condition Evaluation
↓
Final Choice
↓
Ending Resolver
↓
World State
↓
Epilogue
↓
Save Ending
```

---

# 77. ENDING RESOLVER

Input:

```text id="f8k2r6"
FinalChoice
MotherState
FriendState
StoryState
MajorChoices
```

Output:

```text id="b4n9x1"
EndingID
```

---

# 78. TECHNICAL NON-GOALS

Architecture hiện tại không yêu cầu:

* multiplayer
* MMO
* procedural infinite world
* online economy
* server authoritative gameplay
* blockchain
* competitive leaderboard

Các tính năng này chỉ được thêm nếu Game Design thay đổi.

---

# 79. IMPLEMENTATION STRATEGY

Không build toàn bộ game cùng lúc.

Thứ tự:

```text id="m2v7q5"
Core
↓
Player
↓
World
↓
Basic Fishing
↓
One Fish
↓
Inventory
↓
Economy
↓
NPC
↓
Dialogue
↓
Quest
↓
Family
↓
Progression
↓
More Maps
↓
Final Encounter
```

---

# 80. VERTICAL SLICE

Vertical Slice tối thiểu phải chứng minh:

```text id="p5x8n3"
Player Movement
↓
Explore
↓
Find Material
↓
Craft Primitive Rod
↓
Find Bait
↓
Go To Drain
↓
Fish
↓
Catch First Fish
↓
Giant Fish Appears
↓
Rod Breaks
↓
Story State Updated
```

---

# 81. VERTICAL SLICE SUCCESS CRITERIA

Nếu vertical slice hoạt động, Player phải cảm nhận được:

1. Thế giới có đời sống.
2. Câu cá có cảm giác thật.
3. Cá có hành vi riêng.
4. Thất bại có ý nghĩa.
5. Câu chuyện có động lực.
6. Player muốn quay lại bắt Giant Fish.

---

# 82. DEVELOPMENT PHASES

## Phase 01 — Foundation

Implement:

```text id="a7r2m5"
Core
Player
Input
Camera
Basic World
```

---

## Phase 02 — First Fishing

Implement:

```text id="c9x4n7"
Rod
Line
Hook
Bait
Fish
Fishing State
```

---

## Phase 03 — First Story

Implement:

```text id="q3m8v1"
Opening
Material Collection
Crafting
First Fish
Giant Fish
Rod Break
```

---

## Phase 04 — World Simulation

Implement:

```text id="w6p2s9"
NPC
Time
Weather
Dialogue
Events
```

---

## Phase 05 — Progression

Implement:

```text id="n4k7x3"
Inventory
Economy
Quests
Maps
Equipment
Fishing Skill
```

---

## Phase 06 — Narrative

Implement:

```text id="r8m1q5"
Family
Friend
Character Arcs
Major Story
```

---

## Phase 07 — Endgame

Implement:

```text id="v2s6k9"
Old Drain
Giant Fish
Mother
Final Choice
Endings
```

---

# 83. TECHNICAL QUALITY BAR

Một system chỉ được xem là hoàn thành khi:

```text id="y5x9p2"
Works
+
Handles Failure
+
Saves Correctly
+
Doesn't Break Other Systems
+
Can Be Debugged
```

---

# 84. ARCHITECTURE GOLDEN RULE

Không xây architecture để chứng minh technology.

Xây architecture để phục vụ:

> Player Experience + Game Design + Narrative.

---

# 85. FINAL ARCHITECTURE PRINCIPLE

Toàn bộ game có thể nhìn như:

```text id="g7m3x8"
                    GAME
                      │
          ┌───────────┴───────────┐
          │                       │
        WORLD                   PLAYER
          │                       │
     ┌────┴────┐             ┌────┴────┐
     │         │             │         │
    NPC       FISHING       INPUT    INVENTORY
     │         │             │         │
 DIALOGUE    FISH AI       ACTION    ECONOMY
     │         │             │         │
 FAMILY       WATER          │       CRAFTING
     │         │             │         │
     └─────────┴─────────────┴─────────┘
                    │
                GAME STATE
                    │
          ┌─────────┼─────────┐
          │         │         │
        QUEST     STORY     EVENTS
          │         │         │
          └─────────┼─────────┘
                    │
                  SAVE
```

Architecture cuối cùng phải giữ được nguyên tắc:

> **Mỗi system biết việc của mình, nhưng toàn bộ system cùng tạo nên một thế giới thống nhất.**
