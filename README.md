# neb-score-calc

A score calculator for NEBULOUS: Fleet Command's control game mode.
Currently limited to typical 5 points and no time limit. Caps needed to win assumes all caps are controlled by a team (no neutrals remain).

## USAGE

- Click the control point icons to change the team that controls them.
- Use the timer sync button to sync the clock to the match.
- Make any necessary adjustments to the score.
- The score will be updated as you make changes.

## KNOWN ISSUES

- Does not account for neutral control points.
- Limited to 5 control points, no time limit.
- Time before next cap needed only works for case of 3 to 4 points needed

## Bugs and feature requests

Submit any bugs or feature requests here: [GitHub Issues](https://github.com/matthew-cavener/neb-control-score-calculator/issues)

## Credits

- Lys: for developing [NEBULOUS: Fleet Command](https://store.steampowered.com/app/887570/NEBULOUS_Fleet_Command/)
- localmathblob: for initial work on `vic_time.sh` to determine victory time
- 🦞🦞: for help with [time until additional cap needed](https://discord.com/channels/1091469366371029025/1091469367323152386/1353191485893246976) calculation
- jraamus: for help with [caps needed](https://discord.com/channels/1091469366371029025/1091469367323152386/1353181341570830337) and [time until additional cap needed](https://discord.com/channels/1091469366371029025/1091469367323152386/1353200096350699602) calculations
