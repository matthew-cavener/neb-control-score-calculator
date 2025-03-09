extends Control

enum ControlledByTeam { RED, BLUE, NONE }

@export var point_name = "A"
@export var controlled_by = ControlledByTeam.NONE

var red_rgb = Color(242.0/255.0, 100.0/255.0, 45.0/255.0, 1.0)
var blue_rgb = Color(66.0/255.0, 93.0/255.0, 129.0/255.0, 1.0)

func _ready() -> void:
    modulate = Color.GRAY
    add_to_group("neutral_point")
    $ControlPointLabel.text = point_name

func _on_control_point_pressed() -> void:
    Events.emit_signal("_on_control_point_pressed", self)
    match controlled_by:
        ControlledByTeam.NONE:
            controlled_by = ControlledByTeam.RED
            self.modulate = red_rgb
            add_to_group("red_point")
        ControlledByTeam.RED:
            controlled_by = ControlledByTeam.BLUE
            self.modulate = blue_rgb
            remove_from_group("red_point")
            add_to_group("blue_point")
        ControlledByTeam.BLUE:
            controlled_by = ControlledByTeam.NONE
            self.modulate = Color.GRAY
            remove_from_group("blue_point")
            add_to_group("neutral_point")
