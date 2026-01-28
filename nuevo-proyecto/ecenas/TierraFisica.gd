# En TierraFisica.gd (Asignado a tu RigidBody3D de la piedra)
extends RigidBody3D

@onready var timer = $Timer
@onready var voxel_terrain: VoxelLodTerrain = get_tree().root.find_child("VoxelLodTerrain", true, false)

func _ready():
	voxel_terrain = get_tree().root.find_child("VoxelLodTerrain", true, false)
	# El timer debe ser de unos 2 segundos para dar tiempo a caer
	timer.timeout.connect(_on_solidificar)
	timer.start()

func _on_solidificar():
	# Solo solidifica si la piedra ya no se está moviendo rápido (está en el suelo)
	if linear_velocity.length() < 0.2:
		solidificar_en_terreno()
	else:
		# Si sigue rodando o cayendo, reintenta en 1 segundo
		timer.start(1.0)

func solidificar_en_terreno():
	if voxel_terrain:
		var vt = voxel_terrain.get_voxel_tool()
		vt.channel = VoxelBuffer.CHANNEL_SDF
		vt.mode = VoxelTool.MODE_ADD
		vt.value = -1.0 # Añadir masa sólida
		
		# IMPORTANTE: Usamos do_sphere con un radio pequeño
		# para que el terreno crezca justo donde aterrizó la piedra
		vt.do_sphere(global_position, 1.2)
		
		# Efecto visual de polvo al desaparecer (Opcional)
		# crear_polvo(global_position)
		
		queue_free() # La piedra física desaparece, ahora es parte del suelo


var tipo_material : int = 0 # 0: Tierra, 1: Oro, 2: Roca
@onready var mesh = $MeshInstance3D

func configurar_material(id: int):
	tipo_material = id
	var mat = StandardMaterial3D.new()
	match id:
		0: mat.albedo_color = Color("4b3621") # Marrón Tierra
		1: mat.albedo_color = Color("ffcc00") # Dorado Oro
		2: mat.albedo_color = Color("707070") # Gris Roca
	mesh.set_surface_override_material(0, mat)
