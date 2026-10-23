class_name BattleSide
extends RefCounted
## One side of a battle: the hero, the mana, the deck, the hand and the board.

var hero_health: int = 0
var hero_max_health: int = 0
var mana: int = 0
var max_mana: int = 0
## Cards left to draw; the next draw is index 0.
var deck: PackedInt32Array = PackedInt32Array()
var hand: PackedInt32Array = PackedInt32Array()
var board: Array[BattleMinion] = []
## Damage of the next draw from an empty deck minus 1.
var fatigue: int = 0
## How `BattleAi` moves this side: hit the enemy hero rather than trade, and aim damage spells at it.
var face: bool = false


## Index of the minion `uid` on the board, or -1.
func index_of(uid: int) -> int:
	for i: int in board.size():
		if board[i].uid == uid:
			return i
	return -1


## The minion `uid`, or `null`.
func minion(uid: int) -> BattleMinion:
	var index: int = index_of(uid)
	return null if index < 0 else board[index]


func has_guard() -> bool:
	for m: BattleMinion in board:
		if m.guard:
			return true
	return false
