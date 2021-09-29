extends CanvasLayer

signal close

func _ready():
    _on_SpeedSlider_value_changed($SpeedSlider.value)
    _on_BoardSlider_value_changed($BoardSlider.value)
    _on_FoodSlider_value_changed($FoodSlider.value)


func _on_SpeedSlider_value_changed(value):
    Globals.snake_speed = value
    $SpeedIndicator.text = str(value)


func _on_BoardSlider_value_changed(value):
    Globals.boardsize = value
    $BoardIndicator.text = str(value)


func _on_FoodSlider_value_changed(value):
    Globals.food_amount = value
    $FoodIndicator.text = str(value)


func _on_TextureButton_pressed():
    emit_signal('close')
