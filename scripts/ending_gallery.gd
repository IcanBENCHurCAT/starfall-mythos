extends Control
## EndingGallery: the 10 canon endings, locked/unlocked.
## Unlocks persist inside divergence anchors (endings_found).

@onready var _list: ItemList = $Margin/Main/EndingList
@onready var _detail: RichTextLabel = $Margin/Main/DetailText
@onready var _back_btn: Button = $Margin/Main/BackButton


func _ready() -> void:
	_back_btn.pressed.connect(func() -> void: Game.change_scene("res://scenes/title.tscn"))
	_detail.bbcode_enabled = true
	_detail.add_theme_font_size_override("normal_font_size", 8)
	_list.item_selected.connect(_show_detail)
	refresh()


func refresh() -> void:
	_list.clear()
	for ending in StoryDB.all_endings():
		var e: Dictionary = ending
		var found: bool = MythosState.endings_found.has(str(e["id"]))
		var label := ("◆ " if found else "◇ ") + str(e.get("title", e["id"]))
		_list.add_item(label)
		_list.set_item_metadata(_list.item_count - 1, e["id"])


func _show_detail(index: int) -> void:
	var ending_id := str(_list.get_item_metadata(index))
	if not MythosState.endings_found.has(ending_id):
		_detail.text = "[i]This ending is still unwritten. Play to discover it.[/i]"
		return
	var ending := StoryDB.get_ending(ending_id)
	_detail.text = "[b]%s[/b]\n\n%s" % [ending.get("title", ""), ending.get("text", "")]
