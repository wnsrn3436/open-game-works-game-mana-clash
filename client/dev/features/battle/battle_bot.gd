class_name BattleBot
extends RefCounted
## The bot player and the screen commands of the battle feature. In the lobby it starts the picked battle; in a
## battle it plays the move `BattleAi` picks for the player by tapping the hand card or minion and then its target
## (a minion by the anchor number of its place on the board panel); on the full screen reward it taps until the result
## shows; on the result panel it goes to the next opponent when one opened, else it retries; on the pause popup it
## resumes.
## Each tap is picked from the screen as it is, so a dropped tap is tapped again, and the taps keep the click interval
## of `UIButton` (`UICore.buttonClickIntervalMs`) apart, since every button drops a click inside it.

## A lost battle waits for the next battle start to count as a restart.
var _restart_pending: bool = false
## Real time of the last tap the bot returned; 0 before the first.
var _last_tap_ms: int = 0


## `battle.bot_next_input`: the next input command, or `null` while a transition or an effect runs or the click
## interval since the last tap has not passed.
func next_input(_args: PackedStringArray) -> RunCommandResult:
	if SceneCore.is_transitioning() or UICore.is_panel_transitioning() or UICore.is_system_popup_visible():
		return _result(true, "null")
	var gap: int = CoreSettings.get_int("UICore.buttonClickIntervalMs") * BattleConstants.DEV_TAP_INTERVALS
	if _last_tap_ms != 0 and TimeCore.get_real_time() - _last_tap_ms <= gap:
		return _result(true, "null")
	var scene: String = SceneCore.current_scene_key()
	if scene == ResourceKey.SCENE__LOBBY__LOBBY:
		if UICore.get_current_panel_key() == ResourceKey.PREFAB__LOBBY__LOBBY_PANEL and UICore.get_open_popups().is_empty():
			return _tap("lobby_play")
		return _result(true, "null")
	if scene != ResourceKey.SCENE__BATTLE__BATTLE:
		return _result(true, "null")
	if UICore.get_open_popups().has(ResourceKey.PREFAB__BATTLE__PAUSE_POPUP):
		return _tap("pause_resume")
	if UICore.get_current_panel_key() == ResourceKey.PREFAB__BATTLE__RESULT_PANEL:
		if UICore.get_anchor_rect("reward_continue").visible:
			return _tap("reward_continue")
		if UICore.get_anchor_rect("result_next").visible:
			return _tap("result_next")
		return _tap("result_retry")
	var battle: BattleScene = find_battle_scene()
	if battle == null or not battle.is_waiting_for_player() or not UICore.get_open_popups().is_empty():
		return _result(true, "null")
	var board: BattleBoardPanel = BattleBot._find_board((Engine.get_main_loop() as SceneTree).root)
	return _tap(BattleBot.board_tap(battle.get_sim(), battle.get_pick(), battle.get_pick_hand(), battle.get_pick_uid(),
		board))


## The anchor the bot taps on the board for the move `BattleAi` picks for the player. With a pick on screen it is the
## target of that move when the pick starts it, else the backdrop that clears the pick; with no pick it is the hand
## card, the attacker or the end turn button. `board` gives the anchor number of a minion; without it the number is
## the board order from 1.
static func board_tap(sim: BattleSim, pick: BattleScene.Pick, pick_hand: int, pick_uid: int,
		board: BattleBoardPanel = null) -> String:
	var action: BattleAction = BattleAi.next_action(sim, BattleSim.PLAYER)
	var hand: PackedInt32Array = sim.sides[BattleSim.PLAYER].hand
	if pick == BattleScene.Pick.HAND:
		if action.kind == BattleAction.Kind.PLAY and action.hand_index == pick_hand and BattleSim.needs_target(hand[pick_hand]):
			return BattleBot._target_anchor(sim, action.target_side, action.target_uid, board)
		return "board_backdrop"
	if pick == BattleScene.Pick.ATTACKER:
		if action.kind == BattleAction.Kind.ATTACK and action.attacker_uid == pick_uid:
			return BattleBot._target_anchor(sim, action.target_side, action.target_uid, board)
		return "board_backdrop"
	match action.kind:
		BattleAction.Kind.PLAY:
			return "hand_card_%d" % (action.hand_index + 1)
		BattleAction.Kind.ATTACK:
			return "own_minion_%d" % BattleBot._number(sim, BattleSim.PLAYER, action.attacker_uid, board)
	return "end_turn"


func on_finished(event: BattleFinishedEvent) -> void:
	if event.won and event.saved:
		QACore.mark(QACore.MarkKind.GOAL)
	elif not event.won:
		_restart_pending = true
		QACore.mark(QACore.MarkKind.FAIL)


func on_started(_event: BattleStartedEvent) -> void:
	if _restart_pending:
		_restart_pending = false
		QACore.mark(QACore.MarkKind.RESTART)


func on_reward(event: BattleRewardShownEvent) -> void:
	QACore.mark(QACore.MarkKind.REWARD, event.card_id)


func on_responded(_event: BattleRespondedEvent) -> void:
	QACore.mark(QACore.MarkKind.RESPONSE)


## Hero health, mana, board and hand stay inside their limits in a battle on screen.
func limits_hold() -> bool:
	var battle: BattleScene = find_battle_scene()
	if battle == null or battle.get_sim() == null:
		return true
	for s: BattleSide in battle.get_sim().sides:
		if s.hero_health < 0 or s.hero_health > s.hero_max_health:
			return false
		if s.mana < 0 or s.mana > s.max_mana or s.max_mana > GameSetting.max_mana():
			return false
		if s.board.size() > GameSetting.board_size() or s.hand.size() > GameSetting.hand_size():
			return false
	return true


## Every minion on the board has health above 0 and attack at least 0.
func minions_alive() -> bool:
	var battle: BattleScene = find_battle_scene()
	if battle == null or battle.get_sim() == null:
		return true
	for s: BattleSide in battle.get_sim().sides:
		for m: BattleMinion in s.board:
			if m.health <= 0 or m.attack < 0:
				return false
	return true


## Opens the battle scene against the next opponent and waits until the battle runs.
func open_battle(_args: PackedStringArray) -> RunCommandResult:
	UICore.close_all_popups()
	var battle: BattleScene = find_battle_scene()
	var keep: bool = battle != null and UICore.get_current_panel_key() == ResourceKey.PREFAB__BATTLE__BOARD_PANEL \
		and battle.get_sim() != null and not battle.get_sim().over and not battle.is_paused()
	if not keep:
		if not await SceneCore.change_scene(ResourceKey.SCENE__BATTLE__BATTLE, null):
			return _result(false, "\"the battle scene did not open\"")
	for i: int in BattleConstants.DEV_WAIT_FRAMES:
		battle = find_battle_scene()
		if battle != null and battle.is_waiting_for_player():
			return _result(true, "")
		await (Engine.get_main_loop() as SceneTree).process_frame
	return _result(false, "\"the battle did not start\"")


## Opens the result panel of a won first battle with its reward over the battle scene, past its full screen reward
## unless `keep_stage`.
func open_result(args: PackedStringArray, keep_stage: bool = false) -> RunCommandResult:
	var opened: RunCommandResult = await open_battle(args)
	if not opened.ok:
		return opened
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var param: BattleResultParam = BattleResultParam.new()
	param.won = true
	param.saved = true
	param.opponent_id = rows[0].id
	param.turns = BattleConstants.PREVIEW_TURNS
	param.wins = BattleConstants.PREVIEW_WINS
	param.losses = BattleConstants.PREVIEW_LOSSES
	param.win_streak = BattleConstants.PREVIEW_STREAK
	param.reward_cards = rows[0].reward_cards
	param.swap_out_cards = rows[0].reward_removes
	param.next_opponent = rows[1].id if rows.size() > 1 else 0
	param.on_retry = func() -> void: pass
	param.on_next = func() -> void: pass
	param.on_lobby = func() -> void: SceneCore.change_scene(ResourceKey.SCENE__LOBBY__LOBBY, null)
	if not await UICore.open_panel(ResourceKey.PREFAB__BATTLE__RESULT_PANEL, param, false):
		return _result(false, "\"the result panel did not open\"")
	if not keep_stage:
		var panel: BattleResultPanel = BattleBot._find_result((Engine.get_main_loop() as SceneTree).root)
		if panel != null:
			panel.close_stage()
	return _result(true, "")


## `battle.open_reward`: the full screen reward of a won first battle, before the result.
func open_reward(args: PackedStringArray) -> RunCommandResult:
	return await open_result(args, true)


## `battle.open_defeat`: the result panel of a lost battle against the last opponent, with its tip and the cards a
## win over it adds.
func open_defeat(args: PackedStringArray) -> RunCommandResult:
	var opened: RunCommandResult = await open_battle(args)
	if not opened.ok:
		return opened
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	var row: GameData.OpponentRow = rows[rows.size() - 1]
	var param: BattleResultParam = BattleResultParam.new()
	param.won = false
	param.saved = true
	param.opponent_id = row.id
	param.turns = BattleConstants.PREVIEW_TURNS
	param.wins = BattleConstants.PREVIEW_WINS
	param.losses = BattleConstants.PREVIEW_LOSSES
	param.stake_cards = row.reward_cards
	param.tip = row.tip
	param.on_retry = func() -> void: pass
	param.on_next = func() -> void: pass
	param.on_lobby = func() -> void: SceneCore.change_scene(ResourceKey.SCENE__LOBBY__LOBBY, null)
	return _result(await UICore.open_panel(ResourceKey.PREFAB__BATTLE__RESULT_PANEL, param, false), "")


## Opens the pause popup over a running battle.
func open_pause(args: PackedStringArray) -> RunCommandResult:
	var opened: RunCommandResult = await open_battle(args)
	if not opened.ok:
		return opened
	EventCore.publish(EventCore.acquire(BattlePauseRequestedEvent))
	for i: int in BattleConstants.DEV_WAIT_FRAMES:
		if UICore.get_open_popups().has(ResourceKey.PREFAB__BATTLE__PAUSE_POPUP):
			return _result(true, "")
		await (Engine.get_main_loop() as SceneTree).process_frame
	return _result(false, "\"the pause popup did not open\"")


## `battle.simulate_opponent`: one battle against the opponent row (ID name) with the seed, both sides moved by
## `BattleAi`, without a screen or a server request. `damage_peak` is how far below its max the player hero fell.
func simulate_opponent(args: PackedStringArray) -> RunCommandResult:
	if args.size() != 2 or not args[1].is_valid_int():
		return _result(false, "\"arguments: <opponent ID name> <seed>\"")
	var id: int = GameDataDev.find_id_value(args[0])
	if not GameData.OpponentTable.has_row(id):
		return _result(false, "\"no opponent row\"")
	var sim: BattleSim = BattleSimRunner.new_battle(id, int(args[1]))
	var own: BattleSide = sim.sides[BattleSim.PLAYER]
	var lowest: int = own.hero_health
	for i: int in BattleConstants.DEV_SIM_ACTION_LIMIT:
		if sim.over:
			break
		BattleSimRunner.play_out(sim, 1)
		lowest = mini(lowest, own.hero_health)
	return _result(true, JSON.stringify({"solved": sim.over and sim.winner == BattleSim.PLAYER,
		"metrics": {"turns": sim.turn, "damage_peak": own.hero_max_health - maxi(lowest, 0)}}))


static func _target_anchor(sim: BattleSim, side: int, uid: int, board: BattleBoardPanel) -> String:
	if uid == BattleSim.HERO:
		return "own_hero" if side == BattleSim.PLAYER else "enemy_hero"
	var number: int = BattleBot._number(sim, side, uid, board)
	return ("own_minion_%d" if side == BattleSim.PLAYER else "enemy_minion_%d") % number


## The anchor number of the minion `uid` of `side`: from `board` when it shows the minion, else its board order.
static func _number(sim: BattleSim, side: int, uid: int, board: BattleBoardPanel) -> int:
	var number: int = board.anchor_number(side, uid) if board != null else 0
	return number if number > 0 else sim.sides[side].index_of(uid) + 1


static func _find_board(node: Node) -> BattleBoardPanel:
	if node is BattleBoardPanel:
		return node as BattleBoardPanel
	for child: Node in node.get_children():
		var found: BattleBoardPanel = BattleBot._find_board(child)
		if found != null:
			return found
	return null


static func _find_result(node: Node) -> BattleResultPanel:
	if node is BattleResultPanel:
		return node as BattleResultPanel
	for child: Node in node.get_children():
		var found: BattleResultPanel = BattleBot._find_result(child)
		if found != null:
			return found
	return null


## The battle scene on screen, or `null`.
func find_battle_scene() -> BattleScene:
	return _find((Engine.get_main_loop() as SceneTree).root)


func _find(node: Node) -> BattleScene:
	if node is BattleScene:
		return node as BattleScene
	for child: Node in node.get_children():
		var found: BattleScene = _find(child)
		if found != null:
			return found
	return null


func _tap(anchor: String) -> RunCommandResult:
	_last_tap_ms = TimeCore.get_real_time()
	return _result(true, JSON.stringify({"command": "tap_anchor", "args": [anchor]}))


func _result(ok: bool, result: String) -> RunCommandResult:
	var out: RunCommandResult = RunCommandResult.new()
	out.ok = ok
	out.result = result
	return out
