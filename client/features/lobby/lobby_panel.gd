class_name LobbyPanel
extends UIPanel
## Root panel of the lobby: the game name, the record, the opponent ladder, and the start, deck and option buttons.
## The next opponent not beaten yet is picked first; pressing an open opponent picks it. The start button is the first
## focus, so one confirm input starts the picked battle.

@export var title_label: Label
@export var record_label: Label
@export var detail_label: Label
@export var ladder_title_label: Label
@export var ladder_root: Control
@export var hero_portrait: TextureRect
@export var picked_label: Label
@export var deck_label: Label
@export var play_button: Button
@export var deck_button: Button
@export var option_button: Button
@export var play_click: UIButton
@export var deck_click: UIButton
@export var option_click: UIButton

var _entries: Array[LobbyOpponentEntry] = []
var _picked: int = 0
var _starting: bool = false
var _format_args: FormatArgs = FormatArgs.new()


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	if _entries.is_empty():
		for child: Node in ladder_root.get_children():
			if child is LobbyOpponentEntry:
				_entries.append(child as LobbyOpponentEntry)
	LocalizationCore.bind_text(title_label, ReservedString.title_name())
	LocalizationCore.bind_text(ladder_title_label, ReservedString.lobby_ladder_title())
	LocalizationCore.bind_text(play_button, ReservedString.lobby_play())
	LocalizationCore.bind_text(deck_button, ReservedString.lobby_deck())
	LocalizationCore.bind_text(option_button, ReservedString.lobby_options())
	play_click.set_on_click(_on_play)
	deck_click.set_on_click(_on_deck)
	option_click.set_on_click(_on_option)
	for i: int in _entries.size():
		_entries[i].click.set_on_click(_on_entry.bind(i))
	EventCore.subscribe(UserStateChangedEvent, _on_user_state_changed)
	hero_portrait.texture = CommonCardView.texture(ResourceKey.IMAGE__HERO_PLAYER, scope)
	_picked = CommonProgress.next_opponent()
	_write()
	return true


func _exit_tree() -> void:
	EventCore.unsubscribe_all(self)


## The opponent the start button fights.
func get_picked() -> int:
	return _picked


func _on_play() -> void:
	if _starting or not LobbyLadder.is_open(_picked):
		return
	_starting = true
	SceneCore.change_scene(ResourceKey.SCENE__BATTLE__BATTLE, CommonBattleParam.of(_picked))


func _on_deck() -> void:
	UICore.open_panel(ResourceKey.PREFAB__LOBBY__DECK_PANEL, null, false)


func _on_option() -> void:
	UICore.open_panel(ResourceKey.PREFAB__LOBBY__OPTION_PANEL, null, false)


func _on_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var id: int = _entries[index].opponent_id
	if not LobbyLadder.is_open(id):
		MessageCore.show_toast(ReservedString.lobby_status_locked())
		return
	_picked = id
	_write()


func _on_user_state_changed(event: UserStateChangedEvent) -> void:
	if event.kind == GameContract.ProgressUserState:
		if not LobbyLadder.is_open(_picked):
			_picked = CommonProgress.next_opponent()
		_write()


func _write() -> void:
	var wins: int = CommonProgress.wins()
	var losses: int = CommonProgress.losses()
	detail_label.visible = false
	if wins + losses == 0:
		record_label.text = LocalizationCore.get_text(ReservedString.lobby_no_record())
	else:
		_format_args.clear()
		_format_args.set_int("wins", wins)
		_format_args.set_int("losses", losses)
		record_label.text = LocalizationCore.format(ReservedString.lobby_record(), _format_args)
		var streak: int = CommonProgress.win_streak()
		if CommonProgress.all_cleared():
			detail_label.visible = true
			detail_label.text = LocalizationCore.get_text(ReservedString.lobby_all_cleared())
		elif streak >= 2:
			detail_label.visible = true
			_format_args.clear()
			_format_args.set_int("streak", streak)
			detail_label.text = LocalizationCore.format(ReservedString.lobby_streak(), _format_args)
	var rows: Array[GameData.OpponentRow] = CommonProgress.opponents()
	for i: int in _entries.size():
		var entry: LobbyOpponentEntry = _entries[i]
		entry.visible = i < rows.size()
		if entry.visible:
			var row: GameData.OpponentRow = rows[i]
			entry.show_opponent(row, LobbyLadder.is_open(row.id), CommonProgress.is_cleared(row.id), row.id == _picked,
				scope)
	_format_args.clear()
	_format_args.set_string("name", LocalizationCore.get_text(GameData.OpponentTable.get_row(_picked).name))
	picked_label.text = LocalizationCore.format(ReservedString.lobby_selected(), _format_args)
	_format_args.clear()
	_format_args.set_int("count", CommonProgress.deck().size())
	deck_label.text = LocalizationCore.format(ReservedString.lobby_deck_count(), _format_args)
