## Um cliente que pode se conectar a um `UdpServer`.
class_name UdpClient
extends UdpPeer

## Invocado quando uma conexao e estabelecida no nivel de transporte.
signal connected

## Invocado quando uma tentativa de conexao falha no nivel de transporte.
signal connection_failed

## Invocado quando os dados sao recebidos pelo transporte.
## `event EventHandler<DataReceivedEventArgs> DataReceived;`
signal data_received(e: DataReceivedEventArgs)

## A conexao com o servidor.
var _udp_connection: UdpConnection


func _init(
	mode_: Enums.SocketMode = Enums.SocketMode.BOTH,
	socket_buffer_size: int = default_socket_buffer_size
):
	super._init(mode_, socket_buffer_size)


## Inicia o transporte e tenta se conectar ao endereco de host fornecido.
## Espera que o endereco do host consista em um IP e uma porta, separados por dois pontos. Por exemplo: `127.0.0.1:7777`.
## - `host_address`: O endereco do host ao qual se conectar.
## - `connection`: A conexao pendente. `null` se ocorreu um problema.
## - `connectError`: A mensagem de erro associada ao problema que ocorreu, se houver.
## - `returns`: `true` se uma tentativa de conexao for feita. `false` se ocorrer um problema (como `host_address` estar em um formato invalido) e uma tentativa de conexao <i>nao</i> sera feita.
func connect_host(host_address: String) -> OutConnect:
	var out: OutConnect = OutConnect.new()

	out.connect_error = (
		"Endereco de host invalido '"
		+ host_address
		+ "'! IP e porta devem ser separados por dois pontos, por exemplo: '127.0.0.1:7777'."
	)
	var parse := _parse_host_address(host_address)
	if not parse.is_success:
		out.connection = null
		out.is_success = false
		return out

	if (
		(mode == Enums.SocketMode.IP_V4_ONLY and parse.address_family == "IPv6")
		or (mode == Enums.SocketMode.IP_V6_ONLY and parse.address_family == "IPv4")
	):
		# O endereco IP nao esta em um formato aceitavel para o modo de soquete atual
		if mode == Enums.SocketMode.IP_V4_ONLY:
			out.connect_error = "A conexao com enderecos IPv6 nao e permitida durante a execucao no modo somente IPv4!"
		else:
			out.connect_error = "A conexao com enderecos IPv4 nao e permitida durante a execucao no modo somente IPv6!"

		out.connection = null
		out.is_success = false
		return out

	open_socket()

	_udp_connection = UdpConnection.new(IPEndPoint.new(parse.ip, parse.port), self)
	out.connection = _udp_connection
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


## Fecha a conexao com o servidor.
func disconnect_host() -> void:
	close_socket()


## Invoca o evento `connected`.
func _on_connected() -> void:
	connected.emit()


## Invoca o evento `connection_failed`.
func _on_connection_failed():
	connection_failed.emit()


func _on_data_received(data_buffer: PackedByteArray, amount: int, from_end_point: IPEndPoint):
	if _udp_connection.remote_end_point.equals(from_end_point):
		data_received.emit(DataReceivedEventArgs.new(data_buffer, amount, _udp_connection))
