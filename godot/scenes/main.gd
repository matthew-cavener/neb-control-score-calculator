extends Node2D

var projected_loser: String = ""
var loser_caps_needed: int = 0
var time_to_red_victory: float = INF
var time_to_blue_victory: float = INF
var approx_time_to_additional_cap_needed: String = ""
var is_tie: bool = false
var total_caps: int = 5

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
    total_caps = red_caps + blue_caps + neutral_caps

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

    is_tie = time_to_red_victory == time_to_blue_victory

    var red_caps_needed = calculate_caps_needed_to_win(red_score, blue_score, neutral_caps)
    var blue_caps_needed = calculate_caps_needed_to_win(blue_score, red_score, neutral_caps)

    if not is_tie:
        projected_loser = "Red" if time_to_red_victory > time_to_blue_victory else "Blue"
        loser_caps_needed = red_caps_needed if projected_loser == "Red" else blue_caps_needed

        if loser_caps_needed >= total_caps:
            approx_time_to_additional_cap_needed = "N/A"
        else:
            approx_time_to_additional_cap_needed = convert_seconds_to_minutes_seconds(
                calculate_time_until_additional_cap_needed(
                    red_score, blue_score, red_caps, blue_caps, neutral_caps, red_caps_needed, blue_caps_needed
                )
            )
    else:
        projected_loser = ""
        loser_caps_needed = 0
        approx_time_to_additional_cap_needed = "N/A"

    display_victory_conditions(red_caps, blue_caps, red_caps_needed, blue_caps_needed)


func display_victory_conditions(red_caps: int, blue_caps:int, red_caps_needed: int, blue_caps_needed: int) -> void:
    if red_caps == 0 and blue_caps == 0:
        $VictoryConditionsLabel.text = "Neither team bring a cap fleet?\n"
        return

    if is_tie:
        $VictoryConditionsLabel.text = "It's a tie! Both teams will win in %s with their current caps.\n" % [
            convert_seconds_to_minutes_seconds(int(time_to_red_victory))
        ]
        $VictoryConditionsLabel.text += "Red team needs %d caps to win.\n" % [red_caps_needed + 1]
        $VictoryConditionsLabel.text += "Blue team needs %d caps to win.\n" % [blue_caps_needed + 1]
        return

    var projected_winner = "Red" if projected_loser == "Blue" else "Blue"
    var projected_victory_time = time_to_red_victory if projected_winner == "Red" else time_to_blue_victory
    var projected_winner_caps_needed = red_caps_needed if projected_winner == "Red" else blue_caps_needed

    var winning_message = "%s team is winning. They need %d caps to win\n" % [
        projected_winner, projected_winner_caps_needed
    ]

    var losing_message = ""
    if loser_caps_needed >= total_caps:
        losing_message = "%s team is losing. They need all %d caps to win\n\n" % [
            projected_loser, total_caps
        ]
    else:
        losing_message = "%s team is losing. They need %d caps to win\n\n" % [
            projected_loser, loser_caps_needed
        ]

    var additional_cap_message = ""
    if approx_time_to_additional_cap_needed != "N/A":
        additional_cap_message = "%s team will need %s caps in %s\nReminder: it takes 60s to capture a point\n\n" % [
            projected_loser, loser_caps_needed + 1, approx_time_to_additional_cap_needed
        ]

    var winning_time_message = "%s team will win in %s with their current caps\n" % [
        projected_winner, convert_seconds_to_minutes_seconds(int(projected_victory_time))
    ]

    $VictoryConditionsLabel.text = winning_message + losing_message + additional_cap_message + winning_time_message


func calculate_time_to_win(points_to_victory: int, caps: int) -> float:
    if caps > 0:
        var raw_time = (points_to_victory * Constants.SCORE_TIMER_INTERVAL) / (caps * Constants.SCORE_PER_CAP_POINT)
        return ceil(raw_time / Constants.SCORE_TIMER_INTERVAL) * Constants.SCORE_TIMER_INTERVAL
    else:
        return INF


func calculate_caps_needed_to_win(team_score: int, opponent_score: int, neutral_caps: int) -> int:
    var controlled_caps = total_caps - neutral_caps
    var remaining_team_score = score_limit - team_score
    var remaining_opponent_score = score_limit - opponent_score
    var total_remaining_score = remaining_team_score + remaining_opponent_score
    var required_caps = ceil(float(remaining_team_score * controlled_caps) / total_remaining_score)
    return min(required_caps, controlled_caps)


func calculate_time_until_additional_cap_needed(
    red_score: int, blue_score: int, red_caps: int, blue_caps: int, neutral_caps: int, current_red_caps_needed: int, current_blue_caps_needed: int
) -> float:
    var time_elapsed = 0.0
    var projected_loser_current_score = red_score if projected_loser == "Red" else blue_score
    var projected_winner_current_score = blue_score if projected_loser == "Red" else red_score
    var projected_loser_caps = red_caps if projected_loser == "Red" else blue_caps
    var projected_winner_caps = blue_caps if projected_loser == "Red" else red_caps
    var current_projected_loser_caps_needed = current_red_caps_needed if projected_loser == "Red" else current_blue_caps_needed
    while time_elapsed < max_time:
        var ticked_loser_caps_needed = calculate_caps_needed_to_win(projected_loser_current_score, projected_winner_current_score, neutral_caps)
        if ticked_loser_caps_needed > current_projected_loser_caps_needed:
            return time_elapsed
        time_elapsed += Constants.SCORE_TIMER_INTERVAL
        projected_loser_current_score += projected_loser_caps * Constants.SCORE_PER_CAP_POINT
        projected_winner_current_score += projected_winner_caps * Constants.SCORE_PER_CAP_POINT
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


func _on_add_control_point_button_pressed():
    Events.emit_signal("add_control_point_button_pressed")

func _on_remove_control_point_button_pressed():
    Events.emit_signal("remove_control_point_button_pressed")
