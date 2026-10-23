extends UnitTestCase
## The hint line of the first battle: each step shows until the player has done it once, so a player who already
## plays cards and attacks is not told again.

const _SEED: int = 7


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


## A battle on the player's turn with a playable cheap minion in hand and one ready minion on the board.
func battle_with_moves() -> BattleSim:
	var sim: BattleSim = BattleSimRunner.new_battle(id("[opp_apprentice]"), _SEED)
	sim.take_events()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.hand.push_back(id("[card_ember_imp]"))
	own.mana = GameSetting.max_mana()
	var m: BattleMinion = BattleMinion.new()
	m.uid = 900
	m.card_id = id("[card_iron_wolf]")
	m.attack = 3
	m.health = 3
	m.max_health = 3
	m.sleeping = false
	m.attacks_left = 1
	own.board.append(m)
	return sim


func test_a_new_player_is_told_to_play_a_card_first() -> void:
	var sim: BattleSim = battle_with_moves()
	assert_eq(BattleHint.text(sim, BattleScene.Pick.NONE, false, false, false), ReservedString.battle_hint_play())


func test_a_player_who_played_a_card_is_told_to_attack_next() -> void:
	var sim: BattleSim = battle_with_moves()
	assert_eq(BattleHint.text(sim, BattleScene.Pick.NONE, true, false, false), ReservedString.battle_hint_attack())


func test_a_player_with_nothing_left_is_told_to_end_the_turn_until_it_did_once() -> void:
	var sim: BattleSim = battle_with_moves()
	sim.sides[BattleSim.PLAYER].mana = 0
	sim.sides[BattleSim.PLAYER].board[0].attacks_left = 0
	assert_eq(BattleHint.text(sim, BattleScene.Pick.NONE, true, true, false), ReservedString.battle_hint_end_turn())
	assert_eq(BattleHint.text(sim, BattleScene.Pick.NONE, true, true, true), "",
		"no hint once the player did each step")


func test_a_player_who_did_each_step_gets_no_hint_on_a_later_turn() -> void:
	var sim: BattleSim = battle_with_moves()
	assert_eq(BattleHint.text(sim, BattleScene.Pick.NONE, true, true, true), "",
		"a card and an attack wait, but the player knows")


func test_a_pick_waits_for_its_target_whatever_was_done() -> void:
	var sim: BattleSim = battle_with_moves()
	assert_eq(BattleHint.text(sim, BattleScene.Pick.HAND, true, true, true), ReservedString.battle_hint_target())
	assert_eq(BattleHint.text(sim, BattleScene.Pick.ATTACKER, true, true, true), ReservedString.battle_hint_attack_target())
