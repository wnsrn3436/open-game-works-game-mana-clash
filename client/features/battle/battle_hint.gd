class_name BattleHint
extends RefCounted
## The hint line of the first battle: the next step the player can take. A step shows until the player has done it
## once in the battle (played a card, attacked, ended a turn), so a player who knows it is not told again. A waiting
## pick always says what to press.


## The translation key of the hint for the player's turn of `sim` with `pick` waiting, or "" for none. `played`,
## `attacked` and `ended` say which steps the player has done in this battle.
static func text(sim: BattleSim, pick: BattleScene.Pick, played: bool, attacked: bool, ended: bool) -> String:
	if pick == BattleScene.Pick.HAND:
		return ReservedString.battle_hint_target()
	if pick == BattleScene.Pick.ATTACKER:
		return ReservedString.battle_hint_attack_target()
	var can_play: bool = false
	for i: int in sim.sides[BattleSim.PLAYER].hand.size():
		if sim.check_play(BattleSim.PLAYER, i) == BattleSim.PlayCheck.OK:
			can_play = true
			break
	var can_attack: bool = sim.ready_attack(BattleSim.PLAYER) > 0
	if can_play and not played:
		return ReservedString.battle_hint_play()
	if can_attack and not attacked:
		return ReservedString.battle_hint_attack()
	if not can_play and not can_attack and not ended:
		return ReservedString.battle_hint_end_turn()
	return ""
