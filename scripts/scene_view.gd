extends Control
## SceneView: renders the current story scene (BBCode text + choice buttons),
## shows PEERHOOD dice results, and hosts the StatusHUD overlay + quick save.

@onready var _title_label: Label = $Margin/VBox/TitleLabel
@onready var _text: RichTextLabel = $Margin/VBox/StoryText
@onready var _choices: VBoxContainer = $Margin/VBox/ChoiceBox
@onready var _dice_label: Label = $Margin/VBox/DiceLabel
@onready var _status_btn: Button = $Margin/VBox/TopBar/StatusButton
@onready var _save_btn: Button = $Margin/VBox/TopBar/SaveButton
@onready var _hud_layer: CanvasLayer = $HUDLayer

var _status_hud: Control = null


func _ready() -> void:
	SceneDirector.scene_changed.connect(_render_scene)
	SceneDirector.dice_rolled.connect(_show_dice)
	_status_btn.pressed.connect(_toggle_hud)
	_save_btn.pressed.connect(_quick_save)
	_text.bbcode_enabled = true
	_text.add_theme_font_size_override("normal_font_size", 8)
	_text.add_theme_font_size_override("bold_font_size", 8)
	# If we arrived without a scene (fresh boot into this scene), start one.
	if SceneDirector.current_id == "":
		SceneDirector.go_to("title_screen")
	else:
		_render_scene(SceneDirector.last_scene)


func _render_scene(scene: Dictionary) -> void:
	_title_label.text = str(scene.get("title", ""))
	var body := str(scene.get("text", ""))
	body = body.replace("{name}", MythosState.player_name)
	_text.text = body
	_dice_label.text = ""
	for child in _choices.get_children():
		child.queue_free()
	for choice in scene.get("choices", []):
		var c: Dictionary = choice
		var btn := Button.new()
		btn.text = str(c.get("text", "..."))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(SceneDirector.choose.bind(c))
		_choices.add_child(btn)
		# Special routing buttons handled by the director via flags.
		if c.get("to_title", false):
			btn.pressed.connect(func() -> void: Game.change_scene("res://scenes/title.tscn"))
		if c.get("to_gallery", false):
			btn.pressed.connect(func() -> void: Game.change_scene("res://scenes/ending_gallery.tscn"))


func _show_dice(result: Dictionary, _choice: Dictionary) -> void:
	_dice_label.text = "[%d, %d] %+d = %d — %s" % [
		result["d1"], result["d2"], result["modifier"], result["total"],
		MythosDice.band_text(str(result["band"]))]
	await get_tree().create_timer(2.5).timeout
	_dice_label.text = ""


func _toggle_hud() -> void:
	if _status_hud != null:
		_status_hud.queue_free()
		_status_hud = null
		return
	var hud_scene: PackedScene = load("res://scenes/status_hud.tscn")
	_status_hud = hud_scene.instantiate()
	_hud_layer.add_child(_status_hud)


func _quick_save() -> void:
	var slot := "quicksave"
	if SceneDirector.quick_save(slot):
		_dice_label.text = "Divergence anchor saved."
		await get_tree().create_timer(1.5).timeout
		_dice_label.text = ""
