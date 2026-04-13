class_name HH_Chunk
extends StaticBody3D

const SIZE_X := 16
const SIZE_Y := 32
const SIZE_Z := 16

const VOXEL_AIR := 0
const VOXEL_WATER := 1
const VOXEL_GRASS := 2
const VOXEL_DIRT := 3
const VOXEL_STONE := 4
const VOXEL_COPPER := 5
const VOXEL_IRON := 6

const FACE_NORMALS := [
	Vector3.RIGHT,
	Vector3.LEFT,
	Vector3.UP,
	Vector3.DOWN,
	Vector3.BACK,
	Vector3.FORWARD,
]

const FACE_VERTICES := [
	# RIGHT (+X)
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0)],
	# LEFT (-X)
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	# UP (+Y)
	[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],
	# DOWN (-Y)
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)],
	# BACK (+Z)
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	# FORWARD (-Z)
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)],
]

# Atlas layout: 3 cols x 2 rows
# [WATER, GRASS, DIRT]
# [STONE, COPPER, IRON]
const ATLAS_COLS := 3
const ATLAS_ROWS := 2

const VOXEL_ATLAS_POS := {
	1: Vector2i(0, 0),
	2: Vector2i(1, 0),
	3: Vector2i(2, 0),
	4: Vector2i(0, 1),
	5: Vector2i(1, 1),
	6: Vector2i(2, 1),
}

var chunk_coord: Vector2i
var _voxels: PackedInt32Array = PackedInt32Array()
var _mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D
var _material: StandardMaterial3D


func _ready() -> void:
	_ensure_nodes()
	_build_material()


func _build_material() -> void:
	var atlas := load("res://assets/textures/atlas.png") as Texture2D
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_material.albedo_texture = atlas
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST


func setup(coord: Vector2i, voxel_data: PackedInt32Array) -> void:
	_ensure_nodes()
	chunk_coord = coord
	_voxels = voxel_data
	rebuild_mesh()


func rebuild_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(SIZE_X):
		for y in range(SIZE_Y):
			for z in range(SIZE_Z):
				var voxel := get_voxel(x, y, z)
				if voxel == VOXEL_AIR:
					continue
				for face_idx in range(FACE_NORMALS.size()):
					var normal: Vector3 = FACE_NORMALS[face_idx]
					var nx := x + int(normal.x)
					var ny := y + int(normal.y)
					var nz := z + int(normal.z)
					if _is_solid(get_voxel(nx, ny, nz)):
						continue
					_append_face(st, Vector3(x, y, z), face_idx, voxel)

	st.generate_normals()
	var built_mesh := st.commit()
	_mesh_instance.mesh = built_mesh
	_mesh_instance.material_override = _material

	if built_mesh:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(built_mesh.get_faces())
		_collision_shape.shape = shape


func get_voxel(x: int, y: int, z: int) -> int:
	if x < 0 or y < 0 or z < 0 or x >= SIZE_X or y >= SIZE_Y or z >= SIZE_Z:
		return VOXEL_AIR
	return _voxels[_index(x, y, z)]


func set_voxel(x: int, y: int, z: int, voxel: int) -> bool:
	if x < 0 or y < 0 or z < 0 or x >= SIZE_X or y >= SIZE_Y or z >= SIZE_Z:
		return false
	_voxels[_index(x, y, z)] = voxel
	rebuild_mesh()
	return true


func _append_face(st: SurfaceTool, base_pos: Vector3, face_idx: int, voxel: int) -> void:
	var verts: Array = FACE_VERTICES[face_idx]
	var normal: Vector3 = FACE_NORMALS[face_idx]

	var atlas_pos: Vector2i = VOXEL_ATLAS_POS.get(voxel, Vector2i(0, 0))
	var u0 := float(atlas_pos.x) / ATLAS_COLS
	var v0 := float(atlas_pos.y) / ATLAS_ROWS
	var u1 := u0 + 1.0 / ATLAS_COLS
	var v1 := v0 + 1.0 / ATLAS_ROWS

	var uv := [Vector2(u0, v1), Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1)]
	var indices := [0, 1, 2, 0, 2, 3]

	for i in indices:
		st.set_normal(normal)
		st.set_uv(uv[i])
		st.add_vertex(base_pos + verts[i])


func _is_solid(voxel: int) -> bool:
	return voxel != VOXEL_AIR and voxel != VOXEL_WATER


func _index(x: int, y: int, z: int) -> int:
	return x + SIZE_X * (z + SIZE_Z * y)


func _ensure_nodes() -> void:
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance)
	if _collision_shape == null:
		_collision_shape = CollisionShape3D.new()
		add_child(_collision_shape)
