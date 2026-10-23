class_name BattleMinion
extends RefCounted
## One minion on the board of a battle: the card it came from, its stats now and its keyword state.

## Unique in the battle; never 0, which is the hero of a side.
var uid: int = 0
var card_id: int = 0
var attack: int = 0
var health: int = 0
var max_health: int = 0
## Enemies must attack a guard minion first.
var guard: bool = false
## The next damage to this minion is ignored and removes the ward.
var ward: bool = false
## It came this turn without charge and cannot attack yet.
var sleeping: bool = true
## Attacks it may still make this turn.
var attacks_left: int = 0


func can_attack() -> bool:
	return attack > 0 and attacks_left > 0 and not sleeping


func copy() -> BattleMinion:
	var out: BattleMinion = BattleMinion.new()
	out.uid = uid
	out.card_id = card_id
	out.attack = attack
	out.health = health
	out.max_health = max_health
	out.guard = guard
	out.ward = ward
	out.sleeping = sleeping
	out.attacks_left = attacks_left
	return out
