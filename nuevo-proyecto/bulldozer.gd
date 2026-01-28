#bull dozer.gd
extends "res://addons/gevp/scenes/vehicle_base.gd"

@export var tierra_escena : PackedScene
# Referencia a los nuevos RayCasts
@export var rc_izq :RayCast3D
@export var rc_central :RayCast3D
@export var rc_der :RayCast3D

@onready var spawn_tierra = $SpawnTierra
@export var velocidad_carrito := 0.010
@onready var pala = $Node3D
# Límites de rotación (en grados)
var pala_min := -35.0
var pala_max := 50.0

@export_group("Sistema de Tierra")
var tierra_acumulada_auto: float = 0.0
const CAPACIDAD_MAX_AUTO = 100.0  # El bulldozer carga más que el jugador
@export var altura_nivelado_offset := 0.2 # Ajuste fino de la altura del suelo


# Referencia al terreno (ajusta la ruta según tu escena)
@onready var terreno: VoxelLodTerrain = get_tree().root.find_child("VoxelLodTerrain", true, false)

var excavando : bool = false

@export_group("custom")
@export var fuerza = 200
@export var frenada = 10
@export var direccion = 0.3

func _physics_process(_delta: float) -> void:
	if !is_mounted:
		_reset_vehicle_forces()
		return

	procesar_excavacion_raycast()



	# 1. CONTROL DE LA CUCHILLA (Mejorado para 2026)
	var input_pala = Input.get_axis("inclinar_delante", "inclinar_atras") # Ajusta según tu Input Map
	if pala:
		# Aumentamos la velocidad de rotación para que sea más responsiva
		pala.rotation_degrees.x = clamp(
			pala.rotation_degrees.x + (input_pala * 1.5), 
			pala_min, 
			pala_max
		)




	# Lógica de control normal (solo si montado)
	if Input.is_action_pressed("press_w"):
		$VehicleWheel3D3.engine_force = fuerza
		$VehicleWheel3D4.engine_force = fuerza
	elif Input.is_action_pressed("press_s"):
		$VehicleWheel3D3.engine_force = -fuerza
		$VehicleWheel3D4.engine_force = -fuerza
	else:
		$VehicleWheel3D3.engine_force = 0
		$VehicleWheel3D4.engine_force = 0
		
	if Input.is_action_pressed("press_a"):
		$VehicleWheel3D.steering = direccion
		$VehicleWheel3D2.steering = direccion
	elif Input.is_action_pressed("press_d"):
		$VehicleWheel3D.steering = -direccion
		$VehicleWheel3D2.steering = -direccion
	else:
		$VehicleWheel3D.steering = 0
		$VehicleWheel3D2.steering = 0
	
	if Input.is_action_pressed("press_space"):
		$VehicleWheel3D.brake = frenada
		$VehicleWheel3D2.brake = frenada
	else:
		$VehicleWheel3D.brake = 0
		$VehicleWheel3D2.brake = 0

func _reset_vehicle_forces():
	$VehicleWheel3D3.engine_force = 0
	$VehicleWheel3D4.engine_force = 0
	$VehicleWheel3D.steering = 0
	$VehicleWheel3D2.steering = 0
	$VehicleWheel3D.brake = 0
	$VehicleWheel3D2.brake = 0


func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"spawned": false
	}
	return save_dict

# ELIMINA LA FUNCIÓN 'procesar_excavacion()' QUE TENÍAS AQUÍ

func generar_tierra_visual(): # Esta función NO espera argumentos
	if tierra_escena:
		var piedra = tierra_escena.instantiate()
		get_tree().root.add_child(piedra)
		piedra.global_position = spawn_tierra.global_position
		
		if piedra is RigidBody3D:
			var impulso = (global_basis.z * -1.0 + Vector3.UP * 0.5).normalized()
			var fuerza_aleatoria = randf_range(2.0, 5.0)
			piedra.apply_central_impulse(impulso * fuerza_aleatoria)

func procesar_excavacion_raycast():
	if terreno == null: return
	
	var tool = terreno.get_voxel_tool()
	tool.channel = VoxelBuffer.CHANNEL_SDF
	
	# La altura que queremos dejar plana
	var altura_objetivo_global = global_position.y + altura_nivelado_offset

	for ray_cast in [rc_izq, rc_central, rc_der]:
		if !ray_cast.is_colliding(): continue
		
		var col_point = ray_cast.get_collision_point()
		var local_pos = terreno.to_local(Vector3(col_point.x, altura_objetivo_global, col_point.z))
		var tamaño_caja = Vector3(2.0, 1.0, 1.0)
		var p_min = local_pos - Vector3(tamaño_caja.x / 2.0, 0.0, tamaño_caja.z / 2.0)
		var p_max = local_pos + Vector3(tamaño_caja.x / 2.0, -1.0, tamaño_caja.z / 2.0)

		# ESCENARIO A: El terreno está MUY ALTO (Excavar)
		if col_point.y > altura_objetivo_global + 0.1:
			if tierra_acumulada_auto < CAPACIDAD_MAX_AUTO:
				tool.mode = VoxelTool.MODE_REMOVE
				tool.do_box(p_min, p_max)
				tierra_acumulada_auto += 0.5 # Recoge tierra
				
				if Engine.get_frames_drawn() % 40 == 0:
					generar_tierra_visual() # Suelta partículas visuales

		# ESCENARIO B: El terreno está MUY BAJO (Rellenar)
		elif col_point.y < altura_objetivo_global - 0.1:
			if tierra_acumulada_auto > 0:
				tool.mode = VoxelTool.MODE_ADD
				# Rellenamos solo el hueco necesario
				tool.do_box(p_min, p_max)
				tierra_acumulada_auto -= 0.5 # Consume la tierra guardada
				
				# Efecto visual de polvo al rellenar
				if Engine.get_frames_drawn() % 60 == 0:
					print("Rellenando... Tierra restante: ", tierra_acumulada_auto)
