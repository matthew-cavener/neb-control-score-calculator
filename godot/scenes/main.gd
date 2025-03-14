extends Node2D


const SCORE_TIMER_INTERVAL = 10.0
const SCORE_PER_CAP_POINT = 2
const CAPTURE_POINTS = 5


var score_timer: Timer
var projected_loser: String = ""
var loser_caps_needed: int = 0
var time_to_red_victory: float = 999999
var time_to_blue_victory: float = 999999
var red_times_to_win: Dictionary = {}
var blue_times_to_win: Dictionary = {}
var red_time_to_win: float = 0
var blue_time_to_win: float = 0
var red_caps_needed: int = 0
var blue_caps_needed: int = 0
var approx_time_to_extra_cap_needed: String = ""


@onready var points_to_red_victory = $ScoreLimit.text
@onready var points_to_blue_victory = $ScoreLimit.text


func _ready() -> void:
    $BlueTeamScore.text = str(0)
    $RedTeamScore.text = str(0)
    score_timer = Timer.new()
    score_timer.wait_time = SCORE_TIMER_INTERVAL
    score_timer.one_shot = false
    score_timer.timeout.connect(_on_score_timer_timeout)
    add_child(score_timer)
    score_timer.start()


func calculate_score() -> void:
    var score_limit = float($ScoreLimit.text)
    var red_caps = get_tree().get_nodes_in_group("red_point")
    var blue_caps = get_tree().get_nodes_in_group("blue_point")
    var neutral_caps = get_tree().get_nodes_in_group("neutral_point")
    var red_score = int($RedTeamScore.text)
    var blue_score = int($BlueTeamScore.text)
    red_score += SCORE_PER_CAP_POINT * red_caps.size()
    blue_score += SCORE_PER_CAP_POINT * blue_caps.size()

    $RedTeamScore.text = str(red_score)
    $ProgressBarRed.texture_bar_fill_fraction = red_score / score_limit

    $BlueTeamScore.text = str(blue_score)
    $ProgressBarBlue.texture_bar_fill_fraction = blue_score / score_limit
    
    points_to_red_victory = score_limit - red_score
    points_to_blue_victory = score_limit - blue_score

    for number_of_caps in range(1, CAPTURE_POINTS + 1):
        red_time_to_win = calculate_time_to_win(points_to_red_victory, number_of_caps)
        blue_time_to_win = calculate_time_to_win(points_to_blue_victory, number_of_caps)
        red_times_to_win[number_of_caps] = (red_time_to_win)
        blue_times_to_win[number_of_caps] = (blue_time_to_win)

    if red_caps.size() > 0:
        time_to_red_victory = red_times_to_win[red_caps.size()]
    else:
        time_to_red_victory = 999999

    if blue_caps.size() > 0:
        time_to_blue_victory = blue_times_to_win[blue_caps.size()]
    else:
        time_to_blue_victory = 999999

    if time_to_red_victory > time_to_blue_victory:
        projected_loser = "Red"
        loser_caps_needed = red_caps_needed
    else:
        projected_loser = "Blue"
        loser_caps_needed = blue_caps_needed

    for key in red_times_to_win.keys():
        if blue_times_to_win.has(CAPTURE_POINTS - key) and red_times_to_win[key] < blue_times_to_win[CAPTURE_POINTS - key]:
            red_caps_needed = key
            break
    for key in blue_times_to_win.keys():
        if red_times_to_win.has(CAPTURE_POINTS - key) and blue_times_to_win[key] < red_times_to_win[CAPTURE_POINTS - key]:
            blue_caps_needed = key
            break

    approx_time_to_extra_cap_needed = convert_seconds_to_minutes_seconds(calculate_time_before_extra_cap_needed(projected_loser, red_times_to_win, blue_times_to_win, red_caps_needed, blue_caps_needed, red_caps.size(), blue_caps.size()))

    for key in red_times_to_win.keys():
        red_times_to_win[key] = convert_seconds_to_minutes_seconds(int(red_times_to_win[key]))
    for key in blue_times_to_win.keys():
        blue_times_to_win[key] = convert_seconds_to_minutes_seconds(int(blue_times_to_win[key]))

    var red_team_victory_conditions = "Red team needs " + str(points_to_red_victory) + " points to win in " + convert_seconds_to_minutes_seconds(int(time_to_red_victory))
    var blue_team_victory_conditions = "Blue team needs " + str(points_to_blue_victory) + " points to win in " + convert_seconds_to_minutes_seconds(int(time_to_blue_victory))

    red_team_victory_conditions += "\nRed team needs " + str(red_caps_needed) + " caps to win.\n"
    blue_team_victory_conditions += "\nBlue team needs " + str(blue_caps_needed) + " caps to win.\n"

    var red_times_to_win_formatted = format_times_to_win(red_times_to_win)
    var blue_times_to_win_formatted = format_times_to_win(blue_times_to_win)

    $VictoryConditionsLabel.text = (
        red_team_victory_conditions +
        "\n" +
        blue_team_victory_conditions +
        "\n" +
        projected_loser + " needs to make something happen. **EXPERIMENTAL!!!** They will need " + str(loser_caps_needed + 1) + " caps to win in " + approx_time_to_extra_cap_needed +
        "\n\nRed Times to Win:\n" + red_times_to_win_formatted +
        "\nBlue Times to Win:\n" + blue_times_to_win_formatted
    )


func calculate_time_to_win(points_to_victory: int, caps: int) -> float:
    return (points_to_victory * SCORE_TIMER_INTERVAL) / (caps * SCORE_PER_CAP_POINT)


func calculate_time_before_extra_cap_needed(
    projected_loser: String,
    red_times_to_win: Dictionary,
    blue_times_to_win: Dictionary,
    red_caps_needed: int,
    blue_caps_needed: int,
    red_caps_size: int,
    blue_caps_size: int
    ) -> float:
    if projected_loser == "Red":
        return (blue_times_to_win[CAPTURE_POINTS - red_caps_needed] - red_times_to_win[red_caps_needed]) / ((SCORE_PER_CAP_POINT * 0.8) / red_caps_size)
    else:
        return (red_times_to_win[CAPTURE_POINTS - blue_caps_needed] - blue_times_to_win[blue_caps_needed]) / ((SCORE_PER_CAP_POINT * 0.8) / blue_caps_size)


func convert_seconds_to_minutes_seconds(seconds: int) -> String:
    var minutes = seconds / 60
    var remaining_seconds = seconds % 60
    return str(minutes).pad_zeros(2) + ":" + str(remaining_seconds).pad_zeros(2)


func _on_score_timer_timeout() -> void:
    print("score_timer timeout, calculating score")
    calculate_score()


func _on_sync_timer_tick_score_button_pressed() -> void:
    calculate_score()
    score_timer.start()


func _on_timer_reset_button_pressed() -> void:
    score_timer.start()


func _on_manual_score_tick_button_pressed() -> void:
    calculate_score()


func format_times_to_win(times_to_win: Dictionary) -> String:
    var formatted_string = ""
    for key in times_to_win.keys():
        formatted_string += "Caps: " + str(key) + " - Time: " + str(times_to_win[key]) + "\n"
    return formatted_string
