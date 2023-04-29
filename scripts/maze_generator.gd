extends Node

# warning-ignore:UNUSED_SIGNAL
signal generated(maze_data, furthest_away)

var thread: Thread

func i2v(size: Vector2i, i: int) -> Vector2i: 
	return Vector2i(i % size.x, (i % (size.x*size.y)) / size.x)

func v2i(size: Vector2i, v: Vector2i) -> int:
	return v.x + size.x * v.y

class MazeNode:
	var added = false
	
	var position: Vector2i = Vector2i.ZERO 
	var next_walk: int = -1
	
	var x_passage = false
	var y_passage = false
	
	var distance_from_start = null

func __adjust_index_next_step(now: Vector2i, size: Vector2i, previous: Vector2i) -> Vector2i:
	while true:
		var direction := Vector2i.ZERO
		
		match randi_range(0,3):
			0:
				direction = Vector2i.UP
			1:
				direction = Vector2i.LEFT
			2:
				direction = Vector2i.RIGHT
			3:
				direction = Vector2i.DOWN
			_:
				direction = Vector2i.ZERO
		
		var would_be = now + direction
		
		if would_be == previous:
			continue
		if would_be.x < 0 or would_be.x >= size.x:
			continue
		if would_be.y < 0 or would_be.y >= size.y:
			continue
		
		return would_be
	return Vector2i.ZERO # Suppress editor errors. This will not be returned, ever.

func _generate_maze(size: Vector2i, start=null):
	if thread is Thread:
		print("wait shit")
		thread.wait_to_finish()
	else:
		thread = Thread.new()
	thread.start(func(): self.__generate_maze(size, start))

# Main generation fn
func __generate_maze(size: Vector2i, start: Vector2i):
	print("gen")
	var N = size.x * size.y
	
	# Initialize the game field
	var field: Array[MazeNode] = []
	field.resize(N)
	
	for i in range(N):
		var m = MazeNode.new()
		m.position = i2v(size, i)
		
		if m.position.x == size.x - 1:
			m.x_passage = true
		if m.position.y == size.y - 1:
			m.y_passage = true
		
		field[i] = m
	
	# We mark one random node as part of the maze to kick off the algorithm
	var start_node
	if start == null:
		start_node = field[randi() % N]
	else:
		start_node = field[v2i(size, start)]
	
	start_node.added = true
	start_node.distance_from_start = 0
	
	var walk = 0 # Go through all nodes
	var previous = Vector2i.ONE * -1
	
	var furthest_away: MazeNode = start_node
	
	while walk < N:
		var node: MazeNode = field[walk]
		var distance = 0
		if not node.added:
			while true:
				var next_walk = __adjust_index_next_step(node.position, size, previous)
				var next_i = v2i(size, next_walk)
				
				previous = node.position
				node.next_walk = next_i
				node = field[next_i]
				distance += 1
				
				while node.next_walk != -1:
					var goto_next = node.next_walk
					node.next_walk = -1
					distance -= 1
					node = field[goto_next]
				
				if node.added:
					distance += node.distance_from_start
					break
			
			node = field[walk]
			
			if distance > furthest_away.distance_from_start:
				furthest_away = node
			
			while true:
				var current = node.position
				node.distance_from_start = distance
				distance -= 1
				
				var next = node.next_walk
				if next == -1: break
				
				node.added = true
				node.next_walk = -1
				
				var diff = next - v2i(size, current)
				
				if diff == 1:
					node.x_passage = true
				elif diff == size.x:
					node.y_passage = true
					
				node = field[next]
				
				if diff == -1:
					node.x_passage = true
				elif diff == -size.x:
					node.y_passage = true
		
		walk += 1
	
	emit_signal(&"generated", field, furthest_away.position)

func _exit_tree():
	if thread is Thread:
		thread.wait_to_finish()
