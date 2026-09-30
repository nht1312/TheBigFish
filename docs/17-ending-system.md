# Ending System

# CÁ LỚN — ENDING SYSTEM

> Status: Canonical
> Version: 1.0

---

# 1. PURPOSE

Ending là kết quả của toàn bộ hành trình.

Ending không phải:

```text
GOOD
BAD
TRUE
FALSE
```

---

# 2. ENDING PHILOSOPHY

Final choice phải có trọng lượng vì Player đã trải qua:

* fishing
* family
* friendship
* failure
* success
* sacrifice
* growth

---

# 3. FINAL SCENE

Sequence:

```text id="z1v7hq"
Return to Old Drain
↓
Giant Fish Appears
↓
Hook
↓
Fight
↓
Player Exhausted
↓
Mother Arrives
↓
Mother Helps
↓
Mother Falls
↓
Final Choice
```

---

# 4. ENDING VARIABLES

Các biến quan trọng:

```text id="k3m6vv"
MotherTrust
MotherUnderstanding
MotherSupport
FriendRelationship
FishingPassion
FishingSkill
Generosity
MajorChoices
MajorEvents
FinalChoice
```

---

# 5. ENDING A — LET GO

## ID

`ENDING_LET_GO`

Player buông cần.

Ưu tiên:

```text id="7v5g5h"
Mother
```

Con cá thoát.

---

# 6. LET GO — NARRATIVE RESULT

Player không bắt được Giant Fish.

Nhưng Player đã:

* trưởng thành
* hiểu giới hạn
* hiểu giá trị của gia đình

---

# 7. LET GO — EPILOGUE

Có thể cho thấy:

Player vẫn câu cá.

Nhưng fishing không còn chỉ là:

> "Phải bắt con cá đó."

Nó trở thành:

> "Mình thích câu cá."

---

# 8. ENDING B — KEEP PULLING

## ID

`ENDING_KEEP_PULLING`

Player tiếp tục chiến đấu.

Con cá có thể được bắt.

Mother chịu hậu quả tùy implementation và final scene design.

Không cần nói rõ ngay lập tức mọi hậu quả.

---

# 9. KEEP PULLING — NARRATIVE PURPOSE

Ending này cho thấy:

> Ước mơ có thể đạt được, nhưng mọi lựa chọn đều có cái giá của nó.

Không gọi đây là:

```text
Bad Ending
```

---

# 10. ENDING C — TOGETHER

## ID

`ENDING_TOGETHER`

Ending này yêu cầu một số điều kiện narrative.

Ví dụ:

```text id="7nq2zs"
FriendRelationship >= Threshold
MotherSupport >= Threshold
Important Friendship Events Completed
```

---

# 11. TOGETHER

Friend xuất hiện.

Giúp giữ cần.

Player có thể quay sang cứu Mother.

Con cá vẫn còn cơ hội được bắt.

---

# 12. IMPORTANT NOTE

Ending Together không nên tạo cảm giác:

> "Bạn farm đủ relationship nên game thưởng cho bạn ending tốt."

Nó phải có setup narrative trước đó.

Friend phải từng được Player giúp.

Friend phải có lý do để xuất hiện.

---

# 13. ENDING CONDITIONS

Không chỉ dùng numerical threshold.

Có thể dùng:

```text id="w9l4km"
Major Event Completed
AND
Relationship State
AND
Previous Choice
AND
Story State
```

---

# 14. ENDING DECISION

Final choice có thể:

```text id="h1j5k6"
LET_GO
KEEP_PULLING
```

TOGETHER có thể được mở ra trong quá trình final scene nếu điều kiện narrative được đáp ứng.

---

# 15. EPILOGUE STRUCTURE

Mỗi ending có:

```text id="q5j7r8"
Immediate Outcome
↓
Short Time Skip
↓
Character Reactions
↓
Player Reflection
↓
Final Image
```

---

# 16. FINAL IMAGE

Có thể mirror opening.

Opening:

> Player nhìn một người câu cá.

Ending:

> Player ngồi câu cá.

Vai trò đã thay đổi.

---

# 17. ENDING MIRROR

```text id="w7c1r4"
BEGINNING
Player watches Fisherman
        ↓
"I want to fish."

ENDING
Player becomes Fisherman
        ↓
"What matters to me now?"
```

---

# 18. NO MORAL LABELS

Không hiển thị:

```text id="z5k8r1"
GOOD ENDING
BAD ENDING
BEST ENDING
WORST ENDING
```

Chỉ hiển thị tên narrative nếu cần.

---

# 19. ENDING SAVE DATA

Lưu:

```text id="y6n9p2"
EndingID
FinalChoice
FinalFishCaught
MotherOutcome
FriendOutcome
FinalRelationships
MajorChoices
```

---

# 20. REPLAY

Sau khi hoàn thành:

Player có thể:

* New Game
* Replay
* Load earlier save

Nếu có New Game+ thì là TBD.

---

# 21. ENDING DESIGN GOAL

Sau ending, Player nên có cảm giác:

> "Mình đã đưa ra lựa chọn của mình."

Không phải:

> "Game bảo mình lựa chọn đúng hay sai."
