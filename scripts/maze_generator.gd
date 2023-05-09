extends Node

## Maze Generator
## Wilson algorithm implementation in GDScript.

var t: Thread

# Emitted once a maze has been generated (for use with threading)
signal generated(maze_data, furthest_away)

# Convert index integer to Vector2i representation. 
func i2v(size: Vector2i, i: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(i % size.x, (i % (size.x*size.y)) / size.x)

# Convert Vector2i to index integer representation.
func v2i(size: Vector2i, v: Vector2i) -> int:
	return v.x + size.x * v.y

# Helper class that helps represent the maze as a graph.
class MazeNode:
	var added: bool = false
	
	var position: Vector2i = Vector2i.ZERO 
	var next_index: int = -1
	
	var x_passage: bool = false
	var y_passage: bool = false
	
	var distance_from_start: int

# Generates a new step in the maze, ensuring we don't go out of bounds.
func step(now: Vector2i, size: Vector2i, previous: Vector2i) -> Vector2i:
	while true:
		var direction: Vector2i
		
		match randi_range(0,3):
			0:
				direction = Vector2i.UP
			1:
				direction = Vector2i.LEFT
			2:
				direction = Vector2i.RIGHT
			3:
				direction = Vector2i.DOWN
			_: # Needed to suppress errors, never used
				direction = Vector2i.ZERO
		
		var would_be = now + direction
		
		if would_be == previous:
			continue
		if would_be.x < 0 or would_be.x >= size.x:
			continue
		if would_be.y < 0 or would_be.y >= size.y:
			continue
		
		return would_be

	# Needed to suppress errors, never used
	return Vector2i.ZERO

func generate_maze(size: Vector2i, start: Vector2i):
	if t is Thread:
		t.wait_to_finish()
	
	t = Thread.new()
	t.start(_generate_maze.bind(size, start))

# Generation function
func _generate_maze(size: Vector2i, start: Vector2i):
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
	
	# Mark one node as part of the maze to start the algorithm
	var start_node: MazeNode
	# Check if we were asked to start from a specific location
	if start == null:
		start_node = field[randi() % N]
	else:
		start_node = field[v2i(size, start)]
	
	start_node.added = true
	start_node.distance_from_start = 0
	
	# The algorithm works by looping through all nodes. This is a pointer to the current one.
	var walk = 0
	# Previously stepped on node's position. Prevents going back to where you just came from.
	var previous = Vector2i.ONE * -1
	# The node that requires the most steps to reach is the goal. Store it here.
	var goal: MazeNode = start_node
	
	while walk < N:
		var node: MazeNode = field[walk] # Pointer to the currently walked node
		var distance = 0
		
		if not node.added: # Skip over added nodes
			while true: # Randomly walk until there's a path to an added node
				var next_position = step(node.position, size, previous)
				var next_index = v2i(size, next_position)
				
				# Perform the step, link the current node to the next.
				previous = node.position
				node.next_index = next_index
				node = field[next_index]
				distance += 1
				
				# If there's a loop, trace it and erase it.
				while node.next_index != -1:
					var goto_next = node.next_index
					node.next_index = -1
					distance -= 1
					node = field[goto_next]
				
				# Stop operating if we've found a node that is in the maze
				if node.added:
					distance += node.distance_from_start
					break
			
			# Set the pointer back to the node we started on
			node = field[walk]
			
			# If we're farther away than anything before, set the node as the goal
			if distance > goal.distance_from_start:
				goal = node
			
			# Now trace the path again and add all nodes to the maze, calculating their
			# distance from the start and unlinking them.
			while true:
				var current = node.position
				node.distance_from_start = distance
				distance -= 1
				
				var next = node.next_index
				if next == -1: break
				
				node.added = true
				node.next_index = -1

				# The resulting maze is represented as a grid.
				# There's no such thing as an `edge` in a 
				# traditional graph sense, only the information if
				# there's a wall towards X+ or Y+.

				var diff = i2v(size, next) - current

				# If the next node is to the right or bottom (X+ or Y+),
				# we must make a wall on the current node.
				if diff.x == 1: 
					node.x_passage = true
				elif diff.y == 1:
					node.y_passage = true
					
				node = field[next]
				
				# If the next node is to the left or top (X- or Y-),
				# we must make a wall on the next node in the opposite direction
				if diff.x == -1:
					node.x_passage = true
				elif diff.y == -1:
					node.y_passage = true
		
		walk += 1
	
	emit_signal.call_deferred(&"generated", field, goal.position)
