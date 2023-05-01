extends Node3D

var maze = preload("res://scenes/maze/maze.tscn")

var current_maze: Maze = null
var is_holding_maze = false
var selected_difficulty = null
var hands_can_hold = [false, false]

var _do_tween_upwards = false

func _ready():
	$XRPlayer.pointer_enabled = true
	var tw = create_tween()
	tw.tween_property($XRPlayer, "fade_modulate", 0, 2)

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
	
	if current_maze == null:
		return
	if not current_maze.is_ancestor_of(area):
		return
	
	hands_can_hold[hand_i] = enter

func _on_maze_level_finished():
	if is_holding_maze:
		_do_tween_upwards = true
		await get_tree().create_timer(1).timeout
		_do_tween_upwards = false

func _on_xr_player_recentered():
	pass # Replace with function body.

func select_difficulty(difficulty):
	selected_difficulty = difficulty
	
	$DetailsScreen/Viewport/Detail/Controls/Records.show()
	if difficulty == &"easy":
		_setup_leaderboard_items(SaveFile.scores_easy)
		$DetailsScreen/Viewport/Detail/PuzzleType.text = "Lehká"
	elif difficulty == &"medium":
		_setup_leaderboard_items(SaveFile.scores_medium)
		$DetailsScreen/Viewport/Detail/PuzzleType.text = "Střední"
	elif difficulty == &"hard":
		_setup_leaderboard_items(SaveFile.scores_hard)
		$DetailsScreen/Viewport/Detail/PuzzleType.text = "Těžká"
	elif difficulty == &"custom":
		$DetailsScreen/Viewport/Detail/Controls/Records.hide()
		$DetailsScreen/Viewport/Detail/PuzzleType.text = "Vlastní"
	
	$MainScreen.enabled = false
	$MainScreen.hide()
	$DetailsScreen.enabled = true
	$DetailsScreen.show()

func _setup_leaderboard_items(items: Array):
	var r = $DetailsScreen/Viewport/Detail/Controls/Records
	
	for c in r.get_children():
		if c is Label: continue
		c.get_node("RecordBox/Name").text = ""
		c.get_node("RecordBox/Time").text = ""
	
	var idx = 1
	for score in items:
		var c = r.get_child(idx)
		c.get_node("RecordBox/Name").text = score.name
		var time = int(score.time)
		c.get_node("RecordBox/Time").text = "%02d:%02d" % [time / 60, time % 60]
		idx += 1

func _on_back_pressed():
	$MainScreen.enabled = true
	$MainScreen.show()
	$DetailsScreen.enabled = false
	$DetailsScreen.hide()

func _on_play_pressed():
	var size: Vector2i
	var levels: int
	
	if selected_difficulty == &"easy":
		size = Vector2i.ONE * 5
		levels = 5
	elif selected_difficulty == &"medium":
		size = Vector2i.ONE * 8
		levels = 8
	elif selected_difficulty == &"hard":
		size = Vector2i.ONE * 14
		levels = 14
	
	current_maze = maze.instantiate()
	
	current_maze.size = size
	current_maze.levels = levels
	current_maze.resize()
	current_maze.global_position = $XRPlayer/XRCamera3D.global_position - $XRPlayer/XRCamera3D.basis.z * 10
	
	current_maze.get_node("Marble").haptic.connect(_on_marble_haptic)
	current_maze.level_finished.connect(_on_maze_level_finished)
	current_maze.game_ended.connect(game_ended)
	
	
	add_child(current_maze)
	current_maze.create_game()
	
	$DetailsScreen.enabled = false
	$DetailsScreen.hide()
	$XRPlayer.pointer_enabled = false

func game_ended():
	current_maze.queue_free()
	current_maze = null
	_on_back_pressed()
