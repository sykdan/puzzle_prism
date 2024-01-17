func _transform_gripped_object():    
    |$Grip|.global_position = (|$RightHand/GripOrigin|.global_position + |$LeftHand/GripOrigin|.global_position)/2
    
    var pos_diff = |$Grip/Transform|.global_position - _grip_last_transform.origin
    _grip_last_transform.origin = |$Grip/Transform|.global_position
    
    var y1 = _grip_last_transform.basis.y - |$RightHand/GripOrigin|.global_transform.basis.y
    var y2 = _grip_last_transform.basis.y - |$LeftHand/GripOrigin|.global_transform.basis.y
    
    var up_dir = _grip_last_transform.basis.y - (y1+y2)/2
    
    var final_rotation = |$LeftHand|.global_transform.looking_at(|$RightHand|.global_position, up_dir).basis
    |$Grip|.transform.basis = final_rotation
    _grip_last_transform.basis = final_rotation
    
    |$RightHand/GripOrigin|.global_transform.basis = final_rotation
    |$LeftHand/GripOrigin|.global_transform.basis = final_rotation
    
    if not gripped_object:
        return
    
    gripped_object.position += pos_diff
    gripped_object.transform.basis = |$Grip/Transform|.global_transform.basis