class_name TeamData
extends RefCounted

var id: int
var name: String
var color: Color
var controller_type: String
var money: int

func _init(team_id: int, team_name: String, team_color: Color, controller: String, starting_money: int) -> void:
	id = team_id
	name = team_name
	color = team_color
	controller_type = controller
	money = starting_money

func is_cpu() -> bool:
	return controller_type == "cpu"
