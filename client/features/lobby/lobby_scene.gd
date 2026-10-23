class_name LobbyScene
extends SceneBase
## Lobby scene after sign-in. Its root panel holds the record, the opponent ladder, the start, deck and option
## buttons. It plays the lobby BGM.

@export var backdrop: TextureRect


func on_preload(preload_request: PreloadRequest, _prefill_items: Array[PrefillItem]) -> void:
	CommonCardView.preload_art(preload_request)
	preload_request.add_item(ResourceKey.BACKGROUND__LOBBY, ResourceCore.BaseKind.TEXTURE_2D)
	preload_request.add_item(ResourceKey.IMAGE__HERO_PLAYER, ResourceCore.BaseKind.TEXTURE_2D)
	preload_request.add_item(ResourceKey.BGM__LOBBY, ResourceCore.BaseKind.AUDIO_STREAM)


func on_start() -> void:
	backdrop.texture = CommonCardView.texture(ResourceKey.BACKGROUND__LOBBY, scope)
	SoundCore.play_bgm(ResourceKey.BGM__LOBBY, scope)
