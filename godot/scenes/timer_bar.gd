extends Node2D

@export var color = Constants.ColorOptions.RED
@onready var progress_bar = $TextureProgressBar

var score_tick_timer: Timer
var timer_duration: float = Constants.SCORE_TIMER_INTERVAL

func _ready():
    Events.connect("sync_timer_tick_score_button_pressed", _on_sync_timer_tick_score_button_pressed)
    Events.connect("timer_reset_button_pressed", _on_timer_reset_button_pressed)
    score_tick_timer = Timer.new()
    score_tick_timer.wait_time = timer_duration
    score_tick_timer.one_shot = false
    score_tick_timer.timeout.connect(func():
        Events.emit_signal("score_timer_timeout")
    )
    add_child(score_tick_timer)
    score_tick_timer.start()

func _process(delta: float) -> void:
    if not score_tick_timer.is_stopped():
        var remaining_fraction = score_tick_timer.time_left / timer_duration
        progress_bar.value = remaining_fraction * progress_bar.max_value

func _on_sync_timer_tick_score_button_pressed() -> void:
    Events.emit_signal("score_timer_timeout")
    score_tick_timer.start()

func _on_timer_reset_button_pressed() -> void:
    score_tick_timer.start()
