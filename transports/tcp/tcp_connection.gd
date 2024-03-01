## Representa uma conexao com um `TcpServer` ou `TcpClient`.
class_name TcpConnection
extends Connection

## O terminal que representa a outra extremidade da conexao.
var remote_end_point: IPEndPoint

## O PacketPeerStream a ser usado para enviar e receber.
var _socket: StreamPeerTCP
## O par local ao qual esta conexao esta associada.
var _peer: TcpPeer
## O status da conexao
var _status: int

## O array no qual os dados de entrada sao recebidos.
var _received_data: PackedByteArray = PackedByteArray()
## Um array para receber valores de tamanho de mensagem.
var _size_bytes: PackedByteArray = PackedByteArray()
## O tamanho da proxima mensagem a ser recebida.
var _next_message_size: int


## Inicializa a conexao.
## - `socket`: O soquete a ser usado para enviar e receber.
## - `_remote_end_point`: O endpoint que representa a outra extremidade da conexao.
## - `peer`: O par local ao qual esta conexao esta associada.
func _init(socket: StreamPeerTCP, _remote_end_point: IPEndPoint, peer_: TcpPeer):
	super._init()
	remote_end_point = _remote_end_point
	_socket = socket
	_status = socket.get_status()
	_peer = peer_
	_size_bytes.resize(sizeof.SHORT)


func _send_d(data_buffer: PackedByteArray, amount: int):
	if amount == 0:
		NetworkLogger.Log(Enums.LogTypes.THROW, "[amount]: O envio de 0 bytes nao e permitido!")

	_socket.poll()
	_status = _socket.get_status()
	if _status == StreamPeerTCP.STATUS_CONNECTED:
		Converter.from_short(amount, _peer.send_buffer, 0)

		ArrayUtil.copy(data_buffer, 0, _peer.send_buffer, sizeof.SHORT, amount)  # TODO: considere enviar o comprimento separadamente com um soquete extra.Enviar chamada em vez de copiar os dados mais uma vez
		_socket_send(_peer.send_buffer, amount + sizeof.SHORT)


func _socket_send(buffer: PackedByteArray, size: int) -> void:
	var send_buffer := PackedByteArray()
	send_buffer.resize(size)

	ArrayUtil.copy(buffer, send_buffer, size)
	var error := _socket.put_data(send_buffer)
	if error != OK:
		printerr("Error writing to stream: ", error)


## Pesquisa o soquete e verifica se algum dado foi recebido.
func receive() -> void:
	var try_receive_more: bool = true

	while try_receive_more:
		_socket.poll()
		_status = _socket.get_status()

		match _status:
			StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
				try_receive_more = false
				_peer._on_disconnected(self, Enums.DisconnectReason.TRANSPORT_ERROR)
			not StreamPeerTCP.STATUS_CONNECTED:
				try_receive_more = false
				_peer._on_disconnected(self, Enums.DisconnectReason.DISCONNECTED)
			StreamPeerTCP.STATUS_CONNECTED:
				var bytes := _socket.get_available_bytes()
				if bytes > 0:
					var data := _socket.get_data(bytes)
					if data[0] != OK:
						printerr("Error received data: ", data[1])
					_received_data.append_array(data[1])

		var byte_count: int = 0
		if _next_message_size > 0:
			var try := _try_receive_message()
			# Ja temos um valor de tamanho
			try_receive_more = try.is_success
			byte_count = try.received_byte_count

		elif _received_data.size() >= sizeof.SHORT:
			# Temos bytes suficientes para um valor de tamanho completo
			_socket_receive(_size_bytes, 0, sizeof.SHORT)

			_next_message_size = Converter.to_short(_size_bytes, 0)

			if _next_message_size > 0:
				var try: TryReceive = _try_receive_message()
				try_receive_more = try.is_success
				byte_count = try.received_byte_count
		else:
			try_receive_more = false

		if byte_count > 0:
			_peer._on_data_received(byte_count, self)


func _try_receive_message() -> TryReceive:
	var try := TryReceive.new()

	if _received_data.size() >= _next_message_size:
		# Temos bytes suficientes para ler a mensagem completa
		try.received_byte_count = _socket_receive(_peer.receive_buffer, 0, _next_message_size)
		_next_message_size = 0
		try.is_success = true
		return try

	try.received_byte_count = 0
	try.is_success = false
	return try


func _socket_receive(buffer: PackedByteArray, offset: int, size: int) -> int:
	var data_count: int = _received_data.size()
	var bytes_read: int = mini(size, data_count)

	ArrayUtil.copy(_received_data, 0, buffer, offset, bytes_read)

	_received_data = _received_data.slice(bytes_read, _received_data.size())
	return bytes_read


## Fecha a conexao.
func close() -> void:
	_socket.disconnect_from_host()


func _to_string():
	return Extensions.to_string_based_on_ip_format(remote_end_point)
