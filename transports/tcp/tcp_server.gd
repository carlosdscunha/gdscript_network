## Um servidor que pode aceitar conexoes de TcpClients.
class_name TcpServer
extends TcpPeer

## Invocado quando uma conexao e estabelecida no nivel de transporte.
## `event EventHandler<ConnectedEventArgs> Connected`
signal connected(e: ConnectedEventArgs)
## Invocado quando os dados sao recebidos pelo transporte.
## `event EventHandler<DataReceivedEventArgs> DataReceived;`
signal data_received(e: DataReceivedEventArgs)

## A porta local na qual o servidor esta sendo executado.
var port: int:
	get:
		return _port
var _port: int
## O numero maximo de conexoes pendentes a serem permitidas a qualquer momento.
var max_pending_connections: int:
	get:
		return _max_pending_connections
var _max_pending_connections: int = 5

## Se o servidor esta em execucao ou nao.
var _is_running = false
## As conexoes atualmente abertas, acessiveis por seus terminais.
var _connections: Dictionary
## Conexoes que precisam ser fechadas.
var _closed_connections: List = List.new()


func _init(socket_buffer_size: int = _default_socket_buffer_size):
	super._init(socket_buffer_size)


## Inicia o transporte e comeca a ouvir as conexoes de entrada.
## - `port_`: A porta local na qual escutar as conexoes.
func start(port_: int) -> void:
	_port = port_
	_connections = Dictionary()

	_start_listening(port_)


## Inicia a escuta de conexoes na porta fornecida.
## - `port_`: A porta para escutar.
func _start_listening(port_: int) -> void:
	if _is_running:
		_stop_listening()

	var local_end_point := IPEndPoint.new("0.0.0.0", port_)
	_socket = TCPServer.new()

	if _socket.listen(local_end_point.port, local_end_point.address) == OK:
		_is_running = true
	else:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR,
			"Falha ao iniciar o servidor na porta " + str(local_end_point.port),
			"TCP Server listen"
		)


## Inicia o tratamento de qualquer mensagem recebida.
func poll():
	if not _is_running:
		return

	_accept()
	for connection in _connections.values() as Array[TcpConnection]:
		connection.receive()

	for end_point in _closed_connections.values() as Array[IPEndPoint]:
		_connections.erase(end_point)

	_closed_connections.clear()


## Aceita qualquer conexao pendente.
func _accept() -> void:
	if _socket.is_connection_available():
		var accepted_socket: StreamPeerTCP = _socket.take_connection()
		var from_end_point := IPEndPoint.new(
			accepted_socket.get_connected_host(), accepted_socket.get_connected_port()
		)
		if not _connections.has(from_end_point):
			var new_connection := TcpConnection.new(accepted_socket, from_end_point, self)
			_connections[from_end_point] = new_connection
			_on_connected(new_connection)


## Parar de ouvir as conexoes.
func _stop_listening() -> void:
	if not _is_running:
		return

	_is_running = false
	_socket.stop()


## Fecha uma conexao ativa.
## - `connection`: A conexao a ser fechada.
func close(connection: Connection) -> void:
	if connection is TcpConnection:
		var tcp_connection: TcpConnection = connection as TcpConnection
		_closed_connections.add(tcp_connection.remote_end_point)
		tcp_connection.close()


## Fecha todas as conexoes existentes e para de ouvir novas conexoes.
func shutdown():
	_stop_listening()
	_connections.clear()


## Invoca o evento `connected`.
## - `connection`: A conexao estabelecida com sucesso.
func _on_connected(connection: Connection) -> void:
	if not connected.is_null():
		connected.emit(ConnectedEventArgs.new(connection))


func _on_data_received(amount: int, from_connection: TcpConnection):
	if not data_received.is_null():
		data_received.emit(DataReceivedEventArgs.new(receive_buffer, amount, from_connection))
