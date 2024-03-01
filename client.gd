## Um cliente que pode se conectar a um [Server].
class_name Client
extends Peer

## Invocado quando uma conexao com o servidor e estabelecida.
signal connected
## Invocado quando uma conexao com o servidor falha ao ser estabelecida.
## EventHandler<ConnectionFailedEventArgs>
signal connection_failed(e: ConnectionFailedEventArgs)
## Invocado quando uma mensagem e recebida.
## EventHandler<MessageReceivedEventArgs>
signal message_received(e: MessageReceivedEventArgs)
## Invocado quando desconectado do servidor.
## EventHandler<DisconnectedEventArgs>
signal disconnected(e: DisconnectedEventArgs)
## Invocado quando outro cliente <i>nao local</i> se conecta.
## EventHandler<ClientConnectedEventArgs>
signal client_connected(e: ClientConnectedEventArgs)
## Invocado quando outro cliente <i>nao local</i> se desconecta.
## EventHandler<ClientDisconnectedEventArgs>
signal client_disconnected(e: ClientDisconnectedEventArgs)

## O ID numerico do cliente.
var id: int:
	get:
		return _connection.id
## O tempo de ida e volta (ping) da conexao, em milissegundos. -1 se ainda nao calculado.
var RTT: int:
	get:
		return _connection.RTT
## O tempo de ida e volta suavizado (ping) da conexao, em milissegundos. -1 se ainda nao calculado.
## Este valor e mais lento para representar com precisao alteraces duradouras na latencia do que [RTT], mas e menos suscetivel a mudancas drasticas devido a saltos significativos, mas temporarios, na latencia.
var smooth_RTT: int:
	get:
		return _connection.smooth_RTT


## Define o [Connection.timeout_time] do cliente.
func timeout_time(value: int):
	_connection.timeout_time = value


## Se o cliente atualmente <i>nao</i> esta conectado ou tentando se conectar.
var is_not_connected: bool:
	get:
		return _connection == null or _connection.is_not_connected
## Se o cliente esta ou nao em processo de conexao.
var is_connecting: bool:
	get:
		return not (_connection == null) and _connection.is_connecting
## Se a conexao do cliente esta pendente ou nao (so sera [true] quando um servidor nao aceitar imediatamente a solicitacao de conexao).
var is_pending: bool:
	get:
		return not (_connection == null) and _connection.is_pending
## Se o cliente esta ou nao conectado no momento.
var isconnected: bool:
	get:
		return not (_connection == null) and _connection.isconnected
## A conexao do cliente com um servidor.
## Nao e uma propriedade automatica porque as propriedades nao podem ser passadas como parametros ref/out. Poderia use uma variavel local no metodo Connect, mas isso provavelmente nao e nada mais limpo. Esse propriedade tambem provavelmente sera usada apenas raramente de fora da classe/biblioteca.
var connection: Connection:
	get:
		return _connection
# @warning_ignore("unused_parameter")
# ## Encapsula um metodo que manipula uma mensagem de um servidor.
# ## - `message`: A mensagem que foi recebida.
# var message_handler := func(message: Message) -> void: pass

## A conexao do cliente com um servidor.
var _connection: Connection
## Quantas tentativas de conexao foram feitas ate agora.
var _connection_attempts: int
## Quantas tentativas de conexao fazer antes de desistir.
var _max_connection_attempts: int
## Metodos usados para lidar com mensagens, acessiveis por seus IDs de mensagem correspondentes.
var _message_mandlers: Dictionary
## O cliente de transporte subjacente que e usado para enviar e receber dados.
var _transport = null
## Dados personalizados a serem incluidos na conexao.
var _connect_bytes


## Lida com a configuracao inicial.
## - `transport`: O transporte a ser usado para enviar e receber dados.
## - `log_name_`: O nome a ser usado ao registrar mensagens via `NetworkLogger`.
func _init(transport: Variant, log_name_: String = "CLIENT"):
	super._init(log_name_)
	if transport is TcpClient:
		_transport = transport
	elif transport is UdpClient:
		_transport = transport
	else:
		NetworkLogger.Log(
			Enums.LogTypes.THROW, "transport type para TcpClient ou UdpClient", log_name
		)


## Desconecta o cliente se estiver conectado e troca o transporte que esta usando.
## - `new_transport`: O novo transporte a ser usado para enviar e receber dados.
## Este metodo nao se reconecta automaticamente ao servidor. Para continuar a comunicacao com o servidor, [Connect(string, int, byte, Message)] deve ser chamado novamente.
func change_transport(new_transport: Variant) -> void:
	disconnect_host()
	if new_transport is TcpClient:
		_transport = new_transport
	elif new_transport is UdpClient:
		_transport = new_transport
	else:
		NetworkLogger.Log(
			Enums.LogTypes.THROW, "new_transport type para TcpClient ou UdpClient", log_name
		)


## Tenta se conectar a um servidor no endereco de host fornecido.
## - `host_address`: O endereco do host ao qual se conectar.
## - `max_client_count_`: Quantas tentativas de conexao fazer antes de desistir.
## - `message_handler_group_id`: O ID do grupo de metodos do manipulador de mensagem a ser usado ao criar <see cref="messageHandlers"/>.
## - `message`: Dados que devem ser enviados ao servidor com a tentativa de conexao. Use <see cref="Message.Create()"/> para obter uma instancia de mensagem vazia.
## - `_use_message_handlers`: Se o servidor deve ou nao usar o sistema interno de tratamento de mensagens.
## <remarks>O transporte padrao do Network espera que o endereco do host consista em um IP e uma porta, separados por dois pontos. Por exemplo: <c>127.0.0.1:7777</c>. Se voce estiver usando um transporte diferente, verifique a documentacao relevante para saber quais informacoes sao necessarias no endereco do host.</remarks>
## <see langword="true"/> se uma tentativa de conexao for feita. <see langword="false"/> se ocorrer um problema (como <paramref name="hostAddress"/> estar em um formato invalido) e uma tentativa de conexao <i>nao</i> sera feita.
func connect_to_host(
	host_address: HostAddress,
	max_client_count_: int = 5,
	message_handler_group_id: int = 0,
	message: Message = null,
	_use_message_handlers: bool = true
) -> bool:
	disconnect_host()

	_sub_to_transport_events()

	var out: OutConnect = _transport.connect_host(host_address.to_address())

	if not out.is_success:
		NetworkLogger.Log(Enums.LogTypes.ERROR, out.connect_error, log_name)
		_unsub_from_transport_events()
		return false

	_connection = out.connection

	_max_connection_attempts = max_client_count_
	_connection_attempts = 0
	_connection.peer = self
	Client._increase_active_count()
	use_message_handlers = _use_message_handlers
	if _use_message_handlers:
		_create_message_handlers_dictionary(message_handler_group_id)

	if message != null:
		_connect_bytes = message.get_bytes(message.written_length)
		message.release()
	else:
		_connect_bytes = null

	_heartbeat()
	NetworkLogger.Log(Enums.LogTypes.INFO, "Conectando-se a " + str(_connection) + "...", log_name)
	return true


## Inscreve metodos apropriados para os eventos de transporte.
func _sub_to_transport_events() -> void:
	_transport.connected.connect(_transport_connected)
	_transport.connection_failed.connect(_transport_connection_failed)
	_transport.data_received.connect(_handle_data)
	_transport.disconnected.connect(_transport_disconnected)


## Cancela a assinatura de metodos de todos os eventos de transporte.
func _unsub_from_transport_events() -> void:
	_transport.connected.disconnect(_transport_connected)
	_transport.connection_failed.disconnect(_transport_connection_failed)
	_transport.data_received.disconnect(_handle_data)
	_transport.disconnected.disconnect(_transport_disconnected)


func _create_message_handlers_dictionary(message_handler_group_id: int):
	var functions: Array[GetFunctionInfo] = _find_message_handlers()

	_message_mandlers = Dictionary()
	for function in functions:
		var attribute := function.mh_info
		if attribute.group_id != message_handler_group_id:
			continue

		var client_message_handler := function
		if _message_mandlers.has(attribute.message_id):
			var other_method_with_id: GetFunctionInfo = _message_mandlers[attribute.message_id]
			if other_method_with_id:
				NetworkLogger.Log(
					Enums.LogTypes.THROW,
					(
						DuplicateHandlerException
						. new(attribute.message_id, function, other_method_with_id)
						. message
					)
				)
		else:
			var message_handle: GetFunctionInfo = client_message_handler
			message_handle.value = function.value
			_message_mandlers[attribute.message_id] = message_handle

	if NetworkLogger.is_warning_logging_enabled:
		print_rich("[b]======= CLIENT =======[/b]")
	NetworkLogger.table(ArrayUtil.to_array_dictionary(functions), ["mh_info"])
	NetworkLogger.to_tabel(_message_mandlers, message_handler_group_id)


func _heartbeat():
	if is_connecting:
		## Se ainda estiver tentando se conectar, envie mensagens de conexao em vez de heartbeats
		if _connection_attempts < _max_connection_attempts:
			var message := Message.create(Enums.MessageHeader.CONNECT)
			if _connect_bytes != null:
				message.add_bytes(_connect_bytes, false)

			send(message)
			_connection_attempts += 1
		else:
			_local_disconnect(Enums.DisconnectReason.NEVER_CONNECTED)
	elif is_pending:
		## Se estiver esperando o servidor aceitar/rejeitar a tentativa de conexao
		if _connection.has_connect_attempt_timed_out:
			_local_disconnect(Enums.DisconnectReason.TIMED_OUT)
			return
	elif isconnected:
		## Se conectado e sem tempo esgotado, envia pulsacoes
		if _connection.has_timed_out:
			_local_disconnect(Enums.DisconnectReason.TIMED_OUT)
			return

		_connection.send_heartbeat()

	execute_later(heartbeat_interval, HeartbeatEvent.new(self))


func _update():
	super._update()
	_transport.poll()
	_handle_messages()


func _handle(message: Message, header: Enums.MessageHeader, connection_: Connection):
	match header:
		# mensagens do usuario
		Enums.MessageHeader.UNRELIABLE, Enums.MessageHeader.RELIABLE:
			_on_message_received(message)

		# mensagens internas
		Enums.MessageHeader.ACK:
			connection_.handle_ack(message)
		Enums.MessageHeader.ACK_EXTRA:
			connection_.handle_ack_extra(message)
		Enums.MessageHeader.CONNECT:
			connection_.set_pending()
		Enums.MessageHeader.REJECT:
			if not isconnected:  ## Nao desconecta se estivermos conectados
				_local_disconnect(
					Enums.DisconnectReason.CONNECTION_REJECTED,
					message,
					message.get_byte() as Enums.RejectReason
				)
		Enums.MessageHeader.HEARTBEAT:
			connection_.handle_heartbeat_response(message)
		Enums.MessageHeader.DISCONNECT:
			_local_disconnect(message.get_byte() as Enums.DisconnectReason, message)
		Enums.MessageHeader.WELCOME:
			if is_connecting or is_pending:
				connection_.handle_welcome(message)
				_on_connected()
		Enums.MessageHeader.CLIENT_CONNECTED:
			_on_client_connected(message.get_short())
		Enums.MessageHeader.CLIENT_DISCONNECTED:
			_on_client_disconnected(message.get_short())
		_:
			NetworkLogger.Log(
				Enums.LogTypes.WARNING,
				(
					"Cabecalho de mensagem inesperado '"
					+ str(header)
					+ "'! Descartando "
					+ str(message.written_length)
					+ " bytes."
				),
				log_name
			)

	message.release()


## Envia uma mensagem para o servidor.
## - `message`: A mensagem a ser enviada.
## - `should_release`: Retorna ou nao a mensagem ao pool apos o envio.
##
## Se voce pretende continuar usando a instancia da mensagem apos chamar este metodo, voce <i>deve</i> definir [should_release]
## para [false]. [Message.eelease] pode ser usado para retornar manualmente a mensagem para o pool posteriormente.
func send(message: Message, should_release: bool = true) -> void:
	_connection.send(message, should_release)


## Desconecta do servidor.
func disconnect_host() -> void:
	if _connection == null or is_not_connected:
		return

	send(Message.create(Enums.MessageHeader.DISCONNECT))
	_local_disconnect(Enums.DisconnectReason.DISCONNECTED)


## Limpa o lado local da conexao.
## - `reason`: O motivo pelo qual o cliente foi desconectado.
## - `message`: A mensagem de desconexao ou rejeicao, potencialmente contendo dados extras para serem manipulados externamente.
## - `reject_reason`: TData que deve ser enviado para o cliente que esta sendo desconectado. Use [Message.create()] para obter uma instancia de mensagem vazia. Nao utilizado se a conexao nao foi rejeitada.
func _local_disconnect(
	reason: Enums.DisconnectReason,
	message: Message = null,
	reject_reason: Enums.RejectReason = Enums.RejectReason.NO_CONNECTION
) -> void:
	if is_not_connected:
		return

	_unsub_from_transport_events()
	Client._decrease_active_count()

	_stop_time()
	_transport.disconnect_host()

	_connection.local_disconnect()

	if reason == Enums.DisconnectReason.NEVER_CONNECTED:
		_on_connection_failed(Enums.RejectReason.NO_CONNECTION)
	elif reason == Enums.DisconnectReason.CONNECTION_REJECTED:
		_on_connection_failed(reject_reason, message)
	else:
		_on_disconnected(reason, message)


## O que fazer quando o transporte estabelece uma conexao.
func _transport_connected() -> void:
	_start_time()


## O que fazer quando o transporte falha ao conectar.
func _transport_connection_failed():
	_local_disconnect(Enums.DisconnectReason.NEVER_CONNECTED)


## O que fazer quando o transporte se desconecta.
func _transport_disconnected(e: TDisconnectedEventArgs) -> void:
	if _connection == e.connection:
		_local_disconnect(e.reason)


#region Events
## Invoca o evento [connected].
func _on_connected() -> void:
	NetworkLogger.Log(Enums.LogTypes.INFO, "Conectado com sucesso!", log_name)
	connected.emit()


## Invoca o evento [connection_failed].
## - `reason`: O motivo da falha de conexao.
## - `message`: Dados adicionais relacionados e tentativa de conexao com falha.
func _on_connection_failed(reason: Enums.RejectReason, message: Message = null) -> void:
	var reason_string: String
	match reason:
		Enums.RejectReason.NO_CONNECTION:
			reason_string = cr_no_connection
		Enums.RejectReason.SERVER_FULL:
			reason_string = cr_server_full
		Enums.RejectReason.REJECTED:
			reason_string = cr_rejected
		Enums.RejectReason.CUSTOM:
			reason_string = cr_custom
		_:
			reason_string = str(unknown_reason) + "'" + str(reason) + "'"

	NetworkLogger.Log(
		Enums.LogTypes.INFO, "Falha na conexao com o servidor: " + reason_string + ".", log_name
	)
	connection_failed.emit(ConnectionFailedEventArgs.new(message))


## Invoca o evento [message_received] e inicia o tratamento da mensagem recebida.
## - `message`: A mensagem recebida.
func _on_message_received(message: Message) -> void:
	var message_id := message.get_short()
	message_received.emit(MessageReceivedEventArgs.new(_connection, message_id, message))

	if use_message_handlers:
		# var message_handler: GetFunctionInfo = _message_mandlers.get(message_id)
		if _message_mandlers.has(message_id):
			_message_mandlers[message_id].value.call(message)
		else:
			NetworkLogger.Log(
				Enums.LogTypes.WARNING,
				(
					"Nenhum metodo manipulador de mensagem encontrado para o ID de mensagem "
					+ str(message_id)
					+ "!"
				),
				log_name
			)


## Invoca o evento [disconnected].
## - `reason`: O motivo da desconexao.
## - `message`: Dados adicionais relacionados a desconexao.
func _on_disconnected(reason: Enums.DisconnectReason, message: Message) -> void:
	var reason_string: String
	match reason:
		Enums.DisconnectReason.NEVER_CONNECTED:
			reason_string = dc_never_connected
		Enums.DisconnectReason.TRANSPORT_ERROR:
			reason_string = dc_transport_error
		Enums.DisconnectReason.TIMED_OUT:
			reason_string = dc_timed_out
		Enums.DisconnectReason.KICKED:
			reason_string = dc_kicked
		Enums.DisconnectReason.SERVER_STOPPED:
			reason_string = dc_server_stopped
		Enums.DisconnectReason.DISCONNECTED:
			reason_string = dc_disconnected
		_:
			reason_string = str(unknown_reason) + "'" + str(reason) + "'"

	NetworkLogger.Log(
		Enums.LogTypes.INFO, "Desconectado do servidor: " + reason_string + ".", log_name
	)
	disconnected.emit(DisconnectedEventArgs.new(reason, message))


## Invoca o evento [client_connected].
## - `client_id`: O ID numerico do cliente conectado.
func _on_client_connected(client_id: int) -> void:
	NetworkLogger.Log(Enums.LogTypes.INFO, "Cliente " + str(client_id) + " conectado.", log_name)
	client_connected.emit(ClientConnectedEventArgs.new(client_id))


## Invoca o evento [client_disconnected].
## - `client_id`: O ID numerico do cliente que se desconectou.
func _on_client_disconnected(client_id: int) -> void:
	NetworkLogger.Log(Enums.LogTypes.INFO, "Cliente " + str(client_id) + " desconectado.", log_name)
	client_disconnected.emit(ClientDisconnectedEventArgs.new(client_id))

#endregion
