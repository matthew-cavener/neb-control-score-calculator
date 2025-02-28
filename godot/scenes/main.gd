extends Node2D

const SCORE_TIMER_INTERVAL = 10.0
const SCORE_PER_CAP_POINT = 2

var score_timer: Timer

func _ready() -> void:
    $BlueTeamScore.text = str(0)
    $RedTeamScore.text = str(0)
    score_timer = Timer.new()
    score_timer.wait_time = SCORE_TIMER_INTERVAL
    score_timer.one_shot = false
    score_timer.timeout.connect(_on_score_timer_timeout)
    add_child(score_timer)
    score_timer.start()

func _process(delta: float) -> void:
    pass

func _on_score_timer_timeout() -> void:
    calculate_score()

func calculate_score() -> void:
    print("score_timer timeout, calculating score")
    var score_limit = float($ScoreLimit.text)
    var red_caps = get_tree().get_nodes_in_group("red_point")
    var blue_caps = get_tree().get_nodes_in_group("blue_point")
    var red_score = float($RedTeamScore.text)
    var blue_score = float($BlueTeamScore.text)
    red_score += SCORE_PER_CAP_POINT * red_caps.size()
    blue_score += SCORE_PER_CAP_POINT * blue_caps.size()

    $RedTeamScore.text = str(red_score)
    $ProgressBarRed.texture_bar_fill_fraction = red_score / score_limit

    $BlueTeamScore.text = str(blue_score)
    $ProgressBarBlue.texture_bar_fill_fraction = blue_score / score_limit
    
    var points_to_red_victory = score_limit - red_score
    var points_to_blue_victory = score_limit - blue_score
    var time_to_red_victory = (points_to_red_victory * SCORE_TIMER_INTERVAL) / (red_caps.size() * SCORE_PER_CAP_POINT)
    var time_to_blue_victory = (points_to_blue_victory * SCORE_TIMER_INTERVAL) / (blue_caps.size() * SCORE_PER_CAP_POINT)

    var red_times_to_win = {}
    var blue_times_to_win = {}

    for number_of_caps in range(1, 6):
        var red_time_to_win = (points_to_red_victory * SCORE_TIMER_INTERVAL) / (number_of_caps * SCORE_PER_CAP_POINT)
        var blue_time_to_win = (points_to_blue_victory * SCORE_TIMER_INTERVAL) / (number_of_caps * SCORE_PER_CAP_POINT)
        red_times_to_win[number_of_caps] = (red_time_to_win)
        blue_times_to_win[number_of_caps] = (blue_time_to_win)

    var projected_loser = ""

    if time_to_red_victory > time_to_blue_victory:
        projected_loser = "Red"
    else:
        projected_loser = "Blue"

    var red_caps_needed = "game should be over"
    var blue_caps_needed = "game should be over"

    for key in red_times_to_win.keys():
        if blue_times_to_win.has(5 - key) and red_times_to_win[key] < blue_times_to_win[5 - key]:
            red_caps_needed = key
            break
    for key in blue_times_to_win.keys():
        if red_times_to_win.has(5 - key) and blue_times_to_win[key] < red_times_to_win[5 - key]:
            blue_caps_needed = key
            break

    var red_team_victory_conditions = "Red team needs " + str(points_to_red_victory) + " points to win in " + convert_seconds_to_minutes_seconds(int(time_to_red_victory))
    var blue_team_victory_conditions = "Blue team needs " + str(points_to_blue_victory) + " points to win in " + convert_seconds_to_minutes_seconds(int(time_to_blue_victory))

    red_team_victory_conditions += "\nRed team needs " + str(red_caps_needed) + " caps to win.\n"
    blue_team_victory_conditions += "\nBlue team needs " + str(blue_caps_needed) + " caps to win.\n"
    $VictoryConditionsLabel.text = red_team_victory_conditions  + "\n" +  blue_team_victory_conditions + "\n" + projected_loser + " needs to make something happen."

func convert_seconds_to_minutes_seconds(seconds: int) -> String:
    var minutes = seconds / 60
    var remaining_seconds = seconds % 60
    return str(minutes).pad_zeros(2) + ":" + str(remaining_seconds).pad_zeros(2)


func _on_timer_reset_button_pressed() -> void:
    print("timer reset button pressed")
    score_timer.start()
