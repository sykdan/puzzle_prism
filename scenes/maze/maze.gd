extends Node3D

const CHAMBER_SIZE = 1.0
const WALL_SIZE = 0.5

var CHAMBER = preload("./chamber.tscn")

var cull_from = Vector3i.DOWN

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
	
	var d = max(box_sizes.x,box_sizes.y,box_sizes.z) + WALL_SIZE
	$XRay/CollisionShape3D.shape.size = Vector3(d, CHAMBER_SIZE, d)
	
	# Move the Chambers node, so that it is positioned at the bottom-left and we can
	# position individual chambers as multiples of WALL_SIZE later on.
	$Chambers.position = box_sizes/-2 + Vector3.ONE * (WALL_SIZE + CHAMBER_SIZE/2)

func _ready():
	resize(size)

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
	
	cull_snap_to_top()
	$Lopta.position = $Chambers.position + Vector3i(3,5,2) * (CHAMBER_SIZE + WALL_SIZE)

func _physics_process(delta):
	pass#print($XRay.position - $Lopta.position)

func __get_culled_axis(v: Vector3):
	if cull_from.x:
		return v.x
	if cull_from.y:
		return v.y
	if cull_from.z:
		return v.z

func __hide_pass_1():
	var bodies = $XRay.get_overlapping_bodies()

func __hide_pass_2():
	var bodies = $XRay.get_overlapping_bodies()

func cull_snap_to_top():
	var top = Vector3(cull_from) * -($Chambers.position - Vector3.ONE * (WALL_SIZE/2))
	$XRay.position = top

func perform_culling():
	var culled_axis = cull_from.abs().max_axis_index()
	var factor = cull_from[culled_axis]
	const XYZ = "XYZ"
	
	print($Lopta.position)
	print(factor)
	
	while factor * ($XRay.position - $Lopta.position)[culled_axis] > CHAMBER_SIZE:
		var bodies
		
		var keep = XYZ[culled_axis]
		bodies = $XRay.get_overlapping_bodies()
		for b in bodies:
			if not b.is_in_group(&"chamber"): continue
			b.get_node("XMesh").hide()
			b.get_node("YMesh").hide()
			b.get_node("ZMesh").hide()
		$XRay.position -= cull_from * (CHAMBER_SIZE + WALL_SIZE)
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		if factor == 1:
			bodies = $XRay.get_overlapping_bodies()
			for b in bodies:
				if not b.is_in_group(&"chamber"): continue
				b.get_node(keep + "Mesh").hide()

func _on_button_pressed():
	perform_culling()
