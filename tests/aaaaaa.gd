extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var cs = CollisionShape3D.new()
	$StaticBody3D.add_child(cs)
	cs.shape = BoxShape3D.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
