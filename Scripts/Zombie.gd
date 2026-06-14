## Zombie.gd — IA zombie style Just Survive
## À attacher sur un nœud CharacterBody3D
## Hiérarchie requise :
##   CharacterBody3D (ce script)
##   └── CollisionShape3D (CapsuleShape3D h=1.8, r=0.4)

extends CharacterBody3D

enum State { WANDER, CHASE, ATTACK }

# ── Paramètres ────────────────────────────────────────────────
const MOVE_SPEED      := 1.5   # Lent en errance
const CHASE_SPEED     := 3.2   # Plus rapide en poursuite
const DETECTION_RANGE := 10.0
const ATTACK_RANGE    := 1.6
const ATTACK_DAMAGE   := 8.0
const ATTACK_COOLDOWN := 1.5
const GRAVITY         := 20.0
const WANDER_RADIUS   := 12.0  # Distance max du point d'errance
const WANDER_WAIT_MAX := 4.0   # Pause entre deux déplacements

var max_health := 60.0

# ── État interne ──────────────────────────────────────────────
var health        : float
var state         : State = State.WANDER
var player        : CharacterBody3D
var attack_timer  : float = 0.0
var wander_target : Vector3
var wander_wait   : float = 0.0
var spawn_origin  : Vector3  # Position de spawn, centre de la zone d'errance

func _ready() -> void:
	health = max_health
	add_to_group("zombie")
	player = get_tree().get_first_node_in_group("player")
	spawn_origin  = global_position
	wander_target = _random_wander_point()

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	_apply_gravity(delta)
	attack_timer = max(0.0, attack_timer - delta)
	_update_state(delta)

	match state:
		State.WANDER:
			_wander(delta)
		State.CHASE:
			_chase()
		State.ATTACK:
			_try_attack()

	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _update_state(delta: float) -> void:
	var dist := global_position.distance_to(player.global_position)

	if dist <= ATTACK_RANGE:
		state = State.ATTACK
	elif dist <= DETECTION_RANGE:
		state = State.CHASE
	else:
		if state == State.CHASE:
			# Perd le joueur de vue → retour à l'errance
			state = State.WANDER
			wander_target = _random_wander_point()

func _wander(delta: float) -> void:
	if wander_wait > 0.0:
		wander_wait -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var dir := (wander_target - global_position)
	dir.y = 0.0

	if dir.length() < 1.0:
		# Arrivé — pause puis nouveau point
		wander_wait   = randf_range(1.0, WANDER_WAIT_MAX)
		wander_target = _random_wander_point()
		velocity.x = 0.0
		velocity.z = 0.0
		return

	dir = dir.normalized()
	velocity.x = dir.x * MOVE_SPEED
	velocity.z = dir.z * MOVE_SPEED
	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _chase() -> void:
	var dir := (player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * CHASE_SPEED
	velocity.z = dir.z * CHASE_SPEED
	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _try_attack() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if attack_timer <= 0.0:
		player.take_damage(ATTACK_DAMAGE)
		attack_timer = ATTACK_COOLDOWN

func _random_wander_point() -> Vector3:
	var angle := randf() * TAU
	var dist  := randf_range(3.0, WANDER_RADIUS)
	return spawn_origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		_die()

func _die() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.register_zombie_kill()
	queue_free()
