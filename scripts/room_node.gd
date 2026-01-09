class_name RoomNode extends GraphNode

@export var data:Room = Room.new(self, randi_range(1,3) * 2)

func _ready() -> void:
	if not data: 
		queue_free()
		return
	
	for i in len(data.doors):
		var new = Label.new()
		new.text = "Door" + str(i)
		
		add_child(new)
		
		set_slot(i, true, 0, Color(1,0,0), true, 0, Color(1,0,0))
