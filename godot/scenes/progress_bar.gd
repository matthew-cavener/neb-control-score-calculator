extends Node2D

enum ColorOptions { RED, BLUE }

@export var color = ColorOptions.RED
@export var texture_bar_fill_fraction: float = 0.0

@onready var texture_bar = $ProgressBarTextures

var red_texture = load("res://assets/kenney_ui-pack-space-expansion/Vector/Red/bar_square_large_m.svg")
var blue_texture = load("res://assets/kenney_ui-pack-space-expansion/Vector/Blue/bar_square_large_m.svg")

func _ready() -> void:
    texture_bar.value = 0
    match color:
        ColorOptions.RED:
            texture_bar.texture_progress = red_texture
            texture_bar.fill_mode = texture_bar.FILL_LEFT_TO_RIGHT
        ColorOptions.BLUE:
            texture_bar.texture_progress = blue_texture
            texture_bar.fill_mode = texture_bar.FILL_RIGHT_TO_LEFT

func _process(delta: float) -> void:
    texture_bar.value = texture_bar_fill_fraction * 100
