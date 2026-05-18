extends Resource
class_name EnemyPoolData


@export var id: StringName
@export var act: int = 1
@export var pool_type: StringName
@export var enemy_ids: Array[StringName] = []
@export_multiline var notes: String = ""


func get_validation_issues() -> PackedStringArray:
	var issues := PackedStringArray()

	if id.is_empty():
		issues.append("EnemyPoolData.id is required.")
	if act <= 0:
		issues.append("EnemyPoolData.act must be above 0.")
	if pool_type.is_empty():
		issues.append("EnemyPoolData.pool_type is required.")
	if enemy_ids.is_empty():
		issues.append("EnemyPoolData.enemy_ids should not be empty.")

	return issues
