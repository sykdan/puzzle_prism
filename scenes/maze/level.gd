extends Node3D

signal finished

@onready var maze = get_node("../..")
var CHAMBER = preload("./chamber.tscn")
var GOAL = preload("./goal.tscn")

var maze_data = []
var maze_goal: Vector2i

var is_finished = false

func assign(data, goal):
	maze_data = data
	maze_goal = goal

func obstacles():
	if is_in_group(&"has_obstacles"):
		return
	
	var size: Vector2i = maze.size
	
	for node in maze_data:
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
	
	var goal: Area3D = GOAL.instantiate()
	goal.position = Vector3(
		maze_goal.x * Shared.NODE_SIZE,
		Shared.NODE_SIZE/-2.0,
		maze_goal.y * Shared.NODE_SIZE
	)
	add_child(goal)
	goal.body_entered.connect(_goal_collision)
	add_to_group(&"has_obstacles")

func floor():
	if is_in_group(&"has_floor"):
		return
	
	var size: Vector2i = maze.size
	var real_size = Shared.NODE_SIZE * size - Vector2i.ONE * Shared.WALL_SIZE
	
	if maze_goal.y > 0:
		var flr = Vector3(
			real_size.x,
			Shared.WALL_SIZE,
			Shared.NODE_SIZE * maze_goal.y
		)
		var origin = flr/2.0 - Vector3(1,0,1) * Shared.WALL_SIZE
		origin.y = Shared.NODE_SIZE/-2.0
		_build_floor_fragment(flr, origin)
	
	if maze_goal.y != size.y:
		var flr = Vector3(
			real_size.x,
			Shared.WALL_SIZE,
			Shared.NODE_SIZE * (size.y - maze_goal.y - 1)
		)
		var origin = flr/2.0 - Vector3(1,0,-1) * Shared.WALL_SIZE
		origin.z = real_size.y - origin.z
		origin.y = Shared.NODE_SIZE/-2.0
		_build_floor_fragment(flr, origin)
		
	if maze_goal.x > 0:
		var flr = Vector3(
			Shared.NODE_SIZE * maze_goal.x,
			Shared.WALL_SIZE, 
			Shared.CHAMBER_SIZE
		)
		var origin = flr/2.0 + Vector3(0,0,1) * (Shared.NODE_SIZE * maze_goal.y) - Vector3(1,0,1) * Shared.WALL_SIZE
		origin.y = Shared.NODE_SIZE/-2.0
		_build_floor_fragment(flr, origin)
		
	if maze_goal.x != size.x:
		var flr = Vector3(
			Shared.NODE_SIZE * (size.x - maze_goal.x - 1),
			Shared.WALL_SIZE, 
			Shared.CHAMBER_SIZE
		)
		var origin = flr/2.0 + Vector3(0,0,1) * (Shared.NODE_SIZE * maze_goal.y) + Vector3(1,0,-1) * Shared.WALL_SIZE
		origin.x = real_size.x - origin.x
		origin.y = Shared.NODE_SIZE/-2.0
		_build_floor_fragment(flr, origin)
	
	add_to_group(&"has_floor")

func _build_floor_fragment(extents, position):
	var mesh = BoxMesh.new()
	mesh.size = extents
	var shape = BoxShape3D.new()
	shape.size = extents
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = position
	
	var cs = CollisionShape3D.new()
	cs.shape = shape
	cs.position = position
	
	$Floor.add_child(mi)
	$Floor.add_child(cs)

func _goal_collision(body: PhysicsBody3D):
	if body.is_in_group("marble") and not is_finished:
		is_finished = true
		emit_signal(&"finished")
