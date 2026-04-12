class_name HH_Player
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var spawn_point: Vector3 = Vector3.ZERO

var _spawn_set := false


func _ready() -> void:
	global_position = spawn_point


func _physics_process(_delta: float) -> void:
	# Movement/combat/survival loops will be expanded in later phases.
	pass


func set_bed_spawn(new_spawn: Vector3) -> void:
	spawn_point = new_spawn
	_spawn_set = true


func can_skip_night() -> bool:
	return _spawn_set
