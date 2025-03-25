extends Control

enum ControlledByTeam { RED, BLUE, NONE }

@export var point_name = "A"
@export var controlled_by = ControlledByTeam.NONE

func _ready() -> void:
    modulate = Color.GRAY
    add_to_group("neutral_point")
    $ControlPointLabel.text = point_name

func _on_control_point_pressed() -> void:
    Events.emit_signal("control_point_pressed", self)
    match controlled_by:
        ControlledByTeam.NONE:
            controlled_by = ControlledByTeam.RED
            self.modulate = Constants.RED_RGB
            remove_from_group("neutral_point")
            add_to_group("red_point")
        ControlledByTeam.RED:
            controlled_by = ControlledByTeam.BLUE
            self.modulate = Constants.BLUE_RGB
            remove_from_group("neutral_point")
            remove_from_group("red_point")
            add_to_group("blue_point")
        ControlledByTeam.BLUE:
            controlled_by = ControlledByTeam.NONE
            self.modulate = Color.GRAY
            remove_from_group("blue_point")
            add_to_group("neutral_point")
