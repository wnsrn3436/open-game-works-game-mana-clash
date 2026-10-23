extends UnitTestCase
## The board panel: a damage number fades away after its hit, a restart draws an empty board before the new battle,
## a buff says what it added, a heal at full health says so, the turn banner leaves the minions readable, a played
## card flies from the hand, the CPU turn is summed up and a loss shows its banner.

var _idle: int = 0
var _pressed_uids: PackedInt32Array = PackedInt32Array()
var _pressed_cards: PackedInt32Array = PackedInt32Array()
var _tweens_started: int = 0


func before_each() -> void:
	super()
	_idle = 0
	_pressed_uids.clear()
	_pressed_cards.clear()
	_tweens_started = 0


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


## Inits the modules the panel uses in module list order, loads the data and translation and prepares the UI.
func prepare_ui() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(UserStateCore.init(), "UserStateCore.init")
	assert_true(ResolutionCore.init(), "ResolutionCore.init")
	assert_true(SafeAreaCore.init(), "SafeAreaCore.init")
	assert_true(InputBlockCore.init(), "InputBlockCore.init")
	assert_true(InputCore.init(), "InputCore.init")
	assert_true(LocalizationCore.init(), "LocalizationCore.init")
	assert_true(SoundCore.init(), "SoundCore.init")
	assert_true(TweenCore.init(), "TweenCore.init")
	assert_true(UICore.init(), "UICore.init")
	assert_true(MessageCore.init(), "MessageCore.init")
	assert_true(ScreenEffectCore.init(), "ScreenEffectCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")
	assert_true(await UICore.prepare(), "UICore.prepare")
	EventCore.subscribe(BattleFxIdleEvent, _on_idle)


func _on_idle(_event: BattleFxIdleEvent) -> void:
	_idle += 1


func _on_input(event: BattleInputEvent) -> void:
	_pressed_uids.push_back(event.uid)


func _on_tween_started(_event: TweenStartedEvent) -> void:
	_tweens_started += 1


## Loads the battle tween presets `keys` into the panel scope, as the battle scene does.
func load_tweens(panel: BattleBoardPanel, keys: PackedStringArray) -> void:
	for key: String in keys:
		assert_not_null(await ResourceCore.load(key, TweenCore.get_preset_kind(), panel.scope), key)


func id(id_name: String) -> int:
	var value: int = GameDataDev.find_id_value(id_name)
	assert_gt(value, 0, "%s is a data row" % id_name)
	return value


func open_board() -> BattleBoardPanel:
	assert_true(await UICore.open_panel(ResourceKey.PREFAB__BATTLE__BOARD_PANEL, null, false), "open the board panel")
	await UnitTestCore.wait_frames(1)
	var panel: BattleBoardPanel = find_panel(UICore.get_layer(UICore.UILayer.PANEL))
	assert_not_null(panel, "the board panel instance")
	return panel


func find_panel(node: Node) -> BattleBoardPanel:
	if node is BattleBoardPanel:
		return node as BattleBoardPanel
	for child: Node in node.get_children():
		var found: BattleBoardPanel = find_panel(child)
		if found != null:
			return found
	return null


func new_sim() -> BattleSim:
	var sim: BattleSim = BattleSimRunner.new_battle(id("[opp_apprentice]"), 7)
	sim.take_events()
	return sim


func publish_state(sim: BattleSim, stage: BattleScene.Stage) -> void:
	var event: BattleStateChangedEvent = EventCore.acquire(BattleStateChangedEvent) as BattleStateChangedEvent
	event.stage = stage
	event.sim = sim
	event.opponent_id = id("[opp_apprentice]")
	EventCore.publish(event)


func publish_fx(sim: BattleSim) -> void:
	for e: BattleEvent in sim.take_events():
		var fx: BattleFxEvent = EventCore.acquire(BattleFxEvent) as BattleFxEvent
		fx.fx = e
		EventCore.publish(fx)


## Moves the test clock on and lets the frames play the effects of that time.
func pass_ms(ms: int) -> void:
	UnitTestCore.advance_clock(ms, false)
	await UnitTestCore.wait_frames(2)


func test_a_hero_damage_number_fades_away_after_the_hit() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	var bolt: int = sim.sides[BattleSim.PLAYER].hand.find(id("[card_mana_bolt]"))
	if bolt < 0:
		sim.sides[BattleSim.PLAYER].hand.push_back(id("[card_mana_bolt]"))
		bolt = sim.sides[BattleSim.PLAYER].hand.size() - 1
	assert_true(sim.play_card(BattleSim.PLAYER, bolt, BattleSim.CPU, BattleSim.HERO), "bolt the enemy hero")
	publish_fx(sim)
	await UnitTestCore.wait_frames(2)
	await pass_ms(1000)
	await pass_ms(1000)
	await pass_ms(1000)
	await pass_ms(1000)
	assert_gt(_idle, 0, "the effects ended")
	var number: Label = panel.enemy_hero.number_label
	assert_true(not number.visible or number.modulate.a <= 0.0, "the damage number is gone after the hit")





func test_a_restart_draws_an_empty_board_until_the_new_battle_starts() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
	put_minion(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	assert_gt(visible_children(panel.hand_root), 0, "the hand of the battle shows")
	publish_state(null, BattleScene.Stage.STARTING)
	await UnitTestCore.wait_frames(1)
	assert_eq(visible_children(panel.hand_root), 0, "no hand card while the next battle starts")
	assert_eq(visible_children(panel.own_row), 0, "no own minion")
	assert_eq(visible_children(panel.enemy_row), 0, "no enemy minion")
	assert_eq(visible_children(panel.enemy_backs), 0, "no enemy card back")
	assert_false(panel.turn_label.visible, "no turn number")
	assert_false(panel.enemy_hand_label.visible, "no enemy hand count")


func test_a_full_hand_shows_every_card_whole() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var hand: PackedInt32Array = sim.sides[BattleSim.PLAYER].hand
	while hand.size() < GameSetting.hand_size():
		hand.push_back(id("[card_iron_wolf]"))
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var slots: Array[Control] = []
	for child: Node in panel.hand_root.get_children():
		if child is Control and (child as Control).visible:
			slots.append(child as Control)
	assert_eq(slots.size(), GameSetting.hand_size(), "every hand card shows")
	for i: int in slots.size() - 1:
		assert_true(slots[i].position.x + slots[i].size.x <= slots[i + 1].position.x,
			"hand card %d ends before the next one starts" % (i + 1))
	assert_true(slots[slots.size() - 1].position.x + slots[slots.size() - 1].size.x <= BattleConstants.HAND_RIGHT,
		"the last card ends before the mana box")


func test_a_buff_shows_what_it_added() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var wolf: BattleMinion = put_minion(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	wolf.health -= 1
	sim.sides[BattleSim.PLAYER].hand.push_back(id("[card_blessing]"))
	sim.sides[BattleSim.PLAYER].mana = GameSetting.max_mana()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var blessing: GameData.CardRow = GameData.CardTable.get_row(id("[card_blessing]"))
	assert_true(sim.play_card(BattleSim.PLAYER, sim.sides[BattleSim.PLAYER].hand.size() - 1, BattleSim.PLAYER, wolf.uid),
		"bless the wolf")
	publish_fx(sim)
	await UnitTestCore.wait_frames(2)
	await pass_ms(1000)
	await pass_ms(1000)
	await pass_ms(300)
	var slot: BattleMinionSlot = panel.own_row.get_child(0) as BattleMinionSlot
	var args: FormatArgs = FormatArgs.new()
	args.set_int("attack", blessing.amount)
	args.set_int("health", blessing.amount2)
	assert_eq(slot.number_label.text, LocalizationCore.format(ReservedString.battle_buff_amount(), args), "+attack/+health")
	assert_eq(slot.attack_label.text, str(wolf.attack))
	assert_eq(slot.health_label.text, str(wolf.health))



func test_a_burned_card_and_fatigue_toast_with_their_translation_keys() -> void:
	await prepare_ui()
	assert_true(await MessageCore.prepare(), "MessageCore.prepare")
	await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	var burned: BattleEvent = BattleEvent.new()
	burned.kind = BattleEvent.Kind.BURN
	burned.card_id = id("[card_herb_healer]")
	var tired: BattleEvent = BattleEvent.new()
	tired.kind = BattleEvent.Kind.FATIGUE
	tired.amount = 1
	for e: BattleEvent in [burned, tired]:
		var fx: BattleFxEvent = EventCore.acquire(BattleFxEvent) as BattleFxEvent
		fx.fx = e
		EventCore.publish(fx)
	await UnitTestCore.wait_frames(2)
	await pass_ms(500)
	assert_eq(UnitTestCore.check_logs("error", "LocalizationCore"), 0, "no missing translation key")

func visible_children(node: Node) -> int:
	var count: int = 0
	for child: Node in node.get_children():
		if child is CanvasItem and (child as CanvasItem).visible:
			count += 1
	return count


## Puts an awake minion of the card on the board of `side` and returns it.
func put_minion(sim: BattleSim, side: int, id_name: String) -> BattleMinion:
	var row: GameData.CardRow = GameData.CardTable.get_row(id(id_name))
	var m: BattleMinion = BattleMinion.new()
	m.uid = sim.sides[0].board.size() + sim.sides[1].board.size() + 1000
	m.card_id = row.id
	m.attack = row.attack
	m.health = row.health
	m.max_health = row.health
	m.sleeping = false
	m.attacks_left = 1
	sim.sides[side].board.append(m)
	return m

func test_every_opacity_change_of_a_battle_tween_sets_its_value_in_x() -> void:
	await prepare_ui()
	for key: String in BattleScene.tween_keys():
		var definition: TweenDefinition = await ResourceCore.load(key, TweenCore.get_preset_kind(), ResourceCore.get_global_scope()) as TweenDefinition
		assert_not_null(definition, key)
		if definition == null:
			continue
		for step: TweenStep in definition.steps:
			for change: TweenChange in step.changes:
				if change.property != TweenCore.TweenProperty.OPACITY:
					continue
				assert_eq(Vector3(change.target_value.y, change.target_value.z, change.target_value.w), Vector3.ZERO,
					"%s: an opacity target is x only" % key)
				if change.use_start_value:
					assert_eq(Vector3(change.start_value.y, change.start_value.z, change.start_value.w), Vector3.ZERO,
						"%s: an opacity start is x only" % key)


func test_a_heal_at_full_health_says_the_health_is_full() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var heal: BattleEvent = BattleEvent.new()
	heal.kind = BattleEvent.Kind.HEAL
	heal.side = BattleSim.PLAYER
	heal.amount = 0
	heal.value = GameSetting.hero_health()
	var fx: BattleFxEvent = EventCore.acquire(BattleFxEvent) as BattleFxEvent
	fx.fx = heal
	EventCore.publish(fx)
	await UnitTestCore.wait_frames(2)
	await pass_ms(100)
	assert_true(panel.own_hero.number_label.visible, "a number shows over the hero")
	assert_eq(panel.own_hero.number_label.text, LocalizationCore.get_text(ReservedString.battle_heal_full()),
		"it says the health is full")


func test_the_turn_banner_leaves_every_minion_readable() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	for i: int in GameSetting.board_size():
		put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
		put_minion(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var banner: Rect2 = panel.banner.get_global_rect()
	for row: Control in [panel.own_row, panel.enemy_row]:
		for child: Node in row.get_children():
			var slot: BattleMinionSlot = child as BattleMinionSlot
			if slot == null or not slot.visible:
				continue
			assert_false(banner.intersects(slot.get_global_rect()), "the banner is clear of %s" % slot.get_path())


func test_a_played_minion_card_flies_from_the_hand_to_the_board() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.hand.push_back(id("[card_iron_wolf]"))
	own.mana = GameSetting.max_mana()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	assert_not_null(await ResourceCore.load(ResourceKey.TWEEN__BATTLE__CARD_FLY, TweenCore.get_preset_kind(), panel.scope),
		"the fly preset")
	var hand_y: float = (panel.hand_root.get_child(0) as Control).position.y
	var row_y: float = (panel.own_row.get_child(0) as Control).position.y
	assert_true(sim.play_card(BattleSim.PLAYER, own.hand.size() - 1, BattleSim.NO_SIDE, BattleSim.HERO), "play the wolf")
	publish_fx(sim)
	await UnitTestCore.wait_frames(2)
	await pass_ms(230)
	assert_true(panel.reveal.visible, "the card is in flight")
	assert_true(panel.reveal.position.y < hand_y and panel.reveal.position.y > row_y - panel.reveal.size.y,
		"it is on its way from the hand to the row")


func test_the_cpu_turn_is_summed_up_when_the_player_turn_starts() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	sim.end_turn()
	var cpu: BattleSide = sim.sides[BattleSim.CPU]
	cpu.hand.push_back(id("[card_mana_bolt]"))
	cpu.mana = GameSetting.max_mana()
	assert_true(sim.play_card(BattleSim.CPU, cpu.hand.size() - 1, BattleSim.PLAYER, BattleSim.HERO), "the CPU bolts the hero")
	sim.end_turn()
	publish_state(sim, BattleScene.Stage.CPU_TURN)
	publish_fx(sim)
	for i: int in 12:
		await pass_ms(500)
	assert_true(panel.summary_root.visible, "the summary of the CPU turn shows")
	var texts: PackedStringArray = PackedStringArray()
	for child: Node in panel.summary_lines.get_children():
		if child is Label and (child as Label).visible:
			texts.push_back((child as Label).text)
	var bolt: String = LocalizationCore.get_text(GameData.CardTable.get_row(id("[card_mana_bolt]")).name)
	assert_true(" ".join(texts).contains(bolt), "it names the card the CPU played")
	var damage: int = GameData.CardTable.get_row(id("[card_mana_bolt]")).amount
	assert_true(" ".join(texts).contains(str(damage)), "it says how much the hero lost")


func test_a_loss_shows_the_defeat_banner_with_the_player_hero() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	sim.concede(BattleSim.PLAYER)
	publish_fx(sim)
	for i: int in 4:
		await pass_ms(500)
	assert_true(panel.end_banner.visible, "the end banner shows")
	assert_eq(panel.end_banner_label.text, LocalizationCore.get_text(ReservedString.battle_end_defeat()))
	assert_eq(panel.end_banner_portrait.texture, panel.own_hero.portrait.texture, "with the player hero")


func test_a_hand_card_name_stays_above_its_rule_text() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(2)
	for child: Node in panel.hand_root.get_children():
		var slot: BattleHandSlot = child as BattleHandSlot
		if slot == null or not slot.visible:
			continue
		var name_rect: Rect2 = slot.card.name_label.get_global_rect()
		var text_rect: Rect2 = slot.card.text_label.get_global_rect()
		assert_true(name_rect.end.y <= text_rect.position.y,
			"%s: the name (%.1f..%.1f) ends above the rule text (%.1f)" % [slot.name, name_rect.position.y, name_rect.end.y,
				text_rect.position.y])


## Removes `m` from the battle and plays its death on the board.
func kill(sim: BattleSim, side: int, m: BattleMinion) -> void:
	sim.sides[side].board.erase(m)
	var death: BattleEvent = BattleEvent.new()
	death.kind = BattleEvent.Kind.DEATH
	death.side = side
	death.uid = m.uid
	var fx: BattleFxEvent = EventCore.acquire(BattleFxEvent) as BattleFxEvent
	fx.fx = death
	EventCore.publish(fx)


func test_a_minion_keeps_its_anchor_in_the_turn_a_minion_left_of_it_dies() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var first: BattleMinion = put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
	var second: BattleMinion = put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	assert_eq((panel.enemy_row.get_child(1) as BattleMinionSlot).uid, second.uid, "the second minion is at the second place")
	kill(sim, BattleSim.CPU, first)
	await UnitTestCore.wait_frames(2)
	for i: int in 4:
		await pass_ms(500)
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var slot: BattleMinionSlot = panel.enemy_row.get_child(1) as BattleMinionSlot
	assert_true(slot.visible and slot.uid == second.uid, "the second minion keeps its place after the first died")
	assert_true(UICore.get_anchor_rect("enemy_minion_2").visible, "enemy_minion_2 still points at it")
	assert_false(UICore.get_anchor_rect("enemy_minion_1").visible, "enemy_minion_1 is gone")
	assert_eq(slot.position.x, BattleConstants.ROW_CENTER_X - slot.size.x * 0.5, "it moved to the middle of the row")
	EventCore.subscribe(BattleInputEvent, _on_input)
	assert_true(UnitTestCore.tap_anchor("enemy_minion_2"), "tap enemy_minion_2")
	await UnitTestCore.wait_frames(2)
	assert_eq(_pressed_uids, PackedInt32Array([second.uid]), "the press names that minion")


func test_the_places_close_up_left_to_right_when_the_player_turn_starts() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var first: BattleMinion = put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
	var second: BattleMinion = put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	kill(sim, BattleSim.CPU, first)
	var start: BattleEvent = BattleEvent.new()
	start.kind = BattleEvent.Kind.TURN_START
	start.side = BattleSim.PLAYER
	start.value = 3
	start.value2 = 2
	var fx: BattleFxEvent = EventCore.acquire(BattleFxEvent) as BattleFxEvent
	fx.fx = start
	EventCore.publish(fx)
	for i: int in 6:
		await pass_ms(500)
	assert_eq((panel.enemy_row.get_child(0) as BattleMinionSlot).uid, second.uid, "the minion left is first again")
	assert_true(UICore.get_anchor_rect("enemy_minion_1").visible, "enemy_minion_1 points at it")


func test_a_refused_press_says_why_over_the_board() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	await load_tweens(panel, PackedStringArray([ResourceKey.TWEEN__BATTLE__REFUSAL_POP]))
	var refused: BattleRefusedEvent = EventCore.acquire(BattleRefusedEvent) as BattleRefusedEvent
	refused.text_key = ReservedString.battle_not_enough_mana()
	refused.kind = BattleInputEvent.Kind.HAND
	refused.index = 0
	refused.mana = true
	EventCore.publish(refused)
	await UnitTestCore.wait_frames(2)
	assert_true(panel.refusal.visible, "the reason shows on the board")
	assert_eq(panel.refusal_label.text, LocalizationCore.get_text(ReservedString.battle_not_enough_mana()))
	var card: Rect2 = (panel.hand_root.get_child(0) as Control).get_global_rect()
	assert_true(panel.refusal.get_global_rect().end.y <= card.position.y, "it is over the pressed card")
	for i: int in 6:
		await pass_ms(500)
	assert_false(panel.refusal.visible, "it goes away")


func test_a_press_while_the_end_banner_shows_answers_at_once() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	await load_tweens(panel, PackedStringArray([ResourceKey.TWEEN__BATTLE__PRESS_POP]))
	sim.concede(BattleSim.PLAYER)
	publish_state(sim, BattleScene.Stage.ENDING)
	publish_fx(sim)
	for i: int in 4:
		await pass_ms(500)
	assert_true(panel.end_banner.visible, "the end banner shows")
	EventCore.subscribe(TweenStartedEvent, _on_tween_started)
	assert_true(UnitTestCore.tap_anchor("board_backdrop"), "tap the board")
	await UnitTestCore.wait_frames(1)
	assert_gt(_tweens_started, 0, "a tween answers the press")


func test_a_played_minion_card_lifts_with_a_green_glow_before_it_flies() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.hand.push_back(id("[card_iron_wolf]"))
	own.mana = GameSetting.max_mana()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	await load_tweens(panel, PackedStringArray([ResourceKey.TWEEN__BATTLE__CARD_LIFT]))
	assert_true(sim.play_card(BattleSim.PLAYER, own.hand.size() - 1, BattleSim.NO_SIDE, BattleSim.HERO), "play the wolf")
	publish_fx(sim)
	await UnitTestCore.wait_frames(2)
	await pass_ms(100)
	assert_true(panel.reveal.visible, "the played card shows")
	assert_gt(panel.reveal.scale.x, 1.05, "it grows as it is lifted")
	assert_true(panel.reveal.glow.visible, "with its glow")
	assert_eq(panel.reveal.glow.self_modulate, CommonConstants.CARD_PLAYABLE_COLOR, "green")
	for i: int in 4:
		await pass_ms(500)


func test_a_landing_minion_raises_a_dust_ring() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.hand.push_back(id("[card_iron_wolf]"))
	own.mana = GameSetting.max_mana()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	await load_tweens(panel, PackedStringArray([ResourceKey.TWEEN__BATTLE__DUST_RING]))
	assert_true(sim.play_card(BattleSim.PLAYER, own.hand.size() - 1, BattleSim.NO_SIDE, BattleSim.HERO), "play the wolf")
	publish_fx(sim)
	var seen: bool = false
	for i: int in 30:
		await pass_ms(50)
		if panel.dust_ring.visible and panel.dust_ring.modulate.a > 0.0:
			seen = true
			break
	assert_true(seen, "a dust ring shows when the minion lands")
	var slot: BattleMinionSlot = panel.own_row.get_child(0) as BattleMinionSlot
	assert_lt(absf(panel.dust_ring.get_global_rect().get_center().x - slot.get_global_rect().get_center().x), 2.0,
		"under the minion")
	for i: int in 4:
		await pass_ms(500)


func test_the_end_turn_button_glows_green_when_nothing_else_can_be_done() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	sim.sides[BattleSim.PLAYER].mana = 0
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	assert_true(panel.end_turn_glow.visible, "the end turn button glows")
	assert_eq(panel.end_turn_glow.self_modulate, BattleConstants.READY_COLOR, "green")


func test_the_end_turn_button_keeps_its_text_when_the_battle_ends() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	sim.concede(BattleSim.PLAYER)
	publish_state(sim, BattleScene.Stage.ENDING)
	publish_fx(sim)
	for i: int in 4:
		await pass_ms(500)
	assert_eq(panel.end_turn_button.text, LocalizationCore.get_text(ReservedString.battle_end_turn()),
		"the button does not say it is the enemy turn")
	assert_true(panel.end_turn_button.disabled, "and it cannot be pressed")


func test_a_heal_cut_by_the_max_health_says_what_it_healed_and_that_the_health_is_full() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.hero_health = own.hero_max_health - 2
	own.hand.push_back(id("[card_herb_healer]"))
	own.mana = GameSetting.max_mana()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	assert_gt(GameData.CardTable.get_row(id("[card_herb_healer]")).amount, 2, "the healer heals more than the hero lost")
	assert_true(sim.play_card(BattleSim.PLAYER, own.hand.size() - 1, BattleSim.NO_SIDE, BattleSim.HERO), "play the healer")
	publish_fx(sim)
	var args: FormatArgs = FormatArgs.new()
	args.set_int("amount", 2)
	var expected: String = LocalizationCore.format(ReservedString.battle_heal_capped(), args)
	var seen: bool = false
	for i: int in 60:
		await pass_ms(50)
		if panel.own_hero.number_label.visible and panel.own_hero.number_label.text == expected:
			seen = true
			break
	assert_true(seen, "it says it healed 2 and the health is full")
	for i: int in 4:
		await pass_ms(500)


func test_the_cpu_turn_summary_says_what_the_cpu_minion_attacks_did() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	sim.end_turn()
	var turtle: BattleMinion = put_minion(sim, BattleSim.PLAYER, "[card_crystal_turtle]")
	var hound: BattleMinion = put_minion(sim, BattleSim.CPU, "[card_gale_hound]")
	assert_true(sim.attack(BattleSim.CPU, hound.uid, BattleSim.PLAYER, turtle.uid), "the hound hits the turtle")
	assert_null(sim.sides[BattleSim.CPU].minion(hound.uid), "the hound dies on the turtle")
	sim.end_turn()
	publish_state(sim, BattleScene.Stage.CPU_TURN)
	publish_fx(sim)
	for i: int in 12:
		await pass_ms(500)
	assert_true(panel.summary_root.visible, "the summary of the CPU turn shows")
	var texts: PackedStringArray = PackedStringArray()
	for child: Node in panel.summary_lines.get_children():
		if child is Label and (child as Label).visible:
			texts.push_back((child as Label).text)
	var damage: FormatArgs = FormatArgs.new()
	damage.set_int("amount", GameData.CardTable.get_row(id("[card_gale_hound]")).attack)
	assert_has(texts, LocalizationCore.format(ReservedString.battle_cpu_minion_damage(), damage), "it says what my minions lost")
	var lost: FormatArgs = FormatArgs.new()
	lost.set_int("count", 1)
	assert_has(texts, LocalizationCore.format(ReservedString.battle_cpu_enemy_minions_lost(), lost),
		"it says the CPU minion fell")


func test_a_summary_line_has_the_color_of_what_it_says() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	sim.end_turn()
	var cpu: BattleSide = sim.sides[BattleSim.CPU]
	cpu.hero_health = cpu.hero_max_health - 1
	cpu.hand.push_back(id("[card_herb_healer]"))
	cpu.mana = GameSetting.max_mana()
	assert_true(sim.play_card(BattleSim.CPU, cpu.hand.size() - 1, BattleSim.NO_SIDE, BattleSim.HERO), "the CPU plays the healer")
	sim.end_turn()
	publish_state(sim, BattleScene.Stage.CPU_TURN)
	publish_fx(sim)
	for i: int in 30:
		await pass_ms(500)
		if panel.summary_root.visible:
			break
	assert_true(panel.summary_root.visible, "the summary of the CPU turn shows")
	var heal: FormatArgs = FormatArgs.new()
	heal.set_int("amount", 1)
	var heal_text: String = LocalizationCore.format(ReservedString.battle_cpu_hero_heal(), heal)
	var found: bool = false
	var texts: PackedStringArray = PackedStringArray()
	for child: Node in panel.summary_lines.get_children():
		var line: Label = child as Label
		if line != null and line.visible:
			texts.push_back(line.text)
		if line != null and line.visible and line.text == heal_text:
			found = true
			assert_eq(line.get_theme_color("font_color"), BattleConstants.HEAL_COLOR, "the heal line is green")
	assert_true(found, "the heal line shows in %s" % " | ".join(texts))


func test_a_refused_press_on_a_hand_card_leaves_the_own_hero_readable() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	while own.hand.size() < GameSetting.hand_size():
		own.hand.push_back(id("[card_iron_wolf]"))
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	await load_tweens(panel, PackedStringArray([ResourceKey.TWEEN__BATTLE__REFUSAL_POP]))
	for index: int in own.hand.size():
		var refused: BattleRefusedEvent = EventCore.acquire(BattleRefusedEvent) as BattleRefusedEvent
		refused.text_key = ReservedString.battle_not_enough_mana()
		refused.kind = BattleInputEvent.Kind.HAND
		refused.index = index
		refused.mana = true
		EventCore.publish(refused)
		await pass_ms(20)
		assert_false(panel.refusal.get_global_rect().intersects(panel.own_hero.get_global_rect()),
			"the reason for hand card %d is clear of the own hero" % (index + 1))
	for i: int in 4:
		await pass_ms(500)


func test_each_row_stays_on_its_side_of_the_board_line_clear_of_the_heroes_and_the_hand() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	while own.hand.size() < GameSetting.hand_size():
		own.hand.push_back(id("[card_iron_wolf]"))
	for i: int in GameSetting.board_size():
		put_minion(sim, BattleSim.CPU, "[card_iron_wolf]")
		put_minion(sim, BattleSim.PLAYER, "[card_iron_wolf]")
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var others: Array[Control] = [panel.own_hero, panel.enemy_hero]
	for child: Node in panel.hand_root.get_children():
		if child is Control and (child as Control).visible:
			others.append(child as Control)
	for child: Node in panel.own_row.get_children():
		var slot: Control = child as Control
		if slot == null or not slot.visible:
			continue
		assert_gte(slot.position.y, BattleConstants.BOARD_LINE_BOTTOM, "%s is below the board line" % slot.name)
		for other: Control in others:
			assert_false(slot.get_global_rect().intersects(other.get_global_rect()), "%s is clear of %s" % [slot.get_path(), other.get_path()])
	for child: Node in panel.enemy_row.get_children():
		var slot: Control = child as Control
		if slot == null or not slot.visible:
			continue
		assert_lte(slot.position.y + slot.size.y, BattleConstants.BOARD_LINE_TOP, "%s is above the board line" % slot.name)
		for other: Control in others:
			assert_false(slot.get_global_rect().intersects(other.get_global_rect()), "%s is clear of %s" % [slot.get_path(), other.get_path()])
	for child: Node in panel.hand_root.get_children():
		if child is Control and (child as Control).visible:
			assert_false(panel.own_hero.get_global_rect().intersects((child as Control).get_global_rect()),
				"the own hero is clear of %s" % child.name)


func test_a_hand_press_carries_the_card_it_showed() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	EventCore.subscribe(BattleInputEvent, _on_input_card)
	assert_true(UnitTestCore.tap_anchor("hand_card_2"), "tap the second hand card")
	await UnitTestCore.wait_frames(1)
	assert_eq(_pressed_cards, PackedInt32Array([sim.sides[BattleSim.PLAYER].hand[1]]), "the press names the card")


func _on_input_card(event: BattleInputEvent) -> void:
	_pressed_cards.push_back(event.card_id)


func test_a_hand_card_the_player_cannot_pay_for_has_no_glow_and_darker_art() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	own.hand = PackedInt32Array([id("[card_crystal_turtle]"), id("[card_herb_healer]")])
	own.mana = 2
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var cards: Array[CommonCardView] = []
	for child: Node in panel.hand_root.get_children():
		if child is BattleHandSlot and (child as Control).visible:
			cards.append((child as BattleHandSlot).card)
	assert_eq(cards.size(), 2, "both hand cards show")
	assert_true(cards[0].glow.visible, "the 2 mana card glows")
	assert_eq(cards[0].art.self_modulate, Color.WHITE, "the 2 mana card art is bright")
	assert_false(cards[1].glow.visible, "the 3 mana card does not glow")
	assert_eq(cards[1].art.self_modulate, CommonConstants.CARD_WAITING_ART_COLOR, "the 3 mana card art is darker")
	assert_true(cards[0].glow.size.x - cards[0].size.x >= 30.0, "the glow stands out of the card on both sides")
	publish_state(sim, BattleScene.Stage.CPU_TURN)
	await UnitTestCore.wait_frames(1)
	assert_eq(cards[1].art.self_modulate, Color.WHITE, "no card is darker in the CPU turn")


func test_every_enemy_card_back_shows_whole_on_screen() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	var sim: BattleSim = new_sim()
	var enemy: BattleSide = sim.sides[BattleSim.CPU]
	while enemy.hand.size() < GameSetting.hand_size():
		enemy.hand.push_back(id("[card_iron_wolf]"))
	publish_state(sim, BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	var shown: int = 0
	for child: Node in panel.enemy_backs.get_children():
		var back: Control = child as Control
		if back == null or not back.visible:
			continue
		shown += 1
		var transform: Transform2D = back.get_global_transform()
		for corner: Vector2 in [Vector2.ZERO, Vector2(back.size.x, 0.0), Vector2(0.0, back.size.y), back.size]:
			var point: Vector2 = transform * corner
			assert_true(point.y >= 0.0, "%s corner %s is under the screen top" % [back.name, corner])
	assert_eq(shown, GameSetting.hand_size(), "every enemy card back shows")


func test_each_hero_name_sits_on_a_framed_plate() -> void:
	await prepare_ui()
	var panel: BattleBoardPanel = await open_board()
	publish_state(new_sim(), BattleScene.Stage.PLAYER_TURN)
	await UnitTestCore.wait_frames(1)
	for hero: BattleHeroSlot in [panel.own_hero, panel.enemy_hero]:
		var plate: Control = null
		for child: Node in hero.body.get_children():
			if child.name == "Plate":
				plate = child as Control
		assert_not_null(plate, "%s has a name plate" % hero.name)
		var transform: Transform2D = plate.get_global_transform()
		var plate_rect: Rect2 = Rect2(transform * Vector2.ZERO, transform.get_scale() * plate.size)
		assert_true(plate_rect.encloses(hero.name_label.get_global_rect()), "%s name plate holds the whole name" % hero.name)
		assert_true(plate.get_theme_stylebox("panel") is StyleBoxTexture, "%s name plate is drawn with art" % hero.name)
