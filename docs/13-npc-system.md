# NPC System

# CÁ LỚN — NPC SYSTEM

> Status: Canonical
> Version: 1.0
> Scope: NPC Behavior, Schedule, Relationship, Memory, Reactions

---

# 1. PURPOSE

NPC System chịu trách nhiệm mô phỏng cuộc sống của các nhân vật trong thế giới.

NPC không tồn tại chỉ để:

```text
WAIT
↓
PLAYER TALK
↓
GIVE QUEST
↓
WAIT
```

NPC phải có cuộc sống riêng.

---

# 2. NPC DESIGN PRINCIPLE

NPC phải có:

* Schedule
* Location
* Occupation
* Needs
* Mood
* Relationships
* Memory
* Goals
* Dialogue State
* Story State

---

# 3. NPC DATA

Mỗi NPC có:

```text id="zv1xkl"
NPC_ID
Name
Age
Occupation
HomeLocation
CurrentLocation
Schedule
Personality
Needs
Mood
RelationshipData
MemoryData
DialogueState
StoryState
Availability
```

---

# 4. NPC DAILY SCHEDULE

Schedule dựa trên time blocks:

```text id="d4m2rj"
06:00 - Wake
07:00 - Morning Activity
08:00 - Work
12:00 - Lunch
13:00 - Work
17:00 - Travel Home
18:00 - Family / Personal
20:00 - Social Activity
22:00 - Home
```

Đây chỉ là template.

Mỗi NPC có schedule riêng.

---

# 5. SCHEDULE EXAMPLE — FISH VENDOR

```text id="b3v4hp"
05:30
Prepare fish

06:30
Open market

07:00
Sell fish

12:00
Lunch

13:00
Market

18:00
Close

19:00
Home

22:00
Sleep
```

---

# 6. SHOP OWNER SCHEDULE

```text id="v1e4p7"
07:00
Open shop

08:00
Prepare inventory

09:00
Serve customers

12:00
Lunch

13:00
Shop

18:00
Close

19:00
Home
```

---

# 7. OLD FISHERMAN SCHEDULE

Old Fisherman có schedule ít cố định hơn.

Ví dụ:

```text id="pr8k6q"
Morning
Fishing

Afternoon
Rest / Home

Evening
Occasional fishing
```

Có thể thay đổi theo weather.

---

# 8. NPC NEEDS

NPC có thể có các needs:

```text id="z8qf02"
Food
Rest
Work
Social
Safety
Money
Family
```

Không cần mô phỏng tất cả needs ở mức simulation sâu.

Chỉ mô phỏng những gì ảnh hưởng đến gameplay.

---

# 9. NPC MOOD

Mood states:

```text id="v9n0e1"
Happy
Neutral
Tired
Busy
Worried
Angry
Sad
Excited
Relaxed
```

Mood ảnh hưởng đến:

* dialogue
* availability
* reaction
* willingness to help

---

# 10. NPC MEMORY

NPC có memory về Player.

Ví dụ:

```text id="7bq2tx"
Player gave fish
Player helped
Player caused trouble
Player broke promise
Player was rude
Player visited often
Player missed appointment
```

---

# 11. MEMORY IMPORTANCE

Không phải mọi action đều cần lưu.

Memory categories:

```text id="8sy9s7"
MINOR
NORMAL
IMPORTANT
MAJOR
```

---

# 12. MINOR MEMORY

Ví dụ:

Player nói chuyện với NPC.

Không cần lưu lâu dài.

---

# 13. NORMAL MEMORY

Ví dụ:

Player mua hàng nhiều lần.

NPC bắt đầu nhận ra Player.

---

# 14. IMPORTANT MEMORY

Ví dụ:

Player giúp NPC trong một event.

NPC nhớ điều đó.

---

# 15. MAJOR MEMORY

Ví dụ:

Player phản bội lời hứa.

Player gây ra sự cố lớn.

Player cứu NPC.

Những memory này ảnh hưởng lâu dài.

---

# 16. NPC REACTION MODEL

NPC reaction phụ thuộc:

```text id="0lq0y4"
Current Mood
+
Relationship
+
Memory
+
Player Reputation
+
Current Context
+
Story State
```

---

# 17. EXAMPLE

Player bước vào shop.

Nếu:

```text id="j3r9xq"
Relationship = High
Mood = Happy
```

NPC:

> "Lại kiếm đồ mới hả?"

Nếu:

```text id="2g6t4r"
Relationship = Low
Mood = Busy
```

NPC:

> "Đợi một chút."

---

# 18. NPC RELATIONSHIP

Relationship không nhất thiết là một con số duy nhất.

Có thể gồm:

```text id="g3i5a0"
Trust
Familiarity
Respect
Friendship
Conflict
```

---

# 19. NPC REPUTATION

Một số hành động có thể tạo reputation trong community.

Ví dụ:

Player thường giúp người khác:

→ nhiều NPC biết Player.

Player thường gây rắc rối:

→ một số NPC cảnh giác.

---

# 20. NPC KNOWLEDGE

NPC không biết mọi thứ.

Mỗi NPC có knowledge riêng:

```text id="f4c7c5"
Fishing
Market
Local Area
Weather
People
Rumors
```

---

# 21. INFORMATION SPREAD

NPC có thể truyền information.

Ví dụ:

```text id="g75l6u"
NPC A
↓
tells NPC B
↓
NPC B tells Player
```

Không cần mô phỏng toàn bộ xã hội.

Chỉ cần dùng cho các story/event quan trọng.

---

# 22. NPC LOCATION

NPC location thay đổi theo:

* time
* weather
* schedule
* story
* event

---

# 23. NPC AVAILABILITY

NPC có thể:

```text id="d5x3dj"
AVAILABLE
BUSY
AWAY
SLEEPING
EVENT_LOCKED
STORY_LOCKED
```

---

# 24. NPC INTERRUPTION

Player có thể gặp NPC ngoài schedule.

Ví dụ:

Shop Owner đang đóng cửa.

Player vẫn có thể thấy ông ấy đang sửa cửa.

Một event có thể xảy ra.

---

# 25. NPC COMBAT / DANGER

NPC không phải combat entities.

Khi có danger:

* chạy
* cảnh báo
* tìm chỗ trú
* gọi người khác

---

# 26. NPC WEATHER RESPONSE

Ví dụ:

Heavy Rain:

```text id="z1gk0p"
Fish Vendor
→ closes market

Casual Fisherman
→ goes home

Old Fisherman
→ may continue fishing

Child
→ stays indoors
```

---

# 27. NPC STORY LOCK

Trong major story events:

Một số NPC có thể:

```text id="xw2s2s"
Move
Disappear
Wait
Follow
Participate
```

---

# 28. NPC SCHEDULE PRIORITY

Priority:

```text id="h4e2h4"
Major Story
↓
Character Event
↓
Random Event
↓
Daily Schedule
```

---

# 29. NPC DEBUG INFORMATION

Development mode nên hiển thị:

```text id="6jmyu0"
NPC ID
Current Location
Current State
Mood
Relationship
Active Event
Next Schedule
```

---

# 30. NPC SYSTEM RULE

NPC phải tạo cho Player cảm giác:

> "Nếu hôm nay mình quay lại đây, có thể người này đang làm một việc khác."

Đây là nền tảng của một thế giới sống.
