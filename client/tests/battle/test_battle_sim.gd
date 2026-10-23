extends UnitTestCase
## The battle rules: the same seed and moves give the same battle, the opening hand has a cheap card, mana grows each
## turn, charge, guard, ward, death effects, targeted cards, fatigue, the hand limit, surrender and the turn limit.

const _SEED: int = 4242
const _SEEDS: int = 20
const _ACTION_LIMIT: int = 5000


func before_each() -> void:
	super()
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func id(id_name: String) -> int:
	var value: int = GameDataDev.find_id_value(id_name)
	assert_gt(value, 0, "%s is a data row" % id_name)
	return value


## A deck of `count` copies of the card.
func deck_of(id_name: String, count: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for i: int in count:
		out.push_back(id(id_name))
	return out


func started(player_deck: PackedInt32Array, cpu_deck: PackedInt32Array, seed_value: int) -> BattleSim:
	var sim: BattleSim = BattleSim.new(player_deck, cpu_deck, GameSetting.hero_health(), GameSetting.hero_health(), seed_value)
	sim.start()
	sim.take_events()
	return sim


## Puts an awake minion of the card on the board of `side` and returns it.
func put(sim: BattleSim, side: int, id_name: String) -> BattleMinion:
	var row: GameData.CardRow = GameData.CardTable.get_row(id(id_name))
	var m: BattleMinion = BattleMinion.new()
	m.uid = sim.sides[0].board.size() + sim.sides[1].board.size() + 1000
	m.card_id = row.id
	m.attack = row.attack
	m.health = row.health
	m.max_health = row.health
	m.guard = row.guard
	m.ward = row.ward
	m.sleeping = false
	m.attacks_left = 1
	sim.sides[side].board.append(m)
	return m


func snapshot(sim: BattleSim) -> PackedInt64Array:
	var out: PackedInt64Array = PackedInt64Array([sim.turn, sim.winner, sim.cards_played, sim.active])
	for s: BattleSide in sim.sides:
		out.append_array(PackedInt64Array([s.hero_health, s.mana, s.max_mana, s.deck.size(), s.hand.size(), s.board.size(), s.fatigue]))
		for card_id: int in s.hand:
			out.push_back(card_id)
		for m: BattleMinion in s.board:
			out.append_array(PackedInt64Array([m.card_id, m.attack, m.health]))
	return out


func test_the_same_seed_and_moves_give_the_same_battle() -> void:
	var opponent: int = id("[opp_warden]")
	var a: BattleSim = BattleSimRunner.new_battle(opponent, _SEED)
	var b: BattleSim = BattleSimRunner.new_battle(opponent, _SEED)
	assert_eq(snapshot(a), snapshot(b), "the same opening")
	BattleSimRunner.play_out(a, _ACTION_LIMIT)
	BattleSimRunner.play_out(b, _ACTION_LIMIT)
	assert_true(a.over, "the battle ended")
	assert_eq(snapshot(a), snapshot(b), "the same end")


func test_the_opening_hand_has_a_cheap_card() -> void:
	var expensive: PackedInt32Array = deck_of("[card_sky_colossus]", GameSetting.deck_size() - 1)
	expensive.push_back(id("[card_ember_imp]"))
	for seed_value: int in range(1, _SEEDS + 1):
		var sim: BattleSim = started(expensive, expensive, seed_value)
		assert_true(sim.sides[BattleSim.PLAYER].hand.has(id("[card_ember_imp]")), "player hand of seed %d" % seed_value)
		assert_true(sim.sides[BattleSim.CPU].hand.has(id("[card_ember_imp]")), "cpu hand of seed %d" % seed_value)
		assert_eq(sim.sides[BattleSim.PLAYER].hand.size(), GameSetting.start_hand_first() + 1, "the first turn draws one")
		assert_eq(sim.sides[BattleSim.CPU].hand.size(), GameSetting.start_hand_second(), "the CPU waits for its turn")


func test_each_side_can_play_a_card_on_its_first_turn() -> void:
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		for seed_value: int in range(1, _SEEDS + 1):
			var sim: BattleSim = BattleSimRunner.new_battle(row.id, seed_value)
			assert_true(playable(sim, BattleSim.PLAYER), "player first turn of %s seed %d" % [row.id, seed_value])
			sim.end_turn()
			assert_true(playable(sim, BattleSim.CPU), "CPU first turn of %s seed %d" % [row.id, seed_value])


func test_the_opening_hand_brings_in_a_cheap_minion_before_a_cheap_spell() -> void:
	var deck: PackedInt32Array = deck_of("[card_sky_colossus]", GameSetting.deck_size() - 2)
	deck.push_back(id("[card_mana_bolt]"))
	deck.push_back(id("[card_ember_imp]"))
	for seed_value: int in range(1, _SEEDS + 1):
		var sim: BattleSim = started(deck, deck, seed_value)
		assert_true(sim.sides[BattleSim.PLAYER].hand.has(id("[card_ember_imp]")), "player hand of seed %d" % seed_value)
		assert_true(sim.sides[BattleSim.CPU].hand.has(id("[card_ember_imp]")), "cpu hand of seed %d" % seed_value)


func test_each_opening_hand_has_a_minion_for_each_of_the_first_two_turns() -> void:
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		for seed_value: int in range(1, _SEEDS + 1):
			var sim: BattleSim = BattleSimRunner.new_battle(row.id, seed_value)
			for side: int in [BattleSim.PLAYER, BattleSim.CPU]:
				var costs: PackedInt32Array = PackedInt32Array()
				for card_id: int in sim.sides[side].hand:
					if BattleSim.is_minion(card_id):
						costs.push_back(BattleSim.card(card_id).cost)
				costs.sort()
				var label: String = "side %d of %s seed %d" % [side, GameDataDev.find_id_name(row.id), seed_value]
				assert_true(costs.size() >= 2, "%s: two minions" % label)
				if costs.size() >= 2:
					assert_true(costs[0] <= GameSetting.opening_cheap_cost(), "%s: one for the first turn" % label)
					assert_true(costs[1] <= GameSetting.opening_curve_cost(), "%s: one for the second turn" % label)


func test_the_cpu_plays_a_card_on_each_of_its_first_two_turns() -> void:
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		for seed_value: int in range(1, _SEEDS + 1):
			var sim: BattleSim = BattleSimRunner.new_battle(row.id, seed_value)
			sim.take_events()
			var cpu_turns: int = 0
			var played: PackedInt32Array = PackedInt32Array([0, 0, 0])
			var actions: int = 0
			while not sim.over and cpu_turns <= 2 and actions < _ACTION_LIMIT:
				BattleSimRunner.apply(sim, sim.active, BattleAi.next_action(sim, sim.active))
				actions += 1
				for e: BattleEvent in sim.take_events():
					if e.side != BattleSim.CPU:
						continue
					if e.kind == BattleEvent.Kind.TURN_START:
						cpu_turns += 1
					elif e.kind == BattleEvent.Kind.PLAY_CARD and cpu_turns <= 2:
						played[cpu_turns] += 1
			var label: String = "%s seed %d" % [GameDataDev.find_id_name(row.id), seed_value]
			assert_gt(played[1], 0, "%s: the CPU played on its first turn" % label)
			assert_gt(played[2], 0, "%s: the CPU played on its second turn" % label)


func test_a_heal_at_full_health_still_reports_a_heal_of_zero() -> void:
	var sim: BattleSim = started(deck_of("[card_herb_healer]", GameSetting.deck_size()),
		deck_of("[card_herb_healer]", GameSetting.deck_size()), _SEED)
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.mana = GameSetting.max_mana()
	assert_eq(own.hero_health, own.hero_max_health, "the hero is at full health")
	assert_true(sim.play_card(BattleSim.PLAYER, 0, BattleSim.NO_SIDE, BattleSim.HERO), "play the healer")
	var heals: Array[BattleEvent] = []
	for e: BattleEvent in sim.take_events():
		if e.kind == BattleEvent.Kind.HEAL:
			heals.append(e)
	assert_eq(heals.size(), 1, "one heal event")
	if heals.size() == 1:
		assert_eq(heals[0].amount, 0, "it healed nothing")
		assert_eq(heals[0].value, own.hero_max_health, "the health stays full")


func test_every_first_win_reward_is_cards_that_differ() -> void:
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		var seen: PackedInt32Array = PackedInt32Array()
		for card_id: int in row.reward_cards:
			assert_false(seen.has(card_id), "%s gives %s once" % [GameDataDev.find_id_name(row.id),
				GameDataDev.find_id_name(card_id)])
			seen.push_back(card_id)


func playable(sim: BattleSim, side: int) -> bool:
	for i: int in sim.sides[side].hand.size():
		if sim.check_play(side, i) == BattleSim.PlayCheck.OK:
			return true
	return false


func test_mana_grows_each_turn_up_to_the_max() -> void:
	var sim: BattleSim = started(deck_of("[card_iron_wolf]", GameSetting.deck_size()), deck_of("[card_iron_wolf]", GameSetting.deck_size()), _SEED)
	assert_eq(sim.active, BattleSim.PLAYER, "the player goes first")
	assert_eq(sim.sides[BattleSim.PLAYER].mana, 1, "one mana on the first turn")
	for i: int in GameSetting.max_mana() * 2 + 2:
		sim.end_turn()
	var s: BattleSide = sim.sides[BattleSim.PLAYER]
	assert_eq(s.max_mana, GameSetting.max_mana(), "the max mana stops at [max_mana]")
	assert_eq(s.mana, GameSetting.max_mana(), "the turn fills the mana")


func test_a_card_needs_its_mana_and_a_minion_waits_unless_it_has_charge() -> void:
	var deck: PackedInt32Array = deck_of("[card_gale_hound]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	assert_eq(sim.check_play(BattleSim.PLAYER, 0), BattleSim.PlayCheck.NO_MANA, "a 2 mana card on 1 mana")
	sim.end_turn()
	assert_eq(sim.check_play(BattleSim.PLAYER, 0), BattleSim.PlayCheck.NOT_YOUR_TURN, "not on the CPU turn")
	sim.end_turn()
	assert_true(sim.play_card(BattleSim.PLAYER, 0, BattleSim.NO_SIDE, BattleSim.HERO), "plays with 2 mana")
	var hound: BattleMinion = sim.sides[BattleSim.PLAYER].board[0]
	assert_true(sim.can_attack(BattleSim.PLAYER, hound.uid), "charge attacks at once")
	assert_eq(sim.sides[BattleSim.PLAYER].mana, 0, "the cost is paid")
	var wolf_sim: BattleSim = started(deck_of("[card_ember_imp]", GameSetting.deck_size()), deck, _SEED)
	assert_true(wolf_sim.play_card(BattleSim.PLAYER, 0, BattleSim.NO_SIDE, BattleSim.HERO), "plays a 1 mana minion")
	assert_false(wolf_sim.can_attack(BattleSim.PLAYER, wolf_sim.sides[BattleSim.PLAYER].board[0].uid), "it waits a turn")


func test_a_guard_must_be_attacked_first_and_minions_trade_damage() -> void:
	var deck: PackedInt32Array = deck_of("[card_iron_wolf]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	var wolf: BattleMinion = put(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	var guard: BattleMinion = put(sim, BattleSim.CPU, "[card_moss_guard]")
	var other: BattleMinion = put(sim, BattleSim.CPU, "[card_ember_imp]")
	assert_false(sim.is_attack_target(BattleSim.PLAYER, wolf.uid, BattleSim.CPU, BattleSim.HERO), "not the hero")
	assert_false(sim.is_attack_target(BattleSim.PLAYER, wolf.uid, BattleSim.CPU, other.uid), "not the other minion")
	assert_true(sim.attack(BattleSim.PLAYER, wolf.uid, BattleSim.CPU, guard.uid), "the guard")
	assert_eq(sim.sides[BattleSim.CPU].index_of(guard.uid), -1, "the guard died")
	assert_eq(wolf.health, 3 - guard.attack, "the wolf took the guard attack")
	assert_false(sim.can_attack(BattleSim.PLAYER, wolf.uid), "one attack a turn")


func test_a_ward_stops_the_first_damage() -> void:
	var deck: PackedInt32Array = deck_of("[card_iron_wolf]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	var wolf: BattleMinion = put(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	var knight: BattleMinion = put(sim, BattleSim.CPU, "[card_dawn_knight]")
	assert_true(sim.attack(BattleSim.PLAYER, wolf.uid, BattleSim.CPU, knight.uid), "attacks the knight")
	assert_false(knight.ward, "the ward broke")
	assert_eq(knight.health, GameData.CardTable.get_row(knight.card_id).health, "the knight took no damage")
	var kinds: PackedInt32Array = PackedInt32Array()
	for e: BattleEvent in sim.take_events():
		kinds.append(e.kind)
	assert_true(kinds.has(BattleEvent.Kind.WARD_BREAK), "a ward break event")


func test_a_death_effect_hits_the_enemy_hero_and_a_spell_needs_a_fitting_target() -> void:
	var deck: PackedInt32Array = deck_of("[card_mana_bolt]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	var wraith: BattleMinion = put(sim, BattleSim.CPU, "[card_ash_wraith]")
	var bolt: int = id("[card_mana_bolt]")
	assert_true(sim.is_play_target(BattleSim.PLAYER, bolt, BattleSim.CPU, BattleSim.HERO), "a bolt may hit the enemy hero")
	assert_true(sim.is_play_target(BattleSim.PLAYER, bolt, BattleSim.PLAYER, BattleSim.HERO), "and the own hero")
	assert_false(sim.is_play_target(BattleSim.PLAYER, id("[card_blessing]"), BattleSim.CPU, wraith.uid), "a blessing only on an own minion")
	var health: int = sim.sides[BattleSim.PLAYER].hero_health
	assert_true(sim.play_card(BattleSim.PLAYER, 0, BattleSim.CPU, wraith.uid), "the bolt kills the wraith")
	assert_eq(sim.sides[BattleSim.CPU].board.size(), 0, "the wraith died")
	var wraith_row: GameData.CardRow = GameData.CardTable.get_row(id("[card_ash_wraith]"))
	assert_eq(sim.sides[BattleSim.PLAYER].hero_health, health - wraith_row.amount, "its death hit the player hero")


func test_an_empty_deck_deals_growing_damage_and_a_full_hand_burns_the_card() -> void:
	var tough: int = GameSetting.hero_health() * 10
	var sim: BattleSim = BattleSim.new(deck_of("[card_iron_wolf]", GameSetting.hand_size() + 2), deck_of("[card_iron_wolf]", 1),
		tough, tough, _SEED)
	sim.start()
	sim.take_events()
	var cpu: BattleSide = sim.sides[BattleSim.CPU]
	sim.end_turn()
	assert_eq(cpu.fatigue, 1, "the CPU deck was empty")
	assert_eq(cpu.hero_health, tough - 1, "the first empty draw hurts 1")
	sim.end_turn()
	sim.end_turn()
	assert_eq(cpu.hero_health, tough - 3, "the second hurts 2")
	var burns: int = 0
	for i: int in GameSetting.hand_size() * 2:
		sim.end_turn()
		for e: BattleEvent in sim.take_events():
			if e.kind == BattleEvent.Kind.BURN:
				burns += 1
	assert_eq(sim.sides[BattleSim.PLAYER].hand.size(), GameSetting.hand_size(), "the hand stops at [hand_size]")
	assert_gt(burns, 0, "a card drawn into a full hand burned")


func test_surrender_and_the_turn_limit_end_the_battle_as_a_loss() -> void:
	var deck: PackedInt32Array = deck_of("[card_crystal_turtle]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	sim.concede(BattleSim.PLAYER)
	assert_true(sim.over and sim.conceded, "the surrender ended it")
	assert_eq(sim.winner, BattleSim.CPU, "the CPU won")
	var endless: BattleSim = BattleSim.new(deck, deck, GameSetting.max_turns() * 10, GameSetting.max_turns() * 10, _SEED)
	endless.start()
	for i: int in GameSetting.max_turns() + 1:
		endless.end_turn()
	assert_true(endless.over, "the turn limit ended it")
	assert_eq(endless.winner, BattleSim.NO_SIDE, "nobody won")


func test_the_cpu_finishes_a_hero_it_can_kill() -> void:
	var deck: PackedInt32Array = deck_of("[card_iron_wolf]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	sim.end_turn()
	var wolf: BattleMinion = put(sim, BattleSim.CPU, "[card_iron_wolf]")
	sim.sides[BattleSim.PLAYER].hero_health = wolf.attack
	var action: BattleAction = BattleAi.next_action(sim, BattleSim.CPU)
	assert_eq(action.kind, BattleAction.Kind.ATTACK, "an attack")
	assert_eq(action.target_uid, BattleSim.HERO, "on the hero")
	assert_true(BattleSimRunner.apply(sim, BattleSim.CPU, action), "the move is legal")
	assert_eq(sim.winner, BattleSim.CPU, "the CPU won")


func test_a_face_cpu_hits_the_hero_instead_of_a_trade_and_bolts_the_hero() -> void:
	var deck: PackedInt32Array = deck_of("[card_iron_wolf]", GameSetting.deck_size())
	var sim: BattleSim = started(deck, deck, _SEED)
	sim.end_turn()
	sim.sides[BattleSim.CPU].face = true
	put(sim, BattleSim.CPU, "[card_iron_wolf]")
	var imp: BattleMinion = put(sim, BattleSim.PLAYER, "[card_ember_imp]")
	sim.sides[BattleSim.CPU].hand = PackedInt32Array()
	var action: BattleAction = BattleAi.next_action(sim, BattleSim.CPU)
	assert_eq(action.kind, BattleAction.Kind.ATTACK, "an attack")
	assert_eq(action.target_uid, BattleSim.HERO, "on the hero, not the imp it could kill and survive")
	sim.sides[BattleSim.CPU].face = false
	action = BattleAi.next_action(sim, BattleSim.CPU)
	assert_eq(action.target_uid, imp.uid, "a CPU that is not face takes the trade")
	sim.sides[BattleSim.CPU].face = true
	sim.sides[BattleSim.CPU].hand = PackedInt32Array([id("[card_mana_bolt]")])
	action = BattleAi.next_action(sim, BattleSim.CPU)
	assert_eq(action.kind, BattleAction.Kind.PLAY, "it plays the bolt")
	assert_eq(action.target_side, BattleSim.PLAYER, "at the player side")
	assert_eq(action.target_uid, BattleSim.HERO, "at the hero, not the imp it could kill")


func test_the_practice_opponent_is_face_and_the_others_are_not() -> void:
	assert_true(GameData.OpponentTable.get_row(id("[opp_apprentice]")).ai_face, "the practice opponent hits the hero")
	var sim: BattleSim = BattleSimRunner.new_battle(id("[opp_apprentice]"), _SEED)
	assert_true(sim.sides[BattleSim.CPU].face, "its battle CPU side is face")
	assert_false(sim.sides[BattleSim.PLAYER].face, "the player side is not")
	assert_false(BattleSimRunner.new_battle(id("[opp_warden]"), _SEED).sides[BattleSim.CPU].face, "the warden trades")
