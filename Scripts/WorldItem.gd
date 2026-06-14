## WorldItem.gd — Objet ramassable dans le monde
## À attacher sur un nœud Area3D ou Node3D
## Enfants requis : MeshInstance3D (pour voir l'objet)

extends Node3D

@export var item_name : String = "Nourriture"
@export var quantity  : int    = 1

const PICKUP_RANGE := 3.0

var player_nearby : bool = false
var player_node   : Node3D = null

func _ready() -> void:
	player_node = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player")
		return

	var flat_pos_item   := Vector2(global_position.x, global_position.z)
	var flat_pos_player := Vector2(player_node.global_position.x, player_node.global_position.z)
	var dist := flat_pos_item.distance_to(flat_pos_player)

	if dist < PICKUP_RANGE and not player_nearby:
		player_nearby = true
		_show_hud_prompt(true)
	elif dist >= PICKUP_RANGE and player_nearby:
		player_nearby = false
		_show_hud_prompt(false)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_just_pressed("interact"):
		_pick_up()

func _pick_up() -> void:
	var inventory := player_node.get_node_or_null("Inventory")
	if inventory and inventory.add_item(item_name, quantity):
		print("Ramassé : ", item_name, " x", quantity)
		_show_hud_prompt(false)
		queue_free()
	else:
		print("Inventaire plein !")

func _show_hud_prompt(show: bool) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_interact_prompt"):
		hud.show_interact_prompt(show, "E  Ramasser " + item_name)
