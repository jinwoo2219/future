extends Resource
class_name EnemyData


@export var id: StringName
@export var name: String = ""
@export var color: StringName
@export var initial: String = ""
@export var rank: StringName
@export var category: StringName
@export var hp: int = 1
@export var attack: int = 1
@export var move_pattern_id: StringName
@export var traits: Array[StringName] = []
@export var danger_score: int = 1
@export var keywords: PackedStringArray = []
@export_multiline var description: String = ""
@export var icon: Texture2D


func get_validation_issues() -> PackedStringArray:
	var issues := PackedStringArray()

	if id.is_empty():
		issues.append("EnemyData.id is required.")
	if name.is_empty():
		issues.append("EnemyData.name is required.")
	if color.is_empty():
		issues.append("EnemyData.color is required.")
	if initial.is_empty():
		issues.append("EnemyData.initial is required.")
	if rank.is_empty():
		issues.append("EnemyData.rank is required.")
	if category.is_empty():
		issues.append("EnemyData.category is required.")
	if hp <= 0:
		issues.append("EnemyData.hp must be above 0.")
	if attack < 0:
		issues.append("EnemyData.attack must be 0 or above.")
	if move_pattern_id.is_empty():
		issues.append("EnemyData.move_pattern_id is required.")
	if danger_score <= 0:
		issues.append("EnemyData.danger_score must be above 0.")

	return issues
