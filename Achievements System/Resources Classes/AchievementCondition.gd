@tool
class_name AchievementCondition
extends Resource

enum ConditionType {
	MATCH_FILTER,
	VALUE_COMPARISON,
	CHECK_FOR_TRIGGERS_COUNT,
	CONDITIONS_GROUP,
	#EVENTS_LOG_CHECK
}

enum ValueComparator {
	BIGGER,
	SMALLER,
}

var achievement: Achievement
@export var condition_type: ConditionType:
	set(value):
		condition_type = value
		notify_property_list_changed()

@export var filter: Dictionary[String, Variant] = {}  ## Example: {"enemy_type": "goblin", "weapon": "bow"}.

@export var value_name: String
@export var comparator: ValueComparator
@export var allow_equal := false
@export var comparison_value: String
@export var change_comparison_value_by: int

@export var trigger_event_id: String
@export var min_triggers_count: int = 0
@export var max_elapsed_time: float = 0.0 ## In seconds
@export var succesful_triggers_only: bool = true ## Return false if the previous trigger in the events log did't met all the conditions.

@export var conditions: Array[AchievementCondition]
@export_enum("All", "Any") var validation_method = "All"
@export var required_count: int = 1
@export_storage var validity_count: int = 0


func _validate_property(property: Dictionary):
	var affected_properties = []
	
	affected_properties = ["filter"]
	if affected_properties.has(property.name) and condition_type != ConditionType.MATCH_FILTER:
		property.usage = PROPERTY_USAGE_READ_ONLY
	
	affected_properties = [
		"value_name", "comparator",
		"allow_equal", "comparison_value", "change_comparison_value_by"
	]
	if affected_properties.has(property.name) and condition_type != ConditionType.VALUE_COMPARISON:
		property.usage = PROPERTY_USAGE_READ_ONLY
	
	affected_properties = [
		"trigger_event_id", "min_triggers_count",
		"max_elapsed_time", "succesful_triggers_only"
	]
	if affected_properties.has(property.name) and condition_type != ConditionType.CHECK_FOR_TRIGGERS_COUNT:
		property.usage = PROPERTY_USAGE_READ_ONLY
	
	affected_properties = ["conditions", "validation_method", "required_count"]
	if affected_properties.has(property.name) and condition_type != ConditionType.CONDITIONS_GROUP:
		property.usage = PROPERTY_USAGE_READ_ONLY


func is_met(event_data: Dictionary, events_log: Array):
	match condition_type:
		
		ConditionType.MATCH_FILTER:
			for key in filter:
				if Toolbox.get_nested_value_in_dict(event_data, key) != filter[key]: return false
			return true
		
		ConditionType.VALUE_COMPARISON:
			var _comparison_value
			if comparison_value.is_valid_int() or comparison_value.is_valid_float():
				_comparison_value = str_to_var(comparison_value)
			else:
				_comparison_value = Toolbox.get_nested_value_in_dict(event_data, comparison_value)
			_comparison_value += change_comparison_value_by
			
			if allow_equal and event_data[value_name] == _comparison_value:
				return true
			
			match comparator:
				ValueComparator.BIGGER:
					return event_data[value_name] > _comparison_value
				ValueComparator.SMALLER:
					return event_data[value_name] < _comparison_value
		
		ConditionType.CHECK_FOR_TRIGGERS_COUNT:
			var count := 0
			for event in events_log:
				if event.id != trigger_event_id: continue
				if !event.event_successful.has(achievement.id) and succesful_triggers_only: continue
				if max_elapsed_time != 0.0:
					var min_time = (Time.get_ticks_msec() / 1000) - max_elapsed_time
					if event.event_data.time_in_seconds < min_time: continue
				count += 1
			return count >= min_triggers_count
		
		ConditionType.CONDITIONS_GROUP:
			var conditions_are_met = true if validation_method == "All" else false
			for condition in conditions:
				if validation_method == "All":
					if !condition.is_met(event_data, events_log): conditions_are_met = false
				else:
					if condition.is_met(event_data, events_log): conditions_are_met = true
			if conditions_are_met: validity_count += 1
			return validity_count >= required_count
	
	return false
