# Family System

# CÁ LỚN — FAMILY SYSTEM

> Status: Canonical
> Version: 1.0
> Scope: Family Relationship, Mother Arc, Household Dynamics

---

# 1. PURPOSE

Family System quản lý mối quan hệ giữa Player và gia đình.

Trong phiên bản hiện tại, Mother là family character quan trọng nhất.

---

# 2. DESIGN PRINCIPLE

Family không được biến thành:

```text
GOOD FAMILY SCORE
BAD FAMILY SCORE
```

Mối quan hệ phải có nhiều chiều.

---

# 3. CORE FAMILY VARIABLES

```text id="5r0x3u"
Trust
Concern
Understanding
Respect
Conflict
Support
```

---

# 4. TRUST

Trust trả lời:

> "Mother có tin Player sẽ chịu trách nhiệm không?"

Trust tăng khi Player:

* giữ lời
* giúp gia đình
* hoàn thành trách nhiệm
* kiếm tiền
* chăm sóc gia đình

Trust giảm khi Player:

* nói dối
* bỏ bê
* gây rắc rối
* thất hứa

---

# 5. CONCERN

Concern trả lời:

> "Mother lo lắng cho Player đến mức nào?"

Concern có thể tăng khi:

* Player đi câu quá lâu
* Player đi quá xa
* Player gặp nguy hiểm
* Player bị thương
* Player thường xuyên về muộn

Concern cao không có nghĩa Mother ghét Player.

Ngược lại:

> Concern có thể xuất phát từ tình thương.

---

# 6. UNDERSTANDING

Understanding trả lời:

> "Mother hiểu tại sao Player thích câu cá đến mức nào?"

Understanding tăng khi:

* Player chia sẻ
* Mother chứng kiến thành quả
* Player vẫn giữ trách nhiệm
* Mother nhìn thấy ý nghĩa của fishing đối với Player

---

# 7. RESPECT

Respect phản ánh:

> Mother nhìn nhận sự trưởng thành của Player.

Respect tăng khi Player:

* tự kiếm tiền
* tự chịu hậu quả
* giúp người khác
* biết chịu trách nhiệm

---

# 8. CONFLICT

Conflict đại diện cho những bất đồng chưa được giải quyết.

Ví dụ:

```text id="qf9wpp"
Player đi câu quá nhiều
→ Conflict ↑

Player cãi lại Mother
→ Conflict ↑

Player chủ động nói chuyện
→ Conflict ↓
```

---

# 9. SUPPORT

Support phản ánh mức độ Mother sẵn sàng hỗ trợ Player.

Support không chỉ là tiền.

Có thể là:

* lời khuyên
* thức ăn
* chăm sóc
* giúp đỡ
* xuất hiện trong những thời điểm quan trọng

---

# 10. FAMILY STATE

Có thể có các trạng thái:

```text id="1v2q5x"
STABLE
WORRIED
TENSE
CONFLICTED
UNDERSTANDING
SUPPORTIVE
```

---

# 11. FAMILY INTERACTION

Các interaction:

```text id="0e6xv1"
Talk
Eat Together
Help
Give Money
Give Fish
Ask Permission
Apologize
Explain
Ignore
```

---

# 12. FISHING CONFLICT

Nếu Player câu quá nhiều:

```text id="s3r4pi"
Fishing Time ↑
+
Family Responsibility ↓
→
Concern ↑
Conflict ↑
```

---

# 13. POSITIVE FAMILY ACTION

Ví dụ:

Player kiếm được tiền.

Thay vì dùng hết để mua gear:

Player đưa một phần tiền cho gia đình.

Kết quả:

```text id="s7x4ar"
Trust ↑
Respect ↑
Concern ↓
```

---

# 14. GIVING FISH

Player có thể đem cá về nhà.

Mother có thể:

* nấu ăn
* hỏi cá ở đâu
* bình luận về kích thước

Đây là cách fishing kết nối với family.

---

# 15. MOTHER'S FORBIDDEN DAY

Trong một số state:

Mother yêu cầu Player không đi câu một ngày.

Player có thể:

```text id="2d8l9v"
Obey
Argue
Sneak Out
```

Không option nào được gắn nhãn Good/Bad.

---

# 16. CONSEQUENCES

### Obey

Possible:

```text id="q6z3go"
Conflict ↓
Trust ↑
Fishing Progress delayed
```

### Argue

Possible:

```text id="s8w8i3"
Conflict ↑
Understanding may increase if Player explains
```

### Sneak Out

Possible:

```text id="u8l3qw"
Conflict ↑
Trust ↓
Potential Event
```

---

# 17. FAMILY MEMORY

Mother nhớ những sự kiện lớn:

```text id="6c2v9g"
First Fish
Broken Rod
First Real Gear
Illegal Pond
Major Accident
Major Gift
Important Promise
Major Achievement
```

---

# 18. MOTHER'S VIEW OF FISHING

Mother's attitude có thể chuyển:

```text id="e1n3k5"
"Đừng đi câu nữa."
↓
"Đi đâu thì nhớ về sớm."
↓
"Câu được gì rồi?"
↓
"Bao giờ đi câu?"
↓
"Để mẹ phụ."
```

Đây là emotional progression.

---

# 19. FINAL SUPPORT

Mother tham gia final fight không chỉ vì gameplay.

Nó là payoff của toàn bộ family arc.

Meaning:

> Mother finally enters Player's dream.

---

# 20. FINAL CHOICE CONDITIONS

Ending conditions có thể sử dụng:

```text id="6e6q8b"
MotherTrust
MotherUnderstanding
MotherSupport
MajorFamilyChoices
FriendRelationship
```

---

# 21. FAMILY SYSTEM RULE

Family relationship không phải hệ thống để Player "farm điểm".

Nó phải được xây bằng:

```text id="k2c2ch"
Time
Actions
Conversations
Promises
Failures
Sacrifices
Shared Experiences
```

---

# 22. FAMILY DESIGN GOAL

Đến final:

Player không nên nghĩ:

> "Mình cần 80 Family Points để unlock ending."

Player nên nghĩ:

> "Mẹ đã đồng hành với mình suốt hành trình này."

Đây là mục tiêu thực sự của hệ thống.
