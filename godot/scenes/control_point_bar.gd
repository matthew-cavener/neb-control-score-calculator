extends Node2D


const ControlPoint = preload("res://scenes/control_point.tscn")


var control_points = []
var next_point_index = 0


func _ready() -> void:
    for child in $HBoxContainer.get_children():
        child.queue_free()
    control_points.clear()
    next_point_index = 0

    for i in range(5):
        _add_control_point()

    Events.connect("add_control_point_button_pressed", _on_add_control_point_button_pressed)
    Events.connect("remove_control_point_button_pressed", _on_remove_control_point_button_pressed)


func _on_add_control_point_button_pressed() -> void:
    _add_control_point()


func _on_remove_control_point_button_pressed() -> void:
    if control_points.size() > 0:
        var control_point = control_points.pop_back()
        control_point.queue_free()
        next_point_index -= 1


func _add_control_point() -> void:
    var control_point = ControlPoint.instantiate()
    control_point.point_name = char(65 + next_point_index)
    $HBoxContainer.add_child(control_point)
    control_points.append(control_point)
    next_point_index += 1
