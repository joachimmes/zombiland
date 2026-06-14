## GameManager.gd — Singleton (Autoload)
## Gère l'état global du jeu : score, game over, connexions entre systèmes
## À ajouter dans : Project → Project Settings → Autoload
##   Script : scripts/GameManager.gd   |   Nom : GameManager

extends Node

# ── État global ───────────────────────────────────────────────
var current_day   := 1
var is_game_over  := false
var zombies_killed := 0
var nights_survived := 0

# ── Signaux globaux ───────────────────────────────────────────
signal game_over_triggered
signal new_day_started(day: int)
signal zombie_killed(total: int)

func _ready() -> void:
	print("🎮 GameManager initialisé")
	# Attendre que la scène soit chargée avant de connecter les signaux
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var day_night = get_tree().get_first_node_in_group("day_night")
	if day_night:
		day_night.day_started.connect(_on_day_started)
		day_night.night_started.connect(_on_night_started)
		day_night.horde_incoming.connect(_on_horde_incoming)
		print("✅ GameManager connecté au cycle jour/nuit")
	else:
		print("⚠️  GameManager : DayNightCycle introuvable — vérifie le groupe 'day_night'")

# ── Réactions aux événements ──────────────────────────────────
func _on_day_started(day: int) -> void:
	current_day = day
	emit_signal("new_day_started", day)
	print("📅 Jour %d — zombies tués : %d" % [day, zombies_killed])

func _on_night_started(day: int) -> void:
	nights_survived = day - 1
	print("🌙 Nuit %d commence" % day)

func _on_horde_incoming() -> void:
	print("🧟 HORDE ! C'est la nuit %d" % current_day)
	# TODO : appeler le ZombieSpawner ici (phase suivante)

# ── Appelé par le joueur quand il meurt ──────────────────────
func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	emit_signal("game_over_triggered")
	print("💀 GAME OVER — Survie : %d jours, %d zombies tués" % [current_day, zombies_killed])
	# TODO : charger la scène Game Over

# ── Appelé quand un zombie est tué ───────────────────────────
func register_zombie_kill() -> void:
	zombies_killed += 1
	emit_signal("zombie_killed", zombies_killed)

# ── Utilitaire ────────────────────────────────────────────────
func get_stats() -> Dictionary:
	return {
		"day":     current_day,
		"killed":  zombies_killed,
		"nights":  nights_survived
	}
