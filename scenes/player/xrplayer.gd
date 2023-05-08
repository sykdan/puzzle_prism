extends XROrigin3D

@onready var pointer = $LeftHand/Hand/Pointer

var laser_length: float = 1.0 :
	set(new_laser_length):
		if laser_length == new_laser_length:
			return
		var l: MeshInstance3D = pointer.get_node("Laser")
		l.transform.basis.y.y = new_laser_length
		l.transform.origin.y = new_laser_length / -2
		laser_length = new_laser_length

var fade_modulate: float = 1.0 :
	set(new_fade_modulate):
		$XRCamera3D/Curtain.material_override.albedo_color.a = fade_modulate
		fade_modulate = new_fade_modulate

var gripping = false
var gripped_object = null
var grip_last_transform = Transform3D.IDENTITY

var pointer_enabled = false :
	set(is_pointer_enabled):
		pointer.enabled = is_pointer_enabled
		pointer.visible = is_pointer_enabled
		pointer_enabled = is_pointer_enabled

func grip_object(object: Node3D):
	gripped_object = object
	var initial_transform = gripped_object.global_transform.orthonormalized()
	$Grip/Transform.global_transform = initial_transform
	grip_last_transform.origin = initial_transform.origin
	gripping = true

func drop_object():
	gripping = false
	gripped_object = null

func _ready():
	$XRCamera3D/Curtain.show()
	fade_modulate = fade_modulate
	pointer_enabled = pointer_enabled
	laser_length = laser_length
	
	if $XR.xr_interface is OpenXRInterface:
		var interface: OpenXRInterface = $XR.xr_interface
		interface.pose_recentered.connect(recenter)
	if $XR.xr_interface is WebXRInterface:
		var interface: WebXRInterface = $XR.xr_interface
		interface.reference_space_reset.connect(recenter)

func _process(delta):
	if pointer_enabled:
		if not pointer.is_colliding() or not hover():
			laser_length = 0.2

func hover():
	var obj = pointer.get_collider()
	if not obj.is_in_group("screen"):
		return false
	var screen: Screen = obj.get_node("../..")
	var dest_point = pointer.get_collision_point()
	var coords = screen.get_screen_position(dest_point)
	laser_length = pointer.global_position.distance_to(dest_point) / world_scale
	
	var e = InputEventMouseMotion.new()
	e.position = coords
	screen.dispatch_event(e)
	return true

func click(down: bool):
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

func _physics_process(delta):
	grip_tick()

func _on_start_xr_xr_ended():
	pass

func _on_start_xr_xr_started():
	recenter()
	
func grip_tick():
	var midpoint = (
		$RightHand/GripOrigin.global_position +
		$LeftHand/GripOrigin.global_position
	)/2
	$Grip.global_position = midpoint
	
	var pos_diff = $Grip/Transform.global_position - grip_last_transform.origin
	grip_last_transform.origin = $Grip/Transform.global_position
	
	var y1 = grip_last_transform.basis.y - $RightHand/GripOrigin.global_transform.basis.y
	var y2 = grip_last_transform.basis.y - $LeftHand/GripOrigin.global_transform.basis.y
	
	var up_dir = grip_last_transform.basis.y - (y1+y2)/2
	
	var final_rotation = $LeftHand.global_transform.looking_at($RightHand.global_position, up_dir).basis
	$Grip.transform.basis = final_rotation
	grip_last_transform.basis = final_rotation
	
	$RightHand/GripOrigin.global_transform.basis = final_rotation
	$LeftHand/GripOrigin.global_transform.basis = final_rotation
	
	if not gripping:
		return
	
	gripped_object.position += pos_diff
	gripped_object.transform.basis = $Grip/Transform.global_transform.basis

func translate_gripped_object(by: Vector3):
	if not gripped_object:
		return
	
	$Grip/Transform.global_position += by
	grip_tick()

func recenter():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

func _on_button_pressed(name: StringName, hand: StringName, pressed: bool):
	var hand_node: XRController3D
	match hand:
		&"left":
			hand_node = $LeftHand
		&"right":
			hand_node = $RightHand
		_:
			return
	
	if name == &"trigger_click":
		if not hand_node.is_ancestor_of(pointer) and pressed:
			pointer.reparent(hand_node.get_node("Hand"), false)
			pointer.position.x *= -1
		elif pointer_enabled:
			if pointer.is_colliding():
				click(pressed)
