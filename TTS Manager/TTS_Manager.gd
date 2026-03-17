extends Node


var http_request: HTTPRequest

const API_KEY = "INSERT YOUR API KEY"
const TTS_URL = "https://texttospeech.googleapis.com/v1/text:synthesize?key="

var voices_previews = {
	Voice.AOEDE: load("res://modules/TTS Manager/resources/previews/Aoede preview.tres"),
	Voice.PUCK: load("res://modules/TTS Manager/resources/previews/Puck preview.tres"),
	Voice.CHARON: load("res://modules/TTS Manager/resources/previews/Charon preview.tres"),
	Voice.KORE: load("res://modules/TTS Manager/resources/previews/Kore preview.tres"),
	Voice.FENRIR: load("res://modules/TTS Manager/resources/previews/Fenrir preview.tres"),
	Voice.LEDA: load("res://modules/TTS Manager/resources/previews/Leda preview.tres"),
	Voice.ORUS: load("res://modules/TTS Manager/resources/previews/Orus preview.tres"),
	Voice.ZEPHYR: load("res://modules/TTS Manager/resources/previews/Zephyr preview.tres")
}

enum Voice {
	AOEDE,
	PUCK,
	CHARON,
	KORE,
	FENRIR,
	LEDA,
	ORUS,
	ZEPHYR
}


func generate_speech(text: String, language_code: String, voice: Voice) -> PackedByteArray:
	if !is_instance_valid(http_request):
		http_request = HTTPRequest.new()
		http_request.request_completed.connect(_on_request_completed)
		add_child(http_request)
	
	var headers = ["Content-Type: application/json"]
	
	var voice_string = Voice.find_key(voice)
	
	# Build the payload specific to Chirp 3: HD
	var payload = {
		"input": {
			"text": text
		},
		"voice": {
			"languageCode": language_code, # en-US
			"name": "%s-Chirp3-HD-%s" % [language_code, voice_string]
		},
		"audioConfig": {
			"audioEncoding": "MP3"
		}
	}
	
	var json_payload = JSON.stringify(payload)
	
	var error = http_request.request(TTS_URL + API_KEY, headers, HTTPClient.METHOD_POST, json_payload)
	if error != OK:
		print("An error occurred while making the HTTP request.")
		return []
	
	var signal_result = await http_request.request_completed
	var response_code = signal_result[1]
	var body = signal_result[3]
	
	if response_code == 200:
		var response_string = body.get_string_from_utf8()
		var json = JSON.parse_string(response_string)
		
		if json and json.has("audioContent"):
			var base64_audio = json["audioContent"]
			var audio_bytes = Marshalls.base64_to_raw(base64_audio)
			return audio_bytes
	
	return []


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		print("API Error: ", response_code)
		print("Details: ", body.get_string_from_utf8())


func get_voice_preview(voice: Voice):
	return voices_previews[voice]
