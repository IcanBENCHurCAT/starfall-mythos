extends Node
## Autoload SceneDirector: drives the story graph from StoryDB data.
## SceneView listens to scene_changed and renders; choices come back here.
## Choice routing:
##   "next"            -> go to a scene id
##   "field"           -> return to the explorable crash field (main.tscn)
##   "ending"          -> unlock + show an ending
##   "check"           -> PEERHOOD dice check on a stat; routes to the
##                        perfect/messy/break scene ids in the choice

signal scene_changed(scene: Dictionary)
signal dice_rolled(result: Dictionary, choice: Dictionary)

var current_id := ""
var last_scene := {}


func go_to(scene_id: String) -> void:
	if not StoryDB.has_scene(scene_id):
		push_warning("SceneDirector: unknown scene " + scene_id)
		return
	current_id = scene_id
	last_scene = StoryDB.get_scene(scene_id)
	scene_changed.emit(last_scene)


func choose(choice: Dictionary) -> void:
	_apply_choice_effects(choice)
	if choice.has("check"):
		_run_check(choice)
		return
	_route(choice)


func _apply_choice_effects(choice: Dictionary) -> void:
	MythosState.apply_effects(choice.get("effects", {}))
	if choice.has("gives"):
		var gives = choice["gives"]
		var items: Array = gives if gives is Array else [gives]
		for item in items:
			MythosState.add_item(str(item))
	if choice.has("codex"):
		MythosState.add_codex(str(choice["codex"]))


func _run_check(choice: Dictionary) -> void:
	var check: Dictionary = choice["check"]
	var stat: String = str(check.get("stat", "KNOWLEDGE"))
	var result := MythosDice.roll_check(MythosState.get_rng(), MythosState.get_stat(stat))
	dice_rolled.emit(result, choice)
	# The check's own effects land on the band's target scene via its
	# "band_effects", so consequences stay in data, not code.
	var target: String = str(check.get(result["band"], check.get("next", "")))
	var band_fx: Dictionary = check.get("band_effects", {}).get(result["band"], {})
	MythosState.apply_effects(band_fx)
	if target == "":
		return
	_route({"next": target})


func _route(choice: Dictionary) -> void:
	if choice.has("ending"):
		_show_ending(str(choice["ending"]))
		return
	var next_id := str(choice.get("next", ""))
	if next_id == "field":
		Game.change_scene("res://scenes/main.tscn")
		return
	if next_id != "":
		go_to(next_id)


func _show_ending(ending_id: String) -> void:
	MythosState.unlock_ending(ending_id)
	var ending := StoryDB.get_ending(ending_id)
	if ending.is_empty():
		push_warning("SceneDirector: unknown ending " + ending_id)
		return
	current_id = "ending:" + ending_id
	scene_changed.emit({"id": "ending:" + ending_id, "title": ending.get("title", ""),
		"text": ending.get("text", ""), "choices": ending.get("choices", [
			{"text": "Return to title", "to_title": true},
			{"text": "View endings gallery", "to_gallery": true},
		])})


func quick_save(slot: String) -> bool:
	return Anchors.save_anchor(slot)
