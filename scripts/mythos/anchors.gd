extends Node
## Autoload Anchors: divergence-anchor save/load.
## The CLI stores anchors under ~/.mythos/anchors/; here they live in
## user://anchors/ with the same slot-naming idea: name + timestamp.

const DIR := "user://anchors/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func _path(slot: String) -> String:
	return DIR + slot + ".json"


func save_anchor(slot: String) -> bool:
	var clean := slot.strip_edges().to_lower().replace(" ", "_")
	if clean == "":
		return false
	var stamped := "%s_%d" % [clean, int(Time.get_unix_time_from_system())]
	var file := FileAccess.open(_path(stamped), FileAccess.WRITE)
	if file == null:
		return false
	var data := MythosState.to_dict()
	data["scene_id"] = SceneDirector.current_id
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_anchor(slot: String) -> bool:
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return false
	MythosState.from_dict(parsed)
	var scene_id := str(parsed.get("scene_id", "title_screen"))
	if scene_id.begins_with("ending:") or not StoryDB.has_scene(scene_id):
		scene_id = "title_screen"
	SceneDirector.go_to(scene_id)
	return true


func list_anchors() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			out.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	out.reverse()  # newest first: names end with unix timestamps
	return out


func delete_anchor(slot: String) -> bool:
	return DirAccess.remove_absolute(_path(slot)) == OK
