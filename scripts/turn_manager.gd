extends RefCounted
class_name TurnManager

var base_actions_per_turn: int = 2
var actions_left: int = 2
var turn_number: int = 1
var energy_available: bool = true


func setup(base_actions: int = 2) -> void:
	base_actions_per_turn = max(base_actions, 1)
	reset_battle()


func reset_battle() -> void:
	actions_left = base_actions_per_turn
	turn_number = 1
	energy_available = true


func can_act(cost: int = 1) -> bool:
	if cost <= 0:
		return true
	return actions_left >= cost


func spend_action(cost: int = 1) -> bool:
	if cost <= 0:
		return true
	if not can_act(cost):
		return false
	actions_left -= cost
	return true


func can_use_energy() -> bool:
	return energy_available


func consume_energy() -> bool:
	if not can_use_energy():
		return false
	energy_available = false
	return true


func use_energy_for_action() -> bool:
	if not consume_energy():
		return false
	actions_left += 1
	return true


func add_actions(amount: int) -> bool:
	if amount <= 0:
		return false
	actions_left += amount
	return true


func begin_next_turn() -> void:
	turn_number += 1
	actions_left = base_actions_per_turn


func refresh_actions() -> void:
	actions_left = base_actions_per_turn


func get_turn_number() -> int:
	return turn_number


func get_actions_left() -> int:
	return actions_left
