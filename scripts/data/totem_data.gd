extends Resource
class_name TotemData

@export var id: StringName
@export var name: String = ""
@export var short: String = ""
@export var range_type: StringName
@export var effect_key: StringName
@export var values: Dictionary = {}
@export var keywords: PackedStringArray = []
@export_multiline var description: String = ""
@export_multiline var detail_description: String = ""
@export var color: Color = Color.WHITE


func get_validation_issues() -> PackedStringArray:
	var issues := PackedStringArray()

	if id.is_empty():
		issues.append("TotemData.id is required.")
	if name.is_empty():
		issues.append("TotemData.name is required.")
	if range_type.is_empty():
		issues.append("TotemData.range_type is required.")
	if effect_key.is_empty():
		issues.append("TotemData.effect_key is required.")

	return issues
