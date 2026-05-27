extends Resource
class_name ModuleData

@export var id: StringName
@export var name: String = ""
@export var rarity: StringName = &"common"
@export var effect_key: StringName
@export var values: Dictionary = {}
@export_multiline var description: String = ""
@export_multiline var detail_description: String = ""


func get_validation_issues() -> PackedStringArray:
	var issues := PackedStringArray()

	if id.is_empty():
		issues.append("ModuleData.id is required.")
	if name.is_empty():
		issues.append("ModuleData.name is required.")
	if rarity.is_empty():
		issues.append("ModuleData.rarity is required.")
	if effect_key.is_empty():
		issues.append("ModuleData.effect_key is required.")

	return issues
