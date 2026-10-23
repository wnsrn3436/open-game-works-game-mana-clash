class_name CommonCardView
extends Control
## The face of one card: cost, art, name, type, rule text and, for a minion, attack and health. The hand, the deck
## view, the reward and the card the opponent plays all draw it. `glow` is the outline of a playable or picked card; a
## card that cannot be played now has darker art.

@export var art: TextureRect
@export var cost_label: Label
@export var name_label: Label
@export var type_label: Label
@export var text_label: Label
@export var attack_badge: Control
@export var attack_label: Label
@export var health_badge: Control
@export var health_label: Label
@export var glow: Control

var card_id: int = 0
var _args: FormatArgs = FormatArgs.new()
## The rule text size the prefab gives; `fit_text` makes a long text smaller from it.
var _text_size: int = 0


## Draws the card `id`. Its art must be loaded in `scope`.
func show_card(id: int, scope: Scope) -> void:
	card_id = id
	var row: GameData.CardRow = GameData.CardTable.get_row(id)
	LocalizationCore.bind_text(name_label, row.name)
	var minion: bool = row.kind == GameData.CardKind.MINION
	LocalizationCore.bind_text(type_label, ReservedString.card_type_minion() if minion else ReservedString.card_type_spell())
	if row.text.is_empty():
		text_label.text = ""
	else:
		_args.clear()
		_args.set_int("amount", row.amount)
		_args.set_int("amount2", row.amount2)
		text_label.text = LocalizationCore.format(row.text, _args)
	fit_text()
	cost_label.text = str(row.cost)
	attack_badge.visible = minion
	health_badge.visible = minion
	attack_label.text = str(row.attack)
	health_label.text = str(row.health)
	art.texture = CommonCardView.texture(row.art, scope)


## Makes the rule text smaller, one size at a time down to `CommonConstants.CARD_TEXT_MIN_SIZE`, until its lines fit
## the text box, so a long text (a translation, a large text scale) does not run into the attack and health badges.
func fit_text() -> void:
	if _text_size == 0:
		_text_size = text_label.get_theme_font_size("font_size")
	var font_size: int = _text_size
	text_label.add_theme_font_size_override("font_size", font_size)
	while font_size > CommonConstants.CARD_TEXT_MIN_SIZE \
			and text_label.get_line_count() * text_label.get_line_height() > int(text_label.size.y):
		font_size -= 1
		text_label.add_theme_font_size_override("font_size", font_size)


## Shows the outline in `color`, or hides it.
func set_glow(on: bool, color: Color) -> void:
	glow.visible = on
	glow.self_modulate = color


## Darkens the art of a card that cannot be played now, or shows it in full.
func set_waiting(on: bool) -> void:
	art.self_modulate = CommonConstants.CARD_WAITING_ART_COLOR if on else Color.WHITE


## The loaded texture `key` of `scope`, or `null` when it is not loaded.
static func texture(key: String, scope: Scope) -> Texture2D:
	if key.is_empty() or not ResourceCore.is_loaded(key, ResourceCore.BaseKind.TEXTURE_2D):
		return null
	return ResourceCore.get_loaded(key, ResourceCore.BaseKind.TEXTURE_2D, scope) as Texture2D


## Adds the art of every card and the portrait of every opponent to `request`.
static func preload_art(request: PreloadRequest) -> void:
	for row: GameData.CardRow in GameData.CardTable.all_rows():
		request.add_item(row.art, ResourceCore.BaseKind.TEXTURE_2D)
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		request.add_item(row.portrait, ResourceCore.BaseKind.TEXTURE_2D)
