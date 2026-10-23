extends DevRegistrationList


func register_all() -> void:
	BattleDev.register()
	LobbyDev.register()
	TitleDev.register()
