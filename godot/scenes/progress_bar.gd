extends Node2D

@export var color = Constants.ColorOptions.RED
@export var texture_bar_fill_fraction: float = 0.0

@onready var texture_bar = $ProgressBarTextures

func _ready() -> void:
    texture_bar.value = 0
    match color:
        Constants.ColorOptions.RED:
            texture_bar.tint_progress = Constants.RED_RGB
            texture_bar.fill_mode = texture_bar.FILL_LEFT_TO_RIGHT
        Constants.ColorOptions.BLUE:
            texture_bar.tint_progress = Constants.BLUE_RGB
            texture_bar.fill_mode = texture_bar.FILL_RIGHT_TO_LEFT

func _process(delta: float) -> void:
    texture_bar.value = texture_bar_fill_fraction * 100
