class_name FishingSkill
extends RefCounted
## Fishing skill levels (docs/07 §33–40). XP lives in GameState stat "FishingSkill".

const LEVELS: Array[String] = ["BEGINNER", "NOVICE", "INTERMEDIATE", "ADVANCED", "EXPERT", "MASTER"]
const THRESHOLDS: Array[float] = [0.0, 10.0, 30.0, 70.0, 150.0, 300.0]


static func level_index(xp: float) -> int:
	var index := 0
	for i in THRESHOLDS.size():
		if xp >= THRESHOLDS[i]:
			index = i
	return index


static func level_name(xp: float) -> String:
	return LEVELS[level_index(xp)]
