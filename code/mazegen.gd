extends Node

var t: Thread

## Signal emitovany jakmile je bludiste vygenerovano (kvuli threadovani nelze pouzit return z funkce)
signal generated(maze_data, furthest_away)

# Pomocne funkce pro prepocitavani indexu v listu na pozicni vektor a naopak.

## Prevede integer na Vector2i
func i2v(size: Vector2i, i: int) -> Vector2i:
    @warning_ignore("integer_division")
    return Vector2i(i % size.x, (i % (size.x*size.y)) / size.x)

## Prevede Vector2i na integer
func v2i(size: Vector2i, v: Vector2i) -> int:
    return v.x + size.x * v.y

## Trida, ktera reprezentuje jednu bunku (komnatu) v bludisti
class MazeNode:
    var added: bool = false
    
    var position: Vector2i = Vector2i.ZERO 
    var next_index: int = -1
    
    var x_passage: bool = false
    var y_passage: bool = false
    
    var distance_from_start: int

## Pomocna funkce, ktera vrati pozici, na kterou ma algoritmus prejit.
## Zajistuje, ze algoritmus nevykroci z hranic bludiste 
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

# Pozada o vygenerovani bludiste
func generate_maze(size: Vector2i, start: Vector2i):
    if t is Thread:
        t.wait_to_finish()
    
    t = Thread.new()
    t.start(_generate_maze.bind(size, start))

## Vygeneruje bludiste a zavola signal po dokonceni.
## Melo by byt spusteno v threadu, aby to neblokovalo zbytek hry
func _generate_maze(size: Vector2i, start: Vector2i):
    var N = size.x * size.y
    
    # Pole bunek
    var field: Array[MazeNode] = []
    field.resize(N)
    
    for i in range(N):
        var m = MazeNode.new()
        m.position = i2v(size, i)
        
        # Bunky na okrajich by nemely mit zdi splyvajici s okrajem bludiste
        if m.position.x == size.x - 1:
            m.x_passage = true
        if m.position.y == size.y - 1:
            m.y_passage = true
        
        field[i] = m
    
    # Jedna bunka je oznacena jako zahrnuta v bludisti
    var start_node: MazeNode
    # Zkontrolovat, zda-li ma algoritmus zacinat na urictem miste
    if start == null:
        start_node = field[randi() % N]
    else:
        start_node = field[v2i(size, start)]
    
    start_node.added = true
    start_node.distance_from_start = 0
    
    # Algoritmus prochazi vsechny bunky. Toto je index soucasne prochazene bunky
    var walk = 0
    # Bunka, kterou algoritmus naposledy presel. Timto se na ni nebude zbytecne vracet.
    var previous = Vector2i.ONE * -1
    # Prubezne ukladat nejvzdalenejsi bunku
    var goal: MazeNode = start_node
    
    while walk < N:
        var node: MazeNode = field[walk] # Bunka ze ktere jsme zacali
        var distance = 0
        
        if not node.added: # Jiz zahrnute bunky preskocime
            while true: # Nahodna chuze, nez nenarazime na zahrnutou bunku
                var next_position = step(node.position, size, previous)
                var next_index = v2i(size, next_position)
                
                # Provest krok a spojit soucasnou bunku k te nasledujici
                previous = node.position
                node.next_index = next_index
                node = field[next_index]
                distance += 1
                
                # Pokud je smycka, projit ji a vymazat
                while node.next_index != -1:
                    var goto_next = node.next_index
                    node.next_index = -1
                    distance -= 1
                    node = field[goto_next]
                
                # Prestat loopovat pokud jsme nasli zahrnutou bunku
                if node.added:
                    distance += node.distance_from_start
                    break
            
            # Pointer zpatky na bunku ze ktere jsme zacali
            node = field[walk]
            
            # Pokud jsme nasli vzdalenejsi bunku nez jsme doposud znali, nastavit ji jako cil
            if distance > goal.distance_from_start:
                goal = node
            
            # Nyni projdeme cestu znovu a pridame do bludiste zasazene bunky, odpojime je, a zaroven
            # vypocitame jejich vzdalenost od startu. 
            while true:
                var current = node.position
                node.distance_from_start = distance
                distance -= 1
                
                var next = node.next_index
                if next == -1: break
                
                node.added = true
                node.next_index = -1

                var diff = i2v(size, next) - current

                if diff.x == 1: 
                    node.x_passage = true
                elif diff.y == 1:
                    node.y_passage = true
                    
                node = field[next]
                
                if diff.x == -1:
                    node.x_passage = true
                elif diff.y == -1:
                    node.y_passage = true
        
        walk += 1
    
    # Vyvolat signal v threadu nelze, zaradime to do fronty
    emit_signal.call_deferred(&"generated", field, goal.position)