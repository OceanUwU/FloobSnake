extends CanvasLayer

signal restart
signal reset_best

const ENTER_TIME = 1.3
const TRANSPARENTY_ALPHA = 0.4

func _ready():
    _on_OptionsMenu_close()

func game_over(score, best):
    $Restart.disabled = false
    $Score.text = str(score)
    $Best.text = str(best)
    $Transparenty/Fade.interpolate_property($Transparenty, 'modulate', Color(0, 0, 0, 0), Color(0, 0, 0, TRANSPARENTY_ALPHA), ENTER_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
    $Transparenty/Fade.start()
    $Move.interpolate_property(self, 'offset', Vector2(-600, 0), Vector2(0, 0), ENTER_TIME, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
    $Move.start()
    yield($Transparenty/Fade, 'tween_completed')

func new_game():
    emit_signal('restart')
    $Transparenty/Fade.interpolate_property($Transparenty, 'modulate', Color(0, 0, 0, TRANSPARENTY_ALPHA), Color(0, 0, 0, 0), ENTER_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
    $Transparenty/Fade.start()
    $Move.interpolate_property(self, 'offset', Vector2(0, 0), Vector2(600, 0), ENTER_TIME, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
    $Move.start()


func _on_Restart_pressed():
    $Restart.disabled = true
    new_game()


func _on_Options_pressed():#
    open_options()

func open_options():
    emit_signal('reset_best')
    $OptionsMenu.scale = Vector2(1, 1)

func _on_OptionsMenu_close():
    $OptionsMenu.scale = Vector2(-1, -1)
