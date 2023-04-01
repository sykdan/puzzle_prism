extends Node3D

var ms: Vector2 = Vector2.ZERO

var interface : XRInterface

var holding = false



func _ready():
	ms = get_viewport().get_mouse_position()
	
	var size = Vector3i.ONE * 7
	$Maze.size = size
	MazeGen.generated.connect(self.generated)
	MazeGen._generate_maze(size)

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
#func aaa_process(delta):
#	var midpoint = (
#		$Player.right_hand.get_node("Origin").global_transform.origin + 
#		$Player.left_hand.get_node("Origin").global_transform.origin
#	)/2
#	$HandMidpoint.global_transform.origin = midpoint
#
#	var pos_diff = $HandMidpoint/Origin.global_transform.origin - pos_last
#	pos_last = $HandMidpoint/Origin.global_transform.origin
#
#	var d1 = bas_last.y - $Player.right_hand.get_node("Origin").global_transform.basis.y
#	var d2 = bas_last.y - $Player.left_hand.get_node("Origin").global_transform.basis.y
#
#	var d = (d1+d2)/2
#
#	var up_dir = bas_last.y - d
#
#	bas_last = $Player.left_hand.global_transform.looking_at($Player.right_hand.global_transform.origin, up_dir).basis
#	$HandMidpoint.transform.basis = bas_last
#
#	$Player.right_hand.get_node("Origin").global_transform.basis = bas_last
#	$Player.left_hand.get_node("Origin").global_transform.basis = bas_last
#
#	if not can_control: return
#
#	if is_tilting:
#		$PuzzleCube.position += pos_diff
#		$PuzzleCube.tilt = $HandMidpoint/Origin.global_transform.basis
#
#	if slide_up > 0:
#		var movement = delta
#		slide_up -= delta
#		if slide_up < 0:
#			movement += slide_up
#		$HandMidpoint/Origin.translation += movement * $HandMidpoint/Origin.transform.basis.y * ($PuzzleCube.ChamberUnit + $PuzzleCube.WallUnit)/2


func _on_button_pressed():
	var box = Vector3i(
		int($X.value),
		int($Y.value),
		int($Z.value)
	)
	
	$Maze.size = box
