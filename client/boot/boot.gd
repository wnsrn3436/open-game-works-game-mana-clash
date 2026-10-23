extends Node


func _ready() -> void:
	BootstrapCore.start_boot.call_deferred(ContentBoot.new())
