extends Node3D

var ms: Vector2 = Vector2.ZERO
var interface : XRInterface
var holding = false

func _ready():
	ms = get_viewport().get_mouse_position()
	$Maze.size = Vector2i(5, 4)
	$Maze.levels = 3
	$Maze.resize()
	$Maze.create_game()
	
	var tw = create_tween()
	tw.tween_property($XRPlayer, "fade_modulate", 0, 2)

func generated(maze):
	$Maze.add_maze_data(maze)

func _process(delta):
	if not holding:
		if $XRPlayer/LeftHand.is_button_pressed("grip_click") and $XRPlayer/RightHand.is_button_pressed("grip_click"):
			holding = true
			$XRPlayer.grip_object($Maze)
	if holding:
		if not ($XRPlayer/LeftHand.is_button_pressed("grip_click") and $XRPlayer/RightHand.is_button_pressed("grip_click")):
			holding = false
			$XRPlayer.drop_object()

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
