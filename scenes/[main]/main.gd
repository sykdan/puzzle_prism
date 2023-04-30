extends Node3D

var ms: Vector2 = Vector2.ZERO

var holding = false
var ready_hands = [false, false]

var _do_tween_upwards = false

func _ready():
	ms = get_viewport().get_mouse_position()
	$Maze.size = Vector2i(7, 7)
	$Maze.levels = 7
	$Maze.resize()
	$Maze.create_game()
	
	var tw = create_tween()
	tw.tween_property($XRPlayer, "fade_modulate", 0, 2)

func generated(maze):
	$Maze.add_maze_data(maze)

func _process(delta):
	if not holding:
		if $XRPlayer/LeftHand.is_button_pressed("grip_click") and $XRPlayer/RightHand.is_button_pressed("grip_click"):
			if ready_hands[0] and ready_hands[1]:
				holding = true
				$XRPlayer.grip_object($Maze)
	if holding:
		if not ($XRPlayer/LeftHand.is_button_pressed("grip_click") and $XRPlayer/RightHand.is_button_pressed("grip_click")):
			holding = false
			$XRPlayer.drop_object()

func _physics_process(delta):
	if _do_tween_upwards:
		$XRPlayer.translate_gripped_object(
			global_transform.basis.y * Shared.NODE_SIZE * delta
		)

func _on_button_pressed():
	var box = Vector3i(
		int($X.value),
		int($Y.value),
		int($Z.value)
	)
	
	$Maze.size = box

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
	
	if area != $Maze/BoxArea:
		return
	
	ready_hands[hand_i] = enter

func _on_maze_level_finished():
	if holding:
		_do_tween_upwards = true
		await get_tree().create_timer(1).timeout
		_do_tween_upwards = false
