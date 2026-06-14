## DayNightCycle.gd — Cycle jour / nuit dynamique
## À attacher sur un Node3D nommé "DayNightCycle"
## Hiérarchie requise :
##   Node3D (ce script)
##   ├── Sun  (DirectionalLight3D)
##   └── Moon (DirectionalLight3D)
##
## Ajouter aussi un WorldEnvironment à la scène principale avec :
##   - Background mode : Sky
##   - Sky material   : ProceduralSkyMaterial

extends Node3D

# ── Paramètres ────────────────────────────────────────────────
## Durée d'un cycle complet en secondes
## 600 = 10 minutes réelles pour 1 jour de jeu
@export var day_duration := 600.0
## Heure de départ (0.0=minuit / 0.25=6h / 0.5=midi / 0.75=18h)
@export var start_time   := 0.25

# ── État ──────────────────────────────────────────────────────
var current_time := 0.25   ## 0.0 → 1.0 représente 24h
var current_day  := 1
var is_night     := false

# ── Signaux (pour connecter les zombies, le HUD, etc.) ────────
signal day_started(day_number: int)
signal night_started(day_number: int)
signal horde_incoming   ## Émis toutes les 7 nuits !

# ── Lumières ──────────────────────────────────────────────────
@onready var sun:  DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon

func _ready() -> void:
	current_time = start_time
	add_to_group("day_night")

	# Configuration de base de la lune
	moon.light_color  = Color(0.55, 0.65, 0.95)   # Bleu nuit
	moon.light_energy = 0.0
	moon.shadow_enabled = true

	# Configuration du soleil
	sun.shadow_enabled = true
	sun.shadow_bias    = 0.05

	_update_lights()   # Appliquer l'état initial

func _process(delta: float) -> void:
	# Avancer le temps
	current_time += delta / day_duration

	# Nouveau jour ?
	if current_time >= 1.0:
		current_time -= 1.0
		current_day  += 1
		print("🌅 Début du jour ", current_day)

	_update_lights()
	_check_day_night_transition()

# ── Mise à jour des lumières selon l'heure ────────────────────
func _update_lights() -> void:
	# Rotation : le soleil fait un tour complet par jour
	# À midi (0.5) il est au zénith, à minuit (0.0/1.0) sous l'horizon
	var angle_deg := current_time * 360.0 - 90.0
	sun.rotation_degrees.x  = angle_deg
	moon.rotation_degrees.x = angle_deg + 180.0

	# Hauteur dans le ciel (sin va de -1 à 1)
	var sun_height := sin(current_time * TAU)

	# Intensité proportionnelle à la hauteur dans le ciel
	sun.light_energy  = clamp(sun_height * 1.8, 0.0, 1.4)
	moon.light_energy = clamp(-sun_height * 0.6, 0.0, 0.35)

	# Couleur du soleil selon l'heure
	if sun_height > 0.2:
		sun.light_color = Color(1.00, 0.96, 0.88)   # Blanc pur → jour
	elif sun_height > 0.0:
		# Lever / coucher : dégradé orange→blanc
		var t := sun_height / 0.2
		sun.light_color = Color(1.0, 0.5 + t * 0.46, 0.2 + t * 0.68)
	else:
		sun.light_color = Color(0.8, 0.45, 0.15)    # Orange crépuscule

	# Ambient light (minimum de luminosité même la nuit)
	RenderingServer.set_default_clear_color(
		Color(0.02, 0.02, 0.06) if is_night else Color(0.4, 0.6, 0.9)
	)

# ── Transitions jour ↔ nuit ───────────────────────────────────
func _check_day_night_transition() -> void:
	var was_night := is_night
	# Nuit = soleil sous l'horizon (avant 6h ou après 18h)
	is_night = current_time > 0.75 or current_time < 0.25

	if is_night and not was_night:
		print("🌙 La nuit tombe... Jour ", current_day, " — méfie-toi !")
		emit_signal("night_started", current_day)
		# Toutes les 7 nuits = horde !
		if current_day % 7 == 0:
			print("🧟 HORDE NIGHT ! Prépare-toi pour la vague !")
			emit_signal("horde_incoming")

	elif not is_night and was_night:
		print("☀️  L'aube se lève — tu as survécu à la nuit ", current_day, " !")
		emit_signal("day_started", current_day)

# ── Utilitaires ───────────────────────────────────────────────
## Retourne l'heure au format "HH:MM"
func get_time_string() -> String:
	var hours   := int(current_time * 24)
	var minutes := int(fmod(current_time * 24.0, 1.0) * 60.0)
	return "%02d:%02d" % [hours, minutes]

## Retourne la progression du jour (0.0 → 1.0)
func get_day_progress() -> float:
	return current_time
