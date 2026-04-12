class_name HH_World
extends Node3D

const HH_Chunk = preload("res://src/world/HH_Chunk.gd")

@export var world_seed: int = 424242
@export var chunk_radius: int = 3
@export var sea_level: int = 10
@export var max_height: int = HH_Chunk.SIZE_Y - 1
@export var base_noise_frequency: float = 0.008
@export var mountain_noise_frequency: float = 0.03

var _height_noise := FastNoiseLite.new()
var _island_mask_noise := FastNoiseLite.new()
var _mountain_noise := FastNoiseLite.new()

var _chunks: Dictionary = {}


func _ready() -> void:
	_configure_noises()
	_generate_initial_world()


func _configure_noises() -> void:
	_height_noise.seed = world_seed
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = base_noise_frequency

	_island_mask_noise.seed = world_seed + 77
	_island_mask_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_island_mask_noise.frequency = base_noise_frequency * 0.4

	_mountain_noise.seed = world_seed + 911
	_mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_mountain_noise.frequency = mountain_noise_frequency


func _generate_initial_world() -> void:
	for cx in range(-chunk_radius, chunk_radius + 1):
		for cz in range(-chunk_radius, chunk_radius + 1):
			_spawn_chunk(Vector2i(cx, cz))


func _spawn_chunk(coord: Vector2i) -> void:
	if _chunks.has(coord):
		return

	var voxel_data := PackedInt32Array()
	voxel_data.resize(HH_Chunk.SIZE_X * HH_Chunk.SIZE_Y * HH_Chunk.SIZE_Z)

	for lx in HH_Chunk.SIZE_X:
		for lz in HH_Chunk.SIZE_Z:
			var world_x := coord.x * HH_Chunk.SIZE_X + lx
			var world_z := coord.y * HH_Chunk.SIZE_Z + lz
			var surface_y := _sample_surface_height(world_x, world_z)
			var biome := _sample_biome(surface_y)
			for y in HH_Chunk.SIZE_Y:
				var voxel := HH_Chunk.VOXEL_AIR
				if y <= surface_y:
					voxel = _sample_block(y, surface_y, biome, world_x, world_z)
				elif y <= sea_level:
					voxel = HH_Chunk.VOXEL_WATER
				voxel_data[_flat_idx(lx, y, lz)] = voxel

	var chunk := HH_Chunk.new()
	chunk.name = "Chunk_%s_%s" % [coord.x, coord.y]
	chunk.position = Vector3(coord.x * HH_Chunk.SIZE_X, 0, coord.y * HH_Chunk.SIZE_Z)
	add_child(chunk)
	chunk.setup(coord, voxel_data)
	_chunks[coord] = chunk


func break_block(world_position: Vector3) -> void:
	var block := Vector3i(floori(world_position.x), floori(world_position.y), floori(world_position.z))
	_set_block(block, HH_Chunk.VOXEL_AIR)


func place_block(world_position: Vector3, voxel: int = HH_Chunk.VOXEL_GRASS) -> void:
	var block := Vector3i(floori(world_position.x), floori(world_position.y), floori(world_position.z))
	_set_block(block, voxel)


func _set_block(block: Vector3i, voxel: int) -> void:
	var chunk_coord := Vector2i(floori(float(block.x) / HH_Chunk.SIZE_X), floori(float(block.z) / HH_Chunk.SIZE_Z))
	if not _chunks.has(chunk_coord):
		return

	var local_x := posmod(block.x, HH_Chunk.SIZE_X)
	var local_z := posmod(block.z, HH_Chunk.SIZE_Z)
	var chunk: HH_Chunk = _chunks[chunk_coord]
	chunk.set_voxel(local_x, block.y, local_z, voxel)


func _sample_surface_height(world_x: int, world_z: int) -> int:
	var base_h := (_height_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5
	var island_mask := clamp((_island_mask_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5, 0.0, 1.0)
	var island_profile := pow(island_mask, 2.4)
	var mountain := max(_mountain_noise.get_noise_2d(world_x, world_z), 0.0)

	var island_height := lerpf(float(sea_level) - 3.0, float(max_height) - 2.0, base_h * island_profile)
	var with_mountains := island_height + mountain * 8.0
	return clampi(roundi(with_mountains), 1, max_height)


func _sample_biome(surface_y: int) -> String:
	if surface_y >= sea_level + 9:
		return "highland"
	return "lowland"


func _sample_block(y: int, surface_y: int, biome: String, world_x: int, world_z: int) -> int:
	if biome == "lowland":
		if y == surface_y:
			return HH_Chunk.VOXEL_GRASS
		if y >= surface_y - 2:
			return HH_Chunk.VOXEL_DIRT
		return HH_Chunk.VOXEL_STONE

	if y == surface_y:
		# Copper veins on highland stone surfaces.
		if _is_copper_vein(world_x, world_z):
			return HH_Chunk.VOXEL_COPPER
		# Iron veins on high mountain peaks.
		if surface_y >= sea_level + 15 and _is_iron_vein(world_x, world_z):
			return HH_Chunk.VOXEL_IRON
	return HH_Chunk.VOXEL_STONE


func _is_copper_vein(world_x: int, world_z: int) -> bool:
	var ore := _hash01(world_x, world_z, 19)
	return ore < 0.20


func _is_iron_vein(world_x: int, world_z: int) -> bool:
	var ore := _hash01(world_x, world_z, 97)
	return ore < 0.08


func _hash01(x: int, z: int, salt: int) -> float:
	var hashed := int((x * 734287 + z * 912271 + world_seed * salt) & 0x7fffffff)
	return float(hashed % 1000) / 1000.0


func _flat_idx(x: int, y: int, z: int) -> int:
	return x + HH_Chunk.SIZE_X * (z + HH_Chunk.SIZE_Z * y)
