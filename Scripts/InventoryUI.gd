## InventoryUI.gd — Interface de l'inventaire
## À attacher sur un CanvasLayer nommé "InventoryUI"
## Ouvre/ferme avec Tab

extends CanvasLayer

var inventory  : Node   = null
var slot_cells : Array  = []
var bg_panel   : ColorRect

const COLS      := 5
const ROWS      := 4
const CELL_SIZE := 80
const PADDING   := 12

func _ready() -> void:
	add_to_group("inventory_ui")
	_build_ui()
	visible = false

	# Trouver l'inventaire du joueur
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player:
		inventory = player.get_node_or_null("Inventory")
		if inventory:
			inventory.inventory_changed.connect(_refresh)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		print("Inventaire toggle")
		visible = !visible

		if visible:
			_refresh()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_ui() -> void:
	var total_w := COLS * CELL_SIZE + (COLS + 1) * PADDING
	var total_h := ROWS * CELL_SIZE + (ROWS + 1) * PADDING + 50

	bg_panel = ColorRect.new()
	bg_panel.color = Color(0.08, 0.08, 0.08, 0.92)
	bg_panel.size  = Vector2(total_w, total_h)
	bg_panel.set_anchors_preset(Control.PRESET_CENTER)
	bg_panel.position = Vector2(-total_w / 2.0, -total_h / 2.0)
	add_child(bg_panel)

	var title := Label.new()
	title.text     = "INVENTAIRE"
	title.position = Vector2(PADDING, 10)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	bg_panel.add_child(title)

	slot_cells.clear()
	for row in ROWS:
		for col in COLS:
			var cell := _make_cell(col, row)
			bg_panel.add_child(cell)
			slot_cells.append(cell)

func _make_cell(col: int, row: int) -> Control:
	var cell := ColorRect.new()
	cell.size     = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
	cell.position = Vector2(
		PADDING + col * (CELL_SIZE + PADDING),
		50 + PADDING + row * (CELL_SIZE + PADDING)
	)
	cell.color = Color(0.18, 0.18, 0.18)

	var border := ColorRect.new()
	border.size     = cell.size
	border.position = Vector2.ZERO
	border.color    = Color(0.35, 0.35, 0.35, 0.5)
	cell.add_child(border)

	var lbl := Label.new()
	lbl.name             = "Label"
	lbl.text             = ""
	lbl.position         = Vector2(4, 4)
	lbl.size             = Vector2(CELL_SIZE - 12, CELL_SIZE - 8)
	lbl.autowrap_mode    = TextServer.AUTOWRAP_WORD_ARBITRARY
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	cell.add_child(lbl)

	var qty := Label.new()
	qty.name     = "Qty"
	qty.text     = ""
	qty.position = Vector2(CELL_SIZE - 30, CELL_SIZE - 26)
	qty.add_theme_font_size_override("font_size", 13)
	qty.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	cell.add_child(qty)

	return cell

func _refresh() -> void:
	if not inventory:
		return
	for i in slot_cells.size():
		var lbl : Label = slot_cells[i].get_node("Label")
		var qty : Label = slot_cells[i].get_node("Qty")
		var slot = inventory.slots[i]
		if slot:
			lbl.text = slot["name"]
			qty.text = "x%d" % slot["quantity"]
			slot_cells[i].color = Color(0.22, 0.28, 0.22)
		else:
			lbl.text = ""
			qty.text = ""
			slot_cells[i].color = Color(0.18, 0.18, 0.18)
