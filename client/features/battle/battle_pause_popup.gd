class_name BattlePausePopup
extends UIPopup
## Pause popup over the battle: resume, or give up the battle (a loss). Giving up asks once more: the first press of
## `concede` shows what it means and turns the button into the confirming one. A back input resumes.

@export var title_label: Label
@export var confirm_label: Label
@export var resume_button: Button
@export var concede_button: Button
@export var resume_click: UIButton
@export var concede_click: UIButton

var _param: BattlePauseParam = null
var _confirming: bool = false


func accepts_param(param: UIParam) -> bool:
	return param is BattlePauseParam


func prepare() -> bool:
	_param = popup_param as BattlePauseParam
	LocalizationCore.bind_text(title_label, ReservedString.battle_pause_title())
	LocalizationCore.bind_text(resume_button, ReservedString.battle_resume())
	LocalizationCore.bind_text(concede_button, ReservedString.battle_concede())
	resume_click.set_on_click(_on_resume)
	concede_click.set_on_click(_on_concede)
	LocalizationCore.bind_text(confirm_label, ReservedString.battle_concede_confirm())
	confirm_label.visible = false
	_confirming = false
	return true


func on_back() -> void:
	_on_resume()


func _on_resume() -> void:
	UICore.close_popup(self, _param.on_resume)


func _on_concede() -> void:
	if not _confirming:
		_confirming = true
		confirm_label.visible = true
		LocalizationCore.bind_text(concede_button, ReservedString.battle_concede_yes())
		return
	UICore.close_popup(self, _param.on_concede)
