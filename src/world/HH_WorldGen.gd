class_name HH_WorldGen
extends Node3D

## TideBlock world generation for ocean + island clusters.
## This script intentionally focuses on deterministic sampling rules so
## meshing/chunk streaming can be built on top in later phases.

const TILE_WATER := "water"
const TILE_GRASS := "grass"
const TILE_DIRT := "dirt"
const TILE_STONE := "stone"

const ORE_NONE := "none"
const ORE_COPPER := "copper"
const ORE_IRON := "iron"

@export var world_seed: int = 104729
@export var noise_scale: float = 0.01
@export var island_density: float = 0.58
@export var lowland_threshold: float = 0.50
@export var highland_threshold: float = 0.68
@export var peak_threshold: float = 0.82
@export var channel_scale: float = 0.02
@export var channel_cutoff: float = 0.35

var _height_noise := FastNoiseLite.new()
var _channel_noise := FastNoiseLite.new()


func _ready() -> void:
	_configure_noise()


func _configure_noise() -> void:
	_height_noise.seed = world_seed
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_height_noise.frequency = noise_scale

	_channel_noise.seed = world_seed + 1337
	_channel_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_channel_noise.frequency = channel_scale


func sample_cell(world_x: int, world_z: int) -> Dictionary:
	var height_value := _to_01(_height_noise.get_noise_2d(world_x, world_z))
	var channel_value := _to_01(_channel_noise.get_noise_2d(world_x, world_z))
	var is_channel := channel_value < channel_cutoff
	var land_score := height_value * island_density

	if is_channel or land_score < lowland_threshold:
		return {
			"tile": TILE_WATER,
			"height": 0,
			"ore": ORE_NONE,
		}

	if land_score < highland_threshold:
		return {
			"tile": TILE_GRASS,
			"subtile": TILE_DIRT,
			"height": 1,
			"ore": ORE_NONE,
		}

	var ore := ORE_COPPER
	if land_score >= peak_threshold and _roll_peak_iron(world_x, world_z):
		ore = ORE_IRON

	return {
		"tile": TILE_STONE,
		"height": 2,
		"ore": ore,
		"is_peak": land_score >= peak_threshold,
	}


func _roll_peak_iron(world_x: int, world_z: int) -> bool:
	# Rare ore chance on peaks only.
	var hash_seed := int(abs(world_x * 73856093) + abs(world_z * 19349663) + world_seed)
	return (hash_seed % 100) < 12


func _to_01(v: float) -> float:
	return (v + 1.0) * 0.5
