extends Node3D

signal ready_to_play
signal _built_floor
signal built_all

@onready var LEVEL = preload("./level.tscn")

var cull_from = Vector3i.DOWN

@export var size: Vector2i = Vector2i.ONE * 10
@export var levels: int = 10
var current_level = 0
var is_ready = false

var _next_floor_start

func resize():
	# Calculate the size of the box
	var box = Vector3i(size.x, levels, size.y)
	var box_sizes = (box + Vector3i.ONE) * Shared.CHAMBER_SIZE + (box - Vector3i.ONE) * Shared.WALL_SIZE
	box_sizes.y -= Shared.WALL_SIZE
	# Position colliders
	$"Box/X+".shape.size = box_sizes
	$"Box/Z+".shape.size = box_sizes
	$"Box/X+Mesh".mesh.size = box_sizes
	$"Box/Z+Mesh".mesh.size = box_sizes
	$"Box/Y+".shape.size = box_sizes
	
	$"Box/X+".shape.size.x = Shared.WALL_SIZE 
	$"Box/Z+".shape.size.z = Shared.WALL_SIZE
	$"Box/X+Mesh".mesh.size.x = Shared.WALL_SIZE
	$"Box/Z+Mesh".mesh.size.z = Shared.WALL_SIZE
	$"Box/Y+".shape.size.y = Shared.WALL_SIZE
	
	$"Box/X+".position.x = (box_sizes.x - Shared.WALL_SIZE)/2
	$"Box/Z+".position.z = (box_sizes.z - Shared.WALL_SIZE)/2
	$"Box/X-".position.x = (box_sizes.x - Shared.WALL_SIZE)/-2
	$"Box/Z-".position.z = (box_sizes.z - Shared.WALL_SIZE)/-2
	$"Box/Y+".position.y = (box_sizes.y - Shared.WALL_SIZE)/2
	$"Box/X+Mesh".position.x = (box_sizes.x - Shared.WALL_SIZE)/2
	$"Box/Z+Mesh".position.z = (box_sizes.z - Shared.WALL_SIZE)/2
	$"Box/X-Mesh".position.x = (box_sizes.x - Shared.WALL_SIZE)/-2
	$"Box/Z-Mesh".position.z = (box_sizes.z - Shared.WALL_SIZE)/-2
	$"Box/X+Mesh".position.y = -Shared.WALL_SIZE
	$"Box/Z+Mesh".position.y = -Shared.WALL_SIZE
	$"Box/Z-Mesh".position.y = -Shared.WALL_SIZE
	$"Box/X-Mesh".position.y = -Shared.WALL_SIZE
	
	# Move the Chambers node, so that it is positioned at the bottom-left and we can
	# position individual chambers as multiples of WALL_SIZE later on.
	$Levels.position = box_sizes/-2 + Vector3.ONE * (Shared.WALL_SIZE + Shared.CHAMBER_SIZE/2)
	# Start from the top and continue downward
	$Levels.position.y *= -1

func _ready():
	MazeGen.generated.connect(_maze_generated)
	resize()

func clear_game():
	for c in $Levels.get_children():
		c.queue_free()

func create_game():
	is_ready = false
	_next_floor_start = Vector2i(
		randi_range(0, size.x-1),
		randi_range(0, size.y-1)
	)
	$Marble.position = $Levels.position
	$Marble.position += Vector3(_next_floor_start.x,0,_next_floor_start.y) * Shared.NODE_SIZE
	clear_game()
	await get_tree().process_frame
	_add_floor()

func _add_floor():
	var current_level = $Levels.get_child_count()
	if current_level < levels:
		var l = LEVEL.instantiate()
		l.position.y = $Levels.get_child_count() * -Shared.NODE_SIZE
		l.finished.connect(floor_finished.bind(current_level))
		$Levels.add_child(l)
		MazeGen.__generate_maze(size, _next_floor_start)
	else:
		emit_signal(&"built_all")
		reveal(levels-1)

func _maze_generated(data, end):
	var level = $Levels.get_child(-1)
	level.assign(data, end)
	level.floor()
	
	_next_floor_start = end
	emit_signal(&"_built_floor")
	_add_floor()

func reveal(level: int):
	if level >= $Levels.get_child_count():
		return
	$Levels.get_child(level).obstacles()

func _on__built_floor():
	if not is_ready and ($Levels.get_child_count() == 2 or $Levels.get_child_count() == levels):
		is_ready = true
		emit_signal(&"ready_to_play")
		reveal(0)
		reveal(1)

func floor_finished(level_number):
	if level_number == current_level:
		var level = $Levels.get_child(0)
		current_level += 1
		level.hide()
		level.queue_free()
		reveal(2)
		$"Box/X+Mesh".mesh.size.y -= Shared.NODE_SIZE
		$"Box/Z+Mesh".mesh.size.y -= Shared.NODE_SIZE
		$"Box/X+Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/Z+Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/Z-Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/X-Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/Y+".position.y -= Shared.NODE_SIZE
		position += basis.y * Shared.NODE_SIZE
		
		if current_level == levels:
			$Box.hide()
