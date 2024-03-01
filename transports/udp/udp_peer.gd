## Fornece envio base &#38; receba funcionalidade para `UdpServer` e `UdpClient`.
class_name UdpPeer

## Invocado quando uma desconexao e iniciada ou detectada pelo transporte.
signal disconnected(e: TDisconnectedEventArgs)

## O tamanho padrao usado para os buffers de envio e recebimento do soquete.
const default_socket_buffer_size: int = 1024 * 1024  # 1MB
## O tamanho minimo que pode ser usado para os buffers de envio e recebimento do soquete.
const _min_socket_buffer_size: int = 256 * 1024  # 256KB
## Quanto tempo esperar por um pacote, em microssegundos.
const _receive_polling_time: int = 500000  # 0,5 segundos

## Se deseja criar apenas IPv4, somente IPv6 ou soquete de modo duplo.
var mode: Enums.SocketMode
## O tamanho a ser usado para os buffers de envio e recebimento do soquete.
var _socket_buffer_size: int
## O array no qual os dados de entrada sao recebidos.
var _received_data: PackedByteArray
## O soquete a ser usado para enviar e receber.
var _socket: PacketPeerUDP
## Se o transporte esta em execuca ou nao.
var _is_running: bool
## Um endpoint reutilizavel.
var _remote_end_point: IPEndPoint


## Inicializa o transporte.
## -`_mode`: Se deseja criar um soquete somente IPv4, somente IPv6 ou modo dual.
## -`socket_buffer_size`: Qual deve ser o tamanho dos buffers de envio e recebimento do soquete.
func _init(_mode: Enums.SocketMode, socket_buffer_size: int):
	if socket_buffer_size < _min_socket_buffer_size:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			(
				"[socket_buffer_size]: O tamanho minimo do buffer de soquete e "
				+ str(_min_socket_buffer_size)
				+ "!"
			)
		)

	mode = _mode
	_socket_buffer_size = socket_buffer_size
	_received_data = PackedByteArray()
	_received_data.resize(Message.max_size + sizeof.SHORT)


## Inicia o tratamento de qualquer mensagem recebida.
func poll() -> void:
	_receive()


## Abre o socket e inicia o transporte.
## - `port`: A porta para vincular o soquete.
func open_socket(port: int = 0) -> void:
	if _is_running:
		close_socket()

	if mode == Enums.SocketMode.IP_V4_ONLY:
		_socket = PacketPeerUDP.new()
		_socket.bind(port, "0.0.0.0", _socket_buffer_size)
		_remote_end_point = IPEndPoint.new("0.0.0.0", 0)
	elif mode == Enums.SocketMode.IP_V6_ONLY:
		_socket = PacketPeerUDP.new()
		_socket.bind(port, "::", _socket_buffer_size)
		_remote_end_point = IPEndPoint.new("::", 0)
	else:
		_socket = PacketPeerUDP.new()
		_socket.bind(port, "*", _socket_buffer_size)
		_remote_end_point = IPEndPoint.new("*", 0)

	# _socket.encode_buffer_max_size = _socket_buffer_size

	_is_running = true


## Fecha o soquete e interrompe o transporte.
func close_socket() -> void:
	if not _is_running:
		return

	_is_running = false
	_socket.close()


## Pesquisa o soquete e verifica se algum dado foi recebido.
func _receive() -> void:
	if not _is_running:
		return

	while _socket.get_available_packet_count() > 0:
		# var byte_count = _socket_receive_from(_socket, _remote_end_point)
		_socket_receive_from(_socket)

		# if byte_count > 0:
		# 	_on_data_received(_received_data, byte_count, _remote_end_point)


# func _socket_receive_from(packet_peer: PacketPeerUDP, remote_e_p: IPEndPoint) -> int:
# 	var buffer := packet_peer.get_packet()
# 	var bytes_read := buffer.size()

# 	for i in range(bytes_read):
# 		_received_data[i] = buffer[i]

# 	remote_e_p.address = packet_peer.get_packet_ip()
# 	remote_e_p.port = packet_peer.get_packet_port()
# 	return bytes_read


func _socket_receive_from(packet_peer: PacketPeerUDP) -> void:
	var buffer := packet_peer.get_packet()
	var bytes_read := buffer.size()

	for i in range(bytes_read):
		_received_data[i] = buffer[i]

	var remote_e_p := IPEndPoint.new(packet_peer.get_packet_ip(), packet_peer.get_packet_port())
	_on_data_received(_received_data, bytes_read, remote_e_p)


## Envia dados para um determinado endpoint.
## - `data_buffer`: O array que contem os dados.
## - `_num_bytes`: O numero de bytes no array que deve ser enviado.
## - `to_end_point`: O endpoint para o qual enviar os dados.
func send(data_buffer: PackedByteArray, _num_bytes: int, to_end_point: IPEndPoint) -> void:
	if _is_running:
		_socket_send_to(data_buffer, _num_bytes, to_end_point)


func _socket_send_to(buffer: PackedByteArray, size: int, remote_e_p: IPEndPoint) -> void:
	var send_buffer := PackedByteArray()
	send_buffer.resize(size)

	ArrayUtil.copy(buffer, send_buffer, size)
	_socket.set_dest_address(remote_e_p.address, remote_e_p.port)
	_socket.put_packet(send_buffer)


@warning_ignore("unused_parameter")
## Trata os dados recebidos.
## - `data_buffer`: Um array de bytes contendo os dados recebidos.
## - `amount`: O numero de bytes em `_data_buffer` usado pelos dados recebidos.
## - `from_end_point`: O endpoint do qual os dados foram recebidos.
func _on_data_received(
	data_buffer: PackedByteArray, amount: int, from_end_point: IPEndPoint
) -> void:
	print("_on_data_received = pass")


## Invoca o evento `Disconnected`.
## - `connection`: A conexao fechada.
## - `reason`: O motivo da desconexao.
func _on_disconnected(connection: Connection, reason: Enums.DisconnectReason) -> void:
	disconnected.emit(TDisconnectedEventArgs.new(connection, reason))
