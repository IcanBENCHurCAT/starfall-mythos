extends Node
## Autoload MythosState: the canon Player model from the CLI game.
## Four stats (TRUST/DIVERGENCE/KNOWLEDGE/RISK, 0-10), inventory items,
## faction standings, CompanionBond, Codex/journal entries, dice seed + RNG,
## and the set of discovered endings. Survives scene changes; reset per run.

signal stats_changed

const STATS: Array[String] = ["TRUST", "DIVERGENCE", "KNOWLEDGE", "RISK"]
const MIN_STAT := 0
const MAX_STAT := 10

const CLASS_BONUS := {
	"researcher": {"KNOWLEDGE": 2, "TRUST": -1, "item": "field_spectrometer"},
	"investigator": {"RISK": 2, "KNOWLEDGE": 1, "item": "encrypted_drive"},
	"operator": {"KNOWLEDGE": 1, "RISK": -1, "item": "relay_override_key"},
}

var player_name := "Drift"
var role := ""
var stats := {"TRUST": 5, "DIVERGENCE": 0, "KNOWLEDGE": 5, "RISK": 5}
var inventory: Array[String] = []
var factions := {}
var bond := 0
var codex: Array[String] = []
var dice_seed := 12345
var endings_found: Array[String] = []
var _rng: RandomNumberGenerator = null


func reset() -> void:
	player_name = "Drift"
	role = ""
	stats = {"TRUST": 5, "DIVERGENCE": 0, "KNOWLEDGE": 5, "RISK": 5}
	inventory.clear()
	factions.clear()
	bond = 0
	codex.clear()
	dice_seed = 12345
	endings_found.clear()
	_rng = null
	stats_changed.emit()


func new_run(p_name: String, p_role: String) -> void:
	reset()
	player_name = p_name if p_name.strip_edges() != "" else "Drift"
	role = p_role
	var bonus: Dictionary = CLASS_BONUS.get(p_role, {})
	for stat in STATS:
		if bonus.has(stat):
			adjust_stat(stat, int(bonus[stat]))
	if bonus.has("item"):
		add_item(str(bonus["item"]))
	stats_changed.emit()


func adjust_stat(stat: String, delta: int) -> void:
	if not stats.has(stat):
		return
	stats[stat] = clampi(int(stats[stat]) + delta, MIN_STAT, MAX_STAT)
	stats_changed.emit()


func get_stat(stat: String) -> int:
	return int(stats.get(stat, 0))


func add_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
		stats_changed.emit()


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func adjust_faction(faction: String, delta: int) -> void:
	factions[faction] = int(factions.get(faction, 0)) + delta
	stats_changed.emit()


func adjust_bond(delta: int) -> void:
	bond += delta
	stats_changed.emit()


func add_codex(entry: String) -> void:
	if not codex.has(entry):
		codex.append(entry)
		stats_changed.emit()


func unlock_ending(ending_id: String) -> void:
	if not endings_found.has(ending_id):
		endings_found.append(ending_id)


func set_dice_seed(seed: int) -> void:
	dice_seed = seed
	_rng = null


func get_rng() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = dice_seed
	return _rng


func apply_effects(effects: Dictionary) -> void:
	for stat in STATS:
		if effects.has(stat):
			adjust_stat(stat, int(effects[stat]))
	if effects.has("bond"):
		adjust_bond(int(effects["bond"]))
	for faction in effects.get("factions", {}):
		adjust_faction(str(faction), int(effects["factions"][faction]))


func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"role": role,
		"stats": stats.duplicate(),
		"inventory": inventory.duplicate(),
		"factions": factions.duplicate(),
		"bond": bond,
		"codex": codex.duplicate(),
		"dice_seed": dice_seed,
		"endings_found": endings_found.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	reset()
	player_name = str(d.get("player_name", "Drift"))
	role = str(d.get("role", ""))
	var s: Dictionary = d.get("stats", {})
	for stat in STATS:
		stats[stat] = clampi(int(s.get(stat, 5)), MIN_STAT, MAX_STAT)
	inventory.assign(d.get("inventory", []))
	factions = d.get("factions", {}).duplicate()
	bond = int(d.get("bond", 0))
	codex.assign(d.get("codex", []))
	dice_seed = int(d.get("dice_seed", 12345))
	endings_found.assign(d.get("endings_found", []))
	stats_changed.emit()
