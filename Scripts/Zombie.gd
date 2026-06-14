## Zombie.gd — IA zombie basique
## À attacher sur un nœud CharacterBody3D
## Hiérarchie requise :
##   CharacterBody3D (ce script)
##   ├── CollisionShape3D (CapsuleShape3D h=1.8, r=0.4)

extends CharacterBody3D

enum State { IDLE, CHASE, ATTACK }

# ── Paramètres ────────────────────────────────────────────────
const MOVE_SPEED      := 2.5
const DETECTION_RANGE := 12.0
const ATTACK_RANGE    := 1.6
const ATTACK_DAMAGE   := 10.0
const ATTACK_COOLDOWN := 1.2
const GRAVITY         := 20.0

var max_health := 50.0

# ── État interne ──────────────────────────────────────────────
var health       : float
var state        : State = State.IDLE
var player       : CharacterBody3D
var attack_timer : float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("zombie")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	_apply_gravity(delta)
	attack_timer = max(0.0, attack_timer - delta)
	_update_state()

	match state:
		State.CHASE:
			_chase()
		State.ATTACK:
			_try_attack()

	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _update_state() -> void:
	if not player:
		state = State.IDLE
		return

	var dist := global_position.distance_to(player.global_position)

	if dist <= ATTACK_RANGE:
		state = State.ATTACK
	elif dist <= DETECTION_RANGE:
		state = State.CHASE
	else:
		state = State.IDLE
		velocity.x = 0.0
		velocity.z = 0.0

func _chase() -> void:
	var dir := (player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * MOVE_SPEED
	velocity.z = dir.z * MOVE_SPEED
	if dir.length() > 0.01:
		look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _try_attack() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if attack_timer <= 0.0:
		player.take_damage(ATTACK_DAMAGE)
		attack_timer = ATTACK_COOLDOWN

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		_die()

func _die() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.register_zombie_kill()
	queue_free()
