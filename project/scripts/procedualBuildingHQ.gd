extends Node3D

var buildingBase = preload("res://scenes/building_base.tscn")

class Inset:
	var angle
	var depth
	var insetType
	var isGabled
	
	func _init(angle, depth, insetType, isGabled):
		self.angle = angle
		self.depth = depth
		self.insetType = insetType
		self.isGabled = isGabled

class BuildingSectionPrefab:
	var probsForInsets
	var maxInsets
	var minInsets
	var minInsetDepth
	var maxInsetDepth
	var isGabled
	
	# -1 = no limit
	var heightMax
	
	# 2 = normal even
	var angledInsetsWeighting
	var nonSlantedCornerProbability
	func _init(heightMax=-1, minInsets=0, maxInsets=2, probForInsets=2, angledInsetsWeighting=2, minInsetDepth=0.1, maxInsetDepth=0.3, nonSlantedCornerProbability=2):
		self.probsForInsets = probForInsets
		self.angledInsetsWeighting = angledInsetsWeighting
		self.maxInsets = maxInsets
		self.minInsets = minInsets
		self.minInsetDepth = minInsetDepth
		self.maxInsetDepth = maxInsetDepth
		self.heightMax = heightMax
		self.nonSlantedCornerProbability = nonSlantedCornerProbability
	
	func getInsets():
		var insets = []
		while(true):
			if(insets.size() > maxInsets):
				break
			
			var ran = randf_range(0.0, probsForInsets)
			# If spawn inset
			if(ran < 1.0):
				# Choose whether to spawn 45 degree or head on inset
				var ran2 = randf_range(0.0, angledInsetsWeighting)
				if(ran2 < 1.0):
					var insetDepth = randf_range(minInsetDepth, maxInsetDepth)
					var insetAngle = (round(randi_range(0,360) / 90) * 2) % 8
					insets.append(Inset.new(insetAngle,insetDepth,0,isGabled))
				else:
					# Slanted corner
					var ran3 = randf_range(0.0, angledInsetsWeighting)
					if(ran3 < 1.0):
						var insetDepth = randf_range(minInsetDepth, maxInsetDepth)
						var insetAngle = round(randi_range(0,360) / 45) % 8
						insets.append(Inset.new(insetAngle,insetDepth,0,isGabled))
					else:
						#Non-slanted corner
						var insetDepth = randf_range(minInsetDepth, maxInsetDepth)
						var insetAngle = round(randi_range(0,360) / 90) % 4
						insets.append(Inset.new(insetAngle,insetDepth,1,isGabled))
			else:
				if(insets.size() >= minInsets):
					break
		return insets

class BuildingSection:
	var prefab
	var height
	func _init(prefab):
		self.prefab = prefab
		self.height = prefab.heightMax

class FullBuildingPrefab:
	var sections = []
	func _init(sections):
		self.sections = sections

class FullBuilding:
	var prefab
	var sections
	var height
	
	func _init(prefab, height):
		self.prefab = prefab
		self.height = height
		self.sections = []
		for section in prefab.sections:
			self.sections.append(BuildingSection.new(section))
	func allocateSpace():
		var numVariableSize = 0
		var sizeRemaining = height
		for section in sections:
			if (section.height == -1):
				numVariableSize+=1
			else:
				sizeRemaining -= section.height
		
		for section in sections:
			if (section.height == -1):
				section.height = sizeRemaining / numVariableSize

func sideInset(inset, node):
	var childIndex = inset.angle
	if inset.isGabled:
		var child = node.get_child(12)
		#child.transform.siz += inset.depth
		child.show()
	elif(inset.insetType == 0):
		var child = node.get_child(childIndex)
		child.depth += inset.depth
		child.show()
	else:
		var child = node.get_child(8+childIndex)
		child.depth += inset.depth
		child.show()

func drawBuildingFromPreset(length, height, width, preset):
	var fullBuilding = FullBuilding.new(preset, height)
	fullBuilding.allocateSpace()
	var heightAt = 0
	var previousInsets = []
	
	var newPart = buildingBase.instantiate()
	newPart.scale = Vector3(length, width, 1)
	
	newPart.position -= Vector3(0, 0, (width - 1.0) * 1)
	# newPart.position += Vector3(0.5, 0, 0.5)
	
	for section in fullBuilding.sections:
		newPart.depth = section.height
		# TODO no negative for clarity
		#newPart.position= -Vector3((length - 1.0) / -2.0, -heightAt, (width - 1.0) / 2.0)
		newPart.position.y=heightAt
		
		var insets = section.prefab.getInsets()
		
		for inset in insets:
			sideInset(inset, newPart)
		
		add_child(newPart)
		
		newPart = newPart.duplicate()
		
		heightAt += section.height

func drawBuilding(length, height, width, sector):
	var skyscraperPreset = FullBuildingPrefab.new(
		[
			BuildingSectionPrefab.new(0.4, 0, 0),
			BuildingSectionPrefab.new(-1, 1, 3, 1.5,2,0.1,0.2),
			BuildingSectionPrefab.new(-1, 1, 3, 1.5,2,0.1,0.2),
			BuildingSectionPrefab.new(-1, 1, 3, 1.5,2,0.1,0.2),
			BuildingSectionPrefab.new(-1, 1, 3, 1.5,2,0.1,0.2)
		]
	)
	
	var highDensityPreset = FullBuildingPrefab.new(
		[
			BuildingSectionPrefab.new(0.35, 0, 0),
			BuildingSectionPrefab.new(-1,0,2,2,1.2),
		]
	)
	
	# heightMax=-1, minInsets=0, maxInsets=2, probForInsets=2, angledInsetsWeighting=2, minInsetDepth=0.1, maxInsetDepth=0.3, nonSlantedCornerProbability=2
	
	var gabledRoof = BuildingSectionPrefab.new(0.5,-1,0)
	gabledRoof.isGabled = true
	
	var residentialLowDensityPreset = FullBuildingPrefab.new(
		[
			BuildingSectionPrefab.new(-1,0,1,2,5,0.1,0.2,1000),
			#gabledRoof
		]
	)
	
	var ruleset = 0
	var rulesets = [skyscraperPreset, highDensityPreset, residentialLowDensityPreset]
	
	if(height > 3):
		ruleset = 0
	elif(height>1.8):
		ruleset = 1
	else:
		if sector == 0:
			ruleset = 2
			#height+=1
		else:
			ruleset = 1
		
	drawBuildingFromPreset(length,height,width,rulesets[ruleset])
	#sideInset(45, 0.2)
	#sideInset(0, 0.2)
