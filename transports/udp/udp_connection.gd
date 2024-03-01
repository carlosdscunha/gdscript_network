## Representa uma conexao com um `UdpServer` ou `UdpClient`.
class_name UdpConnection
extends Connection

## O terminal que representa a outra extremidade da conexao.
var remote_end_point: IPEndPoint

## O par local ao qual esta conexao esta associada.
var _peer: UdpPeer


## Inicializa a conexao.
## - `_remote_end_point`: O endpoint que representa a outra extremidade da conexao.
## - `peer_`: O par local ao qual esta conexao esta associada.
func _init(_remote_end_point: IPEndPoint, peer_: UdpPeer):
	super._init()
	remote_end_point = _remote_end_point
	_peer = peer_


func _send_d(data_buffer: PackedByteArray, amount: int) -> void:
	_peer.send(data_buffer, amount, remote_end_point)


func _to_string():
	return Extensions.to_string_based_on_ip_format(remote_end_point)


func equals(other: UdpConnection) -> bool:
	if other == null:
		return false

	if self == other:
		return true

	return remote_end_point.equals(other.remote_end_point)
