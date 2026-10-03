extends Node2D
## World root. Builds the demo TileSet at runtime from assets/tiles/ground.png
## so the project runs with zero editor setup. Replace with a real Tiled import
## or a hand-built TileSet resource when you graduate to real maps.

const TILESET_PATH := "res://assets/tiles/ground.png"
const MAP_W := 30
const MAP_H := 20


func _ready() -> void:
	var texture: Texture2D = load(TILESET_PATH)
	if texture == null:
		push_warning("world.gd: tileset not found at " + TILESET_PATH)
		return

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = RetroConfig.TILE_SIZE
	atlas.create_tile(Vector2i(0, 0))
	atlas.create_tile(Vector2i(1, 0))

	var tileset := TileSet.new()
	tileset.tile_size = RetroConfig.TILE_SIZE
	tileset.add_source(atlas, 0)

	var layer := TileMapLayer.new()
	layer.tile_set = tileset
	add_child(layer)

	# Checkerboard floor. Swap this loop for real map data later.
	for y in MAP_H:
		for x in MAP_W:
			var tile := Vector2i((x + y) % 2, 0)
			layer.set_cell(Vector2i(x - MAP_W / 2, y - MAP_H / 2), 0, tile)
