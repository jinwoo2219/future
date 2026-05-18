extends Control

const RUN_STATE = preload("res://scripts/run_state.gd")
const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")
const SKILL_CATALOG = preload("res://scripts/skill_catalog.gd")


func _on_start_pressed() -> void:
	ENEMY_CATALOG.reload()
	SKILL_CATALOG.reload()
	RUN_STATE.reset_run()
	get_tree().change_scene_to_file("res://scenes/stage_select_screen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
