class_name UDPBroadcastSender
extends Node

const BROADCAST_PORT: int = 12345
const _server_identifier: String = "MyServerIdentifier"

var _socket: PacketPeerUDP
var _data: PackedByteArray


func _init():
	_socket = PacketPeerUDP.new()
	_socket.set_broadcast_enabled(true)
	_socket.set_dest_address("255.255.255.255", BROADCAST_PORT)

	_data = _server_identifier.to_utf8_buffer()

	Interval.singleton.new_callback(_send_broadcast, 5.0)
	NetworkLogger.Log(Enums.LogTypes.INFO, "Broadcast started", "BroadcastSender")
	_send_broadcast()


func _send_broadcast():
	_socket.put_packet(_data)
	# NetworkLogger.Log(Enums.LogTypes.INFO, "Broadcast send", "BroadcastSender")


func stop():
	Interval.singleton.stop_callback(_send_broadcast)
	_socket.close()
	NetworkLogger.Log(Enums.LogTypes.INFO, "Fechado Broadcast", "BroadcastSender")
