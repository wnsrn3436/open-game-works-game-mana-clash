class_name BattleMinionSlot
extends Button
## One place of a board row: the minion art, its attack and health, its keywords (guard frame, ward dome, sleep mark),
## the outline of a ready or targetable minion, and the damage or heal number.

@export var body: Control
@export var art: TextureRect
@export var name_label: Label
@export var attack_label: Label
@export var health_label: Label
@export var guard_frame: Control
@export var guard_label: Label
@export var ward: Control
@export var sleep_label: Label
@export var glow: Control
@export var number_label: Label
@export var click: UIButton

var uid: int = 0
var card_id: int = 0
var max_health: int = 0
var attack: int = 0
var health: int = 0
var _args: FormatArgs = FormatArgs.new()


func _ready() -> void:
	LocalizationCore.bind_text(guard_label, ReservedString.card_keyword_guard())
	LocalizationCore.bind_text(sleep_label, ReservedString.battle_sleeping())


## Draws the minion of `card_id` with these stats and keywords.
func show_minion(minion_uid: int, minion_card: int, attack_value: int, health_value: int, health_max: int, guard: bool,
		ward_on: bool, sleeping: bool, scope: Scope) -> void:
	uid = minion_uid
	card_id = minion_card
	max_health = health_max
	var row: GameData.CardRow = GameData.CardTable.get_row(minion_card)
	LocalizationCore.bind_text(name_label, row.name)
	art.texture = CommonCardView.texture(row.art, scope)
	guard_frame.visible = guard
	ward.visible = ward_on
	ward.modulate = Color.WHITE
	ward.scale = Vector2.ONE
	sleep_label.visible = sleeping
	set_stats(attack_value, health_value)
	body.modulate = Color.WHITE
	body.scale = Vector2.ONE
	body.rotation = 0.0
	number_label.visible = false


func set_stats(attack_value: int, health_value: int) -> void:
	attack = attack_value
	health = health_value
	var row: GameData.CardRow = GameData.CardTable.get_row(card_id)
	attack_label.text = str(attack)
	health_label.text = str(health)
	attack_label.add_theme_color_override("font_color",
		CommonConstants.BUFFED_COLOR if attack > row.attack else CommonConstants.STAT_COLOR)
	var health_color: Color = CommonConstants.STAT_COLOR
	if health < max_health:
		health_color = CommonConstants.HURT_COLOR
	elif health > row.health:
		health_color = CommonConstants.BUFFED_COLOR
	health_label.add_theme_color_override("font_color", health_color)


## Shows `key` formatted with `amount` as the floating number.
func show_number(key: String, amount: int, color: Color) -> void:
	_args.clear()
	_args.set_int("amount", amount)
	show_text(LocalizationCore.format(key, _args), color)


## Shows `text` as the floating number.
func show_text(text: String, color: Color) -> void:
	number_label.text = text
	number_label.add_theme_color_override("font_color", color)
	number_label.visible = true


## The center of the slot in the coordinates of its parent.
func center() -> Vector2:
	return position + size * 0.5
