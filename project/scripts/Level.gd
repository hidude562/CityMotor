extends Node

var procedualBuilding = preload("res://scenes/procedualBuilding.tscn")
var procedualRoad = preload("res://scenes/procedualRoad.tscn")
var procedualNothing = preload("res://scenes/procedualNothing.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configured for a smallish town
	var map = Globals.currentCity
	
	if Globals.currentCity == null:
		map = get_node("/root/root").City.new(20, 20, -1)
		Globals.currentCity = map
	map.debugDrawMap()
	
	var walls = []
	var playerPositionSet = false
	
	for i in range(map.mapX):
		for j in range(map.mapY):
			var stencil_pos
			# assigns stencil location based on generation
			if map.tiles[j][i].tile == 1:
				var scene = procedualRoad
				
				var left = 0
				var up = 0
				var right = 0
				var down = 0
				if i > 0:
					if map.tiles[j][i-1].tile != 1:
						left = 1
				if j > 0:
					if map.tiles[j-1][i].tile != 1:
						up = 1
				if i < map.mapX - 1:
					if map.tiles[j][i+1].tile != 1:
						right = 1
				if j < map.mapY - 1:  
					if map.tiles[j+1][i].tile != 1:
						down = 1
				
				name = str(down * 2 + right) + str(1 * (up * 2 + left))
				var instance = scene.instantiate()
				
				var children = instance.get_children()
				for child in children:
					if child.name != name:
						child.queue_free()
					else:
						child.show()
						child.rotate_y(deg_to_rad(-90))
				add_child(instance)
				instance.global_position = Vector3(i, 0, j)
			elif map.tiles[j][i].tile == 2 and map.tiles[j][i].sourceTile:
				var scene = procedualBuilding
				var instance = scene.instantiate()
				add_child(instance)
				instance.global_position = Vector3(i, 0, j)
				instance.drawBuilding(map.tiles[j][i].size.x,map.tiles[j][i].populus / 10 + 0.2,map.tiles[j][i].size.y, map.tiles[j][i].sector)
			elif map.tiles[j][i].tile == 0:
				var scene = procedualNothing
				var instance = scene.instantiate()
				add_child(instance)
				instance.global_position = Vector3(i, 0, j)
