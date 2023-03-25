extends Node

# warning-ignore:UNUSED_SIGNAL
signal generated(maze_data)

var thread: Thread

func i2v(size: Vector3i, i: int) -> Vector3i: 
	return Vector3i(i % size.x, (i % (size.x*size.y)) / size.x, i / (size.x*size.y))

func v2i(size: Vector3i, v: Vector3i) -> int:
	return v.x + size.x * v.y + (size.x * size.y) * v.z

class MazeNode:
	var added = false
	
	var position: Vector3i = Vector3i.ZERO 
	var next_walk: int = -1
	
	var x_passage = false
	var y_passage = false
	var z_passage = false
	
	var distance_from_start = null

func __adjust_index_next_step(now: Vector3i, size: Vector3i, previous: Vector3i) -> Vector3i:
	while true:
		var direction := Vector3i.ZERO
		
		match randi_range(0,5):
			0:
				direction = Vector3i.UP
			1:
				direction = Vector3i.LEFT
			2:
				direction = Vector3i.RIGHT
			3:
				direction = Vector3i.DOWN
			4:
				direction = Vector3i.FORWARD
			5:
				direction = Vector3i.BACK
			_:
				direction = Vector3i.ZERO
		
		var would_be = now + direction
		
		if would_be == previous:
			continue
		if would_be.x < 0 or would_be.x >= size.x:
			continue
		if would_be.y < 0 or would_be.y >= size.y:
			continue
		if would_be.z < 0 or would_be.z >= size.z:
			continue
		
		return would_be
	return Vector3.ZERO # Suppress editor errors. This will not be returned, ever.

# Main generation fn
func _generate_maze(size: Vector3i):
	var N = size.x * size.y * size.z
	
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
		if m.position.z == size.z - 1:
			m.z_passage = true
		
		field[i] = m
	
	# We mark one random node as part of the maze to kick off the algorithm
	var start = randi() % N
		
	var start_node = field[start]
	start_node.added = true
	start_node.distance_from_start = 0
	
	var walk = 0 # Go through all nodes
	var previous = Vector3i.ONE * -1
	
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
				elif diff > 0:
					node.z_passage = true
					
				node = field[next]
				
				if diff == -1:
					node.x_passage = true
				elif diff == -size.x:
					node.y_passage = true
				elif diff < 0:
					node.z_passage = true
		
		walk += 1
	
	emit_signal(&"generated", field)

func _exit_tree():
	if thread is Thread:
		thread.wait_to_finish()
