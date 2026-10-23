extends UnitTestCase
## The battle scene: the presses made while an effect plays act one by one in the order they were made when the
## effects end, and a hand press acts on the card it showed.

var _fx: int = 0


func before_each() -> void:
	super()
	_fx = 0


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


## Inits the modules the scene uses in module list order and loads the data.
func prepare() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(UserStateCore.init(), "UserStateCore.init")
	assert_true(LocalizationCore.init(), "LocalizationCore.init")
	assert_true(SoundCore.init(), "SoundCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")
	EventCore.subscribe(BattleFxEvent, _on_fx)


func _on_fx(_event: BattleFxEvent) -> void:
	_fx += 1


func id(id_name: String) -> int:
	var value: int = GameDataDev.find_id_value(id_name)
	assert_gt(value, 0, "%s is a data row" % id_name)
	return value


## A scene in the player's turn of a new battle whose effects still play.
func busy_scene() -> BattleScene:
	var scene: BattleScene = BattleScene.new()
	scene.scope = ResourceCore.get_global_scope()
	scene._sim = BattleSimRunner.new_battle(id("[opp_apprentice]"), 7)
	scene._sim.take_events()
	scene._stage = BattleScene.Stage.PLAYER_TURN
	scene._fx_busy = true
	return scene


func press(scene: BattleScene, kind: BattleInputEvent.Kind, index: int, card_id: int = 0) -> void:
	var event: BattleInputEvent = BattleInputEvent.new()
	event.kind = kind
	event.index = index
	event.card_id = card_id
	scene._on_input(event)


## The effects of the last change end.
func settle(scene: BattleScene) -> void:
	scene._on_fx_idle(null)


func test_a_card_press_and_an_end_turn_press_made_while_an_effect_plays_both_act_in_order() -> void:
	await prepare()
	var scene: BattleScene = busy_scene()
	var own: BattleSide = scene._sim.sides[BattleSim.PLAYER]
	own.hand.push_back(id("[card_iron_wolf]"))
	own.mana = GameSetting.max_mana()
	var index: int = own.hand.size() - 1
	press(scene, BattleInputEvent.Kind.HAND, index, own.hand[index])
	press(scene, BattleInputEvent.Kind.END_TURN, -1)
	settle(scene)
	assert_eq(own.board.size(), 1, "the pressed card is played first")
	assert_eq(scene._sim.active, BattleSim.PLAYER, "the turn does not end while the card plays")
	settle(scene)
	assert_eq(scene._sim.active, BattleSim.CPU, "then the turn ends")
	scene.free()


func test_an_attack_and_its_target_pressed_while_an_effect_plays_both_act() -> void:
	await prepare()
	var scene: BattleScene = busy_scene()
	var own: BattleSide = scene._sim.sides[BattleSim.PLAYER]
	var wolf: BattleMinion = BattleMinion.new()
	wolf.uid = 900
	wolf.card_id = id("[card_iron_wolf]")
	wolf.attack = 3
	wolf.health = 3
	wolf.max_health = 3
	wolf.attacks_left = 1
	wolf.sleeping = false
	own.board.append(wolf)
	var enemy: BattleSide = scene._sim.sides[BattleSim.CPU]
	var health: int = enemy.hero_health
	var minion_press: BattleInputEvent = BattleInputEvent.new()
	minion_press.kind = BattleInputEvent.Kind.OWN_MINION
	minion_press.index = 0
	minion_press.uid = wolf.uid
	scene._on_input(minion_press)
	press(scene, BattleInputEvent.Kind.ENEMY_HERO, -1)
	settle(scene)
	assert_eq(enemy.hero_health, health - wolf.attack, "the wolf hits the enemy hero")
	scene.free()


func test_a_held_hand_press_plays_the_card_it_showed_after_the_hand_moved() -> void:
	await prepare()
	var scene: BattleScene = busy_scene()
	var own: BattleSide = scene._sim.sides[BattleSim.PLAYER]
	own.mana = GameSetting.max_mana()
	own.hand.clear()
	own.hand.push_back(id("[card_iron_wolf]"))
	own.hand.push_back(id("[card_moss_guard]"))
	press(scene, BattleInputEvent.Kind.HAND, 0, id("[card_iron_wolf]"))
	press(scene, BattleInputEvent.Kind.HAND, 1, id("[card_moss_guard]"))
	settle(scene)
	settle(scene)
	assert_eq(own.board.size(), 2, "both pressed cards are played")
	assert_eq(own.board[1].card_id, id("[card_moss_guard]"), "the second press plays the card it showed")
	scene.free()
