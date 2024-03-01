class_name TcpClient
extends TcpPeer

## Invocado quando uma conexao e estabelecida no nivel de transporte.
signal connected
## Invocado quando uma tentativa de conexao falha no nivel de transporte.
signal connection_failed
## Invocado quando os dados sao recebidos pelo transporte.
signal data_received(e: DataReceivedEventArgs)

var _tcp_connection: TcpConnection

# var _sockett: StreamPeerTCP


## Inicia o transporte e tenta se conectar ao endereco de host fornecido.
## - `host_address`: O endereco do host ao qual se conectar.
## - `connection`: A conexao pendente. `null` se ocorreu um problema.
## - `connectError`: A mensagem de erro associada ao problema que ocorreu, se houver.
## - `returns`: `true` se uma tentativa de conexao for feita. `false` se ocorrer um problema (como `hostAddress` estar em um formato invalido) e uma tentativa de conexao <i>nao</i> sera feita.
func connect_host(host_address: String) -> OutConnect:
	var out := OutConnect.new()

	out.connect_error = (
		"Endereco de host invalido '"
		+ host_address
		+ "'! IP e porta devem ser separados por dois pontos, por exemplo: '127.0.0.1:7777'."
	)
	var parse: OutAddress = _parse_host_address(host_address)
	if not parse.is_success:
		out.connection = null
		out.is_success = false
		return out

	var remote_end_point: IPEndPoint = IPEndPoint.new(parse.ip, parse.port)

	_socket = StreamPeerTCP.new()

	if _socket.connect_to_host(remote_end_point.address, remote_end_point.port) != OK:
		NetworkLogger.Log(Enums.LogTypes.ERROR, "Erro ao criar o socket", "TCP Client socket")

	_tcp_connection = TcpConnection.new(_socket, remote_end_point, self)
	out.connection = _tcp_connection
	_on_connected()
	out.is_success = true

	return out


func _parse_host_address(host_address: String) -> OutAddress:
	var out: OutAddress = OutAddress.new()

	var ip_and_port: Array = host_address.split(":")
	var ip_string: String = ""
	var port_string: String = ""

	if ip_and_port.size() > 2:
		# Havia mais de um ':' no endereco do host, pode ser IPv6
		ip_string = ":".join(ip_and_port.slice(0, ip_and_port.size() - 1))
		port_string = ip_and_port[ip_and_port.size() - 1]
		out.address_family = "IPv6"
	elif ip_and_port.size() == 2:
		# IPv4
		ip_string = ip_and_port[0]
		port_string = ip_and_port[1]
		out.address_family = "IPv4"

	# Precisa garantir que um valor seja atribuido caso a analise de IP falhe
	out.port = 0

	if ip_string.is_valid_ip_address():
		out.ip = ip_string
		if port_string.is_valid_int():
			out.port = int(port_string)
			out.is_success = true

	return out


## Inicia o tratamento de qualquer mensagem recebida.
func poll():
	if _tcp_connection != null:
		_tcp_connection.receive()


## Fecha a conexao com o servidor.
func disconnect_host() -> void:
	_socket.disconnect_from_host()
	_tcp_connection = null


func _on_connected() -> void:
	if not connected.is_null():
		connected.emit()


func _on_connection_failed() -> void:
	if not connection_failed.is_null():
		connection_failed.emit()


func _on_data_received(amount: int, from_connection: TcpConnection):
	if not data_received.is_null():
		data_received.emit(DataReceivedEventArgs.new(receive_buffer, amount, from_connection))
