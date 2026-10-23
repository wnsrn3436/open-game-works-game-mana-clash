class_name TitleScene
extends SceneBase
## Title scene of the boot: the game name and its tagline over the lobby backdrop while the game signs in.

@export var title_label: Label
@export var tagline_label: Label
@export var backdrop: TextureRect


func on_preload(preload_request: PreloadRequest, _prefill_items: Array[PrefillItem]) -> void:
	preload_request.add_item(ResourceKey.BACKGROUND__LOBBY, ResourceCore.BaseKind.TEXTURE_2D)


func _ready() -> void:
	LocalizationCore.bind_text(title_label, ReservedString.title_name())
	LocalizationCore.bind_text(tagline_label, ReservedString.title_tagline())


func on_start() -> void:
	backdrop.texture = CommonCardView.texture(ResourceKey.BACKGROUND__LOBBY, scope)
