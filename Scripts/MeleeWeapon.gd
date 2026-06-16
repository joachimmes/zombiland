## MeleeWeapon.gd — Attaque au corps à corps
## À attacher sur un Node3D enfant de Head (caméra)
## Hiérarchie :
##   Head
##   └── MeleeWeapon (ce script)

extends Node3D

const ATTACK_DAMAGE  := 25.0
const ATTACK_RANGE   := 2.2
const ATTACK_COOLDOWN := 0.6

var cooldown_timer : float = 0.0
var is_attacking   : bool  = false

@onready var camera : Camera3D = get_parent().get_node("Camera3D")

func _process(delta: float) -> void:
	cooldown_timer = max(0.0, cooldown_timer - delta)

	if Input.is_action_just_pressed("attack") and cooldown_timer <= 0.0:
		_attack()

func _attack() -> void:
	cooldown_timer = ATTACK_COOLDOWN
	is_attacking   = true

	# Déclencher l'animation visuelle
	var weapon_view := get_parent().get_node_or_null("Camera3D/WeaponView")
	if weapon_view:
		weapon_view.play_swing()

	# Raycast depuis la caméra vers l'avant
	var space  := get_viewport().get_world_3d().direct_space_state
	var origin := camera.global_position
	var target := origin + (-camera.global_transform.basis.z * ATTACK_RANGE)
	var query  := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_bodies = true
	var result := space.intersect_ray(query)

	if result and result.collider.is_in_group("zombie"):
		result.collider.take_damage(ATTACK_DAMAGE)
		print("Touché !")
	else:
		# Pas de raycast direct — on cherche les zombies dans un rayon sphérique
		_sphere_attack(origin)

	await get_tree().create_timer(0.15).timeout
	is_attacking = false

func _sphere_attack(origin: Vector3) -> void:
	var zombies := get_tree().get_nodes_in_group("zombie")
	var cam_forward := -camera.global_transform.basis.z

	for zombie in zombies:
		var z := zombie as Node3D
		if not z:
			continue
		var to_zombie := (z.global_position - origin)
		if to_zombie.length() > ATTACK_RANGE:
			continue
		var angle := cam_forward.angle_to(to_zombie.normalized())
		if angle < deg_to_rad(60.0):
			z.take_damage(ATTACK_DAMAGE)
			print("Touché zombie (sphère) !")
			break
