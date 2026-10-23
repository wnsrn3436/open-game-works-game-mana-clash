class_name BattleHeroSlot
extends Button
## A hero on the board panel: portrait, name, health, the outline when it can be targeted, and the damage or heal
## number.

@export var body: Control
@export var portrait: TextureRect
@export var name_label: Label
@export var health_label: Label
@export var glow: Control
@export var number_label: Label
@export var click: UIButton

var max_health: int = 0
var _args: FormatArgs = FormatArgs.new()


func set_health(health: int, health_max: int) -> void:
	max_health = health_max
	health_label.text = str(health)
	health_label.add_theme_color_override("font_color",
		CommonConstants.HURT_COLOR if health < health_max else CommonConstants.STAT_COLOR)


func show_number(key: String, amount: int, color: Color) -> void:
	_args.clear()
	_args.set_int("amount", amount)
	number_label.text = LocalizationCore.format(key, _args)
	number_label.add_theme_color_override("font_color", color)
	number_label.visible = true


func center() -> Vector2:
	return position + size * 0.5
