class_name TeamData
extends RefCounted

const TEAM_COLORS := [Color("48bfff"), Color("ff6b5e"), Color("ffd166"), Color("7ee081"), Color("bd8cff"), Color("ff9f5b"), Color("50d5c7"), Color("ee77b8")]
var id: int
var name: String
var color: Color
var controller_type: String
var money: int

func _init(team_id: int, team_name: String, team_color: Color, controller: String = "human", starting_money: int = 260) -> void:
	id = team_id
	name = team_name
	color = team_color
	controller_type = controller
	money = starting_money

static func create_teams(count: int, starting_money: int) -> Array:
	var teams: Array = []
	for team_id in range(clampi(count, 2, 8)):
		teams.append(load("res://scripts/team_data.gd").new(team_id, "Team %d" % (team_id + 1), TEAM_COLORS[team_id], "human" if team_id == 0 else "cpu", starting_money))
	return teams

func is_cpu() -> bool:
	return controller_type == "cpu"
