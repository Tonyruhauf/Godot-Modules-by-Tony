class_name Layer
extends Resource

var name: String = "New Layer"
var draw_order: int = 0
var selected_sub_layer: String = "lines"
var content = {
	"lines": [] as Array[Dictionary],
	"fill": [] as Array[Dictionary]
}

enum SubLayer {
	LINES,
	FILL
}


func get_active_sub_layer():
	return content[selected_sub_layer]
