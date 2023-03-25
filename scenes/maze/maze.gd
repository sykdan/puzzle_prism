extends Node3D

const CHAMBER_SIZE = 1.0
const WALL_SIZE = 0.5

var CHAMBER = preload("./chamber.tscn")

@export var size: Vector3i = Vector3i.ONE * 10 : set = resize

func resize(newsize: Vector3i):
	# Calculate the size of the box
	var box_sizes = (newsize + Vector3i.ONE) * CHAMBER_SIZE + (newsize - Vector3i.ONE) * WALL_SIZE
	
	# Position colliders
	$"Box/X+".shape.size = box_sizes
	$"Box/Y+".shape.size = box_sizes
	$"Box/Z+".shape.size = box_sizes
	$"Box/X+Mesh".mesh.size = box_sizes
	$"Box/Y+Mesh".mesh.size = box_sizes
	$"Box/Z+Mesh".mesh.size = box_sizes
	
	$"Box/X+".shape.size.x = WALL_SIZE 
	$"Box/Y+".shape.size.y = WALL_SIZE
	$"Box/Z+".shape.size.z = WALL_SIZE
	$"Box/X+Mesh".mesh.size.x = WALL_SIZE
	$"Box/Y+Mesh".mesh.size.y = WALL_SIZE
	$"Box/Z+Mesh".mesh.size.z = WALL_SIZE
	
	$"Box/X+".position.x = (box_sizes.x - WALL_SIZE)/2
	$"Box/Y+".position.y = (box_sizes.y - WALL_SIZE)/2
	$"Box/Z+".position.z = (box_sizes.z - WALL_SIZE)/2
	$"Box/X-".position.x = (box_sizes.x - WALL_SIZE)/-2
	$"Box/Y-".position.y = (box_sizes.y - WALL_SIZE)/-2
	$"Box/Z-".position.z = (box_sizes.z - WALL_SIZE)/-2
	$"Box/X+Mesh".position.x = (box_sizes.x - WALL_SIZE)/2
	$"Box/Y+Mesh".position.y = (box_sizes.y - WALL_SIZE)/2
	$"Box/Z+Mesh".position.z = (box_sizes.z - WALL_SIZE)/2
	$"Box/X-Mesh".position.x = (box_sizes.x - WALL_SIZE)/-2
	$"Box/Y-Mesh".position.y = (box_sizes.y - WALL_SIZE)/-2
	$"Box/Z-Mesh".position.z = (box_sizes.z - WALL_SIZE)/-2
	
	# Move the Chambers node, so that it is positioned at the bottom-left and we can
	# position individual chambers as multiples of WALL_SIZE later on.
	$Chambers.position = box_sizes/-2 + Vector3.ONE * (WALL_SIZE + CHAMBER_SIZE/2)

func _ready():
	resize(size)
	
	up_side()

func clear_maze_data():
	for c in $Chambers.get_children():
		c.queue_free()

func add_maze_data(data):
	for d in data:
		var c = CHAMBER.instantiate()
		$Chambers.add_child(c)
		c.position = d.position * (CHAMBER_SIZE + WALL_SIZE)
		c.get_node("X").disabled = d.x_passage
		c.get_node("Y").disabled = d.y_passage
		c.get_node("Z").disabled = d.z_passage
		c.get_node("XMesh").visible = !d.x_passage
		c.get_node("YMesh").visible = !d.y_passage
		c.get_node("ZMesh").visible = !d.z_passage

func up_side():
	var b: Vector3 = $Box.transform.basis.y
	var m = max(abs(b.x),abs(b.y),abs(b.z))
	var d = null
	
	if abs(b.x) == m:
		d = "x"
		m *= sign(b.x)
	
	elif abs(b.y) == m:
		d = "y"
		m *= sign(b.y)
	
	elif abs(b.z) == m:
		d = "z"
		m *= sign(b.z)
	
	print(d, m)
