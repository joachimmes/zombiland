## HUD.gd — Interface joueur (santé, faim, soif, endurance, heure)
## À attacher sur un nœud CanvasLayer nommé "HUD"
## Ce script crée toute l'interface par code — aucun nœud à créer manuellement !

extends CanvasLayer

# ── Barres de stats ───────────────────────────────────────────
var health_bar:  ProgressBar
var hunger_bar:  ProgressBar
var thirst_bar:  ProgressBar
var stamina_bar: ProgressBar

# ── Labels info ───────────────────────────────────────────────
var day_label:  Label
var time_label: Label
var night_label: Label   # Avertissement la nuit

# ── Références vers les autres nœuds ──────────────────────────
var player:    CharacterBody3D
var day_night: Node

func _ready() -> void:
	_build_ui()
	# Chercher le joueur et le cycle jour/nuit dans la scène
	player    = get_tree().get_first_node_in_group("player")
	day_night = get_tree().get_first_node_in_group("day_night")
	
	# Écouter les signaux du cycle jour/nuit
	if day_night:
		day_night.night_started.connect(_on_night_started)
		day_night.day_started.connect(_on_day_started)
		day_night.horde_incoming.connect(_on_horde_incoming)

func _process(_delta: float) -> void:
	# Mettre à jour les barres avec les vraies valeurs du joueur
	if player:
		_update_bar(health_bar,  player.health,  Color.RED)
		_update_bar(hunger_bar,  player.hunger,  Color.ORANGE)
		_update_bar(thirst_bar,  player.thirst,  Color.CYAN)
		_update_bar(stamina_bar, player.stamina, Color.YELLOW)
	
	if day_night:
		day_label.text  = "Jour %d" % day_night.current_day
		time_label.text = day_night.get_time_string()

# ── Construction de l'interface ───────────────────────────────
func _build_ui() -> void:
	# == Panneau des stats (coin inférieur gauche) ==
	var stats_bg := ColorRect.new()
	stats_bg.color = Color(0, 0, 0, 0.55)
	stats_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stats_bg.size          = Vector2(240, 130)
	stats_bg.position      = Vector2(15, -145)
	add_child(stats_bg)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(10, 8)
	vbox.size = Vector2(220, 120)
	stats_bg.add_child(vbox)

	health_bar  = _create_bar_row(vbox, "❤  Santé",      Color.RED)
	hunger_bar  = _create_bar_row(vbox, "🍗 Faim",        Color.ORANGE_RED)
	thirst_bar  = _create_bar_row(vbox, "💧 Soif",        Color.DODGER_BLUE)
	stamina_bar = _create_bar_row(vbox, "⚡ Endurance",   Color.YELLOW)

	# == Panneau Jour/Heure (coin supérieur droit) ==
	var info_bg := ColorRect.new()
	info_bg.color = Color(0, 0, 0, 0.55)
	info_bg.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	info_bg.size     = Vector2(130, 55)
	info_bg.position = Vector2(-145, 15)
	add_child(info_bg)

	day_label = Label.new()
	day_label.text     = "Jour 1"
	day_label.position = Vector2(10, 8)
	day_label.add_theme_font_size_override("font_size", 16)
	day_label.add_theme_color_override("font_color", Color.WHITE)
	info_bg.add_child(day_label)

	time_label = Label.new()
	time_label.text     = "07:12"
	time_label.position = Vector2(10, 30)
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_bg.add_child(time_label)

	# == Viseur central ==
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-6, -12)
	crosshair.add_theme_font_size_override("font_size", 22)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	add_child(crosshair)

	# == Label d'avertissement nuit (caché par défaut) ==
	night_label = Label.new()
	night_label.text = "🌙 NUIT — Restez à l'abri !"
	night_label.set_anchors_preset(Control.PRESET_CENTER)
	night_label.position = Vector2(-150, 70)
	night_label.add_theme_font_size_override("font_size", 20)
	night_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	night_label.visible = false
	add_child(night_label)

# ── Créer une ligne "label + barre" ───────────────────────────
func _create_bar_row(parent: Control, label_text: String, color: Color) -> ProgressBar:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 22)
	parent.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(105, 0)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(lbl)

	var bar := ProgressBar.new()
	bar.max_value           = 100
	bar.value               = 100
	bar.show_percentage     = false
	bar.custom_minimum_size = Vector2(100, 14)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color         = color
	fill_style.corner_radius_top_left     = 3
	fill_style.corner_radius_top_right    = 3
	fill_style.corner_radius_bottom_left  = 3
	fill_style.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bar.add_theme_stylebox_override("background", bg_style)

	hbox.add_child(bar)
	return bar

func _update_bar(bar: ProgressBar, value: float, color: Color) -> void:
	bar.value = value
	# La barre devient rouge foncé quand on est en danger
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		fill.bg_color = color if value > 25.0 else Color(0.7, 0.1, 0.1)

# ── Réactions aux signaux ─────────────────────────────────────
func _on_night_started(_day: int) -> void:
	night_label.text    = "🌙 NUIT — Méfie-toi des zombies !"
	night_label.visible = true

func _on_day_started(_day: int) -> void:
	night_label.visible = false

func _on_horde_incoming() -> void:
	night_label.text = "🧟 HORDE NIGHT ! Bonne chance..."
	night_label.modulate = Color.RED
