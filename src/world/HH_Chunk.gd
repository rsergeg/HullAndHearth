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
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)],
	[Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],
]

var chunk_coord: Vector2i
var _voxels: PackedInt32Array = PackedInt32Array()
var _mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D


func _ready() -> void:
	_ensure_nodes()


func setup(coord: Vector2i, voxel_data: PackedInt32Array) -> void:
	_ensure_nodes()
	chunk_coord = coord
	_voxels = voxel_data
	rebuild_mesh()


func rebuild_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in SIZE_X:
		for y in SIZE_Y:
			for z in SIZE_Z:
				var voxel := get_voxel(x, y, z)
				if voxel == VOXEL_AIR:
					continue

				var color := _voxel_color(voxel)
				for face_idx in FACE_NORMALS.size():
					var normal: Vector3 = FACE_NORMALS[face_idx]
					var nx := x + int(normal.x)
					var ny := y + int(normal.y)
					var nz := z + int(normal.z)
					if _is_solid(get_voxel(nx, ny, nz)):
						continue
					_append_face(st, Vector3(x, y, z), face_idx, color)

	st.generate_normals()
	var built_mesh := st.commit()
	_mesh_instance.mesh = built_mesh

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


func _append_face(st: SurfaceTool, base_pos: Vector3, face_idx: int, color: Color) -> void:
	var verts: Array = FACE_VERTICES[face_idx]
	var normal: Vector3 = FACE_NORMALS[face_idx]
	var uv := [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
	var indices := [0, 1, 2, 0, 2, 3]

	for i in indices:
		st.set_normal(normal)
		st.set_uv(uv[i])
		st.set_color(color)
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


func _voxel_color(voxel: int) -> Color:
	match voxel:
		VOXEL_WATER:
			return Color(0.05, 0.22, 0.7, 0.85)
		VOXEL_GRASS:
			return Color(0.23, 0.62, 0.24)
		VOXEL_DIRT:
			return Color(0.38, 0.24, 0.12)
		VOXEL_STONE:
			return Color(0.45, 0.46, 0.5)
		VOXEL_COPPER:
			return Color(0.72, 0.43, 0.22)
		VOXEL_IRON:
			return Color(0.7, 0.72, 0.75)
		_:
			return Color.WHITE
