class_name BattleSimRunner
extends RefCounted
## DEV: plays whole battles without a screen. Both sides move by `BattleAi`; the player deck is the deck the player has
## when it reaches the opponent on the ladder (the starter deck with the rewards of every opponent before it).


## The player deck on reaching `opponent_id`: `[starter_deck]` with the swaps of each opponent of a lower order.
static func ladder_deck(opponent_id: int) -> PackedInt32Array:
	var deck: PackedInt32Array = GameData.DeckTable.get_row(ReservedId.starter_deck()).cards.duplicate()
	var order: int = GameData.OpponentTable.get_row(opponent_id).order
	for row: GameData.OpponentRow in _by_order():
		if row.order >= order:
			break
		deck = swapped(deck, row)
	return deck


## `deck` with the first-win reward of `row`: each removed card is replaced by the added card at the same position.
static func swapped(deck: PackedInt32Array, row: GameData.OpponentRow) -> PackedInt32Array:
	var out: PackedInt32Array = deck.duplicate()
	for i: int in mini(row.reward_cards.size(), row.reward_removes.size()):
		var at: int = out.find(row.reward_removes[i])
		if at >= 0:
			out[at] = row.reward_cards[i]
	return out


## A battle against `opponent_id` with `seed_value`, started.
static func new_battle(opponent_id: int, seed_value: int) -> BattleSim:
	var opponent: GameData.OpponentRow = GameData.OpponentTable.get_row(opponent_id)
	var sim: BattleSim = BattleSim.new(ladder_deck(opponent_id), GameData.DeckTable.get_row(opponent.deck).cards,
		GameSetting.hero_health(), opponent.hero_health, seed_value)
	sim.sides[BattleSim.CPU].face = opponent.ai_face
	sim.start()
	return sim


## Plays `sim` to its end with `BattleAi` on both sides. Returns the actions taken; stops after `limit` actions.
static func play_out(sim: BattleSim, limit: int) -> int:
	var actions: int = 0
	while not sim.over and actions < limit:
		var action: BattleAction = BattleAi.next_action(sim, sim.active)
		apply(sim, sim.active, action)
		sim.take_events()
		actions += 1
	return actions


## Applies `action` of `side`. Returns whether the simulation took it.
static func apply(sim: BattleSim, side: int, action: BattleAction) -> bool:
	match action.kind:
		BattleAction.Kind.PLAY:
			return sim.play_card(side, action.hand_index, action.target_side, action.target_uid)
		BattleAction.Kind.ATTACK:
			return sim.attack(side, action.attacker_uid, action.target_side, action.target_uid)
	sim.end_turn()
	return true


static func _by_order() -> Array[GameData.OpponentRow]:
	var rows: Array[GameData.OpponentRow] = GameData.OpponentTable.all_rows().duplicate()
	rows.sort_custom(func(a: GameData.OpponentRow, b: GameData.OpponentRow) -> bool: return a.order < b.order)
	return rows
