class_name BattleConstants
extends RefCounted
## Drawing values of the battle feature. Gameplay values are in `game_setting`.

## Center x of the board rows and the hand, and the step between minion places and hand cards, in pixels.
const ROW_CENTER_X: float = 960.0 # layout of the drawing only; no rule reads it
const MINION_STEP: float = 156.0 # layout of the drawing only; no rule reads it
const HAND_STEP_MAX: float = 186.0 # layout of the drawing only; no rule reads it
## Left and right ends of the hand: past the cost badge from the screen edge, and short of the mana box.
const HAND_LEFT: float = 40.0 # layout of the drawing only; no rule reads it
const HAND_RIGHT: float = 1570.0 # layout of the drawing only; no rule reads it
## How far a picked hand card rises, in pixels.
const PICK_RISE: float = 34.0 # layout of the drawing only; no rule reads it
## Title color of a won and a lost battle.
const WIN_COLOR: Color = Color(1.0, 0.85, 0.35, 1.0) # color of the drawing only; no rule reads it
const LOSE_COLOR: Color = Color(0.85, 0.42, 0.42, 1.0) # color of the drawing only; no rule reads it
## Tint of the player's portrait on the end banner of a loss.
const LOST_PORTRAIT_COLOR: Color = Color(0.62, 0.5, 0.5, 1.0) # color of the drawing only; no rule reads it
## Text color of the tip line after a loss.
const TIP_COLOR: Color = Color(0.957, 0.922, 0.867, 1.0) # color of the drawing only; no rule reads it
## Outline of a minion that can attack, of a target, of the picked attacker.
const READY_COLOR: Color = Color(0.357, 0.89, 0.49, 1.0) # color of the drawing only; no rule reads it
const TARGET_COLOR: Color = Color(1.0, 0.42, 0.29, 1.0) # color of the drawing only; no rule reads it
const PICKED_COLOR: Color = Color(1.0, 0.878, 0.4, 1.0) # color of the drawing only; no rule reads it
## Damage and heal number colors.
const DAMAGE_COLOR: Color = Color(1.0, 0.36, 0.3, 1.0) # color of the drawing only; no rule reads it
const HEAL_COLOR: Color = Color(0.45, 0.95, 0.5, 1.0) # color of the drawing only; no rule reads it
## Mana crystal colors: full, spent, locked.
const MANA_FULL_COLOR: Color = Color(0.247, 0.663, 0.961, 1.0) # color of the drawing only; no rule reads it
const MANA_SPENT_COLOR: Color = Color(0.2, 0.25, 0.35, 1.0) # color of the drawing only; no rule reads it
## Hero damage from this much on shakes the board.
const SHAKE_DAMAGE: int = 3 # look of the effect only; no rule reads it
## Instances of each particle effect on the board: as many as can burst at once (an area spell hits a full row).
const BURST_POOL: int = 6 # look of the effect only; no rule reads it
## How far toward its target an attacking minion moves, as a part of the way.
const LUNGE_REACH: float = 0.82 # look of the effect only; no rule reads it
## Frames a DEV screen command waits for the battle to start or the popup to open.
const DEV_WAIT_FRAMES: int = 1200 # DEV command time limit; no game rule reads it
## Click intervals the DEV bot keeps between its taps; a tap lands a moment after the bot command returns it.
const DEV_TAP_INTERVALS: int = 2 # DEV bot pacing; no game rule reads it
## Actions of one DEV simulated battle at most.
const DEV_SIM_ACTION_LIMIT: int = 5000 # DEV simulation guard; no game rule reads it
## Values of the result panel the DEV screen command opens for the UI check.
const PREVIEW_TURNS: int = 11 # DEV preview text only; no game rule reads it
const PREVIEW_WINS: int = 4 # DEV preview text only; no game rule reads it
const PREVIEW_LOSSES: int = 2 # DEV preview text only; no game rule reads it
const PREVIEW_STREAK: int = 3 # DEV preview text only; no game rule reads it
## Presses kept while effects play; more are answered but dropped.
const HELD_PRESS_LIMIT: int = 8 # input buffer size of the drawing only; no rule reads it
## How much a picked hand card grows.
const PICK_SCALE: float = 1.12 # layout of the drawing only; no rule reads it
## Space between a refusal message and the part it is about, the highest it may sit, and its distance from the
## screen sides, in pixels.
const REFUSAL_GAP: float = 6.0 # layout of the drawing only; no rule reads it
const REFUSAL_TOP: float = 60.0 # layout of the drawing only; no rule reads it
const REFUSAL_EDGE: float = 20.0 # layout of the drawing only; no rule reads it
## Top and bottom of the gold line across the board art between the enemy half and the own half, in pixels.
const BOARD_LINE_TOP: float = 544.0 # layout of the drawing only; no rule reads it
const BOARD_LINE_BOTTOM: float = 568.0 # layout of the drawing only; no rule reads it
## Lines of the CPU turn summary: what happened, what the player lost, what the player won.
const SUMMARY_COLOR: Color = Color(0.957, 0.922, 0.867, 1.0) # color of the drawing only; no rule reads it
const SUMMARY_LOSS_COLOR: Color = Color(1.0, 0.42, 0.36, 1.0) # color of the drawing only; no rule reads it
const SUMMARY_GAIN_COLOR: Color = Color(0.91, 0.722, 0.29, 1.0) # color of the drawing only; no rule reads it
## Space under the last line of the CPU turn summary, in pixels.
const SUMMARY_BOTTOM: float = 22.0 # layout of the drawing only; no rule reads it
## The enemy card backs: how far the outer ones lean out in degrees, the step between them, the top of the middle one
## (inside the screen, so every back shows whole) and how much lower the outer ones sit, in pixels.
const BACK_FAN_DEGREES: float = 12.0 # look of the drawing only; no rule reads it
const BACK_STEP: float = 46.0 # layout of the drawing only; no rule reads it
const BACK_TOP: float = 8.0 # layout of the drawing only; no rule reads it
const BACK_DROP: float = 8.0 # layout of the drawing only; no rule reads it
## Draw order of what a hit shows (numbers, shockwave rings, bursts): above an attacker that lunged onto its target.
const HIT_Z: int = 2 # draw order of the drawing only; no rule reads it
## Size of the impact burst at a hit against its particle resource.
const IMPACT_BURST_SCALE: float = 1.7 # look of the effect only; no rule reads it
## Height of the dust ring center under a landed minion, as a part of the minion height.
const DUST_FOOT: float = 0.82 # look of the effect only; no rule reads it
