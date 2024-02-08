extends Node3D
class_name Level

@onready var maze: Maze = $"../.."
const CHAMBER: PackedScene = preload("./chamber.tscn")

var maze_data: Array[MazeGen.MazeNode] = []
var maze_goal: Vector2i

var is_maze_built: bool = false
var is_floor_built: bool = false
var is_finished: bool = false

func _ready():
	$Number.position.z = (maze.size.y * Shared.NODE_SIZE) - Shared.WALL_SIZE
	$Number.position.x = (maze.size.x - 1)/2.0 * Shared.NODE_SIZE
	$Number.position.y = Shared.WALL_SIZE/-2
	$Number.position.z += 0.001

## Assign the maze data, the goal and number to this level.
func assign(data: Array[MazeGen.MazeNode], goal: Vector2i, level: int):
	maze_data = data
	maze_goal = goal
	$Number.text = str(level)

## Build obstacles based on previously assigned maze data.
func build_obstacles():
	if is_maze_built:
		return
	
	var size: Vector2i = maze.size
	
	for node in maze_data:
		var c = CHAMBER.instantiate()
		var wall_x: Node3D = c.get_node("X")
		var wall_x_shape: Node3D = c.get_node("X_Shape")
		var wall_z: Node3D = c.get_node("Z")
		var wall_z_shape: Node3D = c.get_node("Z_Shape")
		
		c.position.x = node.position.x * Shared.NODE_SIZE
		c.position.z = node.position.y * Shared.NODE_SIZE
		
		var i = 2
		
		if node.x_passage:
			wall_x.hide()
			wall_x_shape.disabled = true
			wall_x.queue_free()
			wall_x_shape.queue_free()
			i -= 1
		elif node.position.y == size.y - 1:
			wall_x.scale.z = 1.5
			wall_x.position.z = -0.25
		elif node.position.y == 0:
			wall_x.scale.z = 1.5
			wall_x.position.z = 0.25
		
		if node.y_passage:
			wall_z.hide()
			wall_z_shape.disabled = true
			wall_z.queue_free()
			wall_z_shape.queue_free()
			i -= 1
		elif node.position.x == size.x - 1:
			wall_z.scale.z = 1.5
			wall_z.position.x = -0.25
		elif node.position.x == 0:
			wall_z.scale.z = 1.5
			wall_z.position.x = 0.25
		
		if i != 0:
			add_child(c)
	
	is_maze_built = true

## Build the floor of this level. This is done by making four box meshes and positioning them accordingly.
func build_floor():
	if is_floor_built:
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
	
	is_floor_built = true

func _build_floor_fragment(extents: Vector3, origin: Vector3):
	var mesh = BoxMesh.new()
	mesh.size = extents
	
	var shape = BoxShape3D.new()
	shape.size = extents
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = origin
	
	var cs = CollisionShape3D.new()
	cs.shape = shape
	cs.position = origin
	
	$Floor.add_child(mi)
	$Floor.add_child(cs)

func _goal_collision(body: PhysicsBody3D):
	if body.is_in_group("marble") and not is_finished:
		is_finished = true
		emit_signal(&"finished")
