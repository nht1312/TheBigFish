# Inventory

# CÁ LỚN — INVENTORY SYSTEM

> Status: Canonical
> Version: 1.0

---

# 1. PURPOSE

Inventory quản lý:

* fishing gear
* bait
* fish
* materials
* consumables
* quest items
* special items

---

# 2. INVENTORY CATEGORIES

```text
FISHING_GEAR
BAIT
FISH
MATERIAL
CONSUMABLE
QUEST_ITEM
SPECIAL
```

---

# 3. ITEM DATA

Mỗi item:

```text
ItemID
Name
Category
Description
Weight
Stackable
MaxStack
Value
Durability
Quality
Rarity
Tags
```

---

# 4. FISHING GEAR

```text
Rod
Reel
Line
Hook
Float
Accessory
Net
```

---

# 5. ROD

Properties:

```text
Strength
Flexibility
Durability
Weight
MaxFishWeight
MaxTension
```

---

# 6. REEL

Properties:

```text
ReelSpeed
DragPower
DragStability
Durability
Weight
```

---

# 7. LINE

Properties:

```text
Strength
Diameter
Durability
Visibility
Length
```

---

# 8. HOOK

Properties:

```text
Strength
Sharpness
Size
Durability
FishCompatibility
```

---

# 9. FLOAT

Properties:

```text
Sensitivity
Visibility
Weight
WaterType
```

---

# 10. BAIT

Properties:

```text
Attraction
Durability
PreferredFish
Rarity
Value
```

---

# 11. MATERIALS

Examples:

```text
Bamboo
Wire
Rubber
Plastic
Metal
String
Cloth
Wood
Scrap
```

---

# 12. FISH ITEMS

Fish becomes an inventory item after landing.

Properties:

```text
Species
Weight
Length
Quality
Freshness
Value
CatchLocation
CatchTime
```

---

# 13. FISH FRESHNESS

Freshness can decrease over time.

Example:

```text
Fresh
↓
Normal
↓
Old
↓
Spoiled
```

Freshness may affect:

* sell value
* cooking value
* quest requirements

---

# 14. INVENTORY CAPACITY

Capacity may be based on:

```text
Weight
Slots
```

Recommended:

Use a hybrid model.

Gear uses slots.

Fish/materials contribute weight.

---

# 15. EQUIPPED GEAR

Player can equip:

```text
Rod
Reel
Line
Hook
Float
Bait
Accessory
```

---

# 16. QUICK ACCESS

Frequently used items should be accessible quickly:

```text
Bait
Rod
Reel
Consumables
```

---

# 17. INVENTORY ACTIONS

```text
Equip
Unequip
Use
Drop
Sell
Give
Inspect
Combine
Craft
Store
```

---

# 18. ITEM CONDITION

Gear may degrade through:

* fishing
* high tension
* weather
* accidents

---

# 19. BROKEN ITEMS

Broken gear:

```text
Cannot be used
```

until:

```text
Repair
Replace
```

---

# 20. SPECIAL ITEMS

Examples:

```text
First Fish
Broken First Rod
Giant Fish Scale
Old Hook
Mother's Item
Friend's Item
```

Special items may have narrative meaning.

---

# 21. INVENTORY PHILOSOPHY

Inventory không nên biến game thành spreadsheet.

Player phải cảm thấy:

> "Đây là những thứ mình đã nhặt, chế tạo và kiếm được."

---

# 22. FIRST INVENTORY

Beginning:

```text
Money
Basic Personal Items
No Fishing Gear
```

Sau exploration:

```text
Bamboo
String
Wire
Improvised Float
Bait
```

---

# 23. INVENTORY PROGRESSION

```text
NO GEAR
↓
IMPROVISED
↓
BASIC
↓
INTERMEDIATE
↓
ADVANCED
↓
PROFESSIONAL
↓
ENDGAME
```
