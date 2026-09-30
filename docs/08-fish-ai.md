# Fish AI

# CÁ LỚN — FISH AI

> Status: Canonical
> Version: 1.0

---

# 1. PURPOSE

Fish AI quyết định cách cá:

* di chuyển
* tiếp cận bait
* phản ứng khi mắc hook
* chạy trốn
* mệt
* hồi phục
* tương tác với môi trường

---

# 2. FISH AI PRINCIPLE

Không phải tất cả cá đều phản ứng giống nhau.

Mỗi species phải có:

```text
Identity
Behavior
Preferred Habitat
Preferred Bait
Escape Pattern
Strength
Stamina
```

---

# 3. AI STATES

```text
IDLE
SEARCHING
PATROLLING
APPROACHING
INSPECTING
BITING
HOOKED
FIGHTING
ESCAPING
RESTING
EXHAUSTED
LANDED
```

---

# 4. IDLE

Fish đứng / di chuyển chậm trong khu vực.

---

# 5. SEARCHING

Fish tìm food.

Các yếu tố:

* smell
* movement
* bait
* water condition

---

# 6. APPROACHING

Fish tiến về bait.

Có thể:

* tiến thẳng
* vòng quanh
* tiếp cận từ dưới
* tiếp cận từ bên cạnh

---

# 7. INSPECTING

Một số cá không cắn ngay.

Fish có thể kiểm tra:

```text
BaitType
Movement
WaterCondition
PreviousDisturbance
```

---

# 8. BITING

Fish quyết định bite.

Probability phụ thuộc:

```text
Species
Hunger
Bait
Time
Weather
Water
PlayerNoise
```

---

# 9. HOOKED

Fish phát hiện resistance.

Ngay lập tức chuyển sang phản ứng.

---

# 10. FISH PERSONALITY TYPES

## AGGRESSIVE

* phản ứng mạnh
* chạy nhanh
* đổi hướng nhiều

---

## CAUTIOUS

* tiếp cận chậm
* dễ bỏ bait
* yêu cầu hook timing tốt

---

## PASSIVE

* di chuyển chậm
* fight nhẹ

---

## ERRATIC

* chuyển hướng bất ngờ
* khó dự đoán

---

## DEEP DIVER

* lao xuống sâu
* tạo tension lớn

---

## SURFACE RUNNER

* chạy ngang mặt nước
* tạo splash

---

## BOTTOM FEEDER

* giữ gần đáy
* kéo xuống

---

# 11. FISH STATS

```text
SpeciesID
Weight
Length
Strength
Speed
Acceleration
Stamina
Aggression
Caution
TurnRate
DepthPreference
TemperaturePreference
WaterPreference
BaitPreference
EscapePattern
```

---

# 12. FISH STRENGTH

Strength ảnh hưởng:

* maximum pulling force
* tension generation
* resistance

---

# 13. FISH SPEED

Speed ảnh hưởng:

* escape
* direction change
* run

---

# 14. ACCELERATION

Một số cá không nhanh liên tục.

Chúng có burst.

Ví dụ:

```text
Slow
↓
Detect resistance
↓
Burst
↓
Slow
```

---

# 15. STAMINA

Fish stamina giảm trong fight.

Nhưng fish có thể:

```text
REST
↓
RECOVER
↓
BURST AGAIN
```

Điều này ngăn việc fight trở thành một đường thẳng.

---

# 16. AGGRESSION

Aggression quyết định:

* frequency of escape
* burst
* direction changes
* fight intensity

---

# 17. CAUTION

Caution ảnh hưởng:

* bait inspection
* bite probability
* hook success

---

# 18. TURN RATE

Fish có turn rate khác nhau.

Fish lớn thường:

* khó đổi hướng
* nhưng lực lớn

Fish nhỏ:

* đổi hướng nhanh
* lực nhỏ

---

# 19. DEPTH PREFERENCE

Ví dụ:

```text
SURFACE
SHALLOW
MID
DEEP
BOTTOM
```

---

# 20. WATER PREFERENCE

Fish có thể thích:

```text
Drain
Pond
Lake
Stream
River
Reservoir
Sea
```

---

# 21. BAIT PREFERENCE

Ví dụ:

```text
Worm
Insect
Bread
Small Fish
Artificial
Special
```

---

# 22. ESCAPE PATTERNS

Các pattern:

```text
STRAIGHT_RUN
ZIGZAG
DEEP_DIVE
SURFACE_RUN
CIRCLE
OBSTACLE_RUN
BURST_SEQUENCE
```

---

# 23. OBSTACLE AWARENESS

Fish có thể sử dụng môi trường.

Ví dụ:

* lao vào rong
* chạy về đá
* chui dưới vật cản
* chạy về vùng nước sâu

Player phải ngăn fish.

---

# 24. ENVIRONMENT INTERACTION

Fish có thể:

* làm nước bắn
* làm rong chuyển động
* làm bùn nổi
* tạo splash
* làm float rung

---

# 25. FISH LEARNING

Không cần machine learning.

Có thể dùng state + behavior rules.

Ví dụ:

```text
If Hooked
AND Player pulls hard
→ Fish performs burst
```

---

# 26. FISH DIFFICULTY

Difficulty không chỉ dựa trên weight.

Một fish 3kg có thể khó hơn fish 5kg nếu:

* aggressive
* erratic
* fast
* cautious

---

# 27. SPECIES ARCHETYPES

Mỗi species phải có archetype.

Ví dụ:

```text
SMALL_FRESHWATER
AGGRESSIVE_RIVER
CAUTIOUS_LAKE
DEEP_RESERVOIR
SEA_PREDATOR
GIANT_FISH
```

---

# 28. GIANT FISH AI

Giant Fish có nhiều phase:

```text
PHASE_1
Observe

PHASE_2
Initial Run

PHASE_3
Deep Dive

PHASE_4
Recovery

PHASE_5
Final Burst
```

---

# 29. GIANT FISH MEMORY

Trong final encounter, Giant Fish có thể phản ứng khác với first encounter.

Ví dụ:

Player đã từng hook nó.

Final encounter có thể:

* mạnh hơn
* thận trọng hơn
* có pattern riêng

Tuy nhiên đây là narrative assumption và có thể điều chỉnh.

---

# 30. AI DESIGN RULE

Fish phải tạo ra:

> unpredictability within understandable rules.

Player có thể không biết chính xác fish sẽ làm gì.

Nhưng sau khi chơi đủ lâu:

> Player có thể học cách đọc nó.
