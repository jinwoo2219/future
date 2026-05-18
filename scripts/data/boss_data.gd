extends Resource
class_name BossData


@export var id: StringName
@export var name: String = ""
@export var phase_structure: Array[StringName] = []
@export var traits: Array[StringName] = []
@export var keywords: PackedStringArray = []
@export_multiline var description: String = ""
@export var icon: Texture2D


func get_validation_issues() -> PackedStringArray:
	var issues := PackedStringArray()

	if id.is_empty():
		issues.append("BossData.id is required.")
	if name.is_empty():
		issues.append("BossData.name is required.")
	if phase_structure.is_empty():
		issues.append("BossData.phase_structure should define at least one phase id.")

	return issues
