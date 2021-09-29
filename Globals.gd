extends Node

var boardsize
var tilesize
var food_amount
var snake_speed

func tile_vector(tile):
    return Vector2(tilesize * tile[0], tilesize * tile[1])
