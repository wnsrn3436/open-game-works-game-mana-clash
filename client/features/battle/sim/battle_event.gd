class_name BattleEvent
extends RefCounted
## One thing that happened in a battle, in the order it happened. The battle view plays them one by one.

enum Kind {
	TURN_START,
	DRAW,
	BURN,
	FATIGUE,
	PLAY_CARD,
	SUMMON,
	ATTACK,
	DAMAGE,
	WARD_BREAK,
	HEAL,
	BUFF,
	DEATH,
	GAME_OVER,
}

var kind: Kind = Kind.TURN_START
## The side it happened to or the side that acted.
var side: int = 0
var card_id: int = 0
## A minion uid of `side`, or 0 for the hero of `side`.
var uid: int = 0
## The other end of an attack or a targeted card: its side and uid (0 for the hero), or -1 for none.
var target_side: int = -1
var target_uid: int = 0
## Damage, healing or the attack bonus.
var amount: int = 0
## The health bonus of a buff; the healing a heal asked for, before the max health cut it.
var amount2: int = 0
## Health after damage or healing; attack after a buff; the turn number of a turn start.
var value: int = 0
## Health after a buff; the max mana of a turn start.
var value2: int = 0
## Board index of a summon or death; hand index of a played card.
var index: int = 0
