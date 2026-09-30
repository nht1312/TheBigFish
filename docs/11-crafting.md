# Crafting

# CÁ LỚN — CRAFTING SYSTEM

> Status: Canonical
> Version: 1.0

---

# 1. PURPOSE

Crafting đặc biệt quan trọng ở đầu game.

Nó chứng minh:

> Player bắt đầu không có gì.

---

# 2. CRAFTING PHILOSOPHY

Crafting không phải hệ thống chế tạo hàng trăm item.

Nó tập trung vào:

* fishing gear
* bait
* repair
* special items

---

# 3. CRAFTING TIERS

```text
IMPROVISED
↓
BASIC
↓
INTERMEDIATE
↓
ADVANCED
↓
SPECIAL
```

---

# 4. IMPROVISED CRAFTING

Các item đầu tiên:

```text
Bamboo Rod
Improvised Line
Wire Hook
Shoe Float
```

---

# 5. BAMBOO ROD

Materials:

```text
Bamboo
String
Rubber
```

Result:

```text
Improvised Rod
```

Properties:

```text
Low Strength
Low Durability
Low Control
```

---

# 6. WIRE HOOK

Materials:

```text
Scrap Wire
```

Player phải:

* tìm wire
* tạo hình
* làm đầu hook

Properties:

```text
Low Strength
Low Sharpness
```

---

# 7. SHOE FLOAT

Materials:

```text
Old Shoe / Rubber
```

Mục đích:

> Tạo phao đơn giản.

---

# 8. BAIT CRAFTING

Early game:

Không cần crafting phức tạp.

Player chủ yếu:

```text
Find Worm
Find Insect
Collect Larva
```

---

# 9. BASIC CRAFTING

Sau khi có knowledge:

```text
Basic Rod
Basic Float
Basic Hook
Basic Line
```

---

# 10. INTERMEDIATE

Player có thể kết hợp:

```text
Rod Components
Better Line
Better Hook
Better Float
```

---

# 11. ADVANCED

Crafting không nhất thiết tạo ra toàn bộ advanced gear.

Một số gear phải mua.

Crafting chủ yếu:

* repair
* customization
* accessories
* specialized rigs

---

# 12. RECIPE DATA

Mỗi recipe:

```text
RecipeID
Name
Inputs
Output
RequiredSkill
RequiredTool
CraftTime
Difficulty
```

---

# 13. CRAFTING EXAMPLE

```text
RECIPE_001

Name:
Improvised Fishing Rod

Inputs:
Bamboo x1
String x1
Rubber x1

Output:
Improvised Rod x1

RequiredSkill:
None
```

---

# 14. REPAIR

Gear damaged có thể repair.

Repair cost:

```text
Materials
Money
Time
```

---

# 15. REPAIR LIMIT

Một số item không thể repair vô hạn.

Ví dụ:

```text
Durability
↓
Repair
↓
Maximum Condition ↓
```

Điều này tạo lý do để upgrade.

---

# 16. CRAFTING FAILURE

Early primitive crafting có thể có:

* low durability
* poor quality
* unexpected behavior

Không nên biến thành random frustration quá mức.

---

# 17. CRAFTING DISCOVERY

Một số recipe được học thông qua:

```text
NPC
Exploration
Story
Experiment
Observation
```

---

# 18. NPC KNOWLEDGE

Shop Owner có thể dạy:

* rig
* hook
* line
* repair

Old Fisherman có thể dạy:

* bait
* water reading
* fish behavior

Friend có thể chia sẻ:

* unconventional techniques

---

# 19. CRAFTING MATERIAL SOURCES

```text
Environment
Scrap Yard
Fishing
NPC
Market
Quest
```

---

# 20. CRAFTING RULE

Crafting phải phục vụ câu chuyện.

Đặc biệt:

> Chiếc cần đầu tiên phải là thứ Player tự tay tạo ra.

Nó là một vật phẩm có giá trị cảm xúc.

---

# 21. FIRST ROD MEMORY

Sau khi rod bị Giant Fish phá hủy:

Broken First Rod có thể được lưu như:

```text
SPECIAL_ITEM_FIRST_ROD
```

Không nhất thiết có gameplay value.

Nó tồn tại như một vật kỷ niệm.

---

# 22. ENDGAME CRAFTING

Cuối game có thể craft:

* special rig
* giant fish hook
* reinforced line setup
* specialized bait

Nhưng không craft trực tiếp "victory".

---

# 23. CRAFTING PHILOSOPHY

Crafting phải khiến Player cảm thấy:

> "Mình đã tự tạo ra thứ giúp mình tiến lên."

Không phải:

> "Mình mở menu và click recipe."
