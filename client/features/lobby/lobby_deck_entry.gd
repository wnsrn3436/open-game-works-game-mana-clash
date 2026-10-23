class_name LobbyDeckEntry
extends Control
## One different card of the deck view and how many copies the deck has.

@export var card: CommonCardView
@export var copies_label: Label

var _args: FormatArgs = FormatArgs.new()


func show_entry(card_id: int, copies: int, scope: Scope) -> void:
	card.show_card(card_id, scope)
	card.set_glow(false, CommonConstants.CARD_PLAYABLE_COLOR)
	_args.clear()
	_args.set_int("count", copies)
	copies_label.text = LocalizationCore.format(ReservedString.deck_copies(), _args)
