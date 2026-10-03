extends Area2D
## SignalFragment: the crash-field story trigger in the explorable world.
## Walking into the glow drops the player into the next story beat.
## Which beat fires is data-driven: story_beat_for(role) lives in StoryDB's
## "field_beats" table so writers control the world/story handoff in JSON.

@export var beat_table_id := "field_beats"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var beats: Dictionary = StoryDB.get_scene(beat_table_id)
	var next_id := str(beats.get(MythosState.role, beats.get("default", "branch_node")))
	Game.change_scene("res://scenes/scene_view.tscn")
	SceneDirector.go_to(next_id)
