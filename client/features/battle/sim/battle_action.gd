class_name BattleAction
extends RefCounted
## One move of a side: play a hand card (with a target when it needs one), attack with a minion, or end the turn.

enum Kind { PLAY, ATTACK, END_TURN }

var kind: Kind = Kind.END_TURN
var hand_index: int = -1
var attacker_uid: int = 0
## Side of the target, or -1 for none.
var target_side: int = -1
## Minion uid of the target, or 0 for the hero of `target_side`.
var target_uid: int = 0


static func play(index: int, side: int, uid: int) -> BattleAction:
	var out: BattleAction = BattleAction.new()
	out.kind = Kind.PLAY
	out.hand_index = index
	out.target_side = side
	out.target_uid = uid
	return out


static func attack(attacker: int, side: int, uid: int) -> BattleAction:
	var out: BattleAction = BattleAction.new()
	out.kind = Kind.ATTACK
	out.attacker_uid = attacker
	out.target_side = side
	out.target_uid = uid
	return out


static func end_turn() -> BattleAction:
	return BattleAction.new()
