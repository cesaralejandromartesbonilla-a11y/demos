# Global.gd
extends Node

var estado = 1  # 1 = a pie, 0 = en auto

@export var player_pos: Vector3
@export var player_rot: Vector3
@export var dinero: int
# Esta es la lista para los objetos RigidBody instanciados (camiones, items, etc.)
@export var dynamic_objects: Array[Dictionary] = [] 


func cambia_estado():
	if estado == 0:
		estado = 1
	else:
		estado = 0


var ball_data = {}
var ball_types = ["basketball", "football", "volleyball", "tennis", "golf"]

func _ready():
	ball_data["basketball"] = BallData.new()
	ball_data["basketball"].texture = load("res://images/basketball.png")
	ball_data["basketball"].size = 0.5
	
	ball_data["football"] = BallData.new()
	ball_data["football"].texture = load("res://images/football.png")
	ball_data["football"].size = 0.3
	
	ball_data["volleyball"] = BallData.new()
	ball_data["volleyball"].texture = load("res://images/volleyball.png")
	ball_data["volleyball"].size = 0.25
	
	ball_data["tennis"] = BallData.new()
	ball_data["tennis"].texture = load("res://images/tennis.png")
	ball_data["tennis"].size = 0.2
	
	ball_data["golf"] = BallData.new()
	ball_data["golf"].texture = load("res://images/golf.jpg")
	ball_data["golf"].size = 0.2
