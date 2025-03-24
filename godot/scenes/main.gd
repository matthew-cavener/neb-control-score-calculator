extends Node2D


var projected_loser: String = ""
var loser_caps_needed: int = 0
var time_to_red_victory: float = 999999
var time_to_blue_victory: float = 999999
var red_time_to_win: float = 0
var blue_time_to_win: float = 0
var approx_time_to_extra_cap_needed: String = ""

@onready var points_to_red_victory = $ScoreLimit.text
@onready var points_to_blue_victory = $ScoreLimit.text


func _ready() -> void:
    $BlueTeamScore.text = str(0)
    $RedTeamScore.text = str(0)
    Events.connect("score_timer_timeout", _on_score_timer_timeout)


func calculate_score() -> void:
    var score_limit = int($ScoreLimit.text)
    var red_caps = get_tree().get_nodes_in_group("red_point")
    var blue_caps = get_tree().get_nodes_in_group("blue_point")
    var neutral_caps = get_tree().get_nodes_in_group("neutral_point")
    var red_score = int($RedTeamScore.text)
    var blue_score = int($BlueTeamScore.text)

    red_score += Constants.SCORE_PER_CAP_POINT * red_caps.size()
    blue_score += Constants.SCORE_PER_CAP_POINT * blue_caps.size()

    $RedTeamScore.text = str(red_score)
    $ProgressBarRed.texture_bar_fill_fraction = red_score / float(score_limit)
    $BlueTeamScore.text = str(blue_score)
    $ProgressBarBlue.texture_bar_fill_fraction = blue_score / float(score_limit)
    
    points_to_red_victory = score_limit - red_score
    points_to_blue_victory = score_limit - blue_score
    time_to_red_victory = calculate_time_to_win(int(points_to_red_victory), red_caps.size())
    time_to_blue_victory = calculate_time_to_win(int(points_to_blue_victory), blue_caps.size())

    var caps_needed = calculate_caps_needed_to_win(red_score, blue_score)
    var red_caps_needed = caps_needed["red_caps_needed"]
    var blue_caps_needed = caps_needed["blue_caps_needed"]

    if time_to_red_victory > time_to_blue_victory:
        projected_loser = "Red"
        loser_caps_needed = red_caps_needed
    else:
        projected_loser = "Blue"
        loser_caps_needed = blue_caps_needed

    approx_time_to_extra_cap_needed = convert_seconds_to_minutes_seconds(int(calculate_time_until_extra_cap_needed(
        red_score,
        blue_score,
        red_caps.size(),
        blue_caps.size(),
        red_caps_needed,
        blue_caps_needed
    )))

    var red_team_victory_conditions = "Red team needs " + str(points_to_red_victory) + " points to win.\nWith their current caps, they will win in " + convert_seconds_to_minutes_seconds(int(time_to_red_victory))
    var blue_team_victory_conditions = "Blue team needs " + str(points_to_blue_victory) + " points to win.\nWith their current caps, they will win in " + convert_seconds_to_minutes_seconds(int(time_to_blue_victory))

    red_team_victory_conditions += "\nRed team needs " + str(red_caps_needed) + " caps to win.\n"
    blue_team_victory_conditions += "\nBlue team needs " + str(blue_caps_needed) + " caps to win.\n"

    $VictoryConditionsLabel.text = (
        red_team_victory_conditions +
        "\n" +
        blue_team_victory_conditions +
        "\n" +
        projected_loser + " team is projected to lose. **!!!EXPERIMENTAL!!!** They will need " + str(loser_caps_needed + 1) + " caps to win in " + approx_time_to_extra_cap_needed
    )


func calculate_time_to_win(points_to_victory: int, caps: int) -> float:
    return (points_to_victory * Constants.SCORE_TIMER_INTERVAL) / (caps * Constants.SCORE_PER_CAP_POINT)


func calculate_caps_needed_to_win(red_score: int, blue_score: int) -> Dictionary:
    var score_limit = 1000
    var total_capture_points = Constants.CAPTURE_POINTS

    var red_caps_needed = total_capture_points
    var blue_caps_needed = total_capture_points

    for caps in range(1, total_capture_points + 1):
        var red_numerator = (score_limit - red_score) * total_capture_points
        var red_denominator = (score_limit - red_score) + (score_limit - blue_score)
        var red_required_caps = red_numerator / red_denominator if red_denominator != 0 else 0
        if caps > red_required_caps:
            red_caps_needed = caps
            break

    for caps in range(1, total_capture_points + 1):
        var blue_numerator = (score_limit - blue_score) * total_capture_points
        var blue_denominator = (score_limit - blue_score) + (score_limit - red_score)
        var blue_required_caps = blue_numerator / blue_denominator if blue_denominator != 0 else 0
        if caps > blue_required_caps:
            blue_caps_needed = caps
            break

    return {
        "red_caps_needed": red_caps_needed,
        "blue_caps_needed": blue_caps_needed
    }


func calculate_time_until_extra_cap_needed(
    red_score: int,
    blue_score: int,
    red_caps: int,
    blue_caps: int,
    current_red_caps_needed: int,
    current_blue_caps_needed: int
    ) -> float:
    """
    https://discord.com/channels/1091469366371029025/1091469367323152386/1353191485893246976
    anyways can't you just solve 3(1000-x-x't)=2(1000-y-y't) for t, where x is the current points of the losing team, x' is the rate of points increase for the losing team, y/y' are the same for the winning team, and t represents time?
    1000-x-x't calculates the remaining score that team x needs to win at time t, and you need a 4:1 lead to win once the ratio of your remaining score to the enemy's remaining score becomes greater than 3:2
    you also have to offset t by a minute since capturing an objective is not instantaneous, but im sure you can figure that part out
    -- Lobster
    special case for time until losing team needs 4 caps to win
    (1000 - 4 * red_score + 1 * blue_score) / (4 * red_points_rate - 1 * blue_points_rate)
    """
    var total_capture_points = Constants.CAPTURE_POINTS
    var red_points_rate = Constants.SCORE_PER_CAP_POINT * red_caps / Constants.SCORE_TIMER_INTERVAL
    var blue_points_rate = Constants.SCORE_PER_CAP_POINT * blue_caps / Constants.SCORE_TIMER_INTERVAL
    var numerator = 0
    var denominator = 0
    if projected_loser == "Red":
        numerator = (1000 - (current_red_caps_needed + 1) * red_score + (total_capture_points - (current_red_caps_needed + 1)) * blue_score)
        denominator = ((current_red_caps_needed + 1) * red_points_rate) - ((total_capture_points - (current_red_caps_needed + 1)) * blue_points_rate)
    else:
        numerator = (1000 - (current_blue_caps_needed + 1) * blue_score + (total_capture_points - (current_blue_caps_needed + 1)) * red_score)
        denominator = ((current_blue_caps_needed + 1) * blue_points_rate) - ((total_capture_points - (current_blue_caps_needed + 1)) * red_points_rate)

    if denominator == 0:
        return 99999999

    return numerator / denominator


func convert_seconds_to_minutes_seconds(seconds: int) -> String:
    var minutes = seconds / 60
    var remaining_seconds = seconds % 60
    return str(minutes).pad_zeros(2) + ":" + str(remaining_seconds).pad_zeros(2)


func format_times_to_win(times_to_win: Dictionary) -> String:
    var formatted_string = ""
    for key in times_to_win.keys():
        formatted_string += "Caps: " + str(key) + " - Time: " + str(times_to_win[key]) + "\n"
    return formatted_string


func _on_score_timer_timeout() -> void:
    calculate_score()


func _on_sync_timer_tick_score_button_pressed() -> void:
    Events.emit_signal("sync_timer_tick_score_button_pressed")


func _on_manual_score_tick_button_pressed() -> void:
    calculate_score()


func _on_timer_reset_button_pressed() -> void:
    Events.emit_signal("timer_reset_button_pressed")
