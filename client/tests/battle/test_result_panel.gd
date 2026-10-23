extends UnitTestCase
## The result panel: it shows the battle result, the record and the reward cards of a first win from its param, the
## next button only when an opponent opened, each button acts once, an uncounted battle says so, a first win names the
## cards that leave the deck, and a long card text fits above the card stats.

var _retries: int = 0
var _nexts: int = 0
var _lobbies: int = 0


func before_each() -> void:
	super()
	_retries = 0
	_nexts = 0
	_lobbies = 0


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
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")
	assert_true(await UICore.prepare(), "UICore.prepare")


func first_win() -> BattleResultParam:
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var param: BattleResultParam = BattleResultParam.new()
	param.won = true
	param.saved = true
	param.opponent_id = rows[0].id
	param.turns = 9
	param.wins = 1
	param.losses = 0
	param.win_streak = 1
	param.reward_cards = rows[0].reward_cards
	param.next_opponent = rows[1].id
	param.on_retry = func() -> void: _retries += 1
	param.on_next = func() -> void: _nexts += 1
	param.on_lobby = func() -> void: _lobbies += 1
	return param


func open_panel(param: BattleResultParam) -> BattleResultPanel:
	assert_true(await UICore.open_panel(ResourceKey.PREFAB__BATTLE__RESULT_PANEL, param, false), "open the result panel")
	await UnitTestCore.wait_frames(1)
	var panel: BattleResultPanel = find_panel(UICore.get_layer(UICore.UILayer.PANEL))
	assert_not_null(panel, "the result panel instance")
	return panel


func find_panel(node: Node) -> BattleResultPanel:
	if node is BattleResultPanel:
		return node as BattleResultPanel
	for child: Node in node.get_children():
		var found: BattleResultPanel = find_panel(child)
		if found != null:
			return found
	return null


## Taps the full screen reward away until the result shows: a tap ends the reveal, the next one closes it.
func dismiss_stage(panel: BattleResultPanel) -> void:
	if panel.stage.visible:
		UnitTestCore.tap_anchor("reward_continue")
		await pass_ms(400)
	if panel.stage.visible:
		UnitTestCore.tap_anchor("reward_continue")
		await pass_ms(400)


## Moves the test clock on and lets the frames play the effects of that time.
func pass_ms(ms: int) -> void:
	UnitTestCore.advance_clock(ms, false)
	await UnitTestCore.wait_frames(2)


func record_text(key: String, wins: int, losses: int) -> String:
	var args: FormatArgs = FormatArgs.new()
	args.set_int("wins", wins)
	args.set_int("losses", losses)
	return LocalizationCore.format(key, args)


func shown_cards(panel: BattleResultPanel) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for child: Node in panel.reward_row.get_children():
		var view: CommonCardView = child as CommonCardView
		if view != null and view.visible:
			out.push_back(view.card_id)
	return out


func test_a_first_win_shows_the_record_the_reward_cards_and_the_next_button() -> void:
	await prepare_ui()
	var param: BattleResultParam = first_win()
	var panel: BattleResultPanel = await open_panel(param)
	assert_eq(panel.title_label.text, LocalizationCore.get_text(ReservedString.result_win()))
	assert_eq(panel.record_label.text, record_text(ReservedString.result_record(), 1, 0))
	assert_true(panel.reward_root.visible, "the reward shows")
	assert_eq(shown_cards(panel), param.reward_cards, "the reward cards of the opponent, in order")
	assert_true(panel.next_button.visible, "the next opponent opened")


func test_a_loss_shows_no_reward_and_no_next_button_and_an_uncounted_battle_says_so() -> void:
	await prepare_ui()
	var param: BattleResultParam = first_win()
	param.won = false
	param.saved = false
	param.reward_cards = PackedInt32Array()
	param.next_opponent = 0
	param.wins = 0
	param.losses = 3
	var panel: BattleResultPanel = await open_panel(param)
	assert_eq(panel.title_label.text, LocalizationCore.get_text(ReservedString.result_lose()))
	assert_false(panel.reward_root.visible, "no reward")
	assert_false(panel.next_button.visible, "no next opponent")
	assert_false(panel.streak_label.visible, "no streak line")
	assert_eq(panel.record_label.text, record_text(ReservedString.result_record_unsaved(), 0, 3))


func test_a_loss_to_an_opponent_not_beaten_shows_its_tip_and_the_cards_a_win_adds() -> void:
	await prepare_ui()
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var param: BattleResultParam = first_win()
	param.won = false
	param.reward_cards = PackedInt32Array()
	param.next_opponent = 0
	param.stake_cards = rows[0].reward_cards
	param.tip = rows[0].tip
	var panel: BattleResultPanel = await open_panel(param)
	assert_true(panel.streak_label.visible, "the tip line shows")
	assert_eq(panel.streak_label.text, LocalizationCore.get_text(rows[0].tip))
	assert_true(panel.reward_root.visible, "the cards a win adds show")
	assert_eq(panel.reward_title_label.text, LocalizationCore.get_text(ReservedString.result_stake_title()))
	assert_eq(shown_cards(panel), rows[0].reward_cards, "the reward cards of the opponent, in order")
	assert_false(panel.next_button.visible, "no next opponent")


func test_retry_closes_the_panel_and_then_starts_the_next_battle_once() -> void:
	await prepare_ui()
	await dismiss_stage(await open_panel(first_win()))
	assert_true(UnitTestCore.tap_anchor("result_retry"), "tap retry")
	UnitTestCore.tap_anchor("result_retry")
	await UnitTestCore.wait_frames(30)
	assert_eq(_retries, 1)
	assert_eq(_nexts, 0)
	assert_eq(UICore.get_current_panel_key(), "")


func test_next_closes_the_panel_and_then_starts_the_next_opponent_once() -> void:
	await prepare_ui()
	await dismiss_stage(await open_panel(first_win()))
	assert_true(UnitTestCore.tap_anchor("result_next"), "tap next")
	UnitTestCore.tap_anchor("result_next")
	await UnitTestCore.wait_frames(30)
	assert_eq(_nexts, 1)
	assert_eq(_retries, 0)


func test_lobby_leaves_for_the_lobby_once() -> void:
	await prepare_ui()
	await dismiss_stage(await open_panel(first_win()))
	assert_true(UnitTestCore.tap_anchor("result_lobby"), "tap lobby")
	UnitTestCore.tap_anchor("result_lobby")
	await UnitTestCore.wait_frames(3)
	assert_eq(_lobbies, 1)


func test_a_first_win_names_the_cards_that_leave_the_deck() -> void:
	await prepare_ui()
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var param: BattleResultParam = first_win()
	param.swap_out_cards = rows[0].reward_removes
	var panel: BattleResultPanel = await open_panel(param)
	assert_true(panel.swap_label.visible, "the line of the cards that leave shows")
	for card_id: int in rows[0].reward_removes:
		var name: String = LocalizationCore.get_text(GameData.CardTable.get_row(card_id).name)
		assert_true(panel.swap_label.text.contains(name), "it names %s" % name)


func test_a_loss_says_nothing_leaves_the_deck() -> void:
	await prepare_ui()
	var param: BattleResultParam = first_win()
	param.won = false
	param.reward_cards = PackedInt32Array()
	param.next_opponent = 0
	var panel: BattleResultPanel = await open_panel(param)
	assert_false(panel.swap_label.visible, "no line of cards that leave")


func test_a_long_card_text_fits_above_the_card_stats() -> void:
	await prepare_ui()
	var panel: BattleResultPanel = await open_panel(first_win())
	var view: CommonCardView = panel.reward_row.get_child(0) as CommonCardView
	var label: Label = view.text_label
	label.text = "On Death: Deal 2 damage to the enemy Hero and draw a card, then give your other Minions +1 Attack"
	view.fit_text()
	assert_true(label.get_line_count() * label.get_line_height() <= int(label.size.y),
		"%d lines of %d px fit in %d px" % [label.get_line_count(), label.get_line_height(), int(label.size.y)])


func test_a_first_win_shows_the_new_cards_full_screen_before_the_result() -> void:
	await prepare_ui()
	var param: BattleResultParam = first_win()
	var panel: BattleResultPanel = await open_panel(param)
	assert_true(panel.stage.visible, "the reward fills the screen first")
	assert_false(panel.frame.visible, "the result waits under it")
	var stage_cards: PackedInt32Array = PackedInt32Array()
	for holder: Node in panel.stage_row.get_children():
		if not (holder as Control).visible:
			continue
		for child: Node in holder.get_children():
			var view: CommonCardView = child as CommonCardView
			if view != null:
				stage_cards.push_back(view.card_id)
	assert_eq(stage_cards, param.reward_cards, "it shows the reward cards in order")
	assert_true(panel.stage.get_global_rect().size.x >= panel.frame.get_global_rect().size.x, "wider than the result")
	await dismiss_stage(panel)
	assert_false(panel.stage.visible, "a tap closes it")
	assert_true(panel.frame.visible, "the result shows")
	assert_true(UICore.get_anchor_rect("result_next").visible, "its buttons can be pressed")


func test_a_loss_shows_no_full_screen_reward() -> void:
	await prepare_ui()
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var param: BattleResultParam = first_win()
	param.won = false
	param.reward_cards = PackedInt32Array()
	param.next_opponent = 0
	param.stake_cards = rows[0].reward_cards
	var panel: BattleResultPanel = await open_panel(param)
	assert_false(panel.stage.visible, "no full screen reward")
	assert_true(panel.frame.visible, "the result shows at once")


## Fails when two text labels under `root` that show overlap.
func assert_texts_apart(root: Node) -> void:
	var labels: Array[Label] = []
	collect_labels(root, labels)
	for i: int in labels.size():
		for j: int in range(i + 1, labels.size()):
			var a: Rect2 = labels[i].get_global_rect()
			var b: Rect2 = labels[j].get_global_rect()
			assert_false(a.intersects(b), "%s and %s overlap" % [labels[i].get_path(), labels[j].get_path()])


func collect_labels(node: Node, out: Array[Label]) -> void:
	var label: Label = node as Label
	if label != null and label.is_visible_in_tree() and not label.text.is_empty():
		out.append(label)
	for child: Node in node.get_children():
		collect_labels(child, out)


func test_the_reward_and_the_result_texts_do_not_overlap() -> void:
	await prepare_ui()
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var param: BattleResultParam = first_win()
	param.swap_out_cards = rows[0].reward_removes
	var panel: BattleResultPanel = await open_panel(param)
	for i: int in 8:
		await pass_ms(400)
	assert_texts_apart(panel.stage)
	await dismiss_stage(panel)
	await pass_ms(400)
	assert_texts_apart(panel.frame)


func test_the_reward_light_rings_are_ovals_around_the_cards() -> void:
	await prepare_ui()
	var panel: BattleResultPanel = await open_panel(first_win())
	var styles: Array[StyleBox] = [panel.stage_rays.get_theme_stylebox("panel")]
	for holder: Node in panel.stage_row.get_children():
		for child: Node in holder.get_children():
			if child is Panel and not (child is CommonCardView):
				styles.append((child as Panel).get_theme_stylebox("panel"))
	assert_eq(styles.size(), 4, "the ring behind the row and one burst per card")
	for style: StyleBox in styles:
		var texture_style: StyleBoxTexture = style as StyleBoxTexture
		assert_not_null(texture_style, "drawn with art")
		assert_eq(texture_style.texture_margin_left + texture_style.texture_margin_top, 0.0,
			"the whole oval glow stretches, no box frame")
	var rays: Rect2 = panel.stage_rays.get_global_rect()
	var row_center: Vector2 = Vector2.ZERO
	var holders: int = 0
	for holder: Node in panel.stage_row.get_children():
		var control: Control = holder as Control
		var transform: Transform2D = control.get_global_transform()
		row_center += transform * (control.size * 0.5)
		holders += 1
	row_center /= float(holders)
	assert_almost_eq(rays.get_center().x, row_center.x, 2.0, "the ring is centered on the card row")
	assert_almost_eq(rays.get_center().y, row_center.y, 2.0, "the ring is centered on the card row")
