extends Node2D

var size

func _ready():
	MazeGen.generated.connect(generated)

func generated(mz):
	for c in $Maze.get_children(): c.queue_free()
	for node in mz:
		var n = $MazeNode.duplicate()
		$Maze.add_child(n)
		n.position = node.position * 40.0
		if node.x_passage:
			n.get_node("X_passage").hide()
		if node.y_passage:
			n.get_node("Y_passage").hide()
		n.get_node("Label").text = str(node.distance_from_start)

func _on_go_pressed():
	var size = Vector2i($Control/X.value, $Control/Y.value)
	MazeGen._generate_maze(size, $Control/Start.value)
