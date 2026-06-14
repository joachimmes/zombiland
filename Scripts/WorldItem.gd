## WorldItem.gd — Objet ramassable dans le monde
## À attacher sur un nœud Area3D
## Hiérarchie requise :
##   Area3D (ce script)
##   ├── CollisionShape3D (SphereShape3D r=1.0)
##   └── MeshInstance3D

extends Area3D

@export var item_name : String = "Nourriture"
@export var quantity  : int    = 1

var player_nearby : bool = false
var player_node   : Node  = null
var prompt_label  : Label = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_prompt()

func _create_prompt() -> void:
	prompt_label = Label.new()
	prompt_label.text = "E — Ramasser " + item_name
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.visible = false
	# Le label est en 3D world → on le place via un billboard Label3D serait mieux,
	# mais on utilise un simple overlay via le HUD à la place
	add_child(prompt_label)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_just_pressed("interact"):
		_pick_up()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_node  = body
		player_nearby = true
		_show_hud_prompt(true)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_node  = null
		_show_hud_prompt(false)

func _pick_up() -> void:
	var inventory := player_node.get_node_or_null("Inventory")
	if inventory and inventory.add_item(item_name, quantity):
		print("Ramassé : ", item_name, " x", quantity)
		_show_hud_prompt(false)
		queue_free()
	else:
		print("Inventaire plein !")

func _show_hud_prompt(visible: bool) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_interact_prompt"):
		hud.show_interact_prompt(visible, "E  Ramasser " + item_name)
