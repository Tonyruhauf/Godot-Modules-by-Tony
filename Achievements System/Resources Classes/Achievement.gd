class_name Achievement
extends Resource

@export var id: String
@export_multiline var name: String
@export_multiline var description: String
@export var is_completed := false

@export_category("Logic")
@export var triggers: Array[String] ## Check the "AchievementsManager" in the "connect_signals" function to see all triggers names.
@export var conditions: Array[AchievementCondition]
@export var required_amount: int = 0

@export_storage var current_amount: int = 0


func is_event_successful(event_data: Dictionary, events_log: Array) -> bool:
	for condition in conditions:
		if condition.condition_type == AchievementCondition.ConditionType.CHECK_FOR_TRIGGERS_COUNT:
			continue
		if !condition.is_met(event_data, events_log):
			return false
	return true


func check_conditions(event_data: Dictionary, events_log: Array) -> bool:
	for condition in conditions:
		if !condition.is_met(event_data, events_log):
			return false
	
	current_amount += 1
	is_completed = (current_amount >= required_amount)
	return true


func get_all_conditions_resources(from_condition: AchievementCondition = null) -> Array:
	var conditions_resources = []
	var source = from_condition if from_condition != null else self
	for condition in source.conditions:
		conditions_resources.append(condition)
		if condition.condition_type == AchievementCondition.ConditionType.CONDITIONS_GROUP:
			conditions_resources.append_array(get_all_conditions_resources(condition))
	return conditions_resources
