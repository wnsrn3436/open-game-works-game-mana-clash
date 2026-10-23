class_name LobbyOpponentEntry
extends Button
## One opponent of the ladder in the lobby: portrait, name, line, hero health and whether it is beaten, open or locked.

@export var portrait: TextureRect
@export var name_label: Label
@export var desc_label: Label
@export var health_label: Label
@export var status_label: Label
@export var lock_shade: Control
@export var picked_frame: Control
@export var click: UIButton

var opponent_id: int = 0
var _args: FormatArgs = FormatArgs.new()


func show_opponent(row: GameData.OpponentRow, open: bool, cleared: bool, picked: bool, scope: Scope) -> void:
	opponent_id = row.id
	portrait.texture = CommonCardView.texture(row.portrait, scope)
	LocalizationCore.bind_text(name_label, row.name)
	LocalizationCore.bind_text(desc_label, row.desc)
	_args.clear()
	_args.set_int("health", row.hero_health)
	health_label.text = LocalizationCore.format(ReservedString.lobby_opponent_health(), _args)
	var status: String = ReservedString.lobby_status_locked()
	if cleared:
		status = ReservedString.lobby_status_cleared()
	elif open:
		status = ReservedString.lobby_status_open()
	LocalizationCore.bind_text(status_label, status)
	lock_shade.visible = not open
	picked_frame.visible = picked
	disabled = not open
