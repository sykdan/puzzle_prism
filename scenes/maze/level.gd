extends Node3D

var CHAMBER = preload("./chamber.tscn")

func _build_element(size, position):
	var mesh = BoxMesh.new()
	mesh.size = size
	var shape = BoxShape3D.new()
	shape.size = size
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = position
	
	var cs = CollisionShape3D.new()
	cs.shape = shape
	cs.position = position
	
	add_child(mi)
	add_child(cs)

func build(size: Vector2i, data, end: Vector2i):
	for node in data:
		var c = CHAMBER.instantiate()
		c.position.x = node.position.x * Shared.NODE_SIZE
		c.position.z = node.position.y * Shared.NODE_SIZE
		
		if node.x_passage:
			c.get_node("X").hide()
			c.get_node("X_Shape").disabled = true
			c.get_node("X").queue_free()
			c.get_node("X_Shape").queue_free()
		elif node.position.y == size.y - 1:
			c.get_node("X").scale.z = 1.5
			c.get_node("X").position.z = -0.25
		elif node.position.y == 0:
			c.get_node("X").scale.z = 1.5
			c.get_node("X").position.z = 0.25
		
		if node.y_passage:
			c.get_node("Z").hide()
			c.get_node("Z_Shape").disabled = true
			c.get_node("Z").queue_free()
			c.get_node("Z_Shape").queue_free()
		elif node.position.x == size.x - 1:
			c.get_node("Z").scale.z = 1.5
			c.get_node("Z").position.x = -0.25
		elif node.position.x == 0:
			c.get_node("Z").scale.z = 1.5
			c.get_node("Z").position.x = 0.25
		
		add_child(c)
		
	var sizes = Vector2(
		Shared.NODE_SIZE * size.x - Shared.WALL_SIZE,
		Shared.NODE_SIZE * size.y - Shared.WALL_SIZE
	)

	if end.y > 0:
		var flr = Vector3(
			sizes.x,
			Shared.WALL_SIZE,
			Shared.NODE_SIZE * end.y
		)
		var origin = flr/2.0 - Vector3(1,0,1) * Shared.WALL_SIZE
		origin.y = Shared.NODE_SIZE/-2.0
		_build_element(flr, origin)
	
	if end.y != size.y:
		var flr = Vector3(
			sizes.x,
			Shared.WALL_SIZE,
			Shared.NODE_SIZE * (size.y - end.y - 1)
		)
		var origin = flr/2.0 - Vector3(1,0,-1) * Shared.WALL_SIZE
		origin.z = sizes.y - origin.z
		origin.y = Shared.NODE_SIZE/-2.0
		_build_element(flr, origin)
		
	if end.x > 0:
		var flr = Vector3(
			Shared.NODE_SIZE * end.x,
			Shared.WALL_SIZE, 
			Shared.CHAMBER_SIZE
		)
		var origin = flr/2.0 + Vector3(0,0,1) * (Shared.NODE_SIZE * end.y) - Vector3(1,0,1) * Shared.WALL_SIZE
		origin.y = Shared.NODE_SIZE/-2.0
		_build_element(flr, origin)
		
	if end.x != size.x:
		var flr = Vector3(
			Shared.NODE_SIZE * (size.x - end.x - 1),
			Shared.WALL_SIZE, 
			Shared.CHAMBER_SIZE
		)
		var origin = flr/2.0 + Vector3(0,0,1) * (Shared.NODE_SIZE * end.y) + Vector3(1,0,-1) * Shared.WALL_SIZE
		origin.x = sizes.x - origin.x
		origin.y = Shared.NODE_SIZE/-2.0
		_build_element(flr, origin)
