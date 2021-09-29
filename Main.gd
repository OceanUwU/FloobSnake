extends Node

export (PackedScene) var Food

var food_squares
var snake
var grid
var score
var best = 0

func _ready():
    randomize()
    grid = $Grid
    snake = $Snake
    start_game()

func start_game():
    get_tree().call_group('foods', 'queue_free')
    score = 0
    update_score()
    food_squares = []
    $Grid.scale = Vector2(1,1) * (500.0 / Globals.boardsize / 50)
    #$Grid.offset = Vector2(20,20) / $Grid.scale
    var rect_size = 500.0 / $Grid.scale.x
    $Grid.region_rect = Rect2(0, 0, rect_size, rect_size)
    Globals.tilesize = 500 / Globals.boardsize
    snake.start()
    for _i in range(Globals.food_amount):
        spawn_food()

func update_score():
    $ScoreHUD/Coin/ScoreLabel.text = str(score)
    if (score > best):
        best = score
    $ScoreHUD/Trophy/BestLabel.text = str(best)

func spawn_food():
    var available_squares = []
    for x in range(Globals.boardsize):
        for y in range(Globals.boardsize):
            var available = true
            for i in snake.occupied:
                if i[0] == x && i[1] == y:
                    available = false
            for i in food_squares:
                if i[0] == x && i[1] == y:
                    available = false
            if available:
                available_squares.append([x,y])
    if len(available_squares) > 0:
        var square = available_squares[randi() % len(available_squares)]
        var food = Food.instance()
        food.grid_offset = grid.position
        food.position = food.grid_offset + Globals.tile_vector(square)
        food.scale = $Grid.scale
        add_child(food)
        food_squares.append(square)
    elif len(food_squares) == 0: #all fruits are eaten - win
        snake.slowing = true
        #snake.turns[len(snake.turns)-2] = null


func _on_Snake_eat(square):
    score += 1
    update_score()
    
    for i in range(len(food_squares)):
        if food_squares[i][0] == square[0] && food_squares[i][1] == square[1]:
            food_squares.remove(i)
            return spawn_food()


func _on_DeathMenu_restart():
    start_game()


func _on_Snake_die():
    show_end_menu()


func _on_Snake_win():
    show_end_menu()

func show_end_menu():
    $DeathMenu.game_over(score, best)

func _on_DeathMenu_reset_best():
    best = 0
