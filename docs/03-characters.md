# Characters

# CÁ LỚN — CHARACTERS

> Status: Canonical
> Version: 1.0
> Scope: Main Characters, Supporting Characters, Character Relationships

---

# 1. CHARACTER DESIGN PRINCIPLES

Nhân vật trong CÁ LỚN phải:

1. Có cuộc sống riêng.
2. Có mục tiêu riêng.
3. Có tính cách riêng.
4. Không tồn tại chỉ để giao quest.
5. Có phản ứng khác nhau tùy hành động của Player.
6. Có ký ức về những sự kiện quan trọng.
7. Có thể thay đổi theo thời gian.
8. Không phải tất cả NPC đều thích Player.
9. Không phải tất cả NPC đều hiểu đam mê câu cá.
10. Không giải thích quá nhiều bằng dialogue.

---

# 2. CHARACTER CATEGORIES

```text
MAIN CHARACTERS
    ↓
CORE SUPPORTING CHARACTERS
    ↓
SECONDARY NPCS
    ↓
AMBIENT NPCS
```

---

# 3. CHARACTER ID SYSTEM

Mỗi nhân vật có ID duy nhất.

Format:

```text
CHAR_[CATEGORY]_[NAME]
```

Ví dụ:

```text
CHAR_MAIN_PLAYER
CHAR_MAIN_MOTHER
CHAR_MAIN_OLD_FISHERMAN
CHAR_MAIN_FISHING_FRIEND
CHAR_SUPPORT_SHOP_OWNER
CHAR_SUPPORT_FISH_VENDOR
```

---

# 4. PLAYER

## ID

`CHAR_MAIN_PLAYER`

## Name

Không bắt buộc.

Người chơi tự quyết định nếu hệ thống cho phép.

## Age

TBD.

Recommended range:

18–25.

## Gender

Player selectable hoặc TBD.

## Occupation

Beginning:

Không có nghề nghiệp rõ ràng.

Progression:

Có thể kiếm tiền bằng nhiều công việc nhỏ.

## Personality

Không được hard-code hoàn toàn.

Tính cách được thể hiện thông qua lựa chọn của Player.

---

# 5. PLAYER'S INITIAL STATE

Player bắt đầu với:

```text
Money = Very Low
FishingSkill = Beginner
FishingGear = None
FishingKnowledge = Low
MapAccess = Home Area
FishingReputation = 0
```

---

# 6. PLAYER MOTIVATION

## Initial Motivation

Tò mò.

## Short-term Motivation

Bắt được cá.

## Mid-term Motivation

Có gear tốt.

## Long-term Motivation

Chinh phục con cá khổng lồ.

## Emotional Motivation

Chứng minh với bản thân rằng mình có thể làm được.

---

# 7. PLAYER CHARACTER ARC

```text
CURIOUS
↓
BEGINNER
↓
FRUSTRATED
↓
DETERMINED
↓
SKILLED
↓
PASSIONATE
↓
OBSESSED / COMMITTED
↓
RESPONSIBLE
↓
MATURE
```

---

# 8. MOTHER

## ID

`CHAR_MAIN_MOTHER`

## Role

Nhân vật gia đình quan trọng nhất.

## Narrative Function

Mother đại diện cho:

- gia đình
- trách nhiệm
- tình yêu
- sự lo lắng
- giới hạn
- sự trưởng thành

---

# 9. MOTHER PERSONALITY

Mother:

- thực tế
- quan tâm
- đôi khi nóng tính
- lo lắng
- không dễ dàng thể hiện cảm xúc
- có thể phản đối việc Player câu cá quá nhiều

Mother không phải antagonist.

---

# 10. MOTHER MOTIVATION

Mother muốn:

- Player an toàn.
- Player có tương lai.
- Player không bỏ bê cuộc sống.
- Player biết chịu trách nhiệm.

---

# 11. MOTHER'S CONFLICT

Mother không nhất thiết phản đối câu cá.

Điều Mother phản đối là:

> Player để câu cá chi phối toàn bộ cuộc sống.

---

# 12. MOTHER RELATIONSHIP ARC

## Stage 1

Mother không hiểu.

## Stage 2

Mother lo lắng.

## Stage 3

Mother bắt đầu hiểu.

## Stage 4

Mother chấp nhận.

## Stage 5

Mother hỗ trợ.

## Stage 6

Mother tham gia vào giấc mơ.

---

# 13. OLD FISHERMAN

## ID

`CHAR_MAIN_OLD_FISHERMAN`

## Narrative Role

Người khởi đầu toàn bộ câu chuyện.

---

# 14. OLD FISHERMAN PERSONALITY

- bình tĩnh
- ít nói
- có kinh nghiệm
- thích câu cá
- không khoe khoang
- quan sát nhiều hơn nói

---

# 15. OLD FISHERMAN FUNCTION

Opening:

Player nhìn thấy ông câu được cá.

Later:

Player có thể gặp lại ông.

Ông có thể đưa ra những lời khuyên nhỏ.

Ông không phải mentor chính.

Ông là:

> Người mở cánh cửa đầu tiên.

---

# 16. FISHING SHOP OWNER

## ID

`CHAR_SUPPORT_SHOP_OWNER`

## Role

Người cung cấp gear.

---

# 17. PERSONALITY

- thực tế
- hiểu đồ câu
- thích nói về gear
- có chút hài hước
- nhận ra Player từ từ tiến bộ

---

# 18. RELATIONSHIP WITH PLAYER

Ban đầu:

> Khách hàng bình thường.

Sau này:

> Khách quen.

Late game:

> Người hiểu hành trình của Player.

---

# 19. FISH MARKET WOMAN

## ID

`CHAR_SUPPORT_FISH_VENDOR`

## Role

Người mua cá.

---

# 20. PERSONALITY

- nhanh nhẹn
- thực tế
- biết giá cá
- nói chuyện thẳng
- có khả năng đùa với Player

---

# 21. NARRATIVE FUNCTION

Fish Vendor tạo ra mối liên hệ:

```text
CATCH
↓
SELL
↓
MONEY
↓
UPGRADE
↓
FISH
```

Nhưng cô cũng có thể trở thành NPC quan trọng ngoài economy.

---

# 22. FISHING FRIEND

## ID

`CHAR_MAIN_FISHING_FRIEND`

## Role

Đại diện cho:

- friendship
- peer influence
- shared passion
- risk
- conflict

---

# 23. FRIEND PERSONALITY

- năng động
- thích khám phá
- mê câu cá
- đôi khi liều lĩnh
- dễ rủ Player làm những chuyện không suy nghĩ kỹ

---

# 24. FRIEND ARC

```text
STRANGER
↓
ACQUAINTANCE
↓
FISHING PARTNER
↓
FRIEND
↓
CONFLICT
↓
RECONCILIATION / DISTANCE
```

---

# 25. THE ILLEGAL POND EVENT

Friend rủ Player đi câu.

Player không biết địa điểm là khu vực không được phép câu.

Hai người bị phát hiện.

Player mất gear.

Hậu quả:

- mất tiền
- mất dụng cụ
- relationship thay đổi
- Player học được rằng mọi lựa chọn đều có hậu quả

---

# 26. SCRAP COLLECTOR

## ID

`CHAR_SUPPORT_SCRAP_COLLECTOR`

Role:

- mua ve chai
- cung cấp thông tin
- có thể giúp Player hiểu giá trị của vật liệu

---

# 27. CHILD NPC

## ID

`CHAR_SIDE_CHILD`

Có thể xuất hiện trong các random events.

Ví dụ:

- nhìn Player câu cá
- hỏi về cá
- đánh rơi đồ
- cần giúp đỡ

---

# 28. NEIGHBOR

## ID

`CHAR_SIDE_NEIGHBOR`

Có thể cung cấp:

- gossip
- thông tin
- random events
- family context

---

# 29. OTHER FISHERMEN

Có nhiều loại:

```text
CASUAL_FISHERMAN
PRO_FISHERMAN
OLD_FISHERMAN
COMPETITIVE_FISHERMAN
BEGINNER_FISHERMAN
```

Mỗi nhóm có:

- kỹ năng
- gear
- tính cách
- fishing style

---

# 30. SECURITY / AUTHORITY NPC

Xuất hiện ở các khu vực có hạn chế.

Vai trò:

- enforce rules
- tạo consequence
- cảnh báo Player

Không được sử dụng như villain.

---

# 31. CHARACTER RELATIONSHIP TYPES

```text
Family
Friendship
Business
Respect
Trust
Conflict
Familiarity
```

---

# 32. CHARACTER MEMORY

NPC có thể nhớ:

```text
Player gave fish
Player helped NPC
Player caused trouble
Player borrowed item
Player broke promise
Player visited frequently
Player ignored NPC
```

---

# 33. CHARACTER STATE

Mỗi NPC có:

```text
Mood
Relationship
Location
Schedule
Memory
CurrentGoal
Availability
StoryState
```

---

# 34. CHARACTER DEVELOPMENT RULE

Character development phải xảy ra thông qua:

```text
ACTION
↓
EXPERIENCE
↓
REACTION
↓
MEMORY
↓
RELATIONSHIP CHANGE
↓
FUTURE BEHAVIOR
```

Không nên dùng:

```text
QUEST COMPLETE
→ CHARACTER +10 LOVE
```

như một hệ thống RPG đơn giản.

---

# 35. CORE CHARACTER RELATIONSHIP MAP

```text
                  OLD FISHERMAN
                       |
                       ↓
PLAYER ←────────── FISHING FRIEND
  |
  |
  ├──── MOTHER
  |
  ├──── SHOP OWNER
  |
  └──── FISH VENDOR
```

---

# 36. CHARACTER DESIGN RULE

Mỗi nhân vật quan trọng phải trả lời được:

1. Họ muốn gì?
2. Họ sợ gì?
3. Họ đang cố giải quyết vấn đề gì?
4. Họ nghĩ gì về Player?
5. Điều gì khiến họ thay đổi?
6. Họ sẽ làm gì nếu Player không xuất hiện?
