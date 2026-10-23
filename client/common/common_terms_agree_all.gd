class_name CommonTermsAgreeAll
extends CheckBox
## Agree-all toggle of the terms popup prefab. Turning it on or off turns both agree toggles the same way, and it is
## on only while both are on, so a new user agrees to both items with one press before the confirm button.

@export var terms_toggle: Button
@export var privacy_toggle: Button


func _ready() -> void:
	LocalizationCore.bind_text(self, ReservedString.common_terms_agree_all())
	toggled.connect(_on_toggled)
	terms_toggle.toggled.connect(_on_item_toggled)
	privacy_toggle.toggled.connect(_on_item_toggled)
	_on_item_toggled(false)


func _on_toggled(on: bool) -> void:
	terms_toggle.button_pressed = on
	privacy_toggle.button_pressed = on
	set_pressed_no_signal(on)


func _on_item_toggled(_on: bool) -> void:
	set_pressed_no_signal(terms_toggle.button_pressed and privacy_toggle.button_pressed)
