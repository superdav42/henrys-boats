class_name TurnManager
extends RefCounted

var state
var input_locked := true

func begin_match(match_state) -> void:
	state = match_state
	input_locked = true

func current_team():
	return state.current_team()

func advance_turn():
	state.advance_turn()
	var team = state.current_team()
	team.money += 60 + state.count_units_for_team(team.id) * 15
	state.reset_actions(team.id)
	input_locked = true
	return team

func unlock_human_input() -> void:
	input_locked = false

func lock_input() -> void:
	input_locked = true
