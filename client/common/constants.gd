class_name CommonConstants
extends RefCounted
## Drawing values the shared content code uses. Gameplay values are in `game_setting`.

## Permille of a whole.
const PERMILLE: int = 1000 # unit conversion, not a tunable value
const PERMILLE_F: float = 1000.0 # unit conversion, not a tunable value
## Text color of the terms hint while an agree toggle is off (highlight) and once both are on (secondary text).
const TERMS_HINT_WAITING_COLOR: Color = Color(0.91, 0.722, 0.29, 1.0) # color of the drawing only; no rule reads it
const TERMS_HINT_DONE_COLOR: Color = Color(0.722, 0.675, 0.604, 1.0) # color of the drawing only; no rule reads it
## Card frame border: a playable card, a picked card, a card that waits.
const CARD_PLAYABLE_COLOR: Color = Color(0.357, 0.89, 0.49, 1.0) # color of the drawing only; no rule reads it
const CARD_PICKED_COLOR: Color = Color(1.0, 0.878, 0.4, 1.0) # color of the drawing only; no rule reads it
## Art tint of a hand card that cannot be played now.
const CARD_WAITING_ART_COLOR: Color = Color(0.45, 0.45, 0.5, 1.0) # color of the drawing only; no rule reads it
## Smallest size the rule text of a card shrinks to so a long text fits its box.
const CARD_TEXT_MIN_SIZE: int = 11 # layout of the drawing only; no rule reads it
## Health text of a damaged character, and of a character above its card health.
const HURT_COLOR: Color = Color(1.0, 0.42, 0.36, 1.0) # color of the drawing only; no rule reads it
const BUFFED_COLOR: Color = Color(0.45, 0.95, 0.5, 1.0) # color of the drawing only; no rule reads it
const STAT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0) # color of the drawing only; no rule reads it
