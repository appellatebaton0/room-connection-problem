extends Node
#
#var scene:PackedScene = preload("res://test_node.tscn")
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#var new = make()
	#print(new.value)
	#new.value = randi_range(0,10)
	#
	#var pack := PackedScene.new()
	#pack.pack(new)
	#print(ResourceSaver.save(pack, "res://test_node.tscn"))
	#
	#new.queue_free()
	#
	#var new2 = make()
	#print(new2.value)
	#new2.value = randi_range(0,10)
	#new2.queue_free()
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#
	#pass
#
#func make() -> Node:
	#var new:Node = ResourceLoader.load("res://test_node.tscn").instantiate()
	#
	#return new
