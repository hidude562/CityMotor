extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func drawBuilding(length, height, width, sector):
	global_scale(Vector3(length, height, width))
	position-= Vector3((length - 1.0) / -2.0, 0, (width - 1.0) / 2.0)
	
	for child in get_children():
		if child.name != str(sector):
			child.queue_free()
		else:
			child.show()
			child.rotate_y(deg_to_rad(-90))
