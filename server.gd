## Um servidor que pode aceitar conexoes de Clients.
class_name Server
extends Peer

## Chamado quando um cliente se conecta.
## `EventHandler<ServerConnectedEventArgs>`
signal client_connected(e: ServerConnectedEventArgs)
## Chamado quando uma mensagem e recebida.
## `EventHandler<MessageReceivedEventArgs>`
signal message_received(e: MessageReceivedEventArgs)
## Chamado quando um cliente se desconecta.
## `EventHandler<ServerDisconnectedEventArgs>`
signal client_disconnected(e: ServerDisconnectedEventArgs)

## Se o servidor esta ou nao em execucao no momento.
var is_running: bool
## A porta local na qual o servidor esta sendo executado.
var port: int:
	get:
		return _transport.port


## Define o `Connection.timeout_time` de todos os clientes conectados.
func timeout_time(value: int):
	for connection in _clients.values() as Array[Connection]:
		connection.timeout_time = value


## O numero maximo de conexoes simultaneas.
var max_client_count: int
## O numero de clientes atualmente conectados.
var client_count: int:
	get:
		return _clients.size()
## Um array de todos os clientes atualmente conectados.
## A posicao de cada instancia `Connection` no array <i>nao</i> corresponde ao ID numerico desse cliente (exceto por coincidencia).
var clients: Array[Connection]:
	get:
		return _clients.values()

@warning_ignore("unused_parameter")
## Um metodo opcional que determina se deve ou nao aceitar a tentativa de conexao de um cliente.
## O parametro `Connection` e a conexao pendente e o parametro `Message` e uma mensagem contendo quaisquer dados adicionais que o cliente incluiu com a tentativa de conexao.
var handle_connection: Callable = func(
	pending_connection: Connection, connect_message: Message
) -> void: pass
## Armazena quais IDs de mensagem tem a retransmissao automatica habilitada. A retransmissao e totalmente desativada quando e `null`.
var relat_filter: MessageRelayFilter

## Conexoes atualmente pendentes que estao esperando para serem aceitas ou rejeitadas.
var _pending_connections: Array[Connection]
## Clientes atualmente conectados.
var _clients: Dictionary
## Clientes que expiraram e precisam ser removidos de `_clients`.
var _timed_out_clients: Array[Connection]
## Metodos usados para lidar com mensagens, acessiveis por seus IDs de mensagem correspondentes.
var _message_mandlers: Dictionary
## O servidor de transporte subjacente que e usado para enviar e receber dados.
var _transport = null
## Todos os IDs de cliente atualmente nao utilizados.
var _available_client_ids: Queue


## Lida com a configuracao inicial.
## - `transport`: O transporte a ser usado para enviar e receber dados.
## - `log_name_`: O nome a ser usado ao registrar mensagens via `NetworkLogger`.
func _init(transport: Variant, log_name_: String = "SERVER"):
	super._init(log_name_)
	if transport is TcpServer:
		_transport = transport
	elif transport is UdpServer:
		_transport = transport
	else:
		NetworkLogger.Log(
			Enums.LogTypes.THROW, "transport type para TcpServer ou UdpServer", log_name
		)

	_pending_connections = []
	_clients = Dictionary()
	_timed_out_clients = []


## Parar o servidor se estiver em execucao e troca o transporte que esta usando.
## - `new_transport`: O novo servidor de transporte subjacente a ser usado para enviar e receber dados.
## Este metodo nao reinicia automaticamente o servidor. Para continuar aceitando conexoes, `start(int, int, int, bool)` deve ser chamado novamente.
func change_transport(new_transport: Variant) -> void:
	stop()
	if new_transport is TcpServer:
		_transport = new_transport
	elif new_transport is UdpServer:
		_transport = new_transport
	else:
		NetworkLogger.Log(
			Enums.LogTypes.THROW, "new_transport type para TcpServer ou UdpServer", log_name
		)


## Inicia o servidor.
## - `port`: A porta local na qual iniciar o servidor.
## - `max_client_count_`: O numero maximo de conexoes simultaneas a serem permitidas.
## - `message_handler_group_id`: O ID do grupo de metodos do manipulador de mensagem a ser usado ao criar `message_handlers`.
## - `_use_message_handlers`: Se o servidor deve ou nao usar o sistema interno de tratamento de mensagens.
## Definir `use_message_handlers` como <see langword="false"/> desativara a deteccao automatica e a execucao de metodos com `MessageHandlerAttribute`, o que e benefico se voce preferir manipular mensagens por meio do evento `message_eceived`.
func start(
	port_: int,
	max_client_count_: int,
	message_handler_group_id: int = 0,
	_use_message_handlers: bool = true
):
	stop()

	Server._increase_active_count()
	use_message_handlers = _use_message_handlers
	if _use_message_handlers:
		_create_message_handlers_dictionary(message_handler_group_id)

	max_client_count = max_client_count_
	_clients = Dictionary()
	_initialize_client_ids()

	_sub_to_transport_events()
	_transport.start(port_)

	_start_time()
	_heartbeat()
	is_running = true
	NetworkLogger.Log(Enums.LogTypes.INFO, "Iniciado na porta " + str(port) + ".", log_name)


## Assina metodos apropriados para os eventos do transporte.
func _sub_to_transport_events() -> void:
	_transport.connected.connect(_handle_connection_attempt)
	_transport.data_received.connect(_handle_data)
	_transport.disconnected.connect(_transport_disconnected)


## Cancela a assinatura de metodos de todos os eventos do transporte.
func _unsub_from_transport_events() -> void:
	_transport.connected.disconnect(_handle_connection_attempt)
	_transport.data_received.disconnect(_handle_data)
	_transport.disconnected.disconnect(_transport_disconnected)


func _create_message_handlers_dictionary(message_handler_group_id: int):
	var functions: Array[GetFunctionInfo] = _find_message_handlers()

	_message_mandlers = Dictionary()
	for function in functions:
		var attribute := function.mh_info
		if attribute.group_id != message_handler_group_id:
			continue

		var _server_message_handler := function
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
			var message_handle: GetFunctionInfo = _server_message_handler
			message_handle.value = function.value
			_message_mandlers[attribute.message_id] = message_handle

	if NetworkLogger.is_warning_logging_enabled:
		print_rich("[b]======= SERVER =======[/b]")
	NetworkLogger.table(ArrayUtil.to_array_dictionary(functions), ["mh_info"])
	NetworkLogger.to_tabel(_message_mandlers, message_handler_group_id)


## Lida com uma tentativa de conexao de entrada.
func _handle_connection_attempt(e: ConnectedEventArgs) -> void:
	e.connection.peer = self


## Manipula uma mensagem de conexao.
## - `connection`: O cliente que enviou a mensagem de conexao.
## - `connect_message`: A mensagem de conexao.
func _handle_connect(connection: Connection, connect_message: Message) -> void:
	connection.set_pending()

	if handle_connection.is_null() == false:
		_accept_connection(connection)
	elif client_count < max_client_count:
		# TODO: esta correta find?
		if not _clients.find_key(connection) and not _pending_connections.has(connection):
			_pending_connections.append(connection)
			send(Message.create(Enums.MessageHeader.CONNECT), connection)  # Informe ao cliente que recebemos a tentativa de conexao
			handle_connection.call(connection, connect_message)  # Externamente determina se aceita
		else:
			_reject(connection, Enums.RejectReason.ALREADY_CONNECTED)
	else:
		_reject(connection, Enums.RejectReason.SERVER_FULL)


## Aceita a conexao pendente fornecida.
## - `connection`: A conexao a ser aceita.
func accept(connection: Connection) -> void:
	var removed := false
	if _pending_connections.has(connection):
		_pending_connections.erase(connection)
		removed = true
	if removed:
		_accept_connection(connection)
	else:
		NetworkLogger.Log(
			Enums.LogTypes.WARNING,
			(
				"Nao foi possivel aceitar a conexao de "
				+ str(connection)
				+ " porque nenhuma conexao estava pendente!"
			),
			log_name
		)


## Rejeita a conexao pendente fornecida.
## - `connection`: A conexao a ser rejeitada.
## - `message`: Dados que devem ser enviados para o cliente que esta sendo rejeitado. Use `Message.create()` para obter uma instancia de mensagem vazia.
func reject(connection: Connection, message: Message) -> void:
	var removed := false
	if _pending_connections.has(connection):
		_pending_connections.erase(connection)
		removed = true
	if removed:
		var reject_reason: int
		if message == null:
			reject_reason = Enums.RejectReason.REJECTED
		else:
			reject_reason = Enums.RejectReason.CUSTOM
		_reject(connection, reject_reason, message)
	else:
		NetworkLogger.Log(
			Enums.LogTypes.WARNING,
			(
				"Nao foi possivel rejeitar a conexao de "
				+ str(connection)
				+ " porque nenhuma conexao estava pendente!"
			),
			log_name
		)


## Aceita a conexao pendente fornecida.
## - `connection`: A conexao a ser aceita.
func _accept_connection(connection: Connection) -> void:
	if client_count < max_client_count:
		if not _clients.find_key(connection):
			var client_id: int = _get_available_client_id()
			connection.id = client_id
			_clients[client_id] = connection
			connection.reset_timeout()
			connection.send_welcome()
			return
		else:
			_reject(connection, Enums.RejectReason.ALREADY_CONNECTED)
	else:
		_reject(connection, Enums.RejectReason.SERVER_FULL)


## Rejeita a conexao pendente fornecida.
## - `connection`: A conexao a ser rejeitada.
## - `reason`: O motivo pelo qual a conexao esta sendo rejeitada.
## - `reject_message`: Dados que devem ser enviados ao cliente que esta sendo rejeitado.
func _reject(
	connection: Connection, reason: Enums.RejectReason, reject_message: Message = null
) -> void:
	if reason != Enums.RejectReason.ALREADY_CONNECTED:
		# O envio de uma mensagem de rejeicao sobre o cliente ja conectado poderia teoricamente ser explorado para obter informacoes
		# em outros clientes conectados, embora na pratica isso pareca muito improvavel. No entanto, em circunstancias normais, os clientes
		# nunca deve realmente encontrar um cenario onde eles "ja estejam conectados".

		var message: Message = Message.create(Enums.MessageHeader.REJECT)
		message.add_byte(reason)
		if reason == Enums.RejectReason.CUSTOM:
			message.add_bytes(reject_message.get_bytes(reject_message.written_length), false)

		for i in range(3):  # Envie a mensagem de rejeicao algumas vezes para aumentar as chances de ela chegar
			connection.send(message, false)

		message.release()

	connection.local_disconnect(true)
	execute_later(connect_timeout_time, CloseRejectedConnectionEvent.new(_transport, connection))

	var reason_string: String
	match reason:
		Enums.RejectReason.ALREADY_CONNECTED:
			reason_string = cr_already_connected
		Enums.RejectReason.SERVER_FULL:
			reason_string = cr_server_full
		Enums.RejectReason.REJECTED:
			reason_string = cr_rejected
		Enums.RejectReason.CUSTOM:
			reason_string = cr_custom
		_:
			reason_string = unknown_reason + "'" + str(reason) + "'"

	NetworkLogger.Log(
		Enums.LogTypes.INFO,
		"Conexao rejeitada de " + str(connection) + ": " + reason_string + ".",
		log_name
	)


## Verifica se os clientes atingiram o tempo limite.
func _heartbeat():
	for connection in _clients.values() as Array[Connection]:
		if connection.has_timed_out:
			_timed_out_clients.append(connection)

	for connection in _timed_out_clients:
		_local_disconnect(connection, Enums.DisconnectReason.TIMED_OUT)

	_timed_out_clients.clear()

	execute_later(heartbeat_interval, HeartbeatEvent.new(self))


func _update():
	super._update()
	_transport.poll()
	_handle_messages()


func _handle(message: Message, header: Enums.MessageHeader, connection: Connection):
	match header:
		# mensagens do usuario
		Enums.MessageHeader.UNRELIABLE, Enums.MessageHeader.RELIABLE:
			_on_message_received(message, connection)

		# mensagens internas
		Enums.MessageHeader.ACK:
			connection.handle_ack(message)
		Enums.MessageHeader.ACK_EXTRA:
			connection.handle_ack_extra(message)
		Enums.MessageHeader.CONNECT:
			_handle_connect(connection, message)
		Enums.MessageHeader.HEARTBEAT:
			connection.handle_heartbeat(message)
		Enums.MessageHeader.DISCONNECT:
			_local_disconnect(connection, Enums.DisconnectReason.DISCONNECTED)
		Enums.MessageHeader.WELCOME:
			if connection.is_pending:
				connection.handle_welcome_response(message)
				_on_client_connected(connection)
		_:
			NetworkLogger.Log(
				Enums.LogTypes.WARNING,
				(
					"Cabecalho de mensagem inesperado '"
					+ str(header)
					+ "'! Descartando "
					+ str(message.written_length)
					+ " bytes recebidos de "
					+ str(connection)
					+ "."
				),
				log_name
			)

	message.release()


## Envia uma mensagem para um determinado cliente.
## Se voce pretende continuar usando a instancia da mensagem apos chamar este metodo, voce deve definir `should_release` para `false`. `Message.release()` pode ser usado para retornar manualmente a mensagem para o pool posteriormente.
## - `message`: A mensagem a ser enviada.
## - `to_client`:
## -              `int`: O ID numerico do cliente para o qual enviar a mensagem.
## -              `Connection`: O cliente para o qual enviar a mensagem.
## - `should_release`: Retorna ou nao a mensagem ao pool apos o envio.
func send(message: Message, to_client: Variant, should_release: bool = true) -> void:
	if typeof(to_client) == TYPE_INT:
		if _clients.has(to_client):
			var connection: Connection = _clients[to_client]
			send(message, connection, should_release)

	elif to_client is Connection:
		to_client.send(message, should_release)
	else:
		NetworkLogger.Log(Enums.LogTypes.ERROR, "to_client type para Connection ou int", log_name)


## Envia uma mensagem para todos os clientes conectados, ou exceto o determinado.
## Se voce pretende continuar usando a instancia da mensagem apos chamar este metodo, voce deve definir `should_release` para `false`. `Message.release()` pode ser usado para retornar manualmente a mensagem para o pool posteriormente.
## - `message`: A mensagem a ser enviada.
## - `except_to_client_id`: O ID numerico do cliente para <i>nao</i> enviar a mensagem.
## - `should_release`: Retorna ou nao a mensagem ao pool apos o envio.
func send_to_all(
	message: Message,
	should_release_or_except_to_client_id: Variant = true,
	should_release: bool = true
) -> void:
	if typeof(should_release_or_except_to_client_id) == TYPE_BOOL:
		for client in _clients.values() as Array[Connection]:
			client.send(message, false)

		if should_release_or_except_to_client_id:
			message.release()
	elif typeof(should_release_or_except_to_client_id) == TYPE_INT:
		for client in _clients.values() as Array[Connection]:
			if client.id != should_release_or_except_to_client_id:
				client.send(message, false)

		if should_release:
			message.release()
	else:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR,
			"should_release_or_except_to_client_id type para bool ou int",
			log_name
		)


## Recupera o cliente com o ID fornecido, se um cliente com esse ID estiver conectado no momento.
## - `id`: O ID do cliente a ser recuperado.
## - `returns`: `client` <see langword="true"/> se um cliente com o ID fornecido foi conectado; caso contrario, <consulte langword="false"/> null.
func try_get_client(id: int) -> Connection:
	return _clients[id]


## Desconecta um cliente especifico.[br]
## [param id_or_client]:
## -              `int`: O ID numerico do cliente a ser desconectado.
## -              `Connection`: O cliente a ser desconectado.
## - `message`: Dados que devem ser enviados para o cliente que esta sendo desconectado. Use `Message.create()` para obter uma instancia de mensagem vazia.
func disconnect_client(id_or_client: Variant, message: Message = null) -> void:
	if typeof(id_or_client) == TYPE_INT:
		if _clients.has(id_or_client):
			var client: Connection = _clients[id_or_client]
			_send_disconnect(client, Enums.DisconnectReason.KICKED, message)
			_local_disconnect(client, Enums.DisconnectReason.KICKED)
		else:
			NetworkLogger.Log(
				Enums.LogTypes.WARNING,
				(
					"Nao foi possivel desconectar o cliente "
					+ str(id_or_client)
					+ " porque nao estava conectado!"
				),
				log_name
			)
	elif id_or_client is Connection:
		if _clients.has(id_or_client.id):
			_send_disconnect(id_or_client, Enums.DisconnectReason.KICKED, message)
			_local_disconnect(id_or_client, Enums.DisconnectReason.KICKED)
		else:
			NetworkLogger.Log(
				Enums.LogTypes.WARNING,
				(
					"Nao foi possivel desconectar o cliente "
					+ str(id_or_client.id)
					+ " porque nao estava conectado!"
				),
				log_name
			)
	else:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, " O param id_or_client type para int ou Connection", log_name
		)


## Limpa o lado local da conexao fornecida.
## - `cliente`: O cliente a ser desconectado.
## - `reason`: O motivo pelo qual o cliente esta sendo desconectado.
func _local_disconnect(client: Connection, reason: Enums.DisconnectReason) -> void:
	if client.peer != self:
		return  # O cliente nao pertence a esta instancia do servidor

	_transport.close(client)

	if _clients.erase(client.id):
		_available_client_ids.enqueue(client.id)

	if client.isconnected:
		_on_client_disconnected(client, reason)  # Execute apenas se o cliente estiver realmente conectado

	client.local_disconnect()


## O que fazer quando o transporte desconecta um cliente.
func _transport_disconnected(e: TDisconnectedEventArgs) -> void:
	_local_disconnect(e.connection, e.reason)


## Parar o servidor.
func stop() -> void:
	if not is_running:
		return

	_pending_connections.clear()
	var disconnect_bytes: PackedByteArray = [
		Enums.DisconnectReason.DISCONNECTED, Enums.DisconnectReason.SERVER_STOPPED
	]
	for client in _clients.values() as Array[Connection]:
		client._send_d(disconnect_bytes, disconnect_bytes.size())
	_clients.clear()

	_transport.shutdown()
	_unsub_from_transport_events()

	Server._decrease_active_count()

	_stop_time()
	is_running = false
	NetworkLogger.Log(Enums.LogTypes.INFO, "Servidor parado.", log_name)


## Inicializa os IDs de cliente disponiveis.
func _initialize_client_ids() -> void:
	_available_client_ids = Queue.new(max_client_count)  # capacity max_client_count
	for i in range(1, max_client_count + 1):
		_available_client_ids.enqueue(i)


## Recupera um ID de cliente disponivel.
## - `retorna`: O ID do cliente. 0 se nenhum estiver disponivel.
func _get_available_client_id() -> int:
	if _available_client_ids.count > 0:
		return _available_client_ids.dequeue()

	NetworkLogger.Log(
		Enums.LogTypes.ERROR, "Nenhum ID de cliente disponivel, atribuido 0!", log_name
	)
	return 0


#region Messages
## Envia uma mensagem de desconexao.
## - `client`: O cliente para o qual enviar a mensagem de desconexao.
## - `reason`: Por que o cliente esta sendo desconectado.
## - `disconnect_message`: Dados personalizados opcionais que devem ser enviados ao cliente que esta sendo desconectado.
func _send_disconnect(
	client: Connection, reason: Enums.DisconnectReason, disconnect_message: Message
) -> void:
	var message := Message.create(Enums.MessageHeader.DISCONNECT)
	message.add_byte(reason)

	if reason == Enums.DisconnectReason.KICKED and disconnect_message != null:
		message.add_bytes(disconnect_message.get_bytes(disconnect_message.written_length), false)

	send(message, client)


## Envia uma mensagem de cliente conectado.
## - `new_client`: O cliente recem-conectado.
func _send_client_connected(new_client: Connection) -> void:
	var message := Message.create(Enums.MessageHeader.CLIENT_CONNECTED)
	message.add_short(new_client.id)

	send_to_all(message, new_client.id)


## Envia uma mensagem de cliente desconectado.
## - `id`: O ID numerico do cliente que desconectou.
func _send_client_disconnected(id: int) -> void:
	var message := Message.create(Enums.MessageHeader.CLIENT_DISCONNECTED)
	message.add_short(id)

	send_to_all(message)


#endregion


#region Events
## Invoca o evento [client_connected].
## - `client`: O cliente recem-conectado.
func _on_client_connected(client: Connection) -> void:
	NetworkLogger.Log(
		Enums.LogTypes.INFO,
		"Cliente " + str(client.id) + " (" + str(client) + ") conectado com sucesso!",
		log_name
	)
	_send_client_connected(client)
	client_connected.emit(ServerConnectedEventArgs.new(client))


## Invoca o evento [message_received] e inicia o tratamento da mensagem recebida.
## - `message`: A mensagem recebida.
## - `from_connection`: O cliente do qual a mensagem foi recebida.
func _on_message_received(message: Message, from_connection: Connection) -> void:
	var message_id := message.get_short()
	if relat_filter != null and relat_filter.should_relay(message_id):
		# A mensagem deve ser retransmitida automaticamente aos clientes em vez de ser tratada no servidor
		send_to_all(message, from_connection.id)
		return

	message_received.emit(MessageReceivedEventArgs.new(from_connection, message_id, message))

	if use_message_handlers:
		if _message_mandlers.has(message_id):
			_message_mandlers[message_id].value.call(from_connection.id, message)
		else:
			NetworkLogger.Log(
				Enums.LogTypes.WARNING,
				(
					"Nenhum metodo manipulador de mensagem encontrado para ID de mensagem "
					+ str(message_id)
					+ "!"
				),
				log_name
			)


## Invoca o evento [client_disconnected].
## - `connection`: O cliente que desconectou.
## - `reason`: O motivo da desconexao.
func _on_client_disconnected(connection: Connection, reason: Enums.DisconnectReason) -> void:
	_send_client_disconnected(connection.id)

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
			reason_string = unknown_reason

	NetworkLogger.Log(
		Enums.LogTypes.INFO,
		(
			"Cliente "
			+ str(connection.id)
			+ " ("
			+ str(connection)
			+ ") desconectado: "
			+ reason_string
			+ "."
		),
		log_name
	)
	client_disconnected.emit(ServerDisconnectedEventArgs.new(connection, reason))
#endregion
