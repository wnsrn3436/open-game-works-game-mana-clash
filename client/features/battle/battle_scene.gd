class_name BattleScene
extends SceneBase
## The battle against a CPU opponent. It starts a play session on the server for the opponent, runs `BattleSim` with
## the loadout, takes the player's presses from the board panel (the presses made while an effect plays wait for its
## end and then act one by one in the order they were made; a refused press asks the board to say why; a press while
## the battle ends skips the rest of the wait before the result),
## moves the CPU with `BattleAi` one action at a time,
## and when the battle ends sends the result with `FinishPlaySession` and opens the result panel. The board panel is
## the root panel; it draws `BattleStateChangedEvent` and plays each `BattleFxEvent` before it reports idle.

enum Stage { STARTING, PLAYER_TURN, CPU_TURN, ENDING, SAVING, RESULT, LEAVING }
enum Pick { NONE, HAND, ATTACKER }

@export var backdrop: TextureRect

var _stage: Stage = Stage.STARTING
var _sim: BattleSim = null
var _opponent_id: int = 0
var _play_session_id: String = ""
var _pick: Pick = Pick.NONE
var _pick_hand: int = -1
var _pick_uid: int = 0
## The board panel plays effects; the battle waits for its idle report.
var _fx_busy: bool = false
## The presses of the player's turn made while effects played, oldest first; each acts when the effects before it end.
var _held: Array[BattleInputEvent] = []
var _paused: bool = false
## The press being taken, for the board to say why it was refused.
var _press_kind: BattleInputEvent.Kind = BattleInputEvent.Kind.BACKDROP
var _press_index: int = -1
var _wait_ms: int = 0
## The steps of the first-battle hint the player has done in this battle.
var _played: bool = false
var _attacked: bool = false
var _ended: bool = false
var _was_cleared: bool = false
var _cpu_step: Callable = Callable()
var _send_finish: Callable = Callable()


func on_preload(preload_request: PreloadRequest, _prefill_items: Array[PrefillItem]) -> void:
	CommonCardView.preload_art(preload_request)
	preload_request.add_item(ResourceKey.IMAGE__HERO_PLAYER, ResourceCore.BaseKind.TEXTURE_2D)
	preload_request.add_item(ResourceKey.IMAGE__CARD_BACK, ResourceCore.BaseKind.TEXTURE_2D)
	preload_request.add_item(ResourceKey.BACKGROUND__BATTLE_BOARD, ResourceCore.BaseKind.TEXTURE_2D)
	preload_request.add_item(ResourceKey.BGM__BATTLE, ResourceCore.BaseKind.AUDIO_STREAM)
	for key: String in BattleScene.sound_keys():
		preload_request.add_item(key, ResourceCore.BaseKind.AUDIO_STREAM)
	var tween_kind: int = TweenCore.get_preset_kind()
	for key: String in BattleScene.tween_keys():
		preload_request.add_item(key, tween_kind)
	for key: String in BattleBoardPanel.burst_keys():
		preload_request.add_item(key, ResourceCore.BaseKind.PACKED_SCENE)


func on_prepare() -> bool:
	_cpu_step = _run_cpu_step
	_send_finish = _finish_battle
	var param: CommonBattleParam = scene_param as CommonBattleParam
	_opponent_id = param.opponent_id if param != null else CommonProgress.next_opponent()
	if not GameData.OpponentTable.has_row(_opponent_id):
		_opponent_id = CommonProgress.next_opponent()
	return true


func on_start() -> void:
	backdrop.texture = CommonCardView.texture(ResourceKey.BACKGROUND__BATTLE_BOARD, scope)
	SoundCore.play_bgm(ResourceKey.BGM__BATTLE, scope)
	EventCore.subscribe(BattleInputEvent, _on_input)
	EventCore.subscribe(BattleFxIdleEvent, _on_fx_idle)
	EventCore.subscribe(BattlePauseRequestedEvent, _on_pause_requested)
	EventCore.subscribe(BattleViewReadyEvent, _on_view_ready)
	_begin_battle(_opponent_id)


func on_exit() -> void:
	EventCore.unsubscribe_all(self)
	_set_paused(false)
	GameUpdateCore.set_in_play(false)


## The battle on screen; `null` before the server answered.
func get_sim() -> BattleSim:
	return _sim


func get_stage() -> Stage:
	return _stage


func get_pick() -> Pick:
	return _pick


func get_pick_hand() -> int:
	return _pick_hand


func get_pick_uid() -> int:
	return _pick_uid


func get_opponent_id() -> int:
	return _opponent_id


## Whether the player may press the board now: the player's turn, no effect playing, not paused.
func is_waiting_for_player() -> bool:
	return _stage == Stage.PLAYER_TURN and not _fx_busy and not _paused and _sim != null and not _sim.over


func is_paused() -> bool:
	return _paused


## Starts a new battle against `opponent_id`: a play session on the server first; the battle runs once it answers.
func _begin_battle(opponent_id: int) -> void:
	_opponent_id = opponent_id
	_stage = Stage.STARTING
	_sim = null
	_fx_busy = false
	_held.clear()
	_played = false
	_attacked = false
	_ended = false
	_clear_pick()
	_was_cleared = CommonProgress.is_cleared(opponent_id)
	_publish_state()
	var request: CoreContract.StartPlaySessionRequest = CoreContract.StartPlaySessionRequest.new()
	request.mode_id = ReservedId.battle_mode()
	request.level_id = opponent_id
	NetworkCore.send(request, _on_started, _on_start_failed)


func _on_started(response: ContractMessage) -> void:
	var started: CoreContract.StartPlaySessionResponse = response as CoreContract.StartPlaySessionResponse
	if started == null or _stage != Stage.STARTING:
		return
	var loadout: GameContract.PlaySessionLoadout = GameContract.PlaySessionLoadout.new()
	if not loadout.decode(started.loadout) or loadout.opponent_id != _opponent_id:
		_leave_to_lobby()
		return
	_play_session_id = started.play_session_id
	var opponent: GameData.OpponentRow = GameData.OpponentTable.get_row(_opponent_id)
	_sim = BattleSim.new(loadout.player_deck_ids, loadout.opponent_deck_ids, GameSetting.hero_health(),
		opponent.hero_health, loadout.seed)
	_sim.sides[BattleSim.CPU].face = opponent.ai_face
	_sim.start()
	GameUpdateCore.set_in_play(true)
	_stage = Stage.PLAYER_TURN
	_publish_state()
	var started_event: BattleStartedEvent = EventCore.acquire(BattleStartedEvent) as BattleStartedEvent
	started_event.opponent_id = _opponent_id
	EventCore.publish(started_event)
	_publish_fx()


func _on_start_failed(_failure: RequestFailure) -> bool:
	if _stage == Stage.STARTING:
		_leave_to_lobby()
	return false


func _process(_delta: float) -> void:
	if _paused or _fx_busy or _sim == null:
		return
	if _stage != Stage.CPU_TURN and _stage != Stage.ENDING:
		return
	_wait_ms -= TimeCore.get_game_frame_ms()
	if _wait_ms > 0:
		return
	if _stage == Stage.CPU_TURN:
		_cpu_step.call_deferred()
	else:
		_stage = Stage.SAVING
		_send_finish.call_deferred()


## One CPU action, then the wait before the next one.
func _run_cpu_step() -> void:
	if _stage != Stage.CPU_TURN or _fx_busy or _paused or _sim.over:
		return
	var action: BattleAction = BattleAi.next_action(_sim, BattleSim.CPU)
	match action.kind:
		BattleAction.Kind.PLAY:
			if not _sim.play_card(BattleSim.CPU, action.hand_index, action.target_side, action.target_uid):
				_sim.end_turn()
		BattleAction.Kind.ATTACK:
			if not _sim.attack(BattleSim.CPU, action.attacker_uid, action.target_side, action.target_uid):
				_sim.end_turn()
		_:
			_sim.end_turn()
	_wait_ms = GameSetting.cpu_action_delay()
	_publish_fx()


## Sends the events of the last change to the board panel and follows the turn they lead to.
func _publish_fx() -> void:
	var events: Array[BattleEvent] = _sim.take_events()
	for e: BattleEvent in events:
		var fx: BattleFxEvent = EventCore.acquire(BattleFxEvent) as BattleFxEvent
		fx.fx = e
		EventCore.publish(fx)
	if not events.is_empty():
		_fx_busy = true
	_follow_turn()
	_publish_state()


func _follow_turn() -> void:
	if _stage != Stage.PLAYER_TURN and _stage != Stage.CPU_TURN:
		return
	if _sim.over:
		_stage = Stage.ENDING
		_wait_ms = GameSetting.game_over_delay()
		_clear_pick()
		return
	if _sim.active == BattleSim.CPU and _stage == Stage.PLAYER_TURN:
		_stage = Stage.CPU_TURN
		_wait_ms = GameSetting.cpu_turn_start_delay()
		_clear_pick()
	elif _sim.active == BattleSim.PLAYER and _stage == Stage.CPU_TURN:
		_stage = Stage.PLAYER_TURN


func _on_fx_idle(_event: BattleFxIdleEvent) -> void:
	_fx_busy = false
	_publish_state()
	_take_held()


## Acts on the held presses in order until one starts an effect; the rest wait for its end. Presses held into a turn
## that is no longer the player's are dropped.
func _take_held() -> void:
	while not _held.is_empty() and not _fx_busy:
		var press: BattleInputEvent = _held.pop_front()
		if not is_waiting_for_player():
			_held.clear()
			return
		_take_input(press.kind, press.index, press.uid, press.card_id)


func _on_view_ready(_event: BattleViewReadyEvent) -> void:
	_publish_state()


func _on_input(event: BattleInputEvent) -> void:
	if _stage == Stage.CPU_TURN and not _paused and event.kind != BattleInputEvent.Kind.BACKDROP:
		_publish_refusal(ReservedString.battle_wait_enemy(), event.kind, event.index, false, false)
		_responded()
		return
	if _stage == Stage.ENDING and not _paused:
		_wait_ms = 0
		_responded()
		return
	if _holds():
		if _held.size() < BattleConstants.HELD_PRESS_LIMIT:
			var held: BattleInputEvent = BattleInputEvent.new()
			held.kind = event.kind
			held.index = event.index
			held.uid = event.uid
			held.card_id = event.card_id
			_held.push_back(held)
		_responded()
		return
	_take_input(event.kind, event.index, event.uid, event.card_id)


## Whether a press now waits for the effects that play: any press in the player's turn while an effect plays, or while
## presses made before it still wait.
func _holds() -> bool:
	if _stage != Stage.PLAYER_TURN or _paused or _sim == null or _sim.over:
		return false
	return _fx_busy or not _held.is_empty()


## Acts on a press of `kind`: the hand card `card_id` the place `index` showed, or the minion `uid` at the place
## `index` of the board panel.
func _take_input(kind: BattleInputEvent.Kind, index: int, uid: int, card_id: int = 0) -> void:
	if not is_waiting_for_player():
		return
	_press_kind = kind
	_press_index = index
	match kind:
		BattleInputEvent.Kind.HAND:
			_press_hand(_hand_index(index, card_id))
		BattleInputEvent.Kind.OWN_MINION:
			_press_own_minion(_alive(BattleSim.PLAYER, uid))
		BattleInputEvent.Kind.ENEMY_MINION:
			var target: int = _alive(BattleSim.CPU, uid)
			if target != BattleSim.HERO:
				_press_target(BattleSim.CPU, target)
		BattleInputEvent.Kind.OWN_HERO:
			_press_target(BattleSim.PLAYER, BattleSim.HERO)
		BattleInputEvent.Kind.ENEMY_HERO:
			_press_target(BattleSim.CPU, BattleSim.HERO)
		BattleInputEvent.Kind.END_TURN:
			_clear_pick()
			SoundCore.play(ReservedSound.battle_end_turn(), SoundCore.SoundBus.SFX, scope)
			_responded()
			_ended = true
			_sim.end_turn()
			_publish_fx()
		BattleInputEvent.Kind.BACKDROP:
			if _pick != Pick.NONE:
				_clear_pick()
				_responded()
				_publish_state()


func _press_hand(index: int) -> void:
	if index < 0 or index >= _sim.sides[BattleSim.PLAYER].hand.size():
		return
	if _pick == Pick.HAND and _pick_hand == index:
		_clear_pick()
		_responded()
		_publish_state()
		return
	var check: BattleSim.PlayCheck = _sim.check_play(BattleSim.PLAYER, index)
	if check != BattleSim.PlayCheck.OK:
		_refuse(_refusal_text(check), check == BattleSim.PlayCheck.NO_MANA)
		return
	var card_id: int = _sim.sides[BattleSim.PLAYER].hand[index]
	_responded()
	if BattleSim.needs_target(card_id):
		_pick = Pick.HAND
		_pick_hand = index
		_pick_uid = 0
		_publish_state()
		return
	_clear_pick()
	if _sim.play_card(BattleSim.PLAYER, index, BattleSim.NO_SIDE, BattleSim.HERO):
		_played = true
	_publish_fx()


func _press_own_minion(uid: int) -> void:
	if uid == BattleSim.HERO:
		return
	if _pick == Pick.HAND:
		_press_target(BattleSim.PLAYER, uid)
		return
	if _pick == Pick.ATTACKER and _pick_uid == uid:
		_clear_pick()
		_responded()
		_publish_state()
		return
	if not _sim.can_attack(BattleSim.PLAYER, uid):
		_refuse(ReservedString.battle_cannot_attack())
		return
	_pick = Pick.ATTACKER
	_pick_uid = uid
	_pick_hand = -1
	_responded()
	_publish_state()


## A press on a character while a hand card or an attacker waits for its target.
func _press_target(side: int, uid: int) -> void:
	if side != BattleSim.PLAYER and side != BattleSim.CPU:
		return
	if _pick == Pick.HAND:
		var card_id: int = _sim.sides[BattleSim.PLAYER].hand[_pick_hand]
		if not _sim.is_play_target(BattleSim.PLAYER, card_id, side, uid):
			_refuse(ReservedString.battle_hint_target())
			return
		var hand_index: int = _pick_hand
		_clear_pick()
		_responded()
		if _sim.play_card(BattleSim.PLAYER, hand_index, side, uid):
			_played = true
		_publish_fx()
		return
	if _pick == Pick.ATTACKER:
		if not _sim.is_attack_target(BattleSim.PLAYER, _pick_uid, side, uid):
			var guarded: bool = side == BattleSim.CPU and _sim.sides[BattleSim.CPU].has_guard()
			_refuse(ReservedString.battle_must_attack_guard() if guarded else ReservedString.battle_hint_attack_target(),
				false, guarded)
			return
		var attacker: int = _pick_uid
		_clear_pick()
		_responded()
		if _sim.attack(BattleSim.PLAYER, attacker, side, uid):
			_attacked = true
		_publish_fx()


## The hand index of the card `card_id` the hand place `index` showed when it was pressed: `index` when the card is
## still there, else the first place of that card in the hand, else `index` (0 for no card).
func _hand_index(index: int, card_id: int) -> int:
	var hand: PackedInt32Array = _sim.sides[BattleSim.PLAYER].hand
	if card_id == 0 or (index >= 0 and index < hand.size() and hand[index] == card_id):
		return index
	var at: int = hand.find(card_id)
	return at if at >= 0 else index


## `uid` when it is a minion on the board of `side`, else `BattleSim.HERO` (nothing to press).
func _alive(side: int, uid: int) -> int:
	if uid == BattleSim.HERO or _sim.sides[side].index_of(uid) < 0:
		return BattleSim.HERO
	return uid


func _refusal_text(check: BattleSim.PlayCheck) -> String:
	match check:
		BattleSim.PlayCheck.NO_MANA:
			return ReservedString.battle_not_enough_mana()
		BattleSim.PlayCheck.BOARD_FULL:
			return ReservedString.battle_board_full()
		BattleSim.PlayCheck.NO_TARGET:
			return ReservedString.battle_no_target()
	return ReservedString.battle_enemy_turn()


## Refuses the press being taken: the error sound, and the reason over the pressed part of the board.
func _refuse(text_key: String, mana: bool = false, guard: bool = false) -> void:
	SoundCore.play(ReservedSound.battle_error(), SoundCore.SoundBus.SFX, scope)
	_publish_refusal(text_key, _press_kind, _press_index, mana, guard)
	_responded()


func _publish_refusal(text_key: String, kind: BattleInputEvent.Kind, index: int, mana: bool, guard: bool) -> void:
	var refused: BattleRefusedEvent = EventCore.acquire(BattleRefusedEvent) as BattleRefusedEvent
	refused.text_key = text_key
	refused.kind = kind
	refused.index = index
	refused.mana = mana
	refused.guard = guard
	EventCore.publish(refused)


func _responded() -> void:
	EventCore.publish(EventCore.acquire(BattleRespondedEvent))


func _clear_pick() -> void:
	_pick = Pick.NONE
	_pick_hand = -1
	_pick_uid = 0


func _publish_state() -> void:
	var event: BattleStateChangedEvent = EventCore.acquire(BattleStateChangedEvent) as BattleStateChangedEvent
	event.stage = _stage
	event.sim = _sim
	event.opponent_id = _opponent_id
	event.pick = _pick
	event.pick_hand = _pick_hand
	event.pick_uid = _pick_uid
	event.hint = _hint()
	EventCore.publish(event)


## The hint line of the first battle (`BattleHint`). Empty after the first finished battle.
func _hint() -> String:
	if CommonProgress.battles() > 0 or _stage != Stage.PLAYER_TURN or _sim == null:
		return ""
	return BattleHint.text(_sim, _pick, _played, _attacked, _ended)


## Sends the finished battle. The result panel opens when the server answers, or with the result unsaved when it
## refuses it.
func _finish_battle() -> void:
	if _stage != Stage.SAVING:
		return
	var result: GameContract.PlaySessionResult = GameContract.PlaySessionResult.new()
	result.won = _sim.winner == BattleSim.PLAYER
	result.conceded = _sim.conceded
	result.turns = mini(_sim.turn, GameSetting.max_turns())
	result.player_health = _sim.sides[BattleSim.PLAYER].hero_health
	result.opponent_health = _sim.sides[BattleSim.CPU].hero_health
	result.cards_played = _sim.cards_played
	var request: CoreContract.FinishPlaySessionRequest = CoreContract.FinishPlaySessionRequest.new()
	request.play_session_id = _play_session_id
	request.result = result.encode()
	NetworkCore.send(request, _on_finished, _on_finish_failed)


func _on_finished(_response: ContractMessage) -> void:
	GameUpdateCore.set_in_play(false)
	_show_result(true)


## A play session the server can no longer count (it expired, ended too fast or is unknown) is answered here: the
## result panel says the battle was not counted. Other failures keep the core error handling.
func _on_finish_failed(failure: RequestFailure) -> bool:
	GameUpdateCore.set_in_play(false)
	_show_result(false)
	return BattleScene.is_uncounted(failure)


static func is_uncounted(failure: RequestFailure) -> bool:
	if failure.kind != NetworkCore.FailureKind.SERVER_ERROR:
		return false
	return failure.error_code == CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_EXPIRED \
		or failure.error_code == CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_NOT_FOUND \
		or failure.error_code == CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_TOO_FAST


func _show_result(saved: bool) -> void:
	if _stage != Stage.SAVING:
		return
	_stage = Stage.RESULT
	var won: bool = _sim.winner == BattleSim.PLAYER
	var param: BattleResultParam = BattleResultParam.new()
	param.won = won
	param.saved = saved
	param.opponent_id = _opponent_id
	param.turns = mini(_sim.turn, GameSetting.max_turns())
	param.wins = CommonProgress.wins()
	param.losses = CommonProgress.losses()
	param.win_streak = CommonProgress.win_streak()
	var opponent: GameData.OpponentRow = GameData.OpponentTable.get_row(_opponent_id)
	if won and saved and not _was_cleared and CommonProgress.is_cleared(_opponent_id):
		param.reward_cards = opponent.reward_cards
		param.swap_out_cards = opponent.reward_removes
	if not won:
		param.tip = opponent.tip
		if not CommonProgress.is_cleared(_opponent_id):
			param.stake_cards = opponent.reward_cards
	var next: int = CommonProgress.next_opponent()
	param.next_opponent = next if won and saved and next != _opponent_id and not CommonProgress.is_cleared(next) else 0
	param.all_cleared = won and saved and CommonProgress.all_cleared() and not _was_cleared
	param.on_retry = _retry
	param.on_next = _next
	param.on_lobby = _leave_to_lobby
	_publish_state()
	SoundCore.play(ReservedSound.battle_victory() if won else ReservedSound.battle_defeat(), SoundCore.SoundBus.SFX, scope)
	UICore.open_panel(ResourceKey.PREFAB__BATTLE__RESULT_PANEL, param, false)
	var finished: BattleFinishedEvent = EventCore.acquire(BattleFinishedEvent) as BattleFinishedEvent
	finished.won = won
	finished.saved = saved
	EventCore.publish(finished)


func _retry() -> void:
	_begin_battle(_opponent_id)


func _next() -> void:
	_begin_battle(CommonProgress.next_opponent())


func _on_pause_requested(_event: BattlePauseRequestedEvent) -> void:
	if _paused or (_stage != Stage.PLAYER_TURN and _stage != Stage.CPU_TURN):
		return
	_set_paused(true)
	var param: BattlePauseParam = BattlePauseParam.new()
	param.on_resume = _on_resume
	param.on_concede = _on_concede
	UICore.open_popup(ResourceKey.PREFAB__BATTLE__PAUSE_POPUP, param, Callable())


func _on_resume() -> void:
	_set_paused(false)


## The player gives up: the battle ends as a loss and its result is sent like any other.
func _on_concede() -> void:
	_set_paused(false)
	if _sim == null or _sim.over or (_stage != Stage.PLAYER_TURN and _stage != Stage.CPU_TURN):
		return
	_clear_pick()
	_sim.concede(BattleSim.PLAYER)
	_publish_fx()


func _set_paused(paused: bool) -> void:
	if paused == _paused:
		return
	_paused = paused
	TimeCore.set_paused(paused)


func _leave_to_lobby() -> void:
	if _stage == Stage.LEAVING:
		return
	_stage = Stage.LEAVING
	SceneCore.change_scene(ResourceKey.SCENE__LOBBY__LOBBY, null)


static func sound_keys() -> PackedStringArray:
	return PackedStringArray([
		ReservedSound.battle_card_play(), ReservedSound.battle_card_draw(), ReservedSound.battle_spell_cast(),
		ReservedSound.battle_attack(), ReservedSound.battle_hero_hit(), ReservedSound.battle_minion_death(),
		ReservedSound.battle_heal(), ReservedSound.battle_ward_break(), ReservedSound.battle_buff(),
		ReservedSound.battle_your_turn(), ReservedSound.battle_end_turn(), ReservedSound.battle_victory(),
		ReservedSound.battle_defeat(), ReservedSound.battle_reward(), ReservedSound.battle_error()])


static func tween_keys() -> PackedStringArray:
	return PackedStringArray([
		ResourceKey.TWEEN__BATTLE__SUMMON, ResourceKey.TWEEN__BATTLE__ATTACK_LUNGE, ResourceKey.TWEEN__BATTLE__HIT,
		ResourceKey.TWEEN__BATTLE__NUMBER_POP, ResourceKey.TWEEN__BATTLE__DEATH, ResourceKey.TWEEN__BATTLE__CARD_REVEAL,
		ResourceKey.TWEEN__BATTLE__TURN_BANNER, ResourceKey.TWEEN__BATTLE__BUFF_POP, ResourceKey.TWEEN__BATTLE__HAND_DRAW,
		ResourceKey.TWEEN__BATTLE__BOARD_SHAKE, ResourceKey.TWEEN__BATTLE__GLOW_PULSE, ResourceKey.TWEEN__BATTLE__REWARD_REVEAL,
		ResourceKey.TWEEN__BATTLE__HEAL_POP, ResourceKey.TWEEN__BATTLE__HERO_BREAK, ResourceKey.TWEEN__BATTLE__WARD_BREAK,
		ResourceKey.TWEEN__BATTLE__VICTORY_FLASH, ResourceKey.TWEEN__BATTLE__ATTACK_RETURN, ResourceKey.TWEEN__BATTLE__PRESS_POP,
		ResourceKey.TWEEN__BATTLE__IMPACT_SHAKE, ResourceKey.TWEEN__BATTLE__LAND_THUMP, ResourceKey.TWEEN__BATTLE__STAT_POP,
		ResourceKey.TWEEN__BATTLE__DEFEAT_FLASH, ResourceKey.TWEEN__BATTLE__CARD_FLY, ResourceKey.TWEEN__BATTLE__END_BANNER,
		ResourceKey.TWEEN__BATTLE__CARD_LIFT, ResourceKey.TWEEN__BATTLE__SUMMON_SETTLE, ResourceKey.TWEEN__BATTLE__DUST_RING,
		ResourceKey.TWEEN__BATTLE__REFUSE_SHAKE, ResourceKey.TWEEN__BATTLE__REFUSAL_POP, ResourceKey.TWEEN__BATTLE__MANA_FLASH,
		ResourceKey.TWEEN__BATTLE__FADE_IN, ResourceKey.TWEEN__BATTLE__REWARD_BURST, ResourceKey.TWEEN__BATTLE__IMPACT_RING,
		ResourceKey.TWEEN__BATTLE__HIT_FLASH])
