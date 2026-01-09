extends GraphEdit

@export var room_count := 100

var ROOMSCENE = preload("res://room_node.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var rooms:Array[RoomNode]
	
	# Create the rooms.
	@warning_ignore("unused_variable")
	var grid_size = int(floor(sqrt(room_count)))
	# Create the faux rooms
	for i in range(room_count):
		var new:RoomNode = ROOMSCENE.instantiate()
		
		# Grid
		#new.position_offset = Vector2(i % grid_size, floor(i / grid_size)) * 900
		# Circle
		new.position_offset = Vector2(sin(i), cos(i)) * 1000
		
		add_child(new)
		
		rooms.append(new)
	
	# Shuffle the rooms.
	shuffle(rooms)
	
	print("DONE.")
	
	# Color each room's ports (and by extension connections) by what chain it's in.
	# This makes it easier to see islands.
	#color_by_chain(get_chains(rooms))
	
	# Color each room's ports based on if there's any 
	# other connection between the same two nodes.
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


func shuffle(rooms:Array[RoomNode]):
	
	# I think this should have 3 steps, since just straight connecting is leaving islands.
	# 1. Randomize the array given.
	# 2. Connect every element the array using some maze solver / tree spanning algorithm.
		# As in, every room has at least 1 door connecting it to the rest of the rooms.
	# 4. Use the already-made system to connect all the remaining doors.
	
	## Randomize the rooms' positions.
	# Non-applicable for rn
	
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
	#var not_done:Array[RoomNode] = rooms.duplicate()
	#
	#var max_door_count:int = 0
	#for room in rooms:
		#max_door_count = max(max_door_count, len(room.data.doors))
	#
	#var minimum = 1
	#while len(not_done) > 0:
		#
		#var start_with := available_rooms(not_done, minimum)
		#print("C", len(start_with))
		#
		#var connect_to:Array[RoomNode]
		#for room in not_done:
			#if not start_with.has(room): connect_to.append(room)
		#
		#if not len(connect_to): connect_to = not_done
		#
		#for room in not_done:
			## If this is a room to start w/
			#if start_with.has(room):
				## Try to connect one of the doors.
				#for door in room.data.doors:
					#if door.connected_to: continue
					#
					## If a connection was made,
					#if len(find_connection_for(door, score_sort(door, connect_to)["array"])):
						#print("ER")
						#not_done.erase(room)
						#break
		#
		#for room in not_done:
			#for door in room.data.doors:
				#if door.connected_to:
					#print("ER")
					#not_done.erase(room)
					#break
		#
		#
		#if not len(not_done): break
		#
		#minimum = 1
		#while not len(available_rooms(not_done, minimum)): 
			#minimum += 1
			#
			#if minimum > max_door_count: 
				#print("FAIL")
				#break
		#
		#print(len(not_done))
		#
		#if not len(froms): 
			##print("TRIGGERED OFF ", not_done)
			#for room in not_done:
				#for door in room.data.doors:
					#if door.connected_to: not_done.erase(door)
			#
			#
			#
			#froms = available_rooms(rooms, 1, int(INF))
			#tos = available_rooms(rooms, 1, int(INF))
			#
			#if len(froms) < 5: break
		#
		#
		#
		#while len(froms):
			#var ran_for_this = false
			#for door in froms[0].data.doors:
				#if door.connected_to: continue
				#
				#ran_for_this = true
				#
				#if len(find_connection_for(door, score_sort(door, tos)["array"])): 
					#froms.erase(door.owned_by.node)
					#not_done.erase(door.owned_by.node)
					#break
			#
			## No open doors, so skip.
			#if not ran_for_this:
				##print(froms)
				#if len(froms) and len(not_done): not_done.erase(froms.pop_front())
					#
			#
			## Nothing to check against.
			#if not len(tos): break
			#
		#
		#minimum += 1
	
	#print("left w/ ", len(not_done), " from ", len(rooms))
	
	## Attempt 2
	#var unresolved_doors:Array[Room.Door]
	#
	## Get all the unconnected doors
	#for room in rooms: for door in room.data.doors:
		#if not door.connected_to: unresolved_doors.append(door)
	#
	#var working := 0
	## While there are still doors that are unconnected.
	#while len(unresolved_doors) > 1:
		## Make sure the working door exists.
		#working = min(working, len(unresolved_doors) - 1) # randi_range(0, floor(len(unresolved_doors) / 2))
		## Without shortening
		## working = randi_range(0, len(unresolved_doors) - 1)
		#
		#var connection_found = false
		#var working_door:Room.Door = unresolved_doors[working]
		#
		## Sort the doors by their distance to the working door.
		#var sort_results:Dictionary = score_sort(working_door, unresolved_doors)
		#unresolved_doors = sort_results["array"]
		#working = sort_results["new_id"] # Update the id, since the array has changed.
		#
		## Attempt to find a connection for the current door.
		#unresolved_doors = find_connection_for(working_door, unresolved_doors)
		#connection_found = working_door.connected_to
		#
		## The shuffle has failed...
		#if not connection_found: 
			#print("Connection not found for ", working_door)
			#break
		#
		## Pick the door to work on next.
		#working = get_next_working(working, unresolved_doors)
		#print("U:", len(unresolved_doors))
	
	## Attempt 1
	#var break_count = 0
	#
	#var unresolved_rooms:Array[RoomNode] = rooms.duplicate()
	#while unresolved_rooms: # For every room that hasn't been checked and/or completed
		#var working = randi_range(0, len(unresolved_rooms) - 1)
		#
		#var has_empty_doors = false
		#
		#var doors = unresolved_rooms[0].data.doors
		#for i in range(len(doors)): # For every door in this room
			#if doors[i].connected_to: continue
			#
			#for room in unresolved_rooms: # For every room that can have open doors.
				#if room == unresolved_rooms[working]: continue # Skip the current room, no recursion.
				#
				#var subdoors = room.data.doors
				#for j in range(len(subdoors)): # For every door in *this* room.
					#if subdoors[j].connected_to: continue
					## If this door is empty...
					#
					#link_doors(unresolved_rooms[working], i, room, j)
					#break
				## if doors[i].connected_to: break
			#
			#if not doors[i].connected_to: 
				#print("has empty")
				#has_empty_doors = true
		#
		#if not has_empty_doors:
			#print("popped ", unresolved_rooms[working])
			#unresolved_rooms.pop_at(working)
		#
		#break_count += 1
		#if break_count > 5000: 
			#print("Overflow!")
			#break

# Returns all the rooms with a certain count of unused doors.
func available_rooms(from:Array[RoomNode], door_count_min:int, door_count_max := door_count_min) -> Array[RoomNode]:
	
	var response:Array[RoomNode]
	
	for room in from:
		var unused:int = 0
		for door in room.data.doors: if not door.connected_to: unused += 1
		if unused >= door_count_min and unused <= door_count_max: response.append(room)
	
	return response

# Get the next working door.
func get_next_working(last:int, with:Array[Room.Door]) -> int:
	if not with: return -1
	
	if last == 0: return randi_range(0, floor(len(with) / 2))
	
	return last - 1


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

## NAVIGATION

func _process(_delta: float) -> void:
	if Input.is_action_pressed("M2"):
		for child in get_children(): if child is GraphNode:
			child.position_offset += (child.position_offset - get_global_mouse_position()) / 100

## CHAINS

# Set the ports of each RoomNode based on what chain they're in.
func color_by_chain(chains:Array[Array]):
	for chain in chains:
		
		var color = Color(randf(), randf(), randf())
		for item in chain: if item is Room: # For every room in this chain.
			
			for i in range(len(item.doors)):
				item.node.set_slot_color_left(i, color)
				item.node.set_slot_color_right(i, color)

# Get all the existing chains in the array. Plug in one RoomNode for that node's chain.
func get_chains(from:Array[RoomNode]) -> Array[Array]:
	
	var br = 0
	var real:Array[Room]
	for node in from: real.append(node.data)
	
	var chains:Array[Array]
	
	var working := 0
	while len(real):
		var chain:Array = []
		var room:Room = real[working]
		
		var queue:Array[Room] = [room]
		while len(queue):
			for item in queue:
				for door in item.doors:
					if door.connected_to and not queue.has(door.connected_to) and not chain.has(door.connected_to):
						queue.append(door.connected_to)
				
				chain.append(item)
				queue.erase(item)
		
		chains.append(chain)
		
		for item in chain:
			real.erase(item)
		
		br += 1
		if br > 10000: 
			print("Overflow :()")
			break
	
	return chains

# Whether two doors are in the same chain. 0 for false, otherwise the length of the chain.
func share_chain(a:Room.Door, b:Room.Door) -> int:
	
	var chain:Array = []
	var room:Room = a.owned_by
	
	var queue:Array[Room] = [room]
	while len(queue):
		for item in queue:
			for door in item.doors:
				if door.connected_to and not queue.has(door.connected_to) and not chain.has(door.connected_to):
					queue.append(door.connected_to)
			
			chain.append(item)
			queue.erase(item)
	
	var a_chain = get_chains([a.owned_by.node])[0]

	if a_chain.has(b.owned_by.node): return len(a_chain)
	else: return 0

## CONNECTION / DISCONNECTION (UNUSED)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void: connect_node(from_node, from_port, to_node, to_port, false)
func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void: disconnect_node(from_node, from_port, to_node, to_port)
