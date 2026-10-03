class_name TopDownPlayer
extends CharacterBody2D
## 8-directional top-down movement with 4-directional atlas animation.
## Animation is explicit frame math, not AnimatedSprite2D, so the sheet
## layout stays documented in RetroConfig and swappable in one place.

var walk_speed: float = RetroConfig.WALK_SPEED

var _facing: Vector2 = Vector2.DOWN
var _frame: int = 0
var _anim_time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = load(RetroConfig.PLAYER_SHEET)
	_sprite.region_enabled = true
	_update_frame()


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.0:
		_facing = dir.normalized()
		velocity = dir.normalized() * walk_speed
		_anim_time += delta
		if _anim_time >= 1.0 / RetroConfig.WALK_FPS:
			_anim_time = 0.0
			_frame = (_frame + 1) % RetroConfig.PLAYER_FRAMES_PER_ROW
			_update_frame()
	else:
		velocity = Vector2.ZERO
		if _frame != 0:  # snap back to idle frame when stopping
			_frame = 0
			_update_frame()
	move_and_slide()


func _dir_name(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _update_frame() -> void:
	var row: int = RetroConfig.PLAYER_ROWS[_dir_name(_facing)]
	var cell := RetroConfig.PLAYER_CELL
	_sprite.region_rect = Rect2(_frame * cell.x, row * cell.y, cell.x, cell.y)
