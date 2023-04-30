extends XROrigin3D

signal recentered

@onready var pointer = $LeftHand/LeftHand/Pointer

var fade_modulate: float = 1.0 :
	set(new_fade_modulate):
		fade_modulate = new_fade_modulate
		$XRCamera3D/Curtain.material_override.albedo_color.a = fade_modulate

var gripping = false
var gripped_object = null
var grip_last_transform = Transform3D.IDENTITY

var pointer_enabled = true :
	set(is_pointer_enabled):
		%Pointer.enabled = is_pointer_enabled

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
	
	if $XR.xr_interface is OpenXRInterface:
		var interface: OpenXRInterface = $XR.xr_interface
		interface.pose_recentered.connect(recenter)

func _process(delta):
	if pointer_enabled:
		if pointer.is_colliding():
			hover()

func hover():
	var obj = pointer.get_collider()
	if not obj.is_in_group("screen"):
		return
	var screen: Screen = obj.get_node("../..")
	var coords = screen.get_screen_position(pointer.get_collision_point())
	
	var e = InputEventMouseMotion.new()
	e.position = coords
	screen.dispatch_event(e)

func click():
	var obj = pointer.get_collider()
	if not obj.is_in_group("screen"):
		return
	var screen: Screen = obj.get_node("../..")
	var coords = screen.get_screen_position(pointer.get_collision_point())
	
	var e = InputEventMouseButton.new()
	e.position = coords
	e.button_index = MOUSE_BUTTON_LEFT
	screen.dispatch_event(e)

func _physics_process(delta):
	grip_tick()

func _on_start_xr_xr_ended():
	pass # Replace with function body.

func _on_start_xr_xr_started():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

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
	emit_signal(&"recentered")

func _on_left_hand_button_pressed(name):
	if name == &"trigger_click":
		if not $LeftHand.is_ancestor_of(pointer):
			pointer.reparent($LeftHand/LeftHand, false)
		elif pointer_enabled:
			if pointer.is_colliding():
				click()

func _on_right_hand_button_pressed(name):
	if name == &"trigger_click":
		if not $RightHand.is_ancestor_of(pointer):
			pointer.reparent($RightHand/RightHand, false)
		elif pointer_enabled:
			if pointer.is_colliding():
				click()
