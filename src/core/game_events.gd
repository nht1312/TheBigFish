class_name GameEvents
extends RefCounted
## Canonical event names sent over the EventBus (docs/18 §9).
## Systems never call each other for reactions; they emit one of these.

const FISH_LANDED := &"FishLanded"
const FISH_LOST := &"FishLost"
const FISH_HOOKED := &"FishHooked"
const ROD_BROKEN := &"RodBroken"
const FISHING_STATE_CHANGED := &"FishingStateChanged"
const CAST_MADE := &"CastMade"

const ITEM_OBTAINED := &"ItemObtained"
const ITEM_LOST := &"ItemLost"
const ITEM_CRAFTED := &"ItemCrafted"
const EQUIPMENT_CHANGED := &"EquipmentChanged"

const QUEST_STARTED := &"QuestStarted"
const QUEST_COMPLETED := &"QuestCompleted"
const OBJECTIVE_COMPLETED := &"ObjectiveCompleted"

const FLAG_CHANGED := &"FlagChanged"
const STAT_CHANGED := &"StatChanged"
const MONEY_CHANGED := &"MoneyChanged"
const RELATIONSHIP_CHANGED := &"RelationshipChanged"
const MEMORY_ADDED := &"MemoryAdded"

const MAP_ENTERED := &"MapEntered"
const LOCATION_ENTERED := &"LocationEntered"
const MAP_UNLOCKED := &"MapUnlocked"

const HOUR_CHANGED := &"HourChanged"
const DAY_PHASE_CHANGED := &"DayPhaseChanged"
const WEATHER_CHANGED := &"WeatherChanged"

const DIALOGUE_STARTED := &"DialogueStarted"
const DIALOGUE_NODE := &"DialogueNode"
const DIALOGUE_ENDED := &"DialogueEnded"

const STORY_EVENT_TRIGGERED := &"StoryEventTriggered"
const INTERACTED := &"Interacted"
const FISHERMAN_CATCH_OBSERVED := &"FishermanCatchObserved"
const CHAPTER_STARTED := &"ChapterStarted"

## Presentation-only events: UI/audio/camera react, game logic never depends on them.
const MESSAGE := &"Message"
const CUE := &"Cue"
const AUTOSAVE_REQUESTED := &"AutosaveRequested"
