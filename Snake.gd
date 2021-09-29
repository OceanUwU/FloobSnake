extends Node2D

signal eat
signal win
signal die

const MOVES = ['ui_right', 'ui_down', 'ui_left', 'ui_up']
const MOVE_MOVEMENTS = [[1, 0], [0, 1], [-1, 0], [0, -1]]
const MOVE_SOUNDS = []
const DIRECTION_CURVE = [0.0 * PI, 0.5 * PI, 1.0 * PI, -0.5 * PI]
const SNAKE_ARC_POINTS = 40
const SNAKE_SIZE = 0.9
const SLOWING_TIME = 0.5
const OUTLINE_SIZE = 0.06
const DEATH_AREA = 0.5
const CRASH_TIME = (1.0 / 8) * 3 #3 frames at 8fps
const SLIDE_TIME = 0.5
const DEATH_TIME = CRASH_TIME + SLIDE_TIME
const LIMB_SIZE = 50
const MINIMUM_DRAG = 20
const SNAKE_COLORS = [
    Color.greenyellow,
    Color.yellow,
    Color.crimson,
    Color.aqua,
    Color.mediumblue,
    Color.gray,
    Color.whitesmoke,
    Color.purple,
    Color.sienna,
    Color.orange,
    Color.forestgreen,
    Color.hotpink
]
const SNAKE_DARKEN = 0.1

var eyes
var legs
var length
var occupied
var recently_unoccupied
var turns
var recently_unturned
var direction
var moves_queued
var moving
var moved
var alive
var slowing
var slowing_progress
var looked_for_crash
var death_progress
var enlarge_progress
var tile_progress #how far along the current tile the snake is
var snake_color
var half_tile
var swipe_start

func _ready():
    randomize()
    eyes = $Eyes
    legs = $Legs
    for i in range(len(MOVES)):
        MOVE_SOUNDS.append(load('res://assets/floob/dir'+str(i)+'.mp3'))

func start():
    eyes.animation = 'alive'
    snake_color = SNAKE_COLORS[randi() % len(SNAKE_COLORS)]
    half_tile = Globals.tilesize / 2
    alive = true
    slowing = false
    slowing_progress = 0
    looked_for_crash = false
    death_progress = 0
    enlarge_progress = 1
    length = 1
    occupied = [[max(1, floor(Globals.boardsize/2)-1-1), max(1, floor(Globals.boardsize/2))]]
    for i in range(length-1):
        occupied.append([occupied[i][0]-1, occupied[i][1]])
    turns = []
    for _i in range(length):
        turns.append(false)
    direction = 0
    moves_queued = []
    moving = false
    moved = false
    tile_progress = 0.0
    var scale = Vector2(1,1) * ((500.0 / 50.0) / Globals.boardsize)
    $Area2D.position = Vector2(-1000, -1000)
    $Area2D.scale = scale
    $DeathParticles.scale = scale
    eyes.scale = scale
    legs.scale = scale
    update()

func crash():
    alive = false
    var particle_dir = (direction + 2) % 4
    $DeathParticles.position = line_points(Globals.tile_vector([occupied[0][0]+MOVE_MOVEMENTS[direction][0], occupied[0][1]+MOVE_MOVEMENTS[direction][1]]), particle_dir, Globals.tilesize * SNAKE_SIZE)[1]
    $DeathParticles.rotation = float(particle_dir) / 2 * PI
    $DeathParticles.emitting = true
    $Die.play()
    animate_eyes_crash()

func animate_eyes_crash():
    eyes.frame = 0
    eyes.animation = 'crashing'
    yield(eyes, 'animation_finished')
    eyes.animation = 'dazed'
    pass

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            swipe_start = event.get_position()
        else:
            swipe(event.get_position())

func swipe(swipe_end):
    if alive && !slowing:
        if swipe_start == null: 
            return
        var movement = swipe_end - swipe_start
        if abs(movement.x) > MINIMUM_DRAG && abs(movement.x) > abs(movement.y):
            if movement.x > 0:
                move(0)
            else:
                move(2)
        elif abs(movement.y) > MINIMUM_DRAG && abs(movement.y) > abs(movement.x):
            if movement.y > 0:
                move(1)
            else:
                move(3)
    

func _process(_delta):
    if alive && !slowing:
        for i in range(len(MOVES)):
            if Input.is_action_just_pressed(MOVES[i]):
                move(i)
    if moving:
        update() #draw

func move(dir):
    if ((MOVE_MOVEMENTS[direction if len(moves_queued) == 0 else moves_queued[len(moves_queued)-1]][0] == 0) != (MOVE_MOVEMENTS[dir][0] == 0)) || (!moving && direction == dir):
        if !moved:
            moving = true
            moved = true
            looked_for_crash = false
            if direction != dir:
                turns[0] = direction
                direction = dir
            $Turn.stream = MOVE_SOUNDS[direction]
            $Turn.play()
        else:
            moves_queued.append(dir)

func _physics_process(delta):
    if moving:
        if alive:
            if slowing:
                slowing_progress = min(1, slowing_progress + delta * (SLOWING_TIME * Globals.snake_speed))
                tile_progress = sin(slowing_progress * (0.5 * PI)) * 0.49
                enlarge_progress = tile_progress-0.01
                if (slowing_progress == 1):
                    moving = false
                    $Win.play()
                    emit_signal('win')
            else:
                tile_progress += delta * Globals.snake_speed
                if enlarge_progress < 1:
                    enlarge_progress = min(1, enlarge_progress + delta * Globals.snake_speed)
        else:
            death_progress += delta
            if death_progress < CRASH_TIME: #crashing
                tile_progress = DEATH_AREA + sin((death_progress / CRASH_TIME) * PI) * 0.14
            elif death_progress < DEATH_TIME: #sliding
                tile_progress = DEATH_AREA - sin(((death_progress - CRASH_TIME) / SLIDE_TIME / 2) * PI) * 0.25
            else:
                moving = false
                emit_signal('die')
        
    if !looked_for_crash && tile_progress >= DEATH_AREA:
        looked_for_crash = true
        var new_tile = [occupied[0][0]+MOVE_MOVEMENTS[direction][0], occupied[0][1]+MOVE_MOVEMENTS[direction][1]]
        
        #detect crash
        if (new_tile[0] < 0 || new_tile[0] >= Globals.boardsize || new_tile[1] < 0 || new_tile[1] >= Globals.boardsize):
            return crash()
        for i in range(1, len(occupied)-1):
            if (new_tile[0] == occupied[i][0] && new_tile[1] == occupied[i][1]):
                return crash()
    
    if tile_progress >= 1:
        #move to next tile
        tile_progress -= 1
        looked_for_crash = false
        if moved:
            moved = false
        recently_unturned = turns.pop_back()
        var new_tile = [occupied[0][0]+MOVE_MOVEMENTS[direction][0], occupied[0][1]+MOVE_MOVEMENTS[direction][1]]
        $Area2D.position = Globals.tile_vector(new_tile)
        occupied.push_front(new_tile)
        recently_unoccupied = occupied.pop_back()
        turns.push_front(false)
        if len(moves_queued) > 0:
            turns[0] = direction
            direction = moves_queued[0]
            moves_queued.pop_front()
            moved = true
            $Turn.stream = MOVE_SOUNDS[direction]
            $Turn.play()

func arc_info(tile, from_angle, to_angle):
    var center = tile
    match from_angle:
        2: center.x += Globals.tilesize
        3: center.y += Globals.tilesize
    match to_angle:
        0: center.x += Globals.tilesize
        1: center.y += Globals.tilesize
    var from = DIRECTION_CURVE[from_angle]
    var to = DIRECTION_CURVE[(to_angle + 2) % 4]
    if from_angle == 2:
        from = to * 2
    if to_angle == 0:
        to = from * 2
    return [center, from, to]

func line_points(tile, dir, end):
    var from
    var to
    match dir:
        0: #right
            from = Vector2(tile.x, tile.y + half_tile)
            to = Vector2(tile.x + end, tile.y + half_tile)
        1: #down
            from = Vector2(tile.x + half_tile, tile.y)
            to = Vector2(tile.x + half_tile, tile.y + end)
        2: #left
            from = Vector2(tile.x + Globals.tilesize, tile.y + half_tile)
            to = Vector2(tile.x + Globals.tilesize - end, tile.y + half_tile)
        3: #up
            from = Vector2(tile.x + half_tile, tile.y + Globals.tilesize)
            to = Vector2(tile.x + half_tile, tile.y + Globals.tilesize - end)
    return [from, to]

func _draw():
    #draw back
    var circle_tile = Globals.tile_vector(occupied[len(occupied)-1])
    var circle_pos
    var first_dir_from_back = false
    var second_dir_from_back = false
    for i in range(len(turns)):
        var dir = turns[len(turns)-i-1]
        if typeof(dir) == TYPE_INT:
            if typeof(first_dir_from_back) == TYPE_INT:
                second_dir_from_back = dir
                break
            else:
                first_dir_from_back = dir
    if typeof(first_dir_from_back) == TYPE_BOOL:
        first_dir_from_back = direction
    if typeof(second_dir_from_back) == TYPE_BOOL:
        second_dir_from_back = direction
    if typeof(turns[len(turns)-1]) == TYPE_INT:
        var x = arc_info(circle_tile, first_dir_from_back, second_dir_from_back)
        var center = x[0]
        var from = x[1]
        var to = x[2]
        to = from + (to - from) * (enlarge_progress - tile_progress)
        circle_pos = center + Vector2((Globals.tilesize / 2) * cos(to), (Globals.tilesize / 2) * sin(to))
        legs.rotation = to + (0.5 if (from >= to) else -0.5) * PI
        if enlarge_progress < 1 && (alive || death_progress+(enlarge_progress-0.5) < CRASH_TIME):
            legs.rotation += PI
    else:
        var x = line_points(circle_tile, first_dir_from_back, Globals.tilesize * (tile_progress + (1 - enlarge_progress)))
        var to = x[1]
        circle_pos = to
        legs.rotation = DIRECTION_CURVE[first_dir_from_back]
    var back_color = snake_color
    back_color.r -= SNAKE_DARKEN
    back_color.g -= SNAKE_DARKEN
    back_color.b -= SNAKE_DARKEN
    draw_circle(circle_pos, Globals.tilesize * (SNAKE_SIZE / 2), Color.black)
    draw_circle(circle_pos, Globals.tilesize * (SNAKE_SIZE / 2 - OUTLINE_SIZE), back_color)
    legs.position = circle_pos
    
    #draw front
    circle_tile = Globals.tile_vector(occupied[0])
    if typeof(turns[0]) == TYPE_INT:
        var x = arc_info(circle_tile, turns[0], direction)
        var center = x[0]
        var from = x[1]
        var to = x[2]
        from = to + (from - to) * tile_progress
        circle_pos = center + Vector2((Globals.tilesize / 2) * cos(from), (Globals.tilesize / 2) * sin(from))
        eyes.rotation = from + (0.5 if from > to else -0.5) * PI
    else:
        var x = line_points(circle_tile, direction, Globals.tilesize * tile_progress)
        var to = x[1]
        circle_pos = to
        eyes.rotation = DIRECTION_CURVE[direction]
    draw_circle(circle_pos, Globals.tilesize * (SNAKE_SIZE / 2), Color.black)
    draw_circle(circle_pos, Globals.tilesize * (SNAKE_SIZE / 2 - OUTLINE_SIZE), snake_color)
    eyes.position = circle_pos
        
    var dir_drawing = direction
    for i in range(len(occupied)):
        var tile = Globals.tile_vector(occupied[i])
        var color = snake_color
        var color_darken = (float(i) / len(occupied)) * SNAKE_DARKEN
        color.r -= color_darken
        color.g -= color_darken
        color.b -= color_darken
        if typeof(turns[i]) == TYPE_INT:
            var x = arc_info(tile, turns[i], dir_drawing)
            var center = x[0]
            var from = x[1]
            var to = x[2]
            if i == 0:
                from = to + (from - to) * tile_progress
            if i+1 == len(occupied):
                to = from + (to - from) * (enlarge_progress - tile_progress)
            draw_arc(center, Globals.tilesize/2, from, to, SNAKE_ARC_POINTS, Color.black, Globals.tilesize * SNAKE_SIZE)
            draw_arc(center, Globals.tilesize/2, from, to, SNAKE_ARC_POINTS, color, Globals.tilesize * (SNAKE_SIZE - OUTLINE_SIZE * 2))
            dir_drawing = turns[i]
        elif length > 1:
            var end = Globals.tilesize if i > 0 && i+1 < len(occupied) else Globals.tilesize * (tile_progress if i == 0 else (tile_progress + (1 - enlarge_progress)))
            if i+1 == len(occupied):
                dir_drawing = (dir_drawing + 2) % 4
                end = Globals.tilesize - end
            var x = line_points(tile, dir_drawing, end)
            var from = x[0]
            var to = x[1]
            draw_line(from, to, Color.black, Globals.tilesize * SNAKE_SIZE)
            draw_line(from, to, color, Globals.tilesize * (SNAKE_SIZE - OUTLINE_SIZE * 2))


func _on_Area2D_area_entered(food):
    if alive && moving:
        length += 1
        enlarge_progress = 0
        occupied.append(recently_unoccupied)
        turns.append(recently_unturned)
        food.death_journey(occupied.slice(1, max(2 if len(occupied) > 1 else 1, int(round(len(occupied)/2))), 1, true), (1.0 / Globals.snake_speed) * (length / 2))
        emit_signal('eat', occupied[0])
        $Eat.play()
