@tool
extends Node

const GROQ_API_KEY = "INSERT YOUR API KEY"

var http_request: HTTPRequest
var generated_text: String = ""

signal text_generated
signal request_failed

# It seems that those are the best models:
# openai/gpt-oss-120b  <-- THE BEST MODEL AT THE TIME OF WRITING THIS
# llama-3.3-70b-versatile
# llama-3.2-90b-vision-preview


func _setup_http_request() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(on_http_request_completed)


func query_prompt(prompt:String, model:String = "openai/gpt-oss-120b"):
	if !is_instance_valid(http_request):
		_setup_http_request()
	
	var query = {
		"messages": [
			{
				"role": "user",
				"content": prompt
			}
		],
		"model": model
	}
	
	var headers = [
		"Authorization: Bearer " + GROQ_API_KEY,
		"Content-Type: application/json",
	]
	
	var json = JSON.new()
	var json_body = json.stringify(query)
	
	var err = http_request.request("https://api.groq.com/openai/v1/chat/completions", headers, HTTPClient.METHOD_POST, json_body)
	
	if err != OK:
		emit_signal("request_failed")
		print("Request failed: ", err)
		return
	
	await http_request.request_completed
	await get_tree().process_frame
	
	emit_signal("text_generated", generated_text)
	return generated_text


func encode_image(image_path: String) -> String:
	var file = FileAccess.open(image_path, FileAccess.READ)
	
	if file:
		var image_data = file.get_buffer(file.get_length())
		file.close()
		return Marshalls.variant_to_base64(image_data)
	return ""


func query_prompt_with_image(prompt:String, image:Image, model:String = "llama-3.2-90b-vision-preview"):
	var base64_image = encode_image(image.resource_path)
	
	var query = {
		"messages": [
			{
				"role": "user",
				"content": [
					{
						"type": "text",
						"text": prompt
					},
					{
					"type": "image_url",
					"image_url": {
						"url": "data:image/jpeg;base64,%s" % base64_image
					}
					}
				]
			}
		],
	}
	
	var headers = [
		"Authorization: Bearer " + GROQ_API_KEY,
		"Content-Type: application/json",
	]
	
	var json = JSON.new()
	var json_body = json.stringify(query)
	
	var err = http_request.request("https://api.groq.com/openai/v1/chat/completions", headers, HTTPClient.METHOD_POST, json_body)
	
	if err != OK:
		emit_signal("request_failed")
		print("Request failed: ", err)
		return
	
	await http_request.request_completed
	await get_tree().process_frame
	
	emit_signal("text_generated", generated_text)
	return generated_text


func on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		generated_text = response.choices[0].message.content
	else:
		emit_signal("request_failed")
		print("HTTP Request failed with code: ", response_code)
