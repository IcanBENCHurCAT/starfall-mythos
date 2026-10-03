extends PanelContainer
## StatusHUD overlay: the four canon stats (0-10 bars), inventory,
## and Codex/journal entries. Toggled from SceneView; display only.

@onready var _stat_rows := {
	"TRUST": $Margin/Rows/TrustRow/Bar,
	"DIVERGENCE": $Margin/Rows/DivergenceRow/Bar,
	"KNOWLEDGE": $Margin/Rows/KnowledgeRow/Bar,
	"RISK": $Margin/Rows/RiskRow/Bar,
}
@onready var _stat_values := {
	"TRUST": $Margin/Rows/TrustRow/Value,
	"DIVERGENCE": $Margin/Rows/DivergenceRow/Value,
	"KNOWLEDGE": $Margin/Rows/KnowledgeRow/Value,
	"RISK": $Margin/Rows/RiskRow/Value,
}
@onready var _inventory: ItemList = $Margin/Rows/InventoryList
@onready var _journal: ItemList = $Margin/Rows/JournalList
@onready var _close_btn: Button = $Margin/Rows/CloseButton
@onready var _name_label: Label = $Margin/Rows/NameLabel


func _ready() -> void:
	MythosState.stats_changed.connect(refresh)
	_close_btn.pressed.connect(queue_free)
	refresh()


func refresh() -> void:
	_name_label.text = "%s — %s" % [MythosState.player_name, MythosState.role.capitalize()]
	for stat in MythosState.STATS:
		var v: int = MythosState.get_stat(stat)
		(_stat_rows[stat] as ProgressBar).value = v
		(_stat_values[stat] as Label).text = str(v)
	_inventory.clear()
	for item in MythosState.inventory:
		_inventory.add_item(item.replace("_", " ").capitalize())
	_journal.clear()
	for entry in MythosState.codex:
		_journal.add_item(entry)
