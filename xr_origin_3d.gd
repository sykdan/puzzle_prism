extends XROrigin3D

var gripping = false
var gripped_object = null
var grip_last_transform = Transform3D.IDENTITY

func grip_object(object: Node3D):
	gripped_object = object
	var initial_transform = gripped_object.global_transform.orthonormalized()
	$Grip/Transform.global_transform = initial_transform
	grip_last_transform.origin = initial_transform.origin
	gripping = true

func drop_object():
	gripping = false
	gripped_object = null

func _physics_process(delta):
	grip_tick()

func _on_start_xr_xr_ended():
	pass # Replace with function body.

func _on_start_xr_xr_started():
	pass # Replace with function body.

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
	
#	if slide_up > 0:
#		var movement = delta
#		slide_up -= delta
#		if slide_up < 0:
#			movement += slide_up
#		$HandMidpoint/Origin.translation += movement * $HandMidpoint/Origin.transform.basis.y * ($PuzzleCube.ChamberUnit + $PuzzleCube.WallUnit)/2
