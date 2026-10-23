extends UnitTestCase
## The bot player of the bot playtest picks its next board tap from the battle and the pick on screen alone, so a tap
## the click interval drops is tapped again: a picked attacker or hand card gets its target, a pick the bot does not
## want is cleared on the backdrop, and with no pick it taps the hand card, the minion or the end turn button.

const _SEED: int = 4242


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


## A started battle of decks of the card with empty hands, on the player's first turn.
func started(id_name: String) -> BattleSim:
	var deck: PackedInt32Array = PackedInt32Array()
	for i: int in GameSetting.deck_size():
		deck.push_back(id(id_name))
	var sim: BattleSim = BattleSim.new(deck, deck, GameSetting.hero_health(), GameSetting.hero_health(), _SEED)
	sim.start()
	sim.take_events()
	sim.sides[BattleSim.PLAYER].hand.clear()
	assert_eq(sim.active, BattleSim.PLAYER, "the player starts")
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


func test_a_picked_attacker_whose_target_tap_was_dropped_gets_its_target_again() -> void:
	var sim: BattleSim = started("[card_iron_wolf]")
	var wolf: BattleMinion = put(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	var action: BattleAction = BattleAi.next_action(sim, BattleSim.PLAYER)
	assert_eq(action.kind, BattleAction.Kind.ATTACK, "the bot attacks")
	assert_eq(action.attacker_uid, wolf.uid, "with the wolf")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.NONE, -1, 0), "own_minion_1", "picks the wolf")
	var target: String = BattleBot.board_tap(sim, BattleScene.Pick.ATTACKER, -1, wolf.uid)
	assert_eq(target, "enemy_hero", "the wolf hits the enemy hero")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.ATTACKER, -1, wolf.uid), target, "the same target again")


func test_a_picked_hand_card_that_needs_a_target_gets_it() -> void:
	var sim: BattleSim = started("[card_iron_wolf]")
	var bolt: GameData.CardRow = GameData.CardTable.get_row(id("[card_mana_bolt]"))
	sim.sides[BattleSim.PLAYER].hand.push_back(bolt.id)
	sim.sides[BattleSim.PLAYER].mana = bolt.cost
	sim.sides[BattleSim.CPU].hero_health = bolt.amount
	assert_true(BattleSim.needs_target(bolt.id), "the bolt needs a target")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.NONE, -1, 0), "hand_card_1", "picks the bolt")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.HAND, 0, 0), "enemy_hero", "the bolt finishes the enemy hero")


func test_a_pick_the_bot_does_not_want_is_cleared_and_nothing_left_ends_the_turn() -> void:
	var sim: BattleSim = started("[card_iron_wolf]")
	var wolf: BattleMinion = put(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.ATTACKER, -1, wolf.uid + 1), "board_backdrop", "another attacker")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.HAND, 0, 0), "board_backdrop", "a hand card it does not play")
	assert_true(sim.attack(BattleSim.PLAYER, wolf.uid, BattleSim.CPU, BattleSim.HERO), "the wolf attacks")
	assert_eq(BattleBot.board_tap(sim, BattleScene.Pick.NONE, -1, 0), "end_turn", "nothing left")
