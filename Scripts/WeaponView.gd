## WeaponView.gd — Apparence de l'arme en vue FPS
## À attacher sur un Node3D enfant de Camera3D
## L'arme apparaît en bas à droite de l'écran

extends Node3D

# ── Position de repos et de frappe ────────────────────────────
const REST_POS   := Vector3(0.35, -0.35, -0.6)
const SWING_POS  := Vector3(0.35, -0.1,  -0.5)
const SWING_ROT  := Vector3(-40.0, 0.0, 0.0)
const SWAY_AMOUNT := 0.015
const LERP_SPEED  := 12.0

var _swing_progress : float = 0.0
var _is_swinging    : bool  = false
var _rest_rot       := Vector3.ZERO

func _ready() -> void:
	position = REST_POS
	_build_bat()

func _process(delta: float) -> void:
	_update_sway(delta)
	_update_swing(delta)

# ── Sway : l'arme bouge légèrement avec la souris ─────────────
func _update_sway(delta: float) -> void:
	if _is_swinging:
		return
	var mouse_delta := Input.get_last_mouse_velocity() * SWAY_AMOUNT * delta
	var target_rot  := Vector3(-mouse_delta.y, mouse_delta.x, 0.0)
	rotation_degrees = rotation_degrees.lerp(target_rot, LERP_SPEED * delta)

# ── Animation de frappe ───────────────────────────────────────
func _update_swing(delta: float) -> void:
	if not _is_swinging:
		position = position.lerp(REST_POS, LERP_SPEED * delta)
		return

	_swing_progress = min(_swing_progress + delta * 8.0, 1.0)

	if _swing_progress < 0.5:
		var t := _swing_progress * 2.0
		position       = REST_POS.lerp(SWING_POS, t)
		rotation_degrees = _rest_rot.lerp(SWING_ROT, t)
	else:
		var t := (_swing_progress - 0.5) * 2.0
		position       = SWING_POS.lerp(REST_POS, t)
		rotation_degrees = SWING_ROT.lerp(_rest_rot, t)

	if _swing_progress >= 1.0:
		_is_swinging     = false
		_swing_progress  = 0.0
		rotation_degrees = _rest_rot

func play_swing() -> void:
	if not _is_swinging:
		_is_swinging    = true
		_swing_progress = 0.0

# ── Construction de la batte ──────────────────────────────────
func _build_bat() -> void:
	# Manche (cylindre fin)
	var handle     := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius    = 0.025
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height        = 0.55
	handle.mesh     = handle_mesh
	handle.position = Vector3(0, 0, 0)
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.28, 0.12)
	handle.material_override = handle_mat
	add_child(handle)

	# Corps de la batte (cylindre plus épais)
	var barrel      := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius    = 0.055
	barrel_mesh.bottom_radius = 0.035
	barrel_mesh.height        = 0.45
	barrel.mesh     = barrel_mesh
	barrel.position = Vector3(0, 0.48, 0)
	var barrel_mat := StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.55, 0.35, 0.15)
	barrel.material_override = barrel_mat
	add_child(barrel)

	# Bout arrondi
	var tip      := MeshInstance3D.new()
	var tip_mesh := SphereMesh.new()
	tip_mesh.radius = 0.058
	tip_mesh.height = 0.116
	tip.mesh     = tip_mesh
	tip.position = Vector3(0, 0.72, 0)
	tip.material_override = barrel_mat
	add_child(tip)

	# Orienter la batte horizontalement (dans la main)
	rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_rest_rot = rotation_degrees
