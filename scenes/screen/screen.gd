extends Node3D
class_name Screen

func _ready():
	$Screen/ScreenArea/Shape.shape.size.x = $Screen.mesh.size.x
	$Screen/ScreenArea/Shape.shape.size.y = $Screen.mesh.size.y
	$Screen.mesh.material.albedo_texture.viewport_path = "./Viewport"

func get_screen_position(global: Vector3):
	var local = $Screen.to_local(global) / $Screen/ScreenArea/Shape.shape.size
	var local_xy = (Vector2(local.x, local.y) + Vector2.ONE * 0.5) * Vector2(1, -1)
	return local_xy.clamp(Vector2.ZERO, Vector2.ONE) * Vector2($Viewport.size)

func dispatch_event(event: InputEvent):
	$Viewport.push_input(event)
