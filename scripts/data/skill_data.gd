extends Resource
class_name SkillData

@export var id: StringName
@export var name: String = ""
@export var rarity: StringName
@export var category: StringName
@export var targeting_type: StringName
@export var effect_key: StringName
@export var cooldown: int = 0
@export var consumes_action: bool = true
@export var action_cost: int = 1
@export var values: Dictionary = {}
@export var keywords: PackedStringArray = []
@export_multiline var description: String = ""
@export_multiline var detail_description: String = ""
@export var icon: Texture2D


func get_validation_issues() -> PackedStringArray:
	var issues := PackedStringArray()

	if id.is_empty():
		issues.append("SkillData.id is required.")
	if name.is_empty():
		issues.append("SkillData.name is required.")
	if rarity.is_empty():
		issues.append("SkillData.rarity is required.")
	if category.is_empty():
		issues.append("SkillData.category is required.")
	if targeting_type.is_empty():
		issues.append("SkillData.targeting_type is required.")
	if effect_key.is_empty():
		issues.append("SkillData.effect_key is required.")
	if cooldown < 0:
		issues.append("SkillData.cooldown cannot be negative.")
	if action_cost < 0:
		issues.append("SkillData.action_cost cannot be negative.")

	return issues
