class_name CommonTermsHint
extends Label
## Hint line of the terms popup prefab. It tells that both agree toggles are needed, highlighted while one is off,
## and keeps the confirm button disabled until both are on, so a confirm press without them does not look ignored.

@export var terms_toggle: Button
@export var privacy_toggle: Button
@export var confirm_button: Button


func _ready() -> void:
	LocalizationCore.bind_text(self, ReservedString.common_terms_agree_both())
	terms_toggle.toggled.connect(_on_toggled)
	privacy_toggle.toggled.connect(_on_toggled)
	_refresh()


func _on_toggled(_on: bool) -> void:
	_refresh()


func _refresh() -> void:
	var ready_to_confirm: bool = terms_toggle.button_pressed and privacy_toggle.button_pressed
	confirm_button.disabled = not ready_to_confirm
	add_theme_color_override("font_color",
		CommonConstants.TERMS_HINT_DONE_COLOR if ready_to_confirm else CommonConstants.TERMS_HINT_WAITING_COLOR)
