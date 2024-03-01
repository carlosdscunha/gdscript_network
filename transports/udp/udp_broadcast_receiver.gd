class_name UDPBroadcastReceiver
extends Node

const BROADCAST_PORT: int = 12345

var _udp: PacketPeerUDP


func _init() -> void:
	_udp = PacketPeerUDP.new()
	var bind_result := _udp.bind(BROADCAST_PORT)
	if bind_result == OK:
		NetworkLogger.Log(
			Enums.LogTypes.INFO,
			"Socket UDP vinculado com sucesso e porta " + str(BROADCAST_PORT),
			"BroadcastReceive"
		)
		NetworkLogger.Log(
			Enums.LogTypes.INFO,
			"Aguardando a recepcao do broadcast por 5 segundos...",
			"BroadcastReceive"
		)
		Interval.singleton.new_callback(_receive_callback, 1)
		Interval.singleton.new_callback(_error, 10, true)
	else:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR,
			"Falha ao vincular o socket UDP e porta " + str(BROADCAST_PORT),
			"BroadcastReceive"
		)


func _receive_callback() -> void:
	if _udp.get_available_packet_count() > 0:
		var data: PackedByteArray = _udp.get_packet()
		var endpoint: String = _udp.get_packet_ip()
		var message: String = data.get_string_from_utf8()

		if message == "MyServerIdentifier":
			NetworkLogger.Log(Enums.LogTypes.INFO, str(endpoint), "BroadcastReceive")
			#NetworkManager.singleton.ip = endpoint
			#NetworkManager.singleton.connect_server()
			_close()


func _error() -> void:
	NetworkLogger.Log(
		Enums.LogTypes.WARNING, "Nao recebido por 10 segundos, Sem conexao", "BroadcastReceive"
	)
	UIManager.singleton.show_ui_connect("Nao recebido por 10 segundos, Sem conexao")
	_close()
	Interval.singleton.stop_callback(_error)


func _close() -> void:
	_udp.close()
	Interval.singleton.stop_callback(_error)
	Interval.singleton.stop_callback(_receive_callback)
	NetworkLogger.Log(Enums.LogTypes.INFO, "Fechado Broadcast Receive")
