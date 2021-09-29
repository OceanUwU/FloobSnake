extends Area2D

const FOOD_DIR = 'res://assets/food/'
const FOODS = ['beans', 'caviar', 'cheese', 'coffee', 'crisps', 'dogfood', 'energydrink', 'floob', 'floobfood', 'fugu', 'marshmallow', 'meat', 'pepper', 'pi', 'pill', 'ramennoodles', 'sheetmusic', 'soap', 'water', 'weddingcake']
const APPEAR_TIME = 0.2

var sprite
var pulsating
var grid_offset

func _ready():
    sprite = $S/prite
    pulsating = false
    var food = FOODS[randi() % len(FOODS)]
    sprite.texture = load(FOOD_DIR+food+'.png')
    
    $S/prite/Scale.interpolate_property(sprite, 'scale', Vector2(0,0), Vector2(1,1), APPEAR_TIME, Tween.TRANS_CUBIC, Tween.EASE_OUT)
    $S/prite/Scale.start()
    yield($S/prite/Scale, 'tween_completed')
    pulsating = true
    
func death_journey(points, time):
        pulsating = false
        $CollisionShape2D.set_deferred('disabled', true)
        $Opacity.interpolate_property(self, 'modulate', Color(1,1,1,1), Color(1,1,1,0), time, Tween.TRANS_LINEAR)
        $Opacity.start()
        for point in points:
            $Position.interpolate_property(self, 'position', self.position, grid_offset + Globals.tile_vector(point), time / len(points), Tween.TRANS_LINEAR)
            $Position.start()
            yield($Position, 'tween_completed')
        queue_free()

func _process(_delta):
    if pulsating:
        sprite.scale = Vector2(1, 1) * (1.0 + abs(sin(float(OS.get_ticks_msec()) / 300)) * 0.1)
