extends Node

const UNSPLASH_ACCESS_KEY = "INSERT YOUR API KEY"
const PEXELS_API_KEY = "INSERT YOUR API KEY"

var unsplash_http: HTTPRequest
var pexels_http: HTTPRequest


func _ready() -> void:
	unsplash_http = HTTPRequest.new()
	add_child(unsplash_http)
	unsplash_http.request_completed.connect(_on_unsplash_search_completed)
	
	pexels_http = HTTPRequest.new()
	add_child(pexels_http)
	pexels_http.request_completed.connect(_on_pexels_search_completed)


# --- UNSPLASH ---
func search_unsplash(query: String) -> Array:
	print("[Unsplash] Searching for: ", query)
	var url = "https://api.unsplash.com/search/photos?query=" + query.uri_encode() + "&per_page=3"
	
	var headers = [
		"Authorization: Client-ID " + UNSPLASH_ACCESS_KEY,
		"Accept-Version: v1"
	]
	
	var error = unsplash_http.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		push_error("Failed to start Unsplash HTTP request.")
		return []
	
	var signal_result = await unsplash_http.request_completed
	var response_code = signal_result[1]
	var body = signal_result[3]
	var urls = []
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			var photos = data.get("results", [])
			for photo in photos:
				urls.append(photo["urls"]["regular"])
	else:
		push_error("[Unsplash] API Request failed. Code: ", response_code)
	
	return urls


func _on_unsplash_search_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			var photos = data.get("results", [])
			
			print("\n--- Unsplash Results ---")
			for photo in photos:
				var author = photo["user"]["name"]
				var image_url = photo["urls"]["regular"]
				print("Photo by %s: %s" % [author, image_url])
	else:
		push_error("[Unsplash] API Request failed. Code: ", response_code)


# --- PEXELS ---
func search_pexels(query: String) -> Array:
	print("[Pexels] Searching for: ", query)
	var url = "https://api.pexels.com/v1/search?query=" + query.uri_encode() + "&per_page=3"
	
	var headers = [
		"Authorization: " + PEXELS_API_KEY
	]
	
	var error = pexels_http.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		push_error("Failed to start Pexels HTTP request.")
		return []
	
	var signal_result = await pexels_http.request_completed
	var response_code = signal_result[1]
	var body = signal_result[3]
	var urls = []
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			var photos = data.get("photos", [])
			for photo in photos:
				urls.append(photo["src"]["large"])
	else:
		push_error("[Pexels] API Request failed. Code: ", response_code)
	
	return urls


func _on_pexels_search_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			var photos = data.get("photos", [])
			
			print("\n--- Pexels Results ---")
			for photo in photos:
				var author = photo["photographer"]
				# Pexels provides sizes in the "src" dictionary (e.g., original, large, medium, small)
				var image_url = photo["src"]["large"] 
				print("Photo by %s: %s" % [author, image_url])
	else:
		push_error("[Pexels] API Request failed. Code: ", response_code)


func download_image_from_url(url: String) -> ImageTexture:
	print("Downloading image: ", url)
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url)
	
	var response = await http.request_completed
	var response_code = response[1]
	var body = response[3]
	
	http.queue_free()
	
	if response_code == 200:
		var image = Image.new()
		
		var error = image.load_jpg_from_buffer(body)
		
		if error != OK:
			error = image.load_png_from_buffer(body)
			
		if error == OK:
			return ImageTexture.create_from_image(image)
		else:
			push_error("Failed to decode image data into a texture.")
	else:
		push_error("Failed to download image from URL. Code: ", response_code)
	
	return null
