class_name MythosDice
extends RefCounted
## PEERHOOD dice: 2d6 + attribute modifier.
## Modifier mirrors the CLI's stat tiers: 7+ -> +2, 4+ -> +1, else +0.
## Bands: 10+ Perfect (full success), 7-9 Messy (success at a cost),
## 6- Break (things go wrong, the story moves forward anyway).

static func modifier(stat_value: int) -> int:
	if stat_value >= 7:
		return 2
	if stat_value >= 4:
		return 1
	return 0


static func roll_check(rng: RandomNumberGenerator, stat_value: int) -> Dictionary:
	var d1 := rng.randi_range(1, 6)
	var d2 := rng.randi_range(1, 6)
	var mod := modifier(stat_value)
	var total := d1 + d2 + mod
	var band := "break"
	if total >= 10:
		band = "perfect"
	elif total >= 7:
		band = "messy"
	return {"d1": d1, "d2": d2, "modifier": mod, "total": total, "band": band}


static func band_text(band: String) -> String:
	match band:
		"perfect":
			return "PERFECT — full success, on your terms."
		"messy":
			return "MESSY — success, but at a cost."
		_:
			return "BREAK — things go wrong. The story moves forward anyway."
