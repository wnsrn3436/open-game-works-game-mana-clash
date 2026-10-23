class_name LobbyDeckPanel
extends UIPanel
## The player deck over the lobby: each different card once in cost order with how many copies the deck has, and the
## close button. A back input closes it.

@export var title_label: Label
@export var count_label: Label
@export var grid: Control
@export var close_button: Button
@export var close_click: UIButton

var _format_args: FormatArgs = FormatArgs.new()


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	LocalizationCore.bind_text(title_label, ReservedString.deck_title())
	LocalizationCore.bind_text(close_button, ReservedString.deck_close())
	close_click.set_on_click(_on_close)
	var deck: PackedInt32Array = CommonProgress.deck()
	_format_args.clear()
	_format_args.set_int("count", deck.size())
	count_label.text = LocalizationCore.format(ReservedString.deck_count(), _format_args)
	var cards: PackedInt32Array = LobbyDeckPanel.distinct_in_order(deck)
	var index: int = 0
	for child: Node in grid.get_children():
		var entry: LobbyDeckEntry = child as LobbyDeckEntry
		if entry == null:
			continue
		entry.visible = index < cards.size()
		if entry.visible:
			entry.show_entry(cards[index], LobbyDeckPanel.copies(deck, cards[index]), scope)
		index += 1
	return true


func _on_close() -> void:
	UICore.close_panel()


## Each card of `deck` once, ordered by the card `order`.
static func distinct_in_order(deck: PackedInt32Array) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for id: int in deck:
		if not out.has(id):
			out.push_back(id)
	var rows: Array[GameData.CardRow] = []
	for id: int in out:
		rows.append(GameData.CardTable.get_row(id))
	rows.sort_custom(LobbyDeckPanel._before)
	out.clear()
	for row: GameData.CardRow in rows:
		out.push_back(row.id)
	return out


static func copies(deck: PackedInt32Array, id: int) -> int:
	return deck.count(id)


static func _before(a: GameData.CardRow, b: GameData.CardRow) -> bool:
	return a.order < b.order
