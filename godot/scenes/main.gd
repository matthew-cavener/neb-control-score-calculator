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
    var red_team_victory_conditions = "Red team needs " + str(points_to_red_victory) + " points to win in " + convert_seconds_to_minutes_seconds(int(time_to_red_victory))
    if red_caps.size() == 0:
        red_team_victory_conditions = "Red team needs to disarm all blue ships to win"
    var blue_team_victory_conditions = "Blue team needs " + str(points_to_blue_victory) + " points to win in " + convert_seconds_to_minutes_seconds(int(time_to_blue_victory))
    if blue_caps.size() == 0:
        blue_team_victory_conditions = "Blue team needs to disarm all red ships to win"
    $VictoryConditionsLabel.text = blue_team_victory_conditions + "\n" + red_team_victory_conditions

func convert_seconds_to_minutes_seconds(seconds: int) -> String:
    var minutes = seconds / 60
    var remaining_seconds = seconds % 60
    return str(minutes).pad_zeros(2) + ":" + str(remaining_seconds).pad_zeros(2)


func _on_timer_reset_button_pressed() -> void:
    print("timer reset button pressed")
    score_timer.start()
