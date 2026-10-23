class_name BattleResultPanel
extends UIPanel
## Result panel over the battle: win or loss, the opponent, the turn it ended, the record (or that the battle was not
## counted), the line under it (the win streak, the cleared ladder, or after a loss the opponent's tip), the reward
## cards of a first win with the cards it took out of the deck or, after a loss to an opponent not beaten yet, the cards
## a win would add, and the retry, next opponent and lobby buttons. After a win that opened the next opponent, `next` is the first focus; otherwise `retry`
## is. A back input goes to the lobby.
##
## The reward cards of a first win come first full screen: over a dark screen the title pops, a ring of light pulses
## and the cards turn over large one after another, each with a burst of light. A tap ends the reveal at once; once
## every card shows, a tap closes the full screen and the result fades in with the cards in its row.

@export var title_label: Label
@export var opponent_label: Label
@export var turns_label: Label
@export var record_label: Label
@export var streak_label: Label
@export var reward_root: Control
@export var reward_title_label: Label
@export var reward_row: Control
@export var swap_label: Label
@export var retry_button: Button
@export var next_button: Button
@export var lobby_button: Button
@export var retry_click: UIButton
@export var next_click: UIButton
@export var lobby_click: UIButton
@export var frame: Control
@export var stage: Button
@export var stage_click: UIButton
@export var stage_title_label: Label
@export var stage_rays: Control
@export var stage_row: Control
@export var stage_hint_label: Label

var _param: BattleResultParam = null
var _format_args: FormatArgs = FormatArgs.new()
var _leaving: bool = false
var _reveal: Callable = Callable()
var _reward_views: Array[CommonCardView] = []
## The color the prefab gives the line under the record.
var _streak_color: Color = Color.WHITE
## The large cards of the full screen reward and the burst of light behind each.
var _stage_views: Array[CommonCardView] = []
var _stage_bursts: Array[Control] = []
## Whether every card of the full screen reward shows, and the tweens it plays.
var _stage_done: bool = false
var _stage_handles: PackedInt32Array = PackedInt32Array()
var _reveal_stage: Callable = Callable()


func accepts_param(param: UIParam) -> bool:
	return param is BattleResultParam


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	_param = panel_param as BattleResultParam
	_reveal = _reveal_rewards
	_reveal_stage = _play_stage
	if _reward_views.is_empty():
		_streak_color = streak_label.get_theme_color("font_color")
		for child: Node in reward_row.get_children():
			if child is CommonCardView:
				_reward_views.append(child as CommonCardView)
		for holder: Node in stage_row.get_children():
			for child: Node in holder.get_children():
				if child is CommonCardView:
					_stage_views.append(child as CommonCardView)
				elif child is Control:
					_stage_bursts.append(child as Control)
	LocalizationCore.bind_text(title_label, ReservedString.result_win() if _param.won else ReservedString.result_lose())
	title_label.modulate = BattleConstants.WIN_COLOR if _param.won else BattleConstants.LOSE_COLOR
	LocalizationCore.bind_text(retry_button, ReservedString.result_retry())
	LocalizationCore.bind_text(next_button, ReservedString.result_next())
	LocalizationCore.bind_text(lobby_button, ReservedString.result_lobby())
	LocalizationCore.bind_text(reward_title_label,
		ReservedString.result_reward_title() if _param.won else ReservedString.result_stake_title())
	retry_click.set_on_click(_on_retry)
	next_click.set_on_click(_on_next)
	lobby_click.set_on_click(_on_lobby)
	next_button.visible = _param.next_opponent != 0
	LocalizationCore.bind_text(stage_title_label, ReservedString.result_stage_title())
	LocalizationCore.bind_text(stage_hint_label, ReservedString.result_stage_continue())
	stage_click.set_on_click(_on_stage)
	var staged: bool = _param.won and not _param.reward_cards.is_empty()
	stage.visible = staged
	frame.visible = not staged
	stage_hint_label.visible = false
	_stage_done = false
	initial_focus = stage if staged else _result_focus()
	_write_texts()
	_show_rewards()
	_show_stage()
	return true


func on_opened(_reason: UICore.PanelOpenReason) -> void:
	if stage.visible:
		_reveal_stage.call_deferred()
	elif not _shown_cards().is_empty():
		_reveal.call_deferred()


func _result_focus() -> Control:
	return next_button if next_button.visible else retry_button


func on_back() -> void:
	_on_lobby()


func _write_texts() -> void:
	var opponent: GameData.OpponentRow = GameData.OpponentTable.get_row(_param.opponent_id)
	_format_args.clear()
	_format_args.set_string("name", LocalizationCore.get_text(opponent.name))
	opponent_label.text = LocalizationCore.format(ReservedString.result_opponent(), _format_args)
	_format_args.clear()
	_format_args.set_int("turns", _param.turns)
	turns_label.text = LocalizationCore.format(ReservedString.result_turns(), _format_args)
	_format_args.clear()
	_format_args.set_int("wins", _param.wins)
	_format_args.set_int("losses", _param.losses)
	var record_key: String = ReservedString.result_record() if _param.saved else ReservedString.result_record_unsaved()
	record_label.text = LocalizationCore.format(record_key, _format_args)
	streak_label.visible = _param.saved and (_param.all_cleared or (_param.won and _param.win_streak >= 2))
	streak_label.add_theme_color_override("font_color", _streak_color)
	if not _param.won and not _param.tip.is_empty():
		streak_label.visible = true
		streak_label.add_theme_color_override("font_color", BattleConstants.TIP_COLOR)
		streak_label.text = LocalizationCore.get_text(_param.tip)
	elif _param.all_cleared:
		streak_label.text = LocalizationCore.get_text(ReservedString.result_all_cleared())
	elif streak_label.visible:
		_format_args.clear()
		_format_args.set_int("streak", _param.win_streak)
		streak_label.text = LocalizationCore.format(ReservedString.result_streak(), _format_args)


## The reward cards of a first win, or the cards a win would add after a loss.
func _shown_cards() -> PackedInt32Array:
	return _param.reward_cards if _param.won else _param.stake_cards


func _show_rewards() -> void:
	var cards: PackedInt32Array = _shown_cards()
	reward_root.visible = not cards.is_empty()
	swap_label.visible = _param.won and not _param.swap_out_cards.is_empty()
	if swap_label.visible:
		_format_args.clear()
		_format_args.set_string("cards", _card_list(_param.swap_out_cards))
		swap_label.text = LocalizationCore.format(ReservedString.result_swap_out(), _format_args)
	for i: int in _reward_views.size():
		var view: CommonCardView = _reward_views[i]
		var shown: bool = i < cards.size()
		view.visible = shown
		if shown:
			view.show_card(cards[i], scope)
			view.set_glow(_param.won, CommonConstants.CARD_PICKED_COLOR)
			view.scale = Vector2.ONE
			view.modulate = Color.WHITE if stage.visible else Color.TRANSPARENT


## Draws the reward cards of a first win on the full screen, hidden until each turns over.
func _show_stage() -> void:
	for i: int in _stage_views.size():
		var view: CommonCardView = _stage_views[i]
		var shown: bool = stage.visible and i < _param.reward_cards.size()
		(view.get_parent() as Control).visible = shown
		_stage_bursts[i].visible = false
		if shown:
			view.show_card(_param.reward_cards[i], scope)
			view.set_glow(true, CommonConstants.CARD_PICKED_COLOR)
			view.modulate = Color.TRANSPARENT


## The names of `cards` in order, each once, with the count of a card that comes more than once.
func _card_list(cards: PackedInt32Array) -> String:
	var names: PackedStringArray = PackedStringArray()
	var listed: PackedInt32Array = PackedInt32Array()
	var args: FormatArgs = FormatArgs.new()
	for card_id: int in cards:
		if listed.has(card_id):
			continue
		listed.push_back(card_id)
		var name: String = LocalizationCore.get_text(GameData.CardTable.get_row(card_id).name)
		var count: int = cards.count(card_id)
		if count > 1:
			args.clear()
			args.set_string("name", name)
			args.set_int("count", count)
			name = LocalizationCore.format(ReservedString.card_count(), args)
		names.push_back(name)
	return LocalizationCore.get_text(ReservedString.list_separator()).join(names)


## Fades in each card a win over this opponent would add, one after another, each later by the length of the fade.
func _reveal_rewards() -> void:
	var preset: TweenDefinition = _preset(ResourceKey.TWEEN__BATTLE__FADE_IN)
	if preset == null:
		for view: CommonCardView in _reward_views:
			view.modulate = Color.WHITE
		return
	var stagger: int = preset.steps[0].changes[0].duration
	for i: int in mini(_reward_views.size(), _shown_cards().size()):
		var definition: TweenDefinition = _delayed(preset, stagger * i)
		if definition != null:
			TweenCore.play(definition, _reward_views[i])


## The full screen reward: the screen fades in, the title pops, the ring of light pulses, and the cards turn over one
## after another (each later by the length of the first change of the reveal preset), each with its burst of light.
## Each card is a reward as it turns over. The tap hint shows once the last card is up.
func _play_stage() -> void:
	if not is_inside_tree() or not stage.visible:
		return
	SoundCore.play(ReservedSound.battle_reward(), SoundCore.SoundBus.SFX, scope)
	_track(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__FADE_IN, scope, stage))
	stage_title_label.pivot_offset = stage_title_label.size * 0.5
	_track(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__END_BANNER, scope, stage_title_label))
	stage_rays.pivot_offset = stage_rays.size * 0.5
	_track(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__GLOW_PULSE, scope, stage_rays))
	var reveal: TweenDefinition = _preset(ResourceKey.TWEEN__BATTLE__REWARD_REVEAL)
	var burst: TweenDefinition = _preset(ResourceKey.TWEEN__BATTLE__REWARD_BURST)
	if reveal == null:
		_finish_stage()
		return
	var stagger: int = reveal.steps[0].changes[0].duration
	var last: int = 0
	for i: int in mini(_stage_views.size(), _param.reward_cards.size()):
		var view: CommonCardView = _stage_views[i]
		view.pivot_offset = view.size * 0.5
		var turn: TweenDefinition = _delayed(reveal, stagger * (i + 1))
		if turn != null:
			last = TweenCore.play(turn, view)
			_track(last)
		var flash: TweenDefinition = _delayed(burst, stagger * (i + 1)) if burst != null else null
		if flash != null:
			var ring: Control = _stage_bursts[i]
			ring.pivot_offset = ring.size * 0.5
			ring.modulate = Color.TRANSPARENT
			ring.visible = true
			_track(TweenCore.play(flash, ring))
		var shown: BattleRewardShownEvent = EventCore.acquire(BattleRewardShownEvent) as BattleRewardShownEvent
		shown.card_id = _param.reward_cards[i]
		EventCore.publish(shown)
	if last != 0:
		await TweenCore.wait_end(last)
	if is_inside_tree() and stage.visible and not _stage_done:
		_finish_stage()


## Every card of the full screen reward shows as it ends, and the tap hint pulses.
func _finish_stage() -> void:
	_stage_done = true
	for handle: int in _stage_handles:
		TweenCore.stop(handle)
	_stage_handles.clear()
	stage.modulate = Color.WHITE
	stage_title_label.modulate = Color.WHITE
	stage_title_label.scale = Vector2.ONE
	for i: int in _stage_views.size():
		_stage_views[i].modulate = Color.WHITE
		_stage_views[i].scale = Vector2.ONE
		_stage_bursts[i].visible = false
	stage_hint_label.visible = true
	_track(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__GLOW_PULSE, scope, stage_hint_label))
	stage_rays.pivot_offset = stage_rays.size * 0.5
	_track(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__GLOW_PULSE, scope, stage_rays))


## A tap on the full screen reward: the first one ends the reveal, the next one closes it.
func _on_stage() -> void:
	if not stage.visible:
		return
	if not _stage_done:
		_finish_stage()
		return
	close_stage()


## Closes the full screen reward and fades the result in.
func close_stage() -> void:
	if not stage.visible:
		return
	_stage_done = true
	for handle: int in _stage_handles:
		TweenCore.stop(handle)
	_stage_handles.clear()
	stage.visible = false
	frame.visible = true
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__FADE_IN, scope, frame)
	initial_focus = _result_focus()
	if is_inside_tree():
		initial_focus.grab_focus()


func _track(handle: int) -> void:
	if handle != 0:
		_stage_handles.push_back(handle)


## The loaded tween preset `key` with at least one change, or `null`.
func _preset(key: String) -> TweenDefinition:
	if not ResourceCore.is_loaded(key, TweenCore.get_preset_kind()):
		return null
	var preset: TweenDefinition = ResourceCore.get_loaded(key, TweenCore.get_preset_kind(), scope) as TweenDefinition
	if preset == null or preset.steps.is_empty() or preset.steps[0].changes.is_empty():
		return null
	return preset


## A copy of `preset` whose first step starts `delay` ms later, or `null`.
static func _delayed(preset: TweenDefinition, delay: int) -> TweenDefinition:
	var definition: TweenDefinition = TweenDefinition.new()
	if not TweenCore.copy_definition(preset, definition):
		return null
	for change: TweenChange in definition.steps[0].changes:
		change.delay += delay
	return definition


func _on_retry() -> void:
	if _leaving:
		return
	_leaving = true
	BattleResultPanel._close_then(_param.on_retry)


func _on_next() -> void:
	if _leaving:
		return
	_leaving = true
	BattleResultPanel._close_then(_param.on_next)


func _on_lobby() -> void:
	if _leaving:
		return
	_leaving = true
	_param.on_lobby.call()


static func _close_then(next: Callable) -> void:
	if await UICore.close_panel():
		next.call()
