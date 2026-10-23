class_name BattleRefusedEvent
extends EventBase
## Content event: a press of the player could not act now. The board says why over the pressed part.

## The reason, a reserved string.
var text_key: String = ""
## What was pressed and, for the hand and minion kinds, its place on the board panel.
var kind: BattleInputEvent.Kind = BattleInputEvent.Kind.BACKDROP
var index: int = -1
## The card costs more mana than is left; the mana count flashes.
var mana: bool = false
## A guard minion stands in the way; the enemy guards pulse.
var guard: bool = false
