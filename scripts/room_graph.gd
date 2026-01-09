extends GraphEdit

# How many rooms to run this test with.
@export var room_count := 100

enum GENERATION_SHAPE {CIRCLE, GRID}
@export var generation_shape := GENERATION_SHAPE.GRID
@export var spread := 1000.0

var ROOMSCENE = preload("res://room_node.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Create the rooms.
	var rooms:Array[RoomNode] = create_rooms()
	
	# Shuffle the rooms. (Make the connections.)
	shuffle(rooms)
	
	# Color each room's ports based on if there's any 
	# other connection between the same two nodes.
	color_rooms(rooms)

## MANIPULATING ROOMS

func create_rooms() -> Array[RoomNode]:
	var response:Array[RoomNode]
	
	# Create the rooms.
	@warning_ignore("unused_variable")
	var grid_size = int(floor(sqrt(room_count)))
	# Create the faux rooms
	for i in range(room_count):
		var new:RoomNode = ROOMSCENE.instantiate()
		
		match generation_shape:
			GENERATION_SHAPE.GRID:
				new.position_offset = Vector2(i % grid_size, floor(float(i) / grid_size)) * spread
			GENERATION_SHAPE.CIRCLE:
				new.position_offset = Vector2(sin(i), cos(i)) * spread
		
		add_child(new)
		
		response.append(new)
	
	return response

func shuffle(rooms:Array[RoomNode]):
	
	## Loop (Assumes no 1-doors)
	for i in range(len(rooms)):
		# Connect every door to its next, and the last to the first.
		link_doors(rooms[i], 0, rooms[0 if i == len(rooms) - 1 else i + 1], 1)
	
	## Resolve (Connect all the rest of the doors).
	var not_done:Array[Room.Door]
	for room in rooms:
		for door in room.data.doors: if not door.connected_to: not_done.append(door)
	
	if len(not_done) % 2: push_warning("ODD NUMBER OF DOORS. CANNOT SOLVE.")
	
	# Shuffle so it's unlikely to do doors from the same room in sequence.
	# IE, so two doors from one room are less likely to connect to the same room.
	not_done.shuffle() 
	for door in not_done:
		if door.connected_to: continue
		find_connection_for(door, score_sort(door, not_done))

# Returns the room array, sorted according to score_against(), low to high.
func score_sort(to:Room.Door, arr:Array) -> Array:
	var array:Array[Room.Door]
	
	for item in arr:
		if item is Room.Door: array.append(item)
		elif item is Room: array.append_array(item.doors)
		elif item is RoomNode: array.append_array(item.data.doors)

	# Sorts the array via merge sort.
	var length = len(array)
	
	if length <= 1: return array
	
	@warning_ignore("integer_division")
	var left = array.slice(0, floor((length + 1) / 2))
	@warning_ignore("integer_division")
	var right = array.slice(floor((length + 1) / 2), length)
	
	
	left  = score_sort(to, left)
	right = score_sort(to, right)
	
	# The array's already sorted.
	if   len(left)  <= 0: return right
	elif len(right) <= 0: return left
	
	var li = 0
	var ri = 0
	
	var response:Array[Room.Door]

	while len(response) < len(left) + len(right):
		
		# One of the arrays is empty; append the other and end.
		if li >= len(left): 
			response.append_array(right.slice(ri))
			break
		elif ri >= len(right):
			response.append_array(left.slice(li))
			break
		
		# Define the condition for switching left[li] and right[ri]
		# print(li, " / ", ri)
		var condition = score_against(left[li], to) > score_against(right[ri], to)
		
		# Otherwise, append the next.
		if condition: 
			response.append(right[ri])
			ri += 1
		else:
			response.append(left[li])
			li += 1
	
	return response

# Score a target door based on some qualities in relation to another door, and return that score.
func score_against(target:Room.Door, against:Room.Door) -> float:
	
	var score = 0
	
	var same_room_cost = pow(2, len(target.owned_by.doors) * len(against.owned_by.doors))
	for door in target.owned_by.doors: if door.connected_to == against.connected_to:
		score += same_room_cost
		same_room_cost *= 4
	
	return score
	#16 * pow(4, min(0, 20 - share_chain(target, against))) * (1 + (randf() / 3))
	
	# Lowest score wins.
	#var score = 0
	
	## Score based on distance to the against.
	#score += 64 * target.owned_by.node.position_offset.distance_to(against.owned_by.node.position_offset)
	#
	## Add points if the rooms are directly connected, exponentially.
	#var same_room_cost = pow(2, len(target.owned_by.doors) * len(against.owned_by.doors))
	#for door in target.owned_by.doors: if door.connected_to == against.connected_to:
		#score += same_room_cost
		#same_room_cost *= 4
	#
	## Add points if the rooms are indirectly connected, based on the size of the chain they share.
	#score += 100000 * pow(4, min(0, 20 - share_chain(target, against)))
	##if share_chain(target, against): return INF
	#
	## Subtract points based on how different the door count is.
	## This should (hopefully) incentivize connecting rooms w/ 1 door to rooms with many.
	#score -= 16 * pow(4, (len(target.owned_by.doors) - len(against.owned_by.doors)))
	#
	#score *= 1 + (randf() / 3)
	#
	#return score

## CONNECTING DOORS

func find_connection_for(doorA:Room.Door, from:Array) -> Array[Room.Door]:	
	var _from:Array[Room.Door]
	
	# Parse the input into doors.
	for item in from:
		if item is Room.Door: _from.append(item)
		elif item is Room: _from.append_array(item.doors)
		elif item is RoomNode: _from.append_array(item.data.doors)
	
	# Find a door to connect to.
	for checking in range(len(_from)):
		var doorB:Room.Door = _from[checking]
		# Ignore self & doors in the same room.
		if doorB.owned_by == doorA.owned_by: continue 
		
		if link_doors(doorA.owned_by.node, doorA.owned_by.doors.find(doorA), doorB.owned_by.node, doorB.owned_by.doors.find(doorB)):
			_from.erase(doorA)
			_from.erase(doorB)
			return _from
	
	return []

func link_doors(roomA:RoomNode, doorA:int, roomB:RoomNode, doorB:int) -> bool:
	if roomA.data.doors[doorA].connected_to or roomB.data.doors[doorB].connected_to: return false
	
	roomA.data.doors[doorA].connected_to = roomB.data
	roomB.data.doors[doorB].connected_to = roomA.data
	
	connect_node(roomA.name, doorA, roomB.name, doorB)
	roomA.set_slot_color_right(doorA, Color(0,1,0))
	roomB.set_slot_color_left(doorB, Color(0,1,0))
	# Doing both makes all ports connected, but doubles the lines...
	#connect_node(roomB.name, doorB, roomA.name, doorA)
	roomA.set_slot_color_left(doorA, Color(0,1,0))
	roomB.set_slot_color_right(doorB, Color(0,1,0))
	
	return true

## COLORING

func color_rooms(rooms:Array[RoomNode]):
	for roomA in rooms:
		for roomB in rooms:
			if roomA == roomB: continue
			
			var color := Color(1,1,1, 0.15)
			
			var connection_count := 0
			for i in range(len(roomA.data.doors)): for j in range(len(roomB.data.doors)):
				if roomA.data.doors[i].connected_to == roomB.data and roomB.data.doors[j].connected_to == roomA.data:
					connection_count += 1
			
			if connection_count > 1: color = Color(randf(),randf(),randf(), 1.0)
			for i in range(len(roomA.data.doors)): for j in range(len(roomB.data.doors)):
				if roomA.data.doors[i].connected_to == roomB.data and roomB.data.doors[j].connected_to == roomA.data:
					roomA.set_slot_color_left(i, color)
					roomA.set_slot_color_right(i, color)
					roomB.set_slot_color_left(j, color)
					roomB.set_slot_color_right(j, color)

## NAVIGATION

func _process(_delta: float) -> void:
	if Input.is_action_pressed("M2"):
		for child in get_children(): if child is GraphNode:
			child.position_offset += (child.position_offset - get_global_mouse_position()) / 100
