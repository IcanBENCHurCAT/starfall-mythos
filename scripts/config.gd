class_name RetroConfig
extends RefCounted
## ALL tuning constants live here. Change numbers here, never in logic code.
## (RefCounted + class_name so any script can read RetroConfig.WALK_SPEED.)

# --- Player ---
const WALK_SPEED: float = 80.0
const WALK_FPS: float = 6.0

# --- View ---
const VIEWPORT := Vector2i(320, 180)
const TILE_SIZE := Vector2i(16, 16)

# --- Player sprite sheet layout (assets/sprites/player.png) ---
# Rows: down=0, left=1, right=2, up=3. Cols: idle=0, walk=1. Cells 32x32.
const PLAYER_SHEET := "res://assets/sprites/player.png"
const PLAYER_CELL := Vector2i(32, 32)
const PLAYER_FRAMES_PER_ROW := 2
const PLAYER_ROWS := {"down": 0, "left": 1, "right": 2, "up": 3}

# --- Camera ---
const CAM_SMOOTH_SPEED: float = 8.0
const SHAKE_DECAY: float = 3.0
