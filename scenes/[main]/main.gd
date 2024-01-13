extends Node3D

const MAZE: PackedScene = preload("res://scenes/MAZE/MAZE.tscn")

var current_maze: Maze
var maze_start_time: int = 0

var _slide_upwards = false
var _is_giving_up = false

func player_ready():
	$XRPlayer.pointer_enabled = true
	create_tween().tween_property($XRPlayer, "black_fade_ratio", 0, 2)

func _is_holding_maze() -> bool:
	return current_maze and $XRPlayer.gripped_object == current_maze

## Called when an OpenXR error has occurred.
func xr_error(type: StringName):
	OS.alert(tr(type), tr(&"XR_ERROR_TITLE"))
	get_tree().quit()

func _process(_delta):	
	if not _is_holding_maze():
		var giveup: bool = (
			$XRPlayer/LeftHand.global_position.y > $XRPlayer/XRCamera3D.global_position.y and 
			$XRPlayer/RightHand.global_position.y > $XRPlayer/XRCamera3D.global_position.y
		)
		if giveup != _is_giving_up && not _is_giving_up:
			$MainScreen/Viewport/GUI.start_giveup()
			_is_giving_up = true
		elif giveup != _is_giving_up && _is_giving_up:
			$MainScreen/Viewport/GUI.end_giveup()
			_is_giving_up = false

func _physics_process(delta):
	# Godot Tweens don't support working with relative values, they must transition absolutely from one value to another.
	# But the transform of the gripped object may change during the animation.
	# Therefore animate frame-by-frame
	if _slide_upwards:
		$XRPlayer.translate_gripped_object(
			global_transform.basis.y * Shared.NODE_SIZE * delta
		)

func _on_marble_haptic(diff):
	if not _is_holding_maze():
		return
	
	var vibrate = diff / 15
	
	var l = $XRPlayer/LeftHand.global_position.distance_to(current_maze.marble.global_position)
	var r = $XRPlayer/RightHand.global_position.distance_to(current_maze.marble.global_position)
	
	$XRPlayer/LeftHand.trigger_haptic_pulse("haptic", 1, vibrate * (max(r / l, 1)**2), 0.05, 0)
	$XRPlayer/RightHand.trigger_haptic_pulse("haptic", 1, vibrate * (max(l / r, 1)**2), 0.05, 0)

func _on_maze_level_finished():
	if _is_holding_maze():
		_slide_upwards = true
		await get_tree().create_timer(1).timeout
		_slide_upwards = false

func _on_gui_play(difficulty, params):
	var size: Vector2i
	var levels: int
	
	if difficulty == &"easy":
		size = Vector2i.ONE * 5
		levels = 5
	elif difficulty == &"medium":
		size = Vector2i.ONE * 8
		levels = 8
	elif difficulty == &"hard":
		size = Vector2i.ONE * 14
		levels = 14
	elif difficulty == &"custom":
		size = Vector2i(params.x, params.y)
		levels = params.z
	
	$BGM.play(0.0)
	
	current_maze = MAZE.instantiate() as Maze
	current_maze.size = size
	current_maze.levels = levels
	current_maze.resize()
	current_maze.hide()
	
	var pos = $XRPlayer/XRCamera3D.global_position
	pos -= $XRPlayer/XRCamera3D.basis.z * 12
	pos -= $XRPlayer/XRCamera3D.basis.z * size.length()
	pos += Vector3.DOWN * 12
	
	current_maze.get_node("Marble").haptic.connect(_on_marble_haptic)
	current_maze.level_finished.connect(_on_maze_level_finished)
	current_maze.game_ended.connect(_on_game_ended)
	
	add_child(current_maze)
	current_maze.global_position = pos
	current_maze.create_game()
	
	await current_maze.ready_to_play
	current_maze.show()
	$XRPlayer.pointer_enabled = false
	
	@warning_ignore("NARROWING_CONVERSION")
	maze_start_time = Time.get_unix_time_from_system()

func _on_game_ended():
	$XRPlayer.drop_object()
	current_maze.queue_free()
	current_maze = null
	$finished.play()
	$BGM.stop()
	
	var time_taken: int = ceil(Time.get_unix_time_from_system() - maze_start_time)
	maze_start_time = 0
	
	$XRPlayer.pointer_enabled = true
	
	$MainScreen/Viewport/GUI.finish_game(time_taken)

func _on_gui_at_screen(screen: NodePath):
	var is_main = screen == ^"MainMenu"
	$Title.visible = is_main
	
	$Controls.visible = is_main
	$Controls.enabled = is_main
	var mode: ProcessMode 
	if is_main:
		mode = PROCESS_MODE_ALWAYS
	else:
		mode = PROCESS_MODE_DISABLED
	$Controls.set_process_mode.call_deferred(mode)

func _on_exit_pressed():
	get_tree().quit()

func _on_gui_giveup():
	$XRPlayer.drop_object()
	current_maze.queue_free()
	current_maze = null
	$BGM.stop()
	
	maze_start_time = 0
	
	$XRPlayer.pointer_enabled = true
	
	$MainScreen/Viewport/GUI.back_to_main()
