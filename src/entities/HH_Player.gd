class_name HH_Player
extends CharacterBody3D

const HH_Chunk = preload("res://src/world/HH_Chunk.gd")

@export var move_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.0025
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var interact_distance: float = 7.0

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/InteractRay

var _pitch: float = 0.0
var _selected_block: int = HH_Chunk.VOXEL_GRASS


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	raycast.target_position = Vector3(0, 0, -interact_distance)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = _pitch
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_break_target_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_place_target_block()

	if event.is_action_pressed("ui_cancel"):
		var current_mode := Input.get_mouse_mode()
		if current_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_velocity

	var input_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var basis := global_transform.basis
	var move_dir := (basis.x * input_vec.x + -basis.z * input_vec.y).normalized()

	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed = sprint_speed

	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	move_and_slide()


func _break_target_block() -> void:
	if not raycast.is_colliding():
		return
	var collider := raycast.get_collider()
	if collider == null:
		return

	var point := raycast.get_collision_point() - raycast.get_collision_normal() * 0.01
	if collider.has_method("break_block"):
		collider.break_block(point)
		return

	var world := get_tree().get_first_node_in_group("hh_world")
	if world and world.has_method("break_block"):
		world.break_block(point)


func _place_target_block() -> void:
	if not raycast.is_colliding():
		return
	var collider := raycast.get_collider()
	var point := raycast.get_collision_point() + raycast.get_collision_normal() * 0.51

	if collider and collider.has_method("place_block"):
		collider.place_block(point, _selected_block)
		return

	var world := get_tree().get_first_node_in_group("hh_world")
	if world and world.has_method("place_block"):
		world.place_block(point, _selected_block)
