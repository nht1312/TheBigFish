# Fishing System

# CÁ LỚN — FISHING SYSTEM

> Status: Canonical
> Version: 1.0
> Scope: Core Fishing Gameplay

---

# 1. PURPOSE

Fishing là gameplay system trung tâm.

Mọi hệ thống khác phải có khả năng kết nối với fishing:

```text
Fishing
├── Fish AI
├── Equipment
├── Bait
├── Inventory
├── Economy
├── Weather
├── Water
├── Player Skill
├── NPC
└── Progression
```

Fishing không được trở thành một mini-game tách biệt khỏi thế giới.

---

# 2. CORE FISHING PHILOSOPHY

Fishing phải tạo cảm giác:

* chờ đợi
* quan sát
* căng thẳng
* phản ứng
* kiểm soát
* mất kiểm soát
* hy vọng
* thất vọng
* chiến thắng

Người chơi không chỉ bấm nút để "catch fish".

Người chơi phải cảm thấy:

> "Mình đang thực sự đấu với con cá."

---

# 3. FISHING FLOW

```text
PREPARE
↓
SELECT GEAR
↓
SELECT BAIT
↓
FIND FISHING SPOT
↓
CAST
↓
WAIT
↓
FISH APPROACHES
↓
BITE
↓
HOOK
↓
FIGHT
↓
MANAGE TENSION
↓
MANAGE STAMINA
↓
FISH ESCAPES / EXHAUSTS
↓
LAND
↓
STORE / SELL / KEEP / RELEASE
```

---

# 4. FISHING STATES

```text
IDLE
CASTING
WAITING
BITE
HOOKING
HOOKED
FIGHTING
ESCAPING
EXHAUSTED
LANDING
LANDED
LOST
BROKEN
```

---

# 5. STATE: IDLE

Player chưa bắt đầu fishing.

Có thể:

* di chuyển
* thay gear
* chọn bait
* quan sát nước

---

# 6. STATE: CASTING

Player thực hiện cast.

Các yếu tố:

* cast power
* cast direction
* cast distance
* wind
* player skill
* rod quality

Cast càng chính xác:

→ bait đến fishing spot tốt hơn.

---

# 7. STATE: WAITING

Float/bait ở trong nước.

Player có thể:

* quan sát float
* nghe âm thanh
* điều chỉnh nhẹ
* chờ

Không phải lúc nào cũng có cá.

---

# 8. STATE: BITE

Fish bắt đầu tương tác với bait.

Có thể có:

```text
Light Bite
Normal Bite
Strong Bite
Fake Bite
```

Fake bite giúp tạo căng thẳng.

---

# 9. STATE: HOOKING

Player phải phản ứng đúng thời điểm.

Timing ảnh hưởng:

* hook success
* hook strength
* fish escape probability

---

# 10. STATE: HOOKED

Fish đã mắc hook.

Từ đây bắt đầu fishing fight.

---

# 11. FISH FIGHT

Fish có thể:

```text
RUN
TURN
DIVE
SURFACE
SHAKE
REST
BURST
HIDE
```

---

# 12. PLAYER CONTROLS

Player kiểm soát:

```text
Rod Direction
Reel Speed
Line Tension
Movement
Drag
```

Không nên chỉ có một nút:

> Hold to catch.

---

# 13. LINE TENSION

Tension là biến quan trọng nhất.

Range:

```text
0 → 100
```

Ví dụ:

```text
0–30
Safe

30–60
Normal

60–80
Danger

80–95
Critical

95–100
Break
```

---

# 14. TENSION FACTORS

Tension tăng bởi:

```text
Fish Strength
Fish Acceleration
Reel Speed
Rod Angle
Line Strength
Hook Resistance
Water Current
Player Mistake
```

---

# 15. TENSION MANAGEMENT

Player phải liên tục điều chỉnh.

Nếu tension quá thấp:

→ mất control.

Nếu tension quá cao:

→ line/rod có thể hỏng.

Mục tiêu:

> Giữ tension trong vùng kiểm soát.

---

# 16. ROD ANGLE

Rod direction ảnh hưởng đến:

* fish direction
* tension
* fish fatigue

Player có thể kéo:

```text
Left
Right
Up
Down
```

---

# 17. REEL

Reel quyết định:

* tốc độ thu dây
* drag
* maximum tension
* recovery

Reel tốt:

→ thu dây hiệu quả hơn.

---

# 18. DRAG

Drag giới hạn lực tác động lên line.

Drag quá thấp:

→ fish dễ chạy.

Drag quá cao:

→ line dễ đứt.

---

# 19. PLAYER STAMINA

Fishing fight tiêu hao stamina.

Stamina giảm bởi:

* giữ rod lâu
* chống cá mạnh
* chạy theo cá
* thời tiết
* gear nặng

---

# 20. STAMINA STATES

```text
100–70
Fresh

70–40
Tired

40–15
Exhausted

15–0
Critical
```

---

# 21. FISH STAMINA

Fish cũng có stamina.

Fish càng lớn:

* stamina càng cao
* fight càng lâu

---

# 22. FISH EXHAUSTION

Khi stamina cá giảm thấp:

```text
Aggression ↓
Acceleration ↓
Escape Frequency ↓
Movement Speed ↓
```

Đây là thời điểm Player có thể land fish.

---

# 23. FISH ESCAPE

Fish có thể thoát khi:

* hook thất bại
* line break
* hook break
* fish reaches escape state
* player loses control

---

# 24. LINE BREAK

Điều kiện:

```text
LineTension > LineStrength
```

Trong một khoảng thời gian đủ lâu.

Không nên break ngay lập tức.

---

# 25. ROD BREAK

Rod có durability / strength.

Primitive rod:

```text
Strength = Very Low
```

Professional rod:

```text
Strength = High
```

Giant fish có thể vượt quá giới hạn rod yếu.

---

# 26. HOOK BREAK

Hook có:

```text
Strength
Durability
Sharpness
```

Hook yếu:

→ có thể biến dạng / gãy.

---

# 27. BAIT

Bait có:

```text
BaitType
Attraction
PreferredFish
Durability
Rarity
Value
```

---

# 28. BAIT TYPES

Early:

```text
Worm
Insect
Larva
```

Middle:

```text
Bread
Small Fish
Artificial Bait
```

Late:

```text
Special Bait
Rare Bait
Large Bait
Sea Bait
```

---

# 29. FISHING SPOT

Mỗi fishing spot có:

```text
Depth
WaterType
Current
Temperature
FishPopulation
FishDensity
BottomType
Vegetation
```

---

# 30. WATER CONDITIONS

Các yếu tố:

```text
Current
Depth
Clarity
Temperature
Wave
Wind
Weather
Time
```

Các yếu tố này ảnh hưởng đến fish behavior.

---

# 31. WEATHER EFFECTS

## Sunny

Normal fishing.

## Cloudy

Một số cá hoạt động nhiều hơn.

## Light Rain

Có thể tăng fish activity.

## Heavy Rain

Fishing khó hơn.

## Storm

Fishing có thể bị hạn chế hoặc nguy hiểm.

---

# 32. TIME EFFECTS

Morning:

Một số cá hoạt động mạnh.

Afternoon:

Normal.

Evening:

Một số species bắt đầu hoạt động.

Night:

Species đặc biệt xuất hiện.

---

# 33. FISHING SKILL

Player skill không nên chỉ tăng catch rate.

Skill ảnh hưởng:

```text
Cast Accuracy
Hook Timing
Fish Reading
Tension Control
Reel Efficiency
Stamina Efficiency
```

---

# 34. SKILL LEVELS

```text
BEGINNER
NOVICE
INTERMEDIATE
ADVANCED
EXPERT
MASTER
```

---

# 35. BEGINNER

Player:

* cast chưa chính xác
* dễ panic
* khó giữ tension
* chưa hiểu fish behavior

---

# 36. NOVICE

Player bắt đầu:

* hiểu bite
* kiểm soát rod
* sử dụng gear tốt hơn

---

# 37. INTERMEDIATE

Player:

* đọc được fish pattern
* biết điều chỉnh drag
* xử lý fish mạnh

---

# 38. ADVANCED

Player:

* xử lý cá lớn
* hiểu water conditions
* kiểm soát fight tốt

---

# 39. EXPERT

Player:

* dự đoán fish behavior
* tối ưu gear
* xử lý tình huống khó

---

# 40. MASTER

Player đạt khả năng:

* xử lý giant fish
* tối ưu toàn bộ fishing system
* sử dụng gear endgame

---

# 41. FISH LANDING

Khi fish exhausted:

Player bắt đầu landing.

Có thể yêu cầu:

* đưa cá về gần bờ
* dùng net
* giữ tension
* tránh vật cản

---

# 42. FISH OUTCOME

Sau landing:

```text
KEEP
SELL
GIVE
RELEASE
COOK
```

Tùy species và story state.

---

# 43. FISH QUALITY

Fish có:

```text
Species
Weight
Length
Health
Condition
Rarity
Value
```

---

# 44. FISH RECORD

Player có thể lưu:

```text
Largest Fish
Largest Species
First Catch
Rare Catch
Special Catch
Giant Fish Encounter
```

---

# 45. GIANT FISH

Giant Fish là một special entity.

Nó không được xem như fish bình thường.

Properties:

```text
UniqueID
UnknownSpecies
ExtremeStrength
ExtremeStamina
UniqueBehavior
SpecialEscapePattern
StoryLinked
```

---

# 46. FIRST GIANT FISH ENCOUNTER

Trong Act I:

Player chưa đủ khả năng.

Kết quả:

```text
Rod Break
Fish Escape
```

Đây là scripted narrative event.

---

# 47. FINAL GIANT FISH

Late game:

Player có khả năng chiến đấu.

Fight trở thành dynamic system.

Không được chỉ dùng một animation scripted.

---

# 48. FISHING FAILURE

Failure phải có nhiều dạng:

```text
Missed Bite
Failed Hook
Fish Escape
Line Break
Hook Break
Rod Break
Stamina Exhaustion
Bad Position
```

Mỗi loại failure nên cho Player hiểu:

> Mình đã sai ở đâu?

---

# 49. FISHING FEEDBACK

Player phải nhận feedback thông qua:

### Visual

* rod bending
* line movement
* float movement
* water splash
* fish shadow

### Audio

* reel sound
* line tension
* water
* rod creaking
* fish movement

### Haptic

Nếu platform hỗ trợ.

---

# 50. FISHING GOLDEN RULE

Fishing phải tạo ra cảm giác:

> "Tôi thắng vì tôi hiểu con cá và kiểm soát tình huống."

Không phải:

> "Tôi thắng vì thanh progress chạy đầy."
