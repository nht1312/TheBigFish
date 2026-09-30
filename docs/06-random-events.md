# Random Events

# CÁ LỚN — RANDOM EVENTS

> Status: Canonical
> Version: 1.0

---

# 1. PURPOSE

Random Events tạo cảm giác:

> "Thế giới đang sống."

Không phải mọi thứ đều được thiết kế riêng cho Player.

---

# 2. EVENT CATEGORIES

```text
LIFE
FAMILY
FISHING
WEATHER
FRIENDSHIP
HUMOR
DANGER
DISCOVERY
COMMUNITY
ECONOMY
```

---

# 3. EVENT DATA

Mỗi event có:

```text
EventID
Category
Location
TimeCondition
WeatherCondition
Probability
Cooldown
Prerequisites
Participants
Trigger
Sequence
Choices
Consequences
RelationshipEffects
Rewards
StoryEffects
```

---

# 4. EVENT STATES

```text
AVAILABLE
TRIGGERED
ACTIVE
RESOLVED
COOLDOWN
EXPIRED
```

---

# 5. EVENT — FALL INTO WATER

## ID

`EVENT_LIFE_FALL_WATER`

Trigger:

Player di chuyển gần mép nước.

Possible conditions:

* low stamina
* slippery weather
* incorrect movement

Outcome:

Player falls.

Possible reactions:

* NPC laughs
* NPC helps
* Player embarrassed
* Mother hears about it

---

# 6. EVENT — MOTHER FORBIDS FISHING

## ID

`EVENT_FAMILY_FISHING_BAN`

Trigger:

Fishing too frequently.

Conditions:

```text
MotherConcern > threshold
```

Outcome:

Mother asks Player to stop fishing for one day.

Player can:

```text
Obey
Argue
Ignore
```

---

# 7. EVENT — GIVE FISH

## ID

`EVENT_COMMUNITY_GIVE_FISH`

Trigger:

Player returns from fishing.

A struggling family is encountered.

Choices:

```text
Sell Fish
Keep Fish
Give Fish
```

Consequences:

Give Fish:

* lose potential money
* relationship/community increase

---

# 8. EVENT — RAIN

## ID

`EVENT_WEATHER_RAIN`

Trigger:

Weather changes while Player is fishing.

Possible consequences:

* fishing conditions change
* NPCs leave
* visibility decreases
* equipment gets wet

---

# 9. EVENT — LOST DOG

## ID

`EVENT_LIFE_LOST_DOG`

Trigger:

Player encounters a dog searching around neighborhood.

Choices:

```text
Ignore
Follow
Help
```

Potential outcome:

Discover owner.

---

# 10. EVENT — CHILD WATCHING

## ID

`EVENT_SOCIAL_CHILD_FISHING`

Child watches Player fishing.

Possible dialogue:

> "Anh câu được cá gì vậy?"

Player can:

```text
Explain
Ignore
Show Fish
```

This can create a small relationship.

---

# 11. EVENT — EMPTY FISHING DAY

## ID

`EVENT_FISHING_EMPTY_DAY`

Player spends time fishing but catches nothing.

Purpose:

Normalize failure.

Potential dialogue:

```text
"Chắc hôm nay cá không muốn ăn."
```

---

# 12. EVENT — FRIEND ENCOUNTER

Player encounters Friend unexpectedly.

Friend may:

* invite Player
* share information
* challenge Player
* ask for help

---

# 13. EVENT — GEAR LOSS

Player can lose gear due to:

* accident
* authority confiscation
* environmental event

Purpose:

Create consequences.

---

# 14. EVENT — STRANGER

Player meets an unknown fisherman.

Stranger may:

* provide information
* sell bait
* tell a story
* give advice
* mislead Player

Not every stranger must be trustworthy.

---

# 15. EVENT — FISHERMAN COMPETITION

Two fishermen argue over fishing spot.

Player can:

```text
Ignore
Observe
Intervene
```

Different consequences.

---

# 16. EVENT — HEAVY RAIN

During heavy rain:

NPC behavior changes.

Some NPCs:

* go home
* close shops
* seek shelter

Others:

* continue fishing

Fishing conditions change.

---

# 17. EVENT — HELP SOMEONE CARRY FISH

Player sees someone struggling with heavy fish basket.

Choice:

```text
Help
Ignore
```

If help:

Relationship increases.

---

# 18. EVENT — LOST WALLET

Player finds wallet.

Choices:

```text
Keep
Return
Search for owner
```

This event should not explicitly label one option as morally correct.

World reaction follows Player's choice.

---

# 19. EVENT — BROKEN SHOE

Player can experience a small accident while exploring.

Potential consequence:

Need to buy / repair shoes.

Small event.

Purpose:

Make the world feel ordinary.

---

# 20. EVENT — MARKET GOSSIP

At the market, NPCs discuss:

* large fish
* weather
* fishing spots
* prices
* local news

Information can indirectly help Player.

---

# 21. EVENT — FISH PRICE CHANGE

Fish market price changes.

Causes may include:

* season
* weather
* supply
* demand

---

# 22. EVENT — RARE FISH SIGHTING

NPC tells Player:

> "Hôm qua tôi thấy một con cá rất lớn ở phía dưới."

This may or may not be true.

Player can investigate.

---

# 23. EVENT — OLD FISHERMAN RETURN

Player encounters Old Fisherman again.

He may remember Player.

Dialogue changes depending on progression.

---

# 24. EVENT — FAMILY MEAL

At certain times Player may encounter family meal.

Player can:

```text
Join
Skip
Leave early
```

This affects family interactions.

---

# 25. EVENT — FISH GIFT

Player gives a fish to an NPC.

NPC may:

* cook it
* thank Player
* remember the gesture
* give something later

---

# 26. EVENT COOLDOWN

Events should have cooldowns.

Example:

```text
EVENT_FALL_WATER
Cooldown = 7 in-game days
```

Prevent repetitive events.

---

# 27. EVENT PRIORITY

If multiple events trigger simultaneously:

```text
Critical Story Event
↓
Character Event
↓
Family Event
↓
Major Random Event
↓
Minor Random Event
```

---

# 28. RANDOM EVENT RULE

Randomness must never override major narrative continuity.

Example:

If final story event is active:

```text
Do not trigger
Lost Dog
Market Gossip
Minor Fishing Event
```

---

# 29. RANDOMNESS PHILOSOPHY

Random events should create:

```text
Surprise
Humor
Emotion
Risk
Discovery
Relationships
```

Not artificial difficulty.

---

# 30. EVENT DESIGN TEST

Before adding an event ask:

1. Does this make the world feel more alive?
2. Can it happen naturally?
3. Does it respect the current story state?
4. Does Player have meaningful agency?
5. Does the world remember the outcome?

If not:

> Do not add the event.
