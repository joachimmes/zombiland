## Inventory.gd — Données de l'inventaire du joueur
## À attacher comme enfant du nœud Player

extends Node

signal inventory_changed

const MAX_SLOTS := 20

# Chaque slot : { "name": String, "quantity": int } ou null
var slots : Array = []

func _ready() -> void:
	slots.resize(MAX_SLOTS)
	slots.fill(null)

func add_item(item_name: String, quantity: int = 1) -> bool:
	# Empiler sur un slot existant
	for i in MAX_SLOTS:
		if slots[i] != null and slots[i]["name"] == item_name:
			slots[i]["quantity"] += quantity
			emit_signal("inventory_changed")
			return true

	# Trouver un slot vide
	for i in MAX_SLOTS:
		if slots[i] == null:
			slots[i] = { "name": item_name, "quantity": quantity }
			emit_signal("inventory_changed")
			return true

	return false  # Inventaire plein

func remove_item(item_name: String, quantity: int = 1) -> bool:
	for i in MAX_SLOTS:
		if slots[i] != null and slots[i]["name"] == item_name:
			slots[i]["quantity"] -= quantity
			if slots[i]["quantity"] <= 0:
				slots[i] = null
			emit_signal("inventory_changed")
			return true
	return false

func has_item(item_name: String) -> bool:
	for slot in slots:
		if slot != null and slot["name"] == item_name:
			return true
	return false
