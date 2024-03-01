## Fornece funcionalidade basica para `Server` e `Client`.
class_name Peer

## O nome a ser usado ao registrar mensagens via `NetworkLogger`.
var log_name: String

@warning_ignore("unused_parameter")
## Define as conexoes relevantes `Connection.timeout_time`s.
func timeout_time(value: int):
	pass


## O intervalo (em milissegundos) no qual enviar e esperar que os heartbeats sejam recebidos.
## Mudancas neste valor so terao efeito apos a proxima pulsacao ser executada.
var heartbeat_interval: int = 1000  # 1000

## O numero de instancias `Server` e `Client` atualmente ativas.
static var active_count: int

## O tempo (em milissegundos) que deve ser aguardado antes de desistir de uma tentativa de conexao.
var connect_timeout_time: int = 10000  # 10000
## A hora atual.
var current_time: int

## O texto a ser registrado quando desconectado devido a `DisconnectReason.NEVER_CONNECTED`.
const dc_never_connected: String = "Nunca conectado"
## O texto a ser registrado quando desconectado devido a `DisconnectReason.TRANSPORT_ERROR`.
const dc_transport_error: String = "erro de transporte"
## O texto a ser registrado quando desconectado devido a `DisconnectReason.TIMED_OUT`.
const dc_timed_out: String = "Tempo esgotado"
## O texto a ser registrado quando desconectado devido a `DisconnectReason.KICKED`.
const dc_kicked: String = "Chutado"
## O texto a ser registrado quando desconectado devido a `DisconnectReason.SERVER_STOPPED`.
const dc_server_stopped: String = "Servidor parado"
## O texto a ser registrado quando desconectado devido a `DisconnectReason.DISCONNECTED`.
const dc_disconnected: String = "Desconectado"
## O texto a ser registrado quando desconectado ou rejeitado devido a um motivo desconhecido.
const unknown_reason = "Razao desconhecida"
## O texto a ser registrado quando a conexao falhou devido a `RejectReason.NO_CONNECTION`.
const cr_no_connection: String = "Sem conexao"
## O texto a ser registrado quando a conexao falhou devido a `RejectReason.ALREADY_CONNECTED`.
const cr_already_connected: String = "Este cliente ja esta conectado"
## O texto a ser registrado quando a conexao falhou devido a `RejectReason.SERVER_FULL`.
const cr_server_full: String = "Servidor esta cheio"
## O texto a ser registrado quando a conexao falhou devido a `RejectReason.REJECTED`.
const cr_rejected: String = "Rejeitado"
## O texto a ser registrado quando a conexao falhou devido a `RejectReason.CUSTOM`.
const cr_custom: String = "Rejeitado (com dados personalizados)"
## Se o par deve ou nao usar o sistema de manipulador de mensagens embutido.
var use_message_handlers: bool

## Um cronometro usado para rastrear quanto tempo passou.
var _time: Stopwatch = Stopwatch.new()
## Mensagens recebidas que precisam ser tratadas.
var _messages_to_handle: Queue = Queue.new()
## Uma fila de eventos a serem executados, ordenados por quanto tempo eles precisam ser executados.
var _event_queue: PriorityQueue = PriorityQueue.new()


## Inicializa o par.
## - `_log_name`: O nome a ser usado ao registrar mensagens via `NetworkLogger`.
func _init(_log_name: String):
	log_name = _log_name


## Recupera metodos marcados com `MessageHandlerAttribute`.
## - `returns`: Um array contendo metodos manipuladores de mensagens.
func _find_message_handlers() -> Array[GetFunctionInfo]:
	var functions: Array[GetFunctionInfo] = []

	var classes: PackedStringArray = ClassLoader.get_all_classes()
	for type_name in classes:
		var mp_infos: FInfos = ClassLoader.get_functions_infos(type_name)
		for mh_info in mp_infos.message_handlers:
			if mh_info:
				var function := GetFunctionInfo.new(
					mh_info.function, mh_info.function.get_method(), type_name, mh_info
				)
				functions.append(function)
			else:
				NetworkLogger.Log(
					Enums.LogTypes.THROW, "Metodo nao encontrado ou erro ao obter o Callable"
				)

	return functions


@warning_ignore("unused_parameter")
## Constroi um dicionario de IDs de mensagens e seus metodos de tratamento de mensagens correspondentes.
## - `message_handler_group_id`: message_handler_group_id O ID do grupo de metodos de tratamento de mensagens a serem incluidos no dicionario.
func _create_message_handlers_dictionary(message_handler_group_id: int) -> void:
	pass


## Inicia o rastreamento de quanto tempo passou.
func _start_time() -> void:
	_time.start()


## Parar de rastrear quanto tempo passou.
func _stop_time() -> void:
	_time.reset()
	_event_queue.clear()


##  Bate o coracao.
func _heartbeat() -> void:
	pass


## Manipula todas as mensagens recebidas e invoca quaisquer eventos atrasados que precisam ser invocados.
func _update() -> void:
	current_time = int(_time.get_elapsed_milliseconds())

	while _event_queue.count > 0 and _event_queue.peek_priority() <= current_time:
		_event_queue.dequeue().invoke()


## Configures a delayed event to be executed after a specified time.
## - `inMS`: How long from now to execute the delayed event, in milliseconds.
## - `delayed_event`: The delayed event to execute later.
func execute_later(inMS: int, delayed_event: DelayedEvent) -> void:
	_event_queue.enqueue(delayed_event, current_time + inMS)


## Lida com todas as mensagens em fila.
func _handle_messages() -> void:
	while _messages_to_handle.count > 0:
		var handle: MessageToHandle = _messages_to_handle.dequeue()
		_handle(handle.message, handle.header, handle.from_connection)


## Trata os dados recebidos pelo transporte.
func _handle_data(e: DataReceivedEventArgs) -> void:
	var _header := e.data_buffer[0] as Enums.MessageHeader

	var _message: Message = Message.create_raw()
	_message.prepare_for_use(_header, e.amount)

	if _message.send_mode == Enums.MessageSendMode.RELIABLE:
		# Mensagens confiaveis tem um cabecalho de 3 bytes, se nao houver tantos bytes no pacote, nao trate disso
		if e.amount < 3:
			return

		if e.from_connection.reliable_handle(Converter.to_short(e.data_buffer, 1)):
			ArrayUtil.copy(e.data_buffer, 1, _message.bytes, 1, e.amount - 1)  # Ja estabelecemos que o pacote contem pelo menos 3 bytes e sempre queremos copiar o ID da sequencia

			_messages_to_handle.enqueue(MessageToHandle.new(_message, _header, e.from_connection))
	else:
		# Apenas se preocupe com a copia do array se houver mais de 1 byte no pacote (1 ou menos significa nenhuma carga util para um pacote enviado de forma confiavel)
		if e.amount > 1:
			ArrayUtil.copy(e.data_buffer, 1, _message.bytes, 1, e.amount - 1)

		_messages_to_handle.enqueue(MessageToHandle.new(_message, _header, e.from_connection))


@warning_ignore("unused_parameter")
## Trata uma mensagem.
## - `mensagem`: A mensagem a ser tratada.
## - `header`: O tipo de cabecalho da mensagem.
## - `connection`: A conexao na qual a mensagem foi recebida.
func _handle(mensagem: Message, header: Enums.MessageHeader, connection: Connection) -> void:
	pass


## Aumenta `active_count`. Para uso quando um novo `Server` ou `Client` e iniciado.
static func _increase_active_count() -> void:
	active_count += 1


## Diminui `active_count`. Para uso quando um `Server` ou `Client` e interrompido.
static func _decrease_active_count() -> void:
	active_count -= 1
	if active_count < 0:
		active_count = 0
