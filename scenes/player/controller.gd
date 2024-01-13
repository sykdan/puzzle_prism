extends XRController3D

var grip_targets = []

func _ready():
	$Hand/Grip.area_entered.connect(_on_area_intersect.bind(true))
	$Hand/Grip.area_exited.connect(_on_area_intersect.bind(false))

func _resolve_grip_target(area: Node) -> Node:
	var root = get_tree().get_root()
	while area != root:
		area = area.get_parent()
		if area.is_in_group(&"grippable_target"):
			return area
	return null

func _on_area_intersect(area: Area3D, enter: bool):
	if area.is_in_group(&"grippable_area"):
		var target: Node = _resolve_grip_target(area)
		if not target:
			return

		if enter:
			grip_targets.push_back(target)
		else:
			grip_targets.erase(target)
