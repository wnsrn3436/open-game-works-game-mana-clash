class_name BattleInputEvent
extends EventBase
## Content event: the player pressed a part of the board.

enum Kind { HAND, OWN_MINION, ENEMY_MINION, OWN_HERO, ENEMY_HERO, END_TURN, BACKDROP }

var kind: Kind = Kind.BACKDROP
## Hand index for the hand kind; place on the board panel for the minion kinds.
var index: int = -1
## The minion at that place for the minion kinds; 0 for an empty place and the other kinds.
var uid: int = 0
## The card the pressed hand place showed for the hand kind; 0 for the other kinds.
var card_id: int = 0
