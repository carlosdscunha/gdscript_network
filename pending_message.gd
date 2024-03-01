## Representa uma mensagem atualmente pendente enviada de forma confiavel cuja entrega ainda nao foi confirmada.
class_name PendingMessage

## A hora da ultima tentativa de envio.
var last_send_time: int

## O multiplicador usado para determinar quanto tempo esperar antes de reenviar uma mensagem pendente.
const _retry_time_multiplier: float = 1.2
## Com que frequencia tentar enviar a mensagem antes de desistir.
const _max_send_attempts: int = 15  ## TODO: se livre disso

## Um pool de `PendingMessage` instancias reutilizeveis.
static var pool: Array[PendingMessage] = []

## O `Connection` a ser usado para enviar (e reenviar) a mensagem pendente.
var _connection: Connection
## O ID da sequencia da mensagem.
var _sequence_id: int
## O conteudo da mensagem.
var _data: PackedByteArray
## O comprimento em bytes dos dados que foram gravados na mensagem.
var _written_length: int
## Quantas tentativas de envio foram feitas ate agora.
var _send_attempts: int
## Se a mensagem pendente foi apagada ou nao.
var _was_cleared: bool


## Lida com a configuracao inicial.
func _init():
	_data = PackedByteArray()
	_data.resize(Message.max_size)


# region Pooling
## Recupera uma instancia `PendingMessage`, inicializa-a e entao a envia.
## - `sequenceId`: O ID da sequencia da mensagem.
## - `message`: A mensagem que esta sendo enviada de forma confiavel.
## - `connection`: O `Connection` a ser usado para enviar (e reenviar) a mensagem pendente.
static func create_and_send(sequence_id: int, message: Message, connection: Connection) -> void:
	var pending_message := _retrieve_from_pool()
	pending_message._connection = connection
	pending_message._sequence_id = sequence_id

	pending_message._data[0] = message.bytes[0]  # Copia o cabeaalho da mensagem
	Converter.from_short(sequence_id, pending_message._data, 1)  # Inserir ID da sequencia
	ArrayUtil.copy(message.bytes, 3, pending_message._data, 3, message.written_length - 3)  # Copia o restante da mensagem
	pending_message._written_length = message.written_length

	pending_message._send_attempts = 0
	pending_message._was_cleared = false

	connection.pending_messages[sequence_id] = pending_message
	pending_message.try_send()


## Recupera uma instancia `PendingMessage` do pool. Se nenhuma estiver disponivel, uma nova instancia sera criada.
## - `returns`: Uma instancia `PendingMessage`.
static func _retrieve_from_pool() -> PendingMessage:
	var message: PendingMessage

	# if pool.count > 0:
	if pool.size() > 0:
		# message = pool.get_value(0)
		message = pool[0]
		pool.remove_at(0)
	else:
		message = PendingMessage.new()

	return message


## Retorna a instancia <see cref="PendingMessage"/> ao pool para que possa ser reutilizada.
func _release() -> void:
	# if not pool.contains(self):
	if not pool.has(self):
		# pool.add(self)  # Adicione apenas se ainda nao estiver na lista, caso contrario, este metodo sendo chamado duas vezes seguidas por qualquer motivo pode causar problemas *serios*
		pool.append(self)  # Adicione apenas se ainda nao estiver na lista, caso contrario, este metodo sendo chamado duas vezes seguidas por qualquer motivo pode causar problemas *serios*

	# TODO: considere fazer algo para diminuir a capacidade do pool se houver muito mais
	# instancia disponivel do que o necessario, o que pode ocorrer se uma grande explosao de
	# as mensagens devem ser enviadas por algum motivo


# endregion


## Reenvia a mensagem.
func retry_send():
	if not _was_cleared:
		var time := _connection.peer.current_time
		var sendint: int
		if _connection.smooth_RTT < 0:
			sendint = 25
		else:
			sendint = int(float(_connection.smooth_RTT) / 2)

		if (last_send_time + sendint) <= time:  # Evite acionar um reenvio se o ultimo reenvio foi ha menos de meio RTT
			try_send()
		else:
			_connection.peer.execute_later(
				(
					_connection.smooth_RTT < 0
					if 50
					else max(10, _connection.smooth_RTT * _retry_time_multiplier)
				),
				PendingMessageResendEvent.new(self, time)
			)


## Tentativas de enviar a mensagem.
func try_send() -> void:
	if _send_attempts >= _max_send_attempts:
		# As tentativas de envio excedem o maximo de tentativas de envio, entao desista
		if NetworkLogger.is_warning_logging_enabled:
			var header: Enums.MessageHeader = _data[0] as Enums.MessageHeader
			if header == Enums.MessageHeader.RELIABLE:
				NetworkLogger.Log(
					Enums.LogTypes.WARNING,
					(
						"Nenhuma confirmacao recebida para a mensagem "
						+ str(header)
						+ " (ID: "
						+ str(Converter.to_short(_data, 3))
						+ ") apos "
						+ str(_send_attempts)
						+ " "
						+ str(Helper.correct_form(_send_attempts, "attempt"))
						+ ", a entrega pode ter falhado!"
					),
					_connection.peer.log_name
				)
			else:
				NetworkLogger.Log(
					Enums.LogTypes.WARNING,
					(
						"Nenhuma confirmacao recebida para a mensagem interna "
						+ str(header)
						+ " apos "
						+ str(_send_attempts)
						+ " "
						+ str(Helper.correct_form(_send_attempts, "attempt"))
						+ ", a entrega pode ter falhado!"
					),
					_connection.peer.log_name
				)

		clear()
		return

	_connection._send_d(_data, _written_length)

	last_send_time = _connection.peer.current_time
	_send_attempts += 1

	_connection.peer.execute_later(
		(
			_connection.smooth_RTT < 0
			if 50
			else max(10, _connection.smooth_RTT * _retry_time_multiplier)
		),
		PendingMessageResendEvent.new(self, _connection.peer.current_time)
	)


## Limpa a mensagem.
## - `should_remove_from_dictionary`: Remover ou nao a mensagem de `Connection.pending_messages`.
func clear(should_remove_from_dictionary: bool = true) -> void:
	if should_remove_from_dictionary:
		_connection.pending_messages.erase(_sequence_id)

	_was_cleared = true
	_release()
