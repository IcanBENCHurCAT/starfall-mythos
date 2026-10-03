extends CanvasLayer
## Minimal HUD: title chip + pause indicator. Screen-space, always on top.

var _label: Label
var _pause_label: Label


func _ready() -> void:
	_label = Label.new()
	_label.text = "RETRO ENGINE - arrows/WASD to move, ESC to pause"
	_label.position = Vector2(8, 8)
	_label.add_theme_font_size_override("font_size", 8)
	add_child(_label)

	_pause_label = Label.new()
	_pause_label.text = "PAUSED"
	_pause_label.position = Vector2(140, 80)
	_pause_label.add_theme_font_size_override("font_size", 16)
	_pause_label.visible = false
	add_child(_pause_label)

	Game.paused_changed.connect(_on_paused_changed)


func _on_paused_changed(is_paused: bool) -> void:
	_pause_label.visible = is_paused
