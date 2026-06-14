## ZombieSpawner.gd — Peuple le monde de zombies errants
## À attacher sur un Node nommé "ZombieSpawner" dans la scène principale
## Requiert que le Zombie soit sauvegardé comme "res://Zombie.tscn"

extends Node

@export var zombie_scene   : PackedScene
@export var max_zombies    : int   = 20
@export var spawn_radius   : float = 80.0  # Rayon autour du centre du monde
@export var min_dist_player: float = 15.0  # Ne pas spawner trop près du joueur

var player : Node3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	# Laisser le terrain se générer avant de spawner
	call_deferred("_spawn_initial_zombies")

func _spawn_initial_zombies() -> void:
	for i in max_zombies:
		_spawn_zombie()

func _spawn_zombie() -> void:
	if not zombie_scene:
		push_warning("ZombieSpawner : zombie_scene non assignée !")
		return

	var pos := _random_spawn_position()
	if pos == Vector3.ZERO:
		return

	var zombie : CharacterBody3D = zombie_scene.instantiate()
	get_parent().add_child(zombie)
	zombie.global_position = pos

func _random_spawn_position() -> Vector3:
	# Essaie jusqu'à 10 fois de trouver une position valide
	for _i in 10:
		var angle := randf() * TAU
		var dist  := randf_range(min_dist_player, spawn_radius)
		var pos   := Vector3(cos(angle) * dist, 50.0, sin(angle) * dist)

		# Raycast vers le bas pour atterrir sur le terrain
		var space  := get_viewport().get_world_3d().direct_space_state
		var query  := PhysicsRayQueryParameters3D.create(pos, pos + Vector3.DOWN * 100.0)
		var result := space.intersect_ray(query)

		if result:
			# Vérifier distance au joueur
			if player and result.position.distance_to(player.global_position) < min_dist_player:
				continue
			return result.position + Vector3.UP * 1.0

	return Vector3.ZERO
