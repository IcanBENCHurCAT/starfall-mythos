extends Control
## Character select: name entry + the three canon classes.
## Picks apply class stat bonuses, then the class opener scene plays.

@onready var _name_edit: LineEdit = $VBox/NameEdit
@onready var _role_buttons := {
	"researcher": $VBox/Roles/ResearcherButton,
	"investigator": $VBox/Roles/InvestigatorButton,
	"operator": $VBox/Roles/OperatorButton,
}


func _ready() -> void:
	for role in _role_buttons:
		var btn: Button = _role_buttons[role]
		btn.pressed.connect(_on_role.bind(role))


func _on_role(role: String) -> void:
	MythosState.new_run(_name_edit.text, role)
	Game.change_scene("res://scenes/scene_view.tscn")
	SceneDirector.go_to(role + "_1")
