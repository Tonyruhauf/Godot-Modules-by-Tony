extends Node


var sfx_volume = 0.452
var music_volume = 1.0
var language_locale: String = "en"

var settings_file_path: String = "user://settings.save"


func get_settings():
	var settings = {
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"language_locale": language_locale
	}
	return settings


func set_settings(settings: Dictionary):
	for key in settings:
		set(key, settings[key])


func apply_settings(audio_settings_only: bool = false):
	var settings = get_settings()
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(settings.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.music_volume))
	
	if not audio_settings_only:
		TranslationServer.set_locale(language_locale)


func load_settings_from_file():
	var f = FileAccess.open(settings_file_path, FileAccess.READ)
	if FileAccess.file_exists(settings_file_path):
		set_settings(f.get_var())
		f.close()
	apply_settings()


func save_settings_to_file():
	var f = FileAccess.open(settings_file_path, FileAccess.WRITE)
	f.store_var(GameSettings.get_settings())
	f.close()
