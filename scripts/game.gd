extends Node
## Global autoload: input map, pause, scene switching.
## One place for cross-cutting game systems. Keep game logic OUT of here.

signal paused_changed(is_paused: bool)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input()


func _ensure_input() -> void:
	_bind("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_bind("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_bind("move_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP])
	_bind("move_down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN])
	_bind("pause_game", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])


func _bind(action: StringName, keys: Array, joy_buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
	for btn in joy_buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = btn
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause()


func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	paused_changed.emit(get_tree().paused)


func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
