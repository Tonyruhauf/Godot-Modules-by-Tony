extends Node

# Class Version: 1.1.1


# -- SETTINGS --
const file_path := "user://save_data.tres"
const backup_file_path := "user://save_data_backup.tres"
const SAVE_SYSTEM_ENABLED := true  # Just set this to false to disable user saves for your project.
const SAVING_DELAY := 0  # In seconds (set this to 0 to disable it)
# ________

var SaveFileData = SaveDataResource.new()
var save_is_loaded := false
var save_locked := false

signal save_loaded


func _ready():
	await load_save_file()
	await get_tree().process_frame
	save_is_loaded = true
	save_loaded.emit()
	
	if SAVING_DELAY != 0:
		var timer = Timer.new()
		timer.wait_time = SAVING_DELAY
		timer.autostart = true
		timer.one_shot = false
		timer.timeout.connect(save)
		add_child(timer)


func is_ready():
	if !save_is_loaded: await save_loaded


func get_saved_value(key: String, default):
	if !SAVE_SYSTEM_ENABLED: return default
	if !is_instance_valid(SaveFileData): return default
	if SaveFileData.saved_values.keys().has(key):
		return SaveFileData.saved_values[key]
	else:
		return default


func queue_save(key: String, value):
	if !SAVE_SYSTEM_ENABLED: return
	if !is_instance_valid(SaveFileData): return
	SaveFileData.set_value(key, check_and_duplicate_resources(value))
	#if !SaveFileData.saved_values.has(key): SaveFileData.saved_values.append(key)


func check_and_duplicate_resources(value):
	if value is Array:
		var result_value = []
		for item in value:
			result_value.append(check_and_duplicate_resources(item))
		return result_value
	
	if value is Dictionary:
		var result_value = {}
		for key in value:
			result_value[key] = check_and_duplicate_resources(value[key])
		return result_value
	
	if value is Resource:
		return value.duplicate(true)
	
	return value


func load_save_file():
	if save_locked: return
	
	if FileAccess.file_exists(file_path):
		SaveFileData = ResourceLoader.load(file_path)
	else:
		SaveFileData = null
	
	if !is_instance_valid(SaveFileData):
		if FileAccess.file_exists(backup_file_path):
			SaveFileData = ResourceLoader.load(backup_file_path)
		else:
			SaveFileData = SaveDataResource.new()


func save():
	if !SAVE_SYSTEM_ENABLED: return
	if !save_locked:
		ResourceSaver.save(SaveFileData, file_path)
		await get_tree().create_timer(1).timeout
		var new_save = ResourceLoader.load(file_path)
		if is_instance_valid(new_save): ResourceSaver.save(SaveFileData, backup_file_path)


func quick_save(key: String, value):
	if !SAVE_SYSTEM_ENABLED: return
	queue_save(key, value)
	await get_tree().process_frame
	save()


func delete_savefile(delete_backup: bool):
	save_locked = true
	DirAccess.remove_absolute(file_path)
	if delete_backup: DirAccess.remove_absolute(backup_file_path)


func _exit_tree() -> void:
	save()
