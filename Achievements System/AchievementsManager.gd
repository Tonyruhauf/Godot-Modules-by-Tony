extends Node



var achievements_list = []

var earned_achievements = []
var events_log = []


func _ready() -> void:
	connect_signals()
	load_save()
	
	for achievement: Achievement in achievements_list:
		for condition in achievement.get_all_conditions_resources():
			condition.achievement = achievement


func load_save():
	if !SaveSystem.SAVE_SYSTEM_ENABLED: return
	await SaveSystem.is_ready()
	achievements_list = SaveSystem.get_saved_value("achievements_list", achievements_list)
	earned_achievements = SaveSystem.get_saved_value("earned_achievements", earned_achievements)


func connect_signals() -> void:
	SignalBus.on_achievement_earned.connect(on_event.bind("achievement_earned"))


func on_event(event_data: Dictionary, event_id: String) -> void:
	var time_in_seconds = Time.get_ticks_msec() / 1000
	event_data["time_in_seconds"] = time_in_seconds
	events_log.append({"id": event_id, "event_data": event_data})
	
	for achievement: Achievement in achievements_list:
		if achievement.is_completed: continue
		if !achievement.triggers.has(event_id): continue
		
		if achievement.is_event_successful(event_data, events_log):
			if events_log[-1].has("event_successful"):
				events_log[-1]["event_successful"].append(achievement.id)
			else:
				events_log[-1]["event_successful"] = [achievement.id]
		
		achievement.check_conditions(event_data, events_log)
		if achievement.is_completed: on_achievement_completed(achievement)
		SaveSystem.queue_save("earned_achievements", earned_achievements)
		SaveSystem.quick_save("achievements_list", achievements_list)


func on_achievement_completed(achievement):
	earned_achievements.append(achievement)
	SignalBus.on_achievement_earned.emit({"achievement": achievement, "achievements_earned_count": earned_achievements.size(), "total_achievements_count": achievements_list.size()})
