class_name PixelCamera
extends Camera2D
## Smooth-follow camera with deadzone-free lerp and a tiny shake API.
## Set follow_path in the editor (or leave empty for a fixed camera).

@export var follow_path: NodePath

var _shake: float = 0.0


func _ready() -> void:
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = RetroConfig.CAM_SMOOTH_SPEED


func _process(delta: float) -> void:
	var target := get_node_or_null(follow_path) as Node2D
	if target:
		global_position = target.global_position
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * RetroConfig.SHAKE_DECAY)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 4.0
	elif offset != Vector2.ZERO:
		offset = offset.lerp(Vector2.ZERO, 0.2)


func add_shake(amount: float = 1.0) -> void:
	_shake = minf(1.0, _shake + amount)
