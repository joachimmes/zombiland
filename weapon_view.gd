## WeaponView.gd — Apparence de l'arme en vue FPS
## Enfant de Camera3D

extends Node3D

const REST_POS    := Vector3(0.35, -0.35, -0.6)
const SWING_POS   := Vector3(0.35, -0.1,  -0.5)
const SWING_ROT_X := -40.0
const LERP_SPEED  := 12.0

var _swing_progress : float = 0.0
var _is_swinging    : bool  = false
var _base_rot       := Vector3(90.0, 0.0, 0.0)

func _ready() -> void:
	position         = REST_POS
	rotation_degrees = _base_rot
	_build_bat()

func _process(delta: float) -> void:
	if _is_swinging:
		_update_swing(delta)
	else:
		position = position.lerp(REST_POS, LERP_SPEED * delta)

func _update_swing(delta: float) -> void:
	_swing_progress = min(_swing_progress + delta * 8.0, 1.0)

	if _swing_progress < 0.5:
		var t := _swing_progress * 2.0
		position = REST_POS.lerp(SWING_POS, t)
		rotation_degrees.x = lerp(_base_rot.x, _base_rot.x + SWING_ROT_X, t)
	else:
		var t := (_swing_progress - 0.5) * 2.0
		position = SWING_POS.lerp(REST_POS, t)
		rotation_degrees.x = lerp(_base_rot.x + SWING_ROT_X, _base_rot.x, t)

	if _swing_progress >= 1.0:
		_is_swinging    = false
		_swing_progress = 0.0

func play_swing() -> void:
	if not _is_swinging:
		_is_swinging    = true
		_swing_progress = 0.0

func _build_bat() -> void:
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.28, 0.12)

	var barrel_mat := StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.55, 0.35, 0.15)

	# Manche
	var handle      := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius    = 0.025
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height        = 0.55
	handle.mesh              = handle_mesh
	handle.material_override = handle_mat
	add_child(handle)

	# Corps
	var barrel      := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius    = 0.055
	barrel_mesh.bottom_radius = 0.035
	barrel_mesh.height        = 0.45
	barrel.mesh              = barrel_mesh
	barrel.position          = Vector3(0, 0.48, 0)
	barrel.material_override = barrel_mat
	add_child(barrel)

	# Bout
	var tip      := MeshInstance3D.new()
	var tip_mesh := SphereMesh.new()
	tip_mesh.radius       = 0.058
	tip_mesh.height       = 0.116
	tip.mesh              = tip_mesh
	tip.position          = Vector3(0, 0.72, 0)
	tip.material_override = barrel_mat
	add_child(tip)
