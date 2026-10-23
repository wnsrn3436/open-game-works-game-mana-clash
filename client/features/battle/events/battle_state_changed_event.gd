class_name BattleStateChangedEvent
extends EventBase
## Content event: the battle scene state the board panel draws when no effect plays. The panel reads `sim` only.

## `BattleScene.Stage`.
var stage: int = 0
## The battle; `null` before the server answered.
var sim: BattleSim = null
var opponent_id: int = 0
## `BattleScene.Pick`: nothing, a hand card waiting for its target, or a minion waiting for its attack target.
var pick: int = 0
var pick_hand: int = -1
var pick_uid: int = 0
## Reserved string key of the hint line, or empty for none.
var hint: String = ""
