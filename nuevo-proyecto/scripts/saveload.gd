# © 2023 Ilya S <ilya.s@fmlht.com>
# https://github.com/ismslv/

extends Node

# Use ".tres" if you want human readable file
# File paths are described in:
# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html
var file_template = "user://%s.res"
var file_config = "res://config.cfg"
var file_config_default = "res://configs_default.cfg"
var loaded_data: SaveGame = null
var config = ConfigFile.new()


## SAVES
# You can easily implement multiple files system
# or custom file names by supplying different file_name.
# It can also be used to implement autosave or quicksave
# by naming files accordingly.
# For example, save files can be named 2023-10-03-12-58-00-(auto)save.tres,
# whereas single quicksave file will be quicksave.tres

func game_save(file_name):
	# Show overlay
	get_node("/root/ArcadeDemo/Overlay").show()
	get_node("/root/ArcadeDemo/Overlay/Back/Label").text = "SAVING..."
	
	# Create a new resource
	var save_data = SaveGame.new()
	# Fill it with data
	# You can Fill it from here or send to several other classes
	save_data = get_node("/root/ArcadeDemo").save_data(save_data)
	
	# You can use ResourceSaver.FLAG_COMPRESS as a third argument
	var result = ResourceSaver.save(save_data, file_template % file_name)
	if result == OK:
		print("Saved game to " + file_template % file_name + "!")
	else:
		print("Error saving file!")
	
	# Hide overlay
	await get_tree().create_timer(0.5).timeout
	get_node("/root/ArcadeDemo/Overlay").hide()


func game_load(file_name):
	# Check if file exists
	if ResourceLoader.exists(file_template % file_name):
		# Show overlay
		get_node("/root/ArcadeDemo/Overlay").show()
		get_node("/root/ArcadeDemo/Overlay/Back/Label").text = "LOADING..."
		
		# Load file
		var save_data = ResourceLoader.load(file_template % file_name)
		# Check if file is loaded correctly as a resource of a needed type
		if save_data is SaveGame:
			print("Loaded game!")
			
			# Put loaded data into persistent static variable
			loaded_data = save_data
			
			# Reload scene (it will load all the data on ready)
			await get_tree().create_timer(0.5).timeout
			get_tree().reload_current_scene()
		else:
			print("Error loading!")
	else:
		print("File not found!")


## CONFIGS
# Config file is not saved with the game,
# because it is normally saved each time you change settings
# in the game's menu.


func config_save():
	# Just saving config file
	var result = config.save(file_config)
	if result != OK:
		print("Config saving error!")
	

# Datos del Jugador
@export var player_pos: Vector3
@export var player_rot: Vector3
@export var dinero: int

# Lista para objetos instanciados (Camiones, cajas, etc.)
@export var dynamic_objects: Array[Dictionary] = []

const SAVE_PATH = "user://partida.res"

func full_save():
	var data = savegame.new()
	
	# 1. Guardar Jugador
	var player = get_tree().get_first_node_in_group("player") # Asegúrate de que el jugador esté en este grupo
	if player:
		player.save_data(data)
	
	# 2. Guardar Objetos Dinámicos (Camiones/Items)
	# Solo guardamos los que tienen el grupo "save_transform"
	var objects = get_tree().get_nodes_in_group("save_transform")
	for obj in objects:
		# IMPORTANTE: No guardamos al jugador aquí aunque tenga el grupo
		if obj is CharacterBody3D: continue 
		
		var dict = {
			"scene": obj.scene_file_path,
			"pos": obj.global_position,
			"rot": obj.global_rotation
		}
		# Si es un RigidBody, guardamos su velocidad
		if obj is RigidBody3D:
			dict["vel"] = obj.linear_velocity
			
		data.dynamic_objects.append(dict)
	
	ResourceSaver.save(data, SAVE_PATH)
	print("Juego Guardado")

func full_load():
	if not ResourceLoader.exists(SAVE_PATH): return
	
	var data = ResourceLoader.load(SAVE_PATH)
	
	# 1. Cargar Jugador
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.load_data(data)
	
	# 2. Limpiar y Cargar Objetos
	for old in get_tree().get_nodes_in_group("save_transform"):
		if old is RigidBody3D: old.queue_free()
	
	for item in data.dynamic_objects:
		var scene = load(item["scene"])
		var inst = scene.instantiate() #al momento de cargar el juego no termina de funcionar no se por que solo pasa 
		get_tree().current_scene.add_child(inst)  # un detalle es que solo el full_load y full_save sirven los demas tambien pero a medias 
		
		inst.global_position = item["pos"]
		inst.global_rotation = item["rot"]
		if inst is RigidBody3D and item.has("vel"):
			inst.linear_velocity = item["vel"]
		
		inst.add_to_group("save_transform")
