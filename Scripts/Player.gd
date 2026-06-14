## Player.gd — Contrôleur FPS
## À attacher sur un nœud CharacterBody3D
## Hiérarchie requise :
##   CharacterBody3D (ce script)
##   ├── CollisionShape3D (CapsuleShape3D h=1.8, r=0.4)
##   └── Head (Node3D, position y=0.7)
##       └── Camera3D

extends CharacterBody3D

# ── Mouvement ────────────────────────────────────────────────
const WALK_SPEED    := 5.0
const SPRINT_SPEED  := 9.0
const JUMP_VELOCITY := 4.8
const GRAVITY       := 20.0
const MOUSE_SENSITIVITY := 0.002

# ── Stats de survie ──────────────────────────────────────────
var health   := 100.0
var hunger   := 100.0
var thirst   := 100.0
var stamina  := 100.0

# ── Références internes ──────────────────────────────────────
@onready var head: Node3D = $Head

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	var inv = load("res://Scripts/Inventory.gd").new()
	inv.name = "Inventory"
	add_child(inv)

# ── Input souris (rotation caméra) ───────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotation horizontale du corps
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Rotation verticale de la tête (limité à ±85°)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	# Échap = libérer / recapturer la souris
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ── Physique (chaque frame) ───────────────────────────────────
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	_update_survival(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _handle_movement(delta: float) -> void:
	var sprinting := Input.is_action_pressed("sprint") and stamina > 0
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED

	# ZQSD / WASD
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Sprinter consomme de l'endurance
		if sprinting:
			stamina = max(0.0, stamina - 20.0 * delta)
	else:
		# Décélération progressive
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		# Récupérer l'endurance au repos
		stamina = min(100.0, stamina + 12.0 * delta)

# ── Stats de survie (diminuent avec le temps) ─────────────────
func _update_survival(delta: float) -> void:
	hunger = max(0.0, hunger - 0.4 * delta)   # Vide en ~4 min
	thirst = max(0.0, thirst - 0.6 * delta)   # Vide en ~2.5 min

	# Mourir de faim ou de soif → perd de la vie
	if hunger <= 0.0 or thirst <= 0.0:
		take_damage(2.0 * delta)

# ── Dégâts / mort ─────────────────────────────────────────────
func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	if health == 0.0:
		_on_death()

func heal(amount: float) -> void:
	health = min(100.0, health + amount)

func eat(amount: float) -> void:
	hunger = min(100.0, hunger + amount)

func drink(amount: float) -> void:
	thirst = min(100.0, thirst + amount)

func _on_death() -> void:
	print("💀 Le joueur est mort !")
	# TODO : afficher l'écran de mort + respawn
