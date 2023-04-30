extends Node3D

signal ready_to_play
signal _built_floor
signal built_all

signal level_finished
signal game_ended

@onready var LEVEL = preload("./level.tscn")

var cull_from = Vector3i.DOWN

@export var size: Vector2i = Vector2i.ONE * 10
@export var levels: int = 10

var current_level = 0
var is_ready = false

var _next_floor_start

# Sizes the maze to match desired parameters.
func resize():
	# Calculate the size of the box
	var box = Vector3i(size.x, levels, size.y)
	var box_sizes = (box + Vector3i.ONE) * Shared.CHAMBER_SIZE + (box - Vector3i.ONE) * Shared.WALL_SIZE
	box_sizes.y -= Shared.WALL_SIZE
	
	# The area (for gripping)
	$BoxArea/Shape.shape.size = box_sizes + Vector3.ONE * Shared.WALL_SIZE
	
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
	
	# Move the Chambers node so that it is positioned at the top-left.
	# 
	# This is calculated in a way to allow Levels and Chambers to be
	# positioned as multiples of NODE_SIZE
	$Levels.position = box_sizes/-2 + Vector3.ONE * (Shared.WALL_SIZE + Shared.CHAMBER_SIZE/2)
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
		# Get the level that we've just completed
		var level = $Levels.get_child(0)
		level.call_deferred(&"set_process_mode", Node.PROCESS_MODE_DISABLED) # Disable physics
		current_level += 1
		reveal(2)
		_create_temp_wall_outline(level)
		await get_tree().process_frame
		$"Box/X+Mesh".mesh.size.y -= Shared.NODE_SIZE
		$"Box/Z+Mesh".mesh.size.y -= Shared.NODE_SIZE
		$"Box/X+Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/Z+Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/Z-Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/X-Mesh".position.y -= Shared.NODE_SIZE/2
		$"Box/Y+".position.y -= Shared.NODE_SIZE
		
		
		emit_signal("level_finished")
		await get_tree().process_frame
		
		var tw = get_tree().create_tween()
		
		tw.tween_property(level, "position:y", level.position.y + Shared.CHAMBER_SIZE, 0.3).set_trans(Tween.TRANS_CIRC)
		tw.parallel().tween_property(level, "basis:x", Vector3.RIGHT * 0.005, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(level, "basis:y", Vector3.UP * 0.005, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(level, "basis:z", Vector3.BACK * 0.005, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		var dest = level.to_local(global_position)
		tw.parallel().tween_property(level, "position:x", dest.x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(level, "position:z", dest.z, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(level.hide)
		
		if current_level == levels:
			$Box.hide()
			$Marble.freeze = true
			$Marble.hide()
			emit_signal("game_ended")
		
		await tw.finished
		level.queue_free()

func _create_temp_wall_outline(level):
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
