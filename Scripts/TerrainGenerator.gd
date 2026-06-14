## TerrainGenerator.gd — Génération procédurale du monde
## À attacher sur le nœud racine de la scène (Node3D)
## Génère : terrain heightmap + arbres + collisions

extends Node3D

# ── Paramètres exportés (modifiables dans l'inspecteur Godot) ─
@export var terrain_size       := 200     ## Taille du terrain en unités
@export var terrain_resolution := 150     ## Nb de subdivisions (+ = plus détaillé)
@export var height_scale       := 18.0   ## Hauteur max des collines
@export var noise_frequency    := 0.015  ## Fréquence du bruit (+ = plus de collines)
@export var tree_count         := 350    ## Nombre d'arbres

var noise := FastNoiseLite.new()
# Tableau 2D des hauteurs pour placer les arbres au bon endroit
var height_map: Array = []

func _ready() -> void:
	randomize()
	_setup_noise()
	_generate_terrain()
	_spawn_vegetation()
	print("🌍 Monde généré ! Seed: ", noise.seed)

# ── Configuration du bruit de Perlin ──────────────────────────
func _setup_noise() -> void:
	noise.seed           = randi()
	noise.noise_type     = FastNoiseLite.TYPE_PERLIN
	noise.frequency      = noise_frequency
	noise.fractal_octaves   = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain      = 0.5

# ── Génération du mesh de terrain ─────────────────────────────
func _generate_terrain() -> void:
	var st   := SurfaceTool.new()
	var step := float(terrain_size) / terrain_resolution
	height_map = []

	# 1. Calculer toutes les hauteurs
	for z in range(terrain_resolution + 1):
		height_map.append([])
		for x in range(terrain_resolution + 1):
			var wx := (x * step) - terrain_size / 2.0
			var wz := (z * step) - terrain_size / 2.0
			# Bruit → valeur entre -1 et 1, on ramène entre 0 et height_scale
			var h  := (noise.get_noise_2d(wx, wz) + 1.0) * 0.5 * height_scale
			height_map[z].append(h)

	# 2. Construire les triangles du mesh
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(terrain_resolution):
		for x in range(terrain_resolution):
			var wx0 := x * step - terrain_size / 2.0
			var wx1 := (x + 1) * step - terrain_size / 2.0
			var wz0 := z * step - terrain_size / 2.0
			var wz1 := (z + 1) * step - terrain_size / 2.0

			# Les 4 coins du carré
			var v00 := Vector3(wx0, height_map[z][x],     wz0)
			var v10 := Vector3(wx1, height_map[z][x+1],   wz0)
			var v01 := Vector3(wx0, height_map[z+1][x],   wz1)
			var v11 := Vector3(wx1, height_map[z+1][x+1], wz1)

			# UV pour les textures
			var u0 := float(x) / terrain_resolution
			var u1 := float(x+1) / terrain_resolution
			var v0 := float(z) / terrain_resolution
			var v1 := float(z+1) / terrain_resolution

			# Triangle 1 (bas-gauche)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(v00)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(v10)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(v01)
			# Triangle 2 (haut-droit)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(v10)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(v11)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(v01)

	# 3. Calculer les normales automatiquement (pour l'éclairage)
	st.generate_normals()
	var mesh := st.commit()

	# 4. Matériau vert herbe
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.58, 0.22)
	mat.roughness    = 0.95

	# 5. Créer le MeshInstance et l'ajouter à la scène
	var mi := MeshInstance3D.new()
	mi.mesh              = mesh
	mi.material_override = mat
	mi.name              = "Terrain"
	add_child(mi)

	# 6. Collision (le joueur ne tombera pas à travers !)
	mi.create_trimesh_collision()
	print("✅ Terrain généré avec collisions")

# ── Végétation ────────────────────────────────────────────────
func _spawn_vegetation() -> void:
	var step := float(terrain_size) / terrain_resolution
	for _i in range(tree_count):
		var xi := randi() % (terrain_resolution - 2) + 1
		var zi := randi() % (terrain_resolution - 2) + 1
		var h: float = height_map[zi][xi]
		# Arbres seulement entre 1m et 80% de la hauteur max
		if h > 1.0 and h < height_scale * 0.80:
			var wx := xi * step - terrain_size / 2.0
			var wz := zi * step - terrain_size / 2.0
			_spawn_tree(Vector3(wx, h, wz))

func _spawn_tree(pos: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos

	# Tronc (cylindre marron)
	var trunk      := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius    = 0.22
	trunk_mesh.bottom_radius = 0.30
	trunk_mesh.height        = randf_range(3.0, 5.0)
	trunk.mesh      = trunk_mesh
	trunk.position.y = trunk_mesh.height / 2.0
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(
		randf_range(0.35, 0.50),
		randf_range(0.20, 0.30),
		randf_range(0.08, 0.15)
	)
	trunk.material_override = trunk_mat
	tree.add_child(trunk)

	# Feuilles (3 sphères empilées pour un look naturel)
	for layer in range(3):
		var leaves      := MeshInstance3D.new()
		var leaves_mesh := SphereMesh.new()
		var radius      := 1.8 - layer * 0.35
		leaves_mesh.radius = radius
		leaves_mesh.height = radius * 2.0
		leaves.mesh       = leaves_mesh
		leaves.position.y = trunk_mesh.height + 0.5 + layer * 1.1
		var leaves_mat := StandardMaterial3D.new()
		leaves_mat.albedo_color = Color(
			randf_range(0.06, 0.15),
			randf_range(0.38, 0.58),
			randf_range(0.08, 0.18)
		)
		tree.add_child(leaves)

	# Légère variation de rotation pour que les arbres ne soient pas tous pareils
	tree.rotation.y = randf() * TAU
	tree.scale      = Vector3.ONE * randf_range(0.8, 1.3)
	add_child(tree)
