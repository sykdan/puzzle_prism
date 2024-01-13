extends XROrigin3D

## Emitted when an OpenXR error has occurred.
signal init_error(reason)
## Emitted when OpenXR initialises successfully
signal init_done

@onready var pointer: RayCast3D = $LeftHand/Hand/Pointer

var black_fade_ratio: float = 1.0 :
	set(new_black_fade_ratio):
		$XRCamera3D/Curtain.material_override.albedo_color.a = new_black_fade_ratio
		black_fade_ratio = new_black_fade_ratio

var gripped_object = null
var _grip_last_transform = Transform3D.IDENTITY

## Whether to display the laser pointer (for UI)
var pointer_enabled = false :
	set(is_pointer_enabled):
		pointer.enabled = is_pointer_enabled
		pointer.visible = is_pointer_enabled
		pointer_enabled = is_pointer_enabled

func _ready():
	$XRCamera3D/Curtain.show()
	black_fade_ratio = black_fade_ratio
	pointer_enabled = pointer_enabled
	world_scale = 40.0
	_set_laser_length(0.2)
	
	if not $XRManager.initialize():
		return
	
	if $XRManager.xr_interface_name == &"OpenXR":
		var interface = $XRManager.xr_interface
		interface.pose_recentered.connect(recenter)
	
	if $XRManager.xr_interface_name == &"WebXR":
		var interface = $XRManager.xr_interface
		interface.reference_space_reset.connect(recenter)

func _process(_delta):
	if pointer_enabled:
		if not pointer.is_colliding() or not _laser_point():
			_set_laser_length(0.2)

func _physics_process(_delta):
	_transform_gripped_object()

func _on_xr_started():
	await get_tree().create_timer(0.5).timeout
	recenter()
	init_done.emit()

## Attach an object to the controllers
func _grip_object(object: Node3D):
	gripped_object = object

	var initial_transform = gripped_object.global_transform.orthonormalized()
	$Grip/Transform.global_transform = initial_transform
	_grip_last_transform.origin = initial_transform.origin

## Force the held object to be dropped
func drop_object():
	gripped_object = null

func _set_laser_length(length: float):
	var l: MeshInstance3D = pointer.get_node("Laser")
	l.transform.basis.y.y = length
	l.transform.origin.y = length / -2

## Analyses the laser's collider and creates a mouse hover event on the screen, if it exists.
## Returns true/false whether the laser actually collided with a screen or not. 
func _laser_point() -> bool:
	var obj = pointer.get_collider()
	if not obj.is_in_group("screen"):
		return false
	var screen: Screen = obj.get_node("../..")
	var dest_point = pointer.get_collision_point()
	var coords = screen.get_screen_position(dest_point)
	_set_laser_length(pointer.global_position.distance_to(dest_point) / world_scale)
	
	var e = InputEventMouseMotion.new()
	e.position = coords
	screen.dispatch_event(e)
	return true

func _click(down: bool):
	var obj = pointer.get_collider()
	if not obj.is_in_group("screen"):
		return
	var screen: Screen = obj.get_node("../..")
	var coords = screen.get_screen_position(pointer.get_collision_point())
	
	var e = InputEventMouseButton.new()
	e.position = coords
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	screen.dispatch_event(e)

func _transform_gripped_object():
	# A lot of this code makes use of the fact Godot nodes inherit their transformations.
	# For instance, a Node3D that is a child of another Node3D is offset from its parent.
	# Setting global_* properties overrides this behaviour for that instruction only. 
	# This saves us a lot of math

	$Grip.global_position = ($RightHand/GripOrigin.global_position + $LeftHand/GripOrigin.global_position)/2
	
	var pos_diff = $Grip/Transform.global_position - _grip_last_transform.origin
	_grip_last_transform.origin = $Grip/Transform.global_position
	
	var y1 = _grip_last_transform.basis.y - $RightHand/GripOrigin.global_transform.basis.y
	var y2 = _grip_last_transform.basis.y - $LeftHand/GripOrigin.global_transform.basis.y
	
	var up_dir = _grip_last_transform.basis.y - (y1+y2)/2
	
	var final_rotation = $LeftHand.global_transform.looking_at($RightHand.global_position, up_dir).basis
	$Grip.transform.basis = final_rotation
	_grip_last_transform.basis = final_rotation
	
	$RightHand/GripOrigin.global_transform.basis = final_rotation
	$LeftHand/GripOrigin.global_transform.basis = final_rotation
	
	if not gripped_object:
		return
	
	gripped_object.position += pos_diff
	gripped_object.transform.basis = $Grip/Transform.global_transform.basis

## Allows the gripped object to be moved while keeping the math responsible for movement intact.
func translate_gripped_object(by: Vector3):
	if not gripped_object:
		return
	
	$Grip/Transform.global_position += by
	_transform_gripped_object()

## Reset VR rotation.
func recenter():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

func _get_hand(hand: StringName) -> XRController3D:
	var hand_node: XRController3D = null
	match hand:
		&"left":
			hand_node = $LeftHand
		&"right":
			hand_node = $RightHand
	return hand_node

func _find_grip_target() -> Node3D:
	for target in $LeftHand.grip_targets:
		if target in $RightHand.grip_targets:
			return target
	return null

func _on_button_pressed(label: StringName, hand: StringName, pressed: bool):
	var hand_node: XRController3D = _get_hand(hand)
	
	if label == &"trigger_click":
		if not hand_node.is_ancestor_of(pointer) and pressed:
			pointer.reparent(hand_node.get_node("Hand"), false)
			pointer.position.x *= -1
		elif pointer_enabled:
			if pointer.is_colliding():
				_click(pressed)
	
	if label == &"grip_click":
		if not gripped_object and $LeftHand.is_button_pressed("grip_click") and $RightHand.is_button_pressed("grip_click"):
			var target = _find_grip_target()
			if target:
				_grip_object(target)
		elif gripped_object and not ($LeftHand.is_button_pressed("grip_click") and $RightHand.is_button_pressed("grip_click")):
			drop_object()
