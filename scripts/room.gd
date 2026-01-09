class_name Room extends Resource

var node:RoomNode
var doors:Array[Door]

class Door:
	var connected_to:Room
	var owned_by:Room
	
	func _init(room:Room) -> void: 
		owned_by = room
		
		if not room.doors.has(self): room.doors.append(self)

func link(door:int, to:Room) -> bool:
	if door > len(doors) or not to: return false
	
	doors[door].owned_by = self
	doors[door].connected_to = to
	
	return true

func _init(belongs_to:RoomNode, door_count:int) -> void: 
	node = belongs_to
	
	for i in range(door_count):
		Door.new(self)
