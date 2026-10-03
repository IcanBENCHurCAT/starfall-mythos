extends Control
## Title screen: Begin (new run), Continue (divergence anchor resume),
## dice seed input, and a jump to the endings gallery.

@onready var _begin_btn: Button = $VBox/BeginButton
@onready var _continue_btn: Button = $VBox/ContinueButton
@onready var _anchor_picker: OptionButton = $VBox/AnchorPicker
@onready var _seed_edit: LineEdit = $VBox/SeedRow/SeedEdit
@onready var _gallery_btn: Button = $VBox/GalleryButton


func _ready() -> void:
	_begin_btn.pressed.connect(_on_begin)
	_continue_btn.pressed.connect(_on_continue)
	_gallery_btn.pressed.connect(func() -> void: Game.change_scene("res://scenes/ending_gallery.tscn"))
	_seed_edit.text = str(MythosState.dice_seed)
	_refresh_anchors()


func _refresh_anchors() -> void:
	_anchor_picker.clear()
	var slots := Anchors.list_anchors()
	for slot in slots:
		_anchor_picker.add_item(slot)
	var has_any := not slots.is_empty()
	_anchor_picker.visible = has_any
	_continue_btn.disabled = not has_any


func _apply_seed() -> void:
	var s := _seed_edit.text.strip_edges()
	if s.is_valid_int():
		MythosState.set_dice_seed(int(s))


func _on_begin() -> void:
	_apply_seed()
	MythosState.reset()
	Game.change_scene("res://scenes/character_select.tscn")


func _on_continue() -> void:
	if _anchor_picker.item_count == 0:
		return
	_apply_seed()
	var slot := _anchor_picker.get_item_text(_anchor_picker.selected)
	if Anchors.load_anchor(slot):
		Game.change_scene("res://scenes/scene_view.tscn")
