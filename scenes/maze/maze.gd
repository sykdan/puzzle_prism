extends Node3D
class_name Maze

## The Maze and everything pertaining to it.

## Emitted when the game can be played. (Two mazes have been generated, the rest is done in the background.)
signal ready_to_play
## Emitted when a level has been finished.
signal level_finished
## Emitted when the game has ended. (all levels have been completed)
signal game_ended

const LEVEL: PackedScene = preload("./level.tscn")
const FIREWORK: PackedScene = preload("res://scenes/firework.tscn")
const GOAL: PackedScene = preload("./goal.tscn")

@export var size: Vector2i = Vector2i.ONE * 10
@export var levels: int = 10

@onready var marble: RigidBody3D = $Marble

var current_level: int = 0
var is_ready: bool = false

## Maze generator related, stores where the last maze ended. To be used in the following level.
var _next_level_start: Vector2i

func _ready():
	MazeGen.generated.connect(_maze_generated)
	resize()

## Sizes the maze to match desired parameters
func resize():
	# Calculate the size of the box
	var box = Vector3i(size.x, levels, size.y)
	var box_sizes = (box + Vector3i.ONE) * Shared.CHAMBER_SIZE + (box - Vector3i.ONE) * Shared.WALL_SIZE
	box_sizes.y -= Shared.WALL_SIZE
	
	# The area (for gripping)
	$BoxArea/Shape.shape.size = box_sizes + Vector3.ONE * Shared.WALL_SIZE
	
	# Set size of walls
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

	# Set position of walls
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
	
	# Move the Chambers node so that it is positioned at the top-left.
	# This is done to allow Levels and Chambers to be positioned as negative multiples of Shared.NODE_SIZE
	$Levels.position = box_sizes/-2 + Vector3.ONE * (Shared.WALL_SIZE + Shared.CHAMBER_SIZE/2)
	$Levels.position.y *= -1

## Generate a new maze
func create_game():
	is_ready = false
	_next_level_start = Vector2i(
		randi_range(0, size.x-1),
		randi_range(0, size.y-1)
	)
	$Marble.global_position = $Levels.global_position
	$Marble.position += Vector3(_next_level_start.x, 0, _next_level_start.y) * Shared.NODE_SIZE
	_generate_level()

func _generate_level():
	var generated_levels = $Levels.get_child_count()
	if generated_levels < levels:
		var l = LEVEL.instantiate()
		l.position.y = $Levels.get_child_count() * -Shared.NODE_SIZE
		$Levels.add_child(l)
		MazeGen.generate_maze(size, _next_level_start)
	else:
		_reveal(levels - 1)

func _maze_generated(data: Array[MazeGen.MazeNode], end: Vector2i):
	var level = $Levels.get_child(-1) as Level
	level.assign(data, end, levels - $Levels.get_child_count() + 1)
	level.build_floor()
	
	_next_level_start = end
	# The game can be played as soon as two mazes are generated.
	# Generation continues in the background and will be finished before the player can finish the first maze. 
	if not is_ready and ($Levels.get_child_count() == 2 or $Levels.get_child_count() == levels):
		is_ready = true
		ready_to_play.emit()
		_place_goal($Levels.get_child(0))
		_reveal(0)
		_reveal(1)
	_generate_level()

# To aid performance, the game does not draw all obstacles.
# Instead, it only draws the first two levels 
# (so you see what you're solving AND through the translucent goal hole)
func _reveal(level: int):
	if level >= $Levels.get_child_count():
		return # No-op when out of bounds
	$Levels.get_child(level).build_obstacles()

func _place_goal(level: Level):
	var goal_position = Vector3(
		level.maze_goal.x * Shared.NODE_SIZE,
		level.position.y - Shared.NODE_SIZE/2,
		level.maze_goal.y * Shared.NODE_SIZE
	)
	$Goal.position = $Levels.position + goal_position
	$Goal.show()

func _on_goal_body_entered(body):
	if body.is_in_group("marble"):
		_floor_finished()

func _floor_finished():
	current_level += 1
	_reveal(2)
	
	if not current_level == levels:
		_place_goal($Levels.get_child(1))
	else:
		$Goal.hide()
	
	# Get the level that we've just completed
	var level: Level = $Levels.get_child(0)
	# Workaround for a bug: Physics nodes scaled to incredibly small values cause lag
	# Disable processing to work around this
	level.call_deferred(&"set_process_mode", Node.PROCESS_MODE_DISABLED)
	_create_temp_wall_outline(level)
	
	await get_tree().process_frame
	# Shrink the wall around the maze. This shrinking is not visible to the player, because we previously created a fake wall around the finished level 
	$"Box/X+Mesh".mesh.size.y -= Shared.NODE_SIZE
	$"Box/Z+Mesh".mesh.size.y -= Shared.NODE_SIZE
	$"Box/X+Mesh".position.y -= Shared.NODE_SIZE/2
	$"Box/Z+Mesh".position.y -= Shared.NODE_SIZE/2
	$"Box/Z-Mesh".position.y -= Shared.NODE_SIZE/2
	$"Box/X-Mesh".position.y -= Shared.NODE_SIZE/2
	$"Box/Y+".position.y -= Shared.NODE_SIZE
	level_finished.emit()
	
	await get_tree().process_frame
	# Animation of the level disappearing
	var tw = get_tree().create_tween()
	tw.tween_callback($floor_solved.play)
	tw.tween_property(level, "position:y", level.position.y + Shared.CHAMBER_SIZE, 0.3).set_trans(Tween.TRANS_CIRC)
	tw.parallel().tween_property(level, "basis:x", Vector3.RIGHT * 0.005, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(level, "basis:y", Vector3.UP * 0.005, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(level, "basis:z", Vector3.BACK * 0.005, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var center = level.to_local(global_position)
	tw.parallel().tween_property(level, "position:x", center.x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(level, "position:z", center.z, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(level.hide)
	
	if current_level == levels: # Finished the last level
		$Box.hide()
		$Marble.freeze = true
		$Marble.hide()
		
		await _spawn_firework().tree_exited
		game_ended.emit()
	
	await tw.finished
	level.queue_free()

func _spawn_firework() -> Node3D:
	var f: Node3D = FIREWORK.instantiate()
	get_parent().add_child(f)
	f.global_position = $Marble.global_position
	return f

## Create a "fake wall" around a level. This is only used for the fade animation
func _create_temp_wall_outline(level: Level):
	var fake_wall_x = BoxMesh.new()
	var fake_wall_z = BoxMesh.new()
	
	fake_wall_x.size = $"Box/X+Mesh".mesh.size
	fake_wall_x.size.y = Shared.NODE_SIZE
	fake_wall_z.size = $"Box/Z+Mesh".mesh.size
	fake_wall_z.size.y = Shared.NODE_SIZE
	
	var xp = MeshInstance3D.new()
	var xm = MeshInstance3D.new()
	xp.mesh = fake_wall_x
	xm.mesh = fake_wall_x
	xp.position = level.to_local($"Box/X+Mesh".global_position)
	xm.position = level.to_local($"Box/X-Mesh".global_position)
	xp.position.y = Shared.WALL_SIZE/-2
	xm.position.y = Shared.WALL_SIZE/-2
	
	var zp = MeshInstance3D.new()
	var zm = MeshInstance3D.new()
	zp.mesh = fake_wall_z
	zm.mesh = fake_wall_z
	zp.position = level.to_local($"Box/Z+Mesh".global_position)
	zm.position = level.to_local($"Box/Z-Mesh".global_position)
	zp.position.y = Shared.WALL_SIZE/-2
	zm.position.y = Shared.WALL_SIZE/-2
	
	level.add_child(xp)
	level.add_child(xm)
	level.add_child(zp)
	level.add_child(zm)
