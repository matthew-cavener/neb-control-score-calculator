extends Node2D

var projected_loser: String = ""
var loser_caps_needed: int = 0
var time_to_red_victory: float = INF
var time_to_blue_victory: float = INF
var approx_time_to_additional_cap_needed: String = ""

@onready var score_limit = int($ScoreLimit.text)
@onready var max_time = Constants.SCORE_TIMER_INTERVAL * score_limit / Constants.SCORE_PER_CAP_POINT

func _ready() -> void:
    reset_scores()
    Events.connect("score_timer_timeout", _on_score_timer_timeout)

func reset_scores() -> void:
    $BlueTeamScore.text = "0"
    $RedTeamScore.text = "0"

func calculate_score() -> void:
    var neutral_caps = get_tree().get_nodes_in_group("neutral_point").size()
    var red_caps = get_tree().get_nodes_in_group("red_point").size()
    var blue_caps = get_tree().get_nodes_in_group("blue_point").size()
    var red_score = int($RedTeamScore.text) + red_caps * Constants.SCORE_PER_CAP_POINT
    var blue_score = int($BlueTeamScore.text) + blue_caps * Constants.SCORE_PER_CAP_POINT

    update_scores(red_score, blue_score)
    update_victory_conditions(red_score, blue_score, red_caps, blue_caps, neutral_caps)

func update_scores(red_score: int, blue_score: int) -> void:
    $RedTeamScore.text = str(red_score)
    $ProgressBarRed.texture_bar_fill_fraction = red_score / float(score_limit)
    $BlueTeamScore.text = str(blue_score)
    $ProgressBarBlue.texture_bar_fill_fraction = blue_score / float(score_limit)

func update_victory_conditions(red_score: int, blue_score: int, red_caps: int, blue_caps: int, neutral_caps: int) -> void:
    var points_to_red_victory = score_limit - red_score
    var points_to_blue_victory = score_limit - blue_score

    time_to_red_victory = calculate_time_to_win(points_to_red_victory, red_caps)
    time_to_blue_victory = calculate_time_to_win(points_to_blue_victory, blue_caps)

    var caps_needed = calculate_caps_needed_to_win(red_score, blue_score, neutral_caps)
    var red_caps_needed = caps_needed["red_caps_needed"]
    var blue_caps_needed = caps_needed["blue_caps_needed"]

    projected_loser = "Red" if time_to_red_victory > time_to_blue_victory else "Blue"
    loser_caps_needed = red_caps_needed if projected_loser == "Red" else blue_caps_needed

    if loser_caps_needed >= Constants.CAPTURE_POINTS:
        approx_time_to_additional_cap_needed = "N/A"
    else:
        approx_time_to_additional_cap_needed = convert_seconds_to_minutes_seconds(
            calculate_time_until_additional_cap_needed(
                red_score, blue_score, red_caps, blue_caps, neutral_caps, red_caps_needed, blue_caps_needed
            )
        )

    display_victory_conditions(points_to_red_victory, points_to_blue_victory, red_caps_needed, blue_caps_needed)

func display_victory_conditions(points_to_red_victory: int, points_to_blue_victory: int, red_caps_needed: int, blue_caps_needed: int) -> void:
    var winning_team = "Red" if projected_loser == "Blue" else "Blue"
    var winning_time = time_to_red_victory if winning_team == "Red" else time_to_blue_victory
    var winning_caps_needed = red_caps_needed if winning_team == "Red" else blue_caps_needed
    var winning_message = "%s team is winning. They need %d caps to win.\n" % [
        winning_team, winning_caps_needed
    ]

    var losing_message = ""
    if loser_caps_needed >= Constants.CAPTURE_POINTS:
        losing_message = "%s team is losing. They need all %d caps to win.\n\n" % [
            projected_loser, Constants.CAPTURE_POINTS
        ]
    else:
        losing_message = "%s team is losing. They need %d caps to win.\n\n" % [
            projected_loser, loser_caps_needed
        ]

    var additional_cap_message = ""
    if approx_time_to_additional_cap_needed != "N/A":
        additional_cap_message = "%s team will need an additional cap in %s.\nReminder: it takes 60s to capture a point\n\n" % [projected_loser, approx_time_to_additional_cap_needed]

    var winning_time_message = "%s team will win in %s with their current caps.\n" % [winning_team, convert_seconds_to_minutes_seconds(int(winning_time))]

    $VictoryConditionsLabel.text = winning_message + losing_message + additional_cap_message + winning_time_message

func calculate_time_to_win(points_to_victory: int, caps: int) -> float:
    return (points_to_victory * Constants.SCORE_TIMER_INTERVAL) / (caps * Constants.SCORE_PER_CAP_POINT) if caps > 0 else INF

func calculate_caps_needed_to_win(red_score: int, blue_score: int, neutral_caps: int) -> Dictionary:
    var total_capture_points = Constants.CAPTURE_POINTS
    return {
        "red_caps_needed": calculate_team_caps_needed(red_score, blue_score, total_capture_points, neutral_caps),
        "blue_caps_needed": calculate_team_caps_needed(blue_score, red_score, total_capture_points, neutral_caps)
    }

func calculate_team_caps_needed(team_score: int, opponent_score: int, total_capture_points: int, neutral_caps: int) -> int:
    var available_caps = total_capture_points - neutral_caps
    for caps in range(1, available_caps + 1):
        var numerator = (score_limit - team_score) * available_caps
        var denominator = (score_limit - team_score) + (score_limit - opponent_score)
        if caps > numerator / denominator if denominator != 0 else 0:
            return caps
    return available_caps

func calculate_time_until_additional_cap_needed(
    red_score: int, blue_score: int, red_caps: int, blue_caps: int, neutral_caps: int, current_red_caps_needed: int, current_blue_caps_needed: int
) -> float:
    var time_elapsed = 0.0
    var red_current_score = red_score
    var blue_current_score = blue_score

    while time_elapsed < max_time:
        var caps_needed = calculate_caps_needed_to_win(red_current_score, blue_current_score, neutral_caps)
        if projected_loser == "Red" and caps_needed["red_caps_needed"] > current_red_caps_needed:
            return time_elapsed
        elif projected_loser == "Blue" and caps_needed["blue_caps_needed"] > current_blue_caps_needed:
            return time_elapsed

        time_elapsed += Constants.SCORE_TIMER_INTERVAL
        red_current_score += red_caps * Constants.SCORE_PER_CAP_POINT
        blue_current_score += blue_caps * Constants.SCORE_PER_CAP_POINT

    return -1.0

func convert_seconds_to_minutes_seconds(seconds: int) -> String:
    return "%02d:%02d" % [seconds / 60, seconds % 60]

func _on_score_timer_timeout() -> void:
    calculate_score()

func _on_sync_timer_tick_score_button_pressed() -> void:
    Events.emit_signal("sync_timer_tick_score_button_pressed")

func _on_manual_score_tick_button_pressed() -> void:
    calculate_score()

func _on_timer_reset_button_pressed() -> void:
    Events.emit_signal("timer_reset_button_pressed")
