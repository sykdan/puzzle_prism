extends Node3D

var maze = preload("res://scenes/maze/maze.tscn")

var is_holding_maze = false
var hands_can_hold = [false, false]

var _do_tween_upwards = false

var current_maze: Maze = null
var maze_start_time: int = 0

func player_ready():
	$XRPlayer.pointer_enabled = true
	var tw = create_tween()
	tw.tween_property($XRPlayer, "fade_modulate", 0, 2)
	await get_tree().create_timer(3).timeout

func player_error():
	OS.alert(tr("OXR_ERROR"), tr("OXR_ERROR_TITLE"))
	get_tree().quit(1)

func _process(delta):
	if not is_holding_maze:
		if $XRPlayer/LeftHand.is_button_pressed("grip_click") and $XRPlayer/RightHand.is_button_pressed("grip_click"):
			if hands_can_hold[0] and hands_can_hold[1]:
				$XRPlayer.grip_object(current_maze)
				is_holding_maze = true
	if is_holding_maze:
		if not ($XRPlayer/LeftHand.is_button_pressed("grip_click") and $XRPlayer/RightHand.is_button_pressed("grip_click")):
			is_holding_maze = false
			$XRPlayer.drop_object()

func _physics_process(delta):
	if _do_tween_upwards:
		$XRPlayer.translate_gripped_object(
			global_transform.basis.y * Shared.NODE_SIZE * delta
		)

func _on_marble_haptic(diff):
	var vibrate = diff / 15
	$XRPlayer/LeftHand.trigger_haptic_pulse("haptic", 1, vibrate, 0.05, 0)
	$XRPlayer/RightHand.trigger_haptic_pulse("haptic", 1, vibrate, 0.05, 0)

func _hand_can_grip(area: Area3D, hand: StringName, enter: bool):
	var hand_i: int
	
	if hand == &"left":
		hand_i = 0
	elif hand == &"right":
		hand_i = 1
	else:
		return
	
	if not area.get_parent() == current_maze:
		return
	
	hands_can_hold[hand_i] = enter

func _on_maze_level_finished():
	if is_holding_maze:
		_do_tween_upwards = true
		await get_tree().create_timer(1).timeout
		_do_tween_upwards = false

func _on_gui_play(difficulty, params: Vector3i):
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
	
	current_maze = maze.instantiate()
	
	current_maze.size = size
	current_maze.levels = levels
	current_maze.resize()
	var pos = $XRPlayer/XRCamera3D.global_position
	pos -= $XRPlayer/XRCamera3D.basis.z * 12
	pos -= $XRPlayer/XRCamera3D.basis.z * size.length()
	pos += Vector3.DOWN * 12
	
	current_maze.get_node("Marble").haptic.connect(_on_marble_haptic)
	current_maze.level_finished.connect(_on_maze_level_finished)
	current_maze.game_ended.connect(game_ended)
	
	add_child(current_maze)
	current_maze.global_position = pos
	current_maze.create_game()
	
	$MainScreen.enabled = false
	$MainScreen.hide()
	$XRPlayer.pointer_enabled = false
	
	maze_start_time = Time.get_unix_time_from_system()

func game_ended():
	$XRPlayer.drop_object()
	current_maze.queue_free()
	current_maze = null
	
	var time_took: int = ceil(Time.get_unix_time_from_system() - maze_start_time)
	maze_start_time = 0
	
	$MainScreen.enabled = true
	$MainScreen.show()
	$XRPlayer.pointer_enabled = true
	
	$MainScreen/Viewport/GUI.finish_game(time_took)

func _on_gui_at_screen(screen: NodePath):
	$Title.visible = screen == ^"MainMenu"
