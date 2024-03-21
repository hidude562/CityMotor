extends Node

# idk how big the city tile will be, but it probably wont be 11x11 like the normal tiles
# Each tile is like a road and stuff, or a building, whatever
# if it is the source tile, spawn the scene on it
# if its not the source tile , it serves to demonstrate to the other generation that this spot is taken
class CityTile:
	# Types:
	# -0 = empty stuff
	# -1 = can't anything here (probably not implemmented yet
	var tile = -1
	var sourceTile = false
	
	# 100 will be urban areas
	# 25 is like main road for a small town
	# 10 is outskirts
	
	# this will guide the building style (maybe)
	
	var populus = 0
	
	# 0 is residential, 1 is commercial
	var sector = 0
	
	var height = 0
	
	var size = Vector2i(1,1)
	var hasExpandedItsTiles = false
	
	# building id
	var id = -1
	
	# 0 is inn, 1 is market, 2 is plaza, 3 is generic
	var buildingType = 0
	
	
	func _init(type, sourceTile, populus=0):
		self.tile = type
		self.sourceTile = sourceTile
		self.populus = populus
	
	func setID(id):
		self.id = id

class RoadBuilder:
	var x
	var y
	var orientation
	
	var delete = false
	
	# passed by reference
	var tiles
	var totalIterations
	var subdivision = 1
	var startingPopulus
	
	# valid values are, 0 - commerical, 1 - residential
	var sectorType = 0
	
	var seed = 0
	var populus
	
	var continusePopulusProbability = 10
	var continusePopulusMultiplier = 1.1
	
	var singlePopulusProbability = 5
	var singlePopulusMultiplier = 2.5
	
	
	func _init(x,y,orientation,tiles, subdivision=1, sectorType=0, startingPopulus=15.0, singlePopulusModifier=1.0):
		self.x = x
		self.y = y
		self.orientation = orientation
		self.tiles = tiles
		self.totalIterations = 0
		self.subdivision = subdivision 
		self.startingPopulus = startingPopulus 
		self.populus = calculatePopulus() * singlePopulusModifier
		self.sectorType = sectorType
	
	func markSelfForDeletion():
		delete = true
	
	func calculatePopulus():
		return self.startingPopulus / self.subdivision
	
	func getFork(upDown):
		var orientation = orientation+upDown
		while(orientation < 0):
			orientation+=4
		
		var forkSectorType = self.sectorType
		if(randi()%5 == 0):
			forkSectorType = (self.sectorType + 1) % 2
		
		var populusMultiplier = 1.0
		if(randi()%continusePopulusProbability == 0):
			populusMultiplier=self.continusePopulusMultiplier
			
		var singlePopulusMultiplier = 1.0
		if(randi()%singlePopulusProbability == 0):
			singlePopulusMultiplier=self.singlePopulusMultiplier
		var newRoadBuilder = RoadBuilder.new(x, y, orientation, tiles, subdivision+1, forkSectorType, startingPopulus * populusMultiplier, singlePopulusMultiplier)
		newRoadBuilder.move()
		return newRoadBuilder
	
	
	# Tests for parellel roads right next to each other
	# Returns true if funky
	
	func countRoadType():
		var numTiles = 0
		for y2 in range(y-1,y+2):
			var xTiles = []
			for x2 in range(x-1,x+2):
				if(not(x2 == x and y2 == y)):
					var gotTile = tiles.getTile(x2,y2)
					if(gotTile):
						if gotTile.tile == 1:
							numTiles+=1
		return numTiles
	
	func pave():
		tiles.setTile(x,y, 1, populus, sectorType)
	func unpave():
		tiles.setTile(x,y, 0, 0, 0)
	
	func move():
		if(orientation%4 == 0):
			x+=1
			y+=0
		elif(orientation%4 == 1):
			x+=0
			y+=-1
		elif(orientation%4 == 2):
			x+=-1
			y+=0
		elif(orientation%4 == 3):
			x+=0
			y+=1
		
	func getRandomIfOffbranch():
		var probabilityOf3Size = 2
		var probabilityOf5Size = 4
		var probabilityOf7Size = 8
		
		if(totalIterations < 3):
			pass
		elif(totalIterations < 4):
			if(randf_range(0,probabilityOf3Size) < 1.0):
				return true
		elif(totalIterations < 6):
			if(randf_range(0,probabilityOf5Size) < 1.0):
				return true
		elif(totalIterations < 8):
			if(randf_range(0,probabilityOf7Size) < 1.0):
				return true
		elif(totalIterations == 10):
			return true
		return false
	
	func iterate():
		totalIterations+=1
		
		var countedRoadType = countRoadType()
		
		#print(tiles.inBounds(x,y))
		if(tiles.inBounds(x,y) and tiles.getTile(x,y).tile==0 and countedRoadType < 5):
			pave()
			
			# Whether to fork a new road
			if(getRandomIfOffbranch()):
				var fourwayIntersectionProbability = 20/populus + 8
				if(randf_range(0, fourwayIntersectionProbability) < 8):
					# A 4 way intersection
					return [getFork(1), getFork(-1), getFork(0)]
				else:
					# Only 3 way intersection
					
					var threewayIntersectionProbability = 15/populus + 8
					if(randf_range(0, fourwayIntersectionProbability) < 8):
						return [getFork(1), getFork(-1)]
					else:
						var bendProbability = 10/populus
						if(randf_range(0, fourwayIntersectionProbability) < 8):
							if(randi() % 2 == 0):
								return [getFork(-1)]
							else:
								return [getFork(1)]
						else:
							markSelfForDeletion()
		else:
			if(countRoadType() > 4):
				var orientation = orientation-2
				while(orientation < 0):
					orientation+=4
				while(true):
					move()
					if(countRoadType() > 4):
						unpave()
					else:
						break
			markSelfForDeletion()
		
		move()
		return []


# TODO: Fix source tiles to bottom left, store attribute of size and allat
class City extends Node:
	var tiles = []
	var mapX = 0
	var mapY = 0
	var idCounter = 1
	
	var denisty = -1
	
	func _init(mapX, mapY, denisty=-1):
		self.mapX = mapX
		self.mapY = mapY
		
		self.denisty = denisty
		
		seed(Globals.seedForCity)
		
		for y in range(mapY):
			var xTiles = []
			
			# Construct a 2d array
			for x in range(mapX):
				if(x<2 or x>mapX-3 or y<2 or y>mapY-3):
					xTiles.append(CityTile.new(3, false, 3))
				else:
					xTiles.append(CityTile.new(0, false, 0))
			self.tiles.append(xTiles)
		
		generateRoads()
		calculatePopulus()
		createBuildingTiles()
		
		debugDrawMap()
	func debugDrawMap():
		for y in tiles:
			var str = ""
			for x in y:
				var repr = ""
				
				match x.tile:
					-1:
						repr="X"
					0:
						repr="*"
					1:
						repr=" "
					2:
						if x.sourceTile:
							repr="S"
						else:
							repr="B"
					3:
						repr="P"
				str += repr + " "
			print(str)
	func setTile(x,y,value,populus=0, sector=0):
		if(inBounds(x,y)):
			tiles[y][x].tile = value
			tiles[y][x].populus = populus
			tiles[y][x].sector = sector
		else:
			print("Attempted to set tile!!!!")
	func inBounds(x,y):
		if(x >= 0 and x < mapX and y>=0 and y < mapY):
			return true
		return false
	func getTile(x,y):
		if(inBounds(x,y)):
			return tiles[y][x]
		else:
			return false
	
	# Calculates all of the populus, from the roads (which is determined by the l-system subdivision level)
	func calculatePopulus():
		for y in range(mapY):
			for x in range(mapX):
				if(getTile(x,y).tile == 0):
					var sourounding = getSurroundingTilesOfType(x,y,1)
					var countedPopullus = 0
					var countedRoads = 1
					for j in sourounding:
						if(j.tile == 1):
							countedPopullus+=j.populus
							countedRoads+=1
					tiles[y][x].populus = countedPopullus
				
	func getSurroundingTilesOfType(x,y,type):
		var tiles = []
		for y2 in range(y-1,y+2):
			for x2 in range(x-1,x+2):
				var tile = getTile(x2,y2)
				if(tile):
					if tile.tile == type:
						tiles.append(tile)
		return tiles
	
	func getIfRandomHouse(x,y):
		var scaledPopulus = getTile(x,y).populus ** 1.2
		return randf_range(0.0, 60.0/scaledPopulus + 1) < 1.0
	
	func copyTileToAnother(tile1: Vector2i, tile2: Vector2i):
		# TODO: Implement a method that copies the properties of one to anther
		pass
	
	func randomBuildingExpand(x,y,forceSize=-1):
		var density = getTile(x,y).populus
		
		# A few types of buildings
		# If high density, wider buildings are more likely
		
		
		var probabilityForMaxSize = 1.18 ** x / 8
		var probabilityForMedSize = (1.03 ** x) * 2
		var probabilityForNoSize  = (0.94 ** x) * 8
		
		var totalProbability = probabilityForMaxSize + probabilityForMedSize + probabilityForNoSize
		
		var randomNum = randf_range(0.0, totalProbability)
		if(randomNum < probabilityForMaxSize and (forceSize == -1 or forceSize==0)):
			var canDoRight  = false
			var canDoLeft   = false
			var canDoUp     = false
			var canDoDown   = false
			
			if(getTile(x+1,y)):
				if(getTile(x+1,y).tile == 0):
					canDoRight = true
			if(getTile(x-1,y)):
				if(getTile(x-1,y).tile == 0):
					canDoLeft = true
			if(getTile(x,y-1)):
				if(getTile(x,y-1).tile == 0):
					canDoUp = true
			if(getTile(x,y+1)):
				if(getTile(x,y+1).tile == 0):
					canDoDown = true
			
			
			var movementVector = Vector2i(0,0)
			var numMovementPossibilities = 0
			if(canDoUp and canDoRight):
				movementVector = Vector2i(1,-1)
				numMovementPossibilities+=1
			elif(canDoDown and canDoLeft):
				movementVector = Vector2i(-1,1)
				numMovementPossibilities+=1
			elif(canDoDown and canDoRight):
				movementVector = Vector2i(1,1)
				numMovementPossibilities+=1
			elif(canDoUp and canDoLeft):
				movementVector = Vector2i(-1,-1)
				numMovementPossibilities+=1
			else:
				randomBuildingExpand(x,y,1)
				return
			print(movementVector)
			
			var x2 = x
			var y2 = y
			var iter = 1
			while(true):
				x2+=movementVector.x
				y2+=movementVector.y
				if(getTile(x2,y2).tile == 0):
					var isContinuous = true
					var x3 = x2
					var y3 = y2
					for i in range(iter):
						y3-=movementVector.y
						x3-=movementVector.x
						if(getTile(x2,y3).tile != 0):
							isContinuous = false
						if(getTile(x3,y2).tile != 0):
							isContinuous = false
					x3 = x2
					y3 = y2
					# TODO: fix speghetti
					if(isContinuous):
						tiles[y2][x2].id = tiles[y][x].id
						tiles[y2][x2].tile = tiles[y][x].tile
						tiles[y2][x2].sourceTile = false
						tiles[y2][x2].sector = tiles[y][x].sector
						tiles[y2][x2].populus = tiles[y][x].populus
						tiles[y2][x2].height = tiles[y][x].height
						tiles[y2][x2].size = tiles[y][x].size
						tiles[y2][x2].buildingType = tiles[y][x].buildingType
						for i in range(iter):
							y3-=movementVector.y
							x3-=movementVector.x
							tiles[y3][x2].id = tiles[y][x].id
							tiles[y3][x2].tile = tiles[y][x].tile
							tiles[y3][x2].sourceTile = false
							tiles[y3][x2].sector = tiles[y][x].sector
							tiles[y3][x2].populus = tiles[y][x].populus
							tiles[y3][x2].height = tiles[y][x].height
							tiles[y3][x2].size = tiles[y][x].size
							tiles[y3][x2].buildingType = tiles[y][x].buildingType
							
							tiles[y2][x3].id = tiles[y][x].id
							tiles[y2][x3].tile = tiles[y][x].tile
							tiles[y2][x3].sourceTile = false
							tiles[y2][x3].sector = tiles[y][x].sector
							tiles[y2][x3].populus = tiles[y][x].populus
							tiles[y2][x3].height = tiles[y][x].height
							tiles[y2][x3].size = tiles[y][x].size
							tiles[y2][x3].buildingType = tiles[y][x].buildingType
							
					else:
						break
				else:
					break
				if randf_range(0, sqrt(density) / 4 + 1) < iter or iter > 2:
					break
				iter+=1
		elif(randomNum < probabilityForMaxSize + probabilityForMedSize  and (forceSize == -1 or forceSize==1)):
			var canDoRight  = false
			var canDoLeft   = false
			var canDoUp     = false
			var canDoDown   = false
			
			if(getTile(x+1,y)):
				if(getTile(x+1,y).tile == 0):
					canDoRight = true
			if(getTile(x-1,y)):
				if(getTile(x-1,y).tile == 0):
					canDoLeft = true
			if(getTile(x,y-1)):
				if(getTile(x,y-1).tile == 0):
					canDoUp = true
			if(getTile(x,y+1)):
				if(getTile(x,y+1).tile == 0):
					canDoDown = true
			
			# choose random dir to expand
			while true:
				var random = randi() % 4
				if(random == 0 and canDoRight):
					tiles[y][x+1].id = tiles[y][x].id
					tiles[y][x+1].tile = tiles[y][x].tile
					tiles[y][x+1].sourceTile = false
					tiles[y][x+1].sector = tiles[y][x].sector
					tiles[y][x+1].populus = tiles[y][x].populus
					tiles[y][x+1].height = tiles[y][x].height
					tiles[y][x+1].size = tiles[y][x].size
					tiles[y][x+1].buildingType = tiles[y][x].buildingType
					break
				if(random == 1 and canDoLeft):
					tiles[y][x-1].id = tiles[y][x].id
					tiles[y][x-1].tile = tiles[y][x].tile
					tiles[y][x-1].sourceTile = false
					tiles[y][x-1].sector = tiles[y][x].sector
					tiles[y][x-1].populus = tiles[y][x].populus
					tiles[y][x-1].height = tiles[y][x].height
					tiles[y][x-1].size = tiles[y][x].size
					tiles[y][x-1].buildingType = tiles[y][x].buildingType
					break
				if(random == 2 and canDoDown):
					tiles[y+1][x].id = tiles[y][x].id
					tiles[y+1][x].tile = tiles[y][x].tile
					tiles[y+1][x].sourceTile = false
					tiles[y+1][x].sector = tiles[y][x].sector
					tiles[y+1][x].populus = tiles[y][x].populus
					tiles[y+1][x].height = tiles[y][x].height
					tiles[y+1][x].size = tiles[y][x].size
					tiles[y+1][x].buildingType = tiles[y][x].buildingType
					break
				if(random == 3 and canDoUp):
					tiles[y-1][x].id = tiles[y][x].id
					tiles[y-1][x].tile = tiles[y][x].tile
					tiles[y-1][x].sourceTile = false
					tiles[y-1][x].sector = tiles[y][x].sector
					tiles[y-1][x].populus = tiles[y][x].populus
					tiles[y-1][x].height = tiles[y][x].height
					tiles[y-1][x].size = tiles[y][x].size
					tiles[y-1][x].buildingType = tiles[y][x].buildingType
					
					
					break
				
				if(not (canDoUp or canDoDown or canDoLeft or canDoRight)):
					break
				
			
		else:
			pass
	
	# The source of buildings from where to grow from
	func createBuildingTiles():
		for i in range(mapX*mapY * 10):
			var x = randi() % self.mapX
			var y = randi() % self.mapY
			if(tiles[y][x].tile == 0):
				if(getIfRandomHouse(x,y)):
					tiles[y][x].sourceTile = true
					tiles[y][x].tile = 2
					
					var roadTiles = getSurroundingTilesOfType(x,y,1)
					tiles[y][x].sector = roadTiles[randi()%len(roadTiles)].sector
					tiles[y][x].setID(idCounter)
					idCounter+=1
					
					randomBuildingExpand(x,y)
		
		# Tries to get the bottom left of the building
		for y in range(mapY):
			for x in range(mapX):
				if getTile(x,y).sourceTile and (not getTile(x,y).hasExpandedItsTiles):
					var newSourceTile = Vector2i(x,y)
					var leftMost = x
					var rightMost = x
					var downMost = y
					var upMost = y
					var highestPop = getTile(x,y).populus
					
					# TODO: go down, left, and calculate using that.
					# because this is bad and inneficieint
					for y2 in range(y-3, y+4):
						for x2 in range(x-3, x+4):
							if getTile(x2,y2):
								if(getTile(x2,y2).id == getTile(x,y).id):
									if(y2 >= downMost and x2 <= leftMost):
										tiles[y][x].sourceTile = false
										tiles[y2][x2].sourceTile = true
										
										newSourceTile = Vector2i(x2,y2)
									if(x2<leftMost):
										leftMost=x2
									if(x2>rightMost):
										rightMost=x2
									if(y2<upMost):
										upMost=y2
									if(y2>downMost):
										downMost=y2
									if(getTile(x,y).populus > highestPop):
										highestPop = getTile(x,y).populus
					var sizeX = rightMost-leftMost + 1
					var sizeY = downMost-upMost + 1
					
					print(sizeX, " ", sizeY)
					
					tiles[newSourceTile.y][newSourceTile.x].hasExpandedItsTiles = true
					tiles[newSourceTile.y][newSourceTile.x].size = Vector2i(sizeX,sizeY)
					#tiles[newSourceTile.y][newSourceTile.x].populus = highestPop
					
					var newPopulus = tiles[newSourceTile.y][newSourceTile.x].populus
					
					var area = sizeX * sizeY
					var populusModifier = (newPopulus / (newPopulus + area * 80)) * area * 80
					tiles[newSourceTile.y][newSourceTile.x].populus = populusModifier
					
		
		
		
	
	# l system goes brrrr
	func generateRoads():
		var roadBuilders = [
			RoadBuilder.new(int(mapX/2),int(mapY/2),0, self),
			RoadBuilder.new(int(mapX/2)-1,int(mapY/2),2, self),
			
			RoadBuilder.new(int(mapX/2),int(mapY/2)+1,1, self),
			RoadBuilder.new(int(mapX/2),int(mapY/2)-1,3, self)
		]
		
		var roadBuildingIter = 0
		while len(roadBuilders) > 0:
			#print(roadBuilders)
			for i in roadBuilders:
				var forks = i.iterate()
				if(len(forks) > 0):
					roadBuilders += forks
			
			var i = 0
			while i < len(roadBuilders):
				if(roadBuilders[i].delete):
					roadBuilders.remove_at(i)
					i-=1
				i+=1
			
			var counted = 0
			for j in roadBuilders:
				#print(i)
				if(j.delete):
					counted+=1
			roadBuildingIter+=1
			
			if (denisty != -1):
				if(roadBuildingIter > denisty):
					break

