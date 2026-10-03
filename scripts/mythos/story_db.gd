extends Node
## Autoload StoryDB: loads every story/*.json data file into one scene graph.
## Story content lives in data, never in code. See STORY_FORMAT.md.

var scenes := {}
var endings := {}


func _ready() -> void:
	_load_dir("res://story/")


func _load_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("StoryDB: cannot open " + path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			_load_file(path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_warning("StoryDB: bad JSON in " + path)
		return
	if path.ends_with("endings.json"):
		for e in parsed.get("endings", []):
			endings[e["id"]] = e
	else:
		for s in parsed.get("scenes", []):
			scenes[s["id"]] = s


func get_scene(scene_id: String) -> Dictionary:
	return scenes.get(scene_id, {})


func has_scene(scene_id: String) -> bool:
	return scenes.has(scene_id)


func get_ending(ending_id: String) -> Dictionary:
	return endings.get(ending_id, {})


func all_endings() -> Array:
	return endings.values()
