# Dialogue System

# CÁ LỚN — DIALOGUE SYSTEM

> Status: Canonical
> Version: 1.0

---

# 1. PURPOSE

Dialogue System quản lý:

* conversation
* branching dialogue
* choices
* relationship effects
* story conditions
* NPC memory
* dynamic dialogue

---

# 2. DIALOGUE PRINCIPLE

Dialogue phải phục vụ:

```text id="3gk1mg"
Character
Story
Relationship
World
Information
Emotion
```

Không dùng dialogue chỉ để giải thích mechanic.

---

# 3. DIALOGUE DATA

Mỗi dialogue node:

```text id="b0l1kl"
DialogueID
Speaker
Text
Conditions
Choices
NextNode
Effects
Tags
```

---

# 4. DIALOGUE NODE

Ví dụ:

```text id="0b2q2w"
Speaker:
Mother

Text:
"Đi đâu giờ này mới về?"

Choices:
1. "Con đi câu."
2. "Con đi có chút việc."
3. "Con xin lỗi."
```

---

# 5. CONDITIONS

Dialogue có thể phụ thuộc:

```text id="h5r4w7"
StoryProgress
Relationship
Time
Weather
Location
Inventory
QuestState
PreviousChoice
MajorEvent
FamilyState
```

---

# 6. DIALOGUE CHOICE

Choice có thể:

* thay đổi relationship
* trigger event
* set memory
* unlock quest
* change story state

---

# 7. DIALOGUE EFFECTS

```text id="3c0j1f"
Trust +1
Conflict -1
Friendship +2
Set Memory
Start Quest
Complete Quest
Unlock Event
Give Item
Remove Item
```

---

# 8. DIALOGUE TAGS

Ví dụ:

```text id="6pr4vy"
HUMOR
FAMILY
FISHING
EMOTIONAL
STORY
TUTORIAL
WARNING
RUMOR
```

---

# 9. CONDITIONAL DIALOGUE

Ví dụ:

Nếu Player chưa bắt cá:

> "Câu được con nào chưa?"

Nếu Player đã bắt cá lớn:

> "Nghe nói dạo này câu được cá to lắm."

Nếu Player đã gặp Giant Fish:

> "Mẹ thấy dạo này con cứ nhắc con cá đó."

---

# 10. DIALOGUE MEMORY

NPC có thể reference previous actions.

Ví dụ:

Player đã cho Fish Vendor một con cá hiếm.

Lần sau:

> "Hôm trước con cá đó bán được giá lắm."

---

# 11. DIALOGUE BRANCHING

Không phải branch nào cũng cần tạo storyline hoàn toàn khác.

Có 3 loại:

```text id="6z3n6u"
COSMETIC
RELATIONSHIP
STORY
```

---

# 12. COSMETIC BRANCH

Chỉ thay đổi câu thoại.

---

# 13. RELATIONSHIP BRANCH

Thay đổi:

* Trust
* Friendship
* Respect
* Conflict

---

# 14. STORY BRANCH

Thay đổi:

* quest
* event
* character availability
* ending conditions

---

# 15. DIALOGUE LENGTH

Normal conversation:

1–5 exchanges.

Important scene:

5–15 exchanges.

Major emotional scene:

Có thể dài hơn nhưng phải có gameplay/context xen kẽ.

---

# 16. SILENCE

Không phải lúc nào Player cũng phải lựa chọn.

Một số emotional moments nên có:

```text id="qzzb4j"
Pause
Animation
Look
Environment
Silence
```

thay vì dialogue.

---

# 17. ENVIRONMENTAL DIALOGUE

NPC có thể nói khi đang làm việc.

Ví dụ:

Fish Vendor vừa cân cá vừa nói chuyện.

Shop Owner vừa sửa reel vừa giải thích.

Điều này giúp dialogue tự nhiên hơn.

---

# 18. DIALOGUE CONDITIONS EXAMPLE

```text id="n3m6ts"
IF:
MotherConcern > 70
AND
Time > 22:00

THEN:

Mother dialogue:
"Con nhìn đồng hồ chưa?"
```

---

# 19. DIALOGUE CONSEQUENCE EXAMPLE

```text id="k1x1rs"
Player:
"Con sẽ về sớm."

Effect:

Set Promise_FamilyReturnEarly = true
```

Nếu Player phá lời hứa:

```text id="b8n4t9"
Trust ↓
Conflict ↑
Memory added
```

---

# 20. DIALOGUE TYPES

```text id="1m3ztt"
Greeting
Small Talk
Story
Quest
Tutorial
Argument
Emotional
Humor
Rumor
Farewell
```

---

# 21. DYNAMIC GREETING

Greeting thay đổi theo:

* time
* mood
* relationship
* weather
* previous event

---

# 22. DIALOGUE INTERRUPT

Dialogue có thể bị ngắt bởi:

* rain
* fish bite
* NPC event
* danger
* phone call
* family event

---

# 23. DIALOGUE RULE

Không cho NPC nói những điều họ không thể biết.

NPC knowledge phải được giới hạn.

---

# 24. PLAYER DIALOGUE

Player có thể có lựa chọn:

```text id="kw3t8f"
Neutral
Friendly
Funny
Honest
Aggressive
Avoidant
```

Không cần biến Player thành một character có personality cố định.

---

# 25. EMOTIONAL DIALOGUE

Các scene quan trọng nên giảm UI.

Ví dụ final:

Không cần:

```text id="m7t7aw"
[1] Save Mother
[2] Catch Fish
```

Có thể sử dụng:

```text id="p6t8f7"
LET GO
KEEP PULLING
```

hoặc lựa chọn hành động trực tiếp.

---

# 26. DIALOGUE DESIGN GOAL

Player phải cảm thấy:

> "Đây là cuộc trò chuyện giữa hai con người."

Không phải:

> "Đây là UI menu có text."
