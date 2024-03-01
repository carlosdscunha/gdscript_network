## Um servidor que pode aceitar conexoes de `UdpClients`.
class_name UdpServer
extends UdpPeer

## Invocado quando uma conexao e estabelecida no nivel de transporte.
## `event EventHandler<ConnectedEventArgs> Connected`
signal connected(e: ConnectedEventArgs)
## Invocado quando os dados sao recebidos pelo transporte.
## `event EventHandler<DataReceivedEventArgs> DataReceived;`
signal data_received(e: DataReceivedEventArgs)

## A porta local na qual o servidor esta sendo executado
var port: int:
	get:
		return _port
var _port: int

## As conexoes atualmente abertas, acessiveis por seus terminais.
var _connections: Dictionary


func _init(
	_mode: Enums.SocketMode = Enums.SocketMode.BOTH,
	socketBufferSize: int = default_socket_buffer_size
):
	super._init(_mode, socketBufferSize)


## Inicia o transporte e comeca a ouvir as conexoes de entrada.
## - `port_`: A porta local na qual escutar as conexoes.
func start(port_: int) -> void:
	_port = port_
	_connections = Dictionary()

	open_socket(port)


## Decide o que fazer com uma tentativa de conexao.
## - `connection`: A conexao para aceitar ou rejeitar.
## - `returns`: Se a tentativa de conexao foi ou nao uma nova conexao.
func _handle_connection_attempt(connection: UdpConnection) -> bool:
	if _connections.has(connection.remote_end_point._to_string()):
		return false

	NetworkLogger.Log(
		Enums.LogTypes.DEBUG, "new conection: " + connection.remote_end_point._to_string()
	)
	_connections[connection.remote_end_point._to_string()] = connection
	_on_connected(connection)
	return true


## Fecha uma conexao ativa.
## - `connection`: A conexao a ser fechada.
func close(connection: Connection) -> void:
	if connection is UdpConnection:
		_connections.erase(connection.remote_end_point._to_string())


## Fecha todas as conexoes existentes e para de ouvir novas conexoes.
func shutdown() -> void:
	close_socket()
	_connections.clear()


## Invoca o evento `Connected`.
## - `connection`: A conexao estabelecida com sucesso.
func _on_connected(connection: Connection) -> void:
	connected.emit(ConnectedEventArgs.new(connection))


func _on_data_received(
	data_buffer: PackedByteArray, amount: int, from_end_point: IPEndPoint
) -> void:
	if (
		data_buffer[0] == Enums.MessageHeader.CONNECT
		and not _handle_connection_attempt(UdpConnection.new(from_end_point, self))
	):
		return

	if _connections.has(from_end_point._to_string()):
		var connection: Connection = _connections.get(from_end_point._to_string())
		data_received.emit(DataReceivedEventArgs.new(data_buffer, amount, connection))
	
