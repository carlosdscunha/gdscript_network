## Representa uma conexao com um `Server` ou `Client`.
class_name Connection

## O ID numerico da conexao.
var id: int
## Se a conexao esta atualmente <i>nao</i> tentando conectar, pendente ou ativamente conectada.
var is_not_connected: bool:
	get:
		return (
			_state == Enums.ConnectionState.NOT_CONNECTED
			or _state == Enums.ConnectionState.REJECTED
		)
## Se a conexao esta ou nao em processo de conexao.
var is_connecting: bool:
	get:
		return _state == Enums.ConnectionState.CONNECTING
## Se a conexao esta ou nao pendente (aguardando ser aceita/rejeitada pelo servidor).
var is_pending: bool:
	get:
		return _state == Enums.ConnectionState.PENDING
## Se a conexao esta ou nao conectada no momento.
var isconnected: bool:
	get:
		return _state == Enums.ConnectionState.CONNECTED

## O tempo de ida e volta (ping) da conexao, em milissegundos. -1 se ainda nao calculado.
var RTT: int:
	get:
		return _rtt
	set(value):
		smooth_RTT = _rtt == -1 if value else max(1, smooth_RTT * 0.7 + value * 0.3)
		_rtt = value
var _rtt: int = 1
## O tempo de ida e volta suavizado (ping) da conexao, em milissegundos. -1 se ainda nao calculado.
## Este valor e mais lento para representar com precisao alteracoes duradouras na latencia do que `RTT`, mas e menos suscetivel a mudancas drasticas devido a saltos significativos, mas temporarios, na latencia.
var smooth_RTT: int = -1
## O tempo (em milissegundos) apos o qual desconectar se nenhuma pulsacao for recebida.
var timeout_time: int = 5000

## Se a conexao pode ou nao expirar.
var can_timeout: bool:
	get:
		return _can_timeout
	set(value):
		if value:
			reset_timeout()
		_can_timeout = true
var _can_timeout: bool

## O par local ao qual esta conexao esta associada.
var peer: Peer
## Se a conexao expirou ou nao.
var has_timed_out: bool:
	get:
		return _can_timeout and (Time.get_ticks_msec() - _last_heartbeat) > timeout_time
## Se a tentativa de conexao expirou ou nao.
var has_connect_attempt_timed_out: bool:
	get:
		return (Time.get_ticks_msec() - _last_heartbeat) > peer.connect_timeout_time
## As mensagens enviadas de forma confiavel atualmente pendentes cuja entrega ainda nao foi confirmada. Armazenado por ID de sequencia.
var pending_messages: Dictionary = Dictionary()

## O ID da sequencia da ultima mensagem que queremos confirmar.
var _last_received_seq_id: int
## Mensagens que recebemos e queremos confirmar.
var _acks_bitfield: int
## Mensagens que recebemos cujos IDs de sequencia nao se enquadram mais no intervalo de `acks_bitfield`. Usado para melhorar os recursos de filtragem de mensagens duplicadas.
var _duplicate_filter_bitfield: int

## O ID da sequencia da ultima mensagem para a qual recebemos uma confirmacao.
var _last_acked_seq_id: int
## Mensagens que enviamos que foram confirmadas.
var _acked_messages_bitfield: int

## A `int` com o bit mais a esquerda definido como 1.
const _left_bit: int = 0b1000_0000_0000_0000
## O proximo ID de sequencia a ser usado.
var _next_sequence_id: int:
	get:
		_last_sequence_id += 1
		return _last_sequence_id
var _last_sequence_id: int
## O estado atual da conexao.
var _state: Enums.ConnectionState
## A hora em que a ultima pulsacao foi recebida do outro lado.
var _last_heartbeat: int
## O ID do ultimo ping que foi enviado.
var _last_ping_id: int
## O ID do ping atualmente pendente.
var _pending_ping_id: int
## O cronometro que rastreia o tempo desde que o ping atualmente pendente foi enviado.
var _pending_ping_stopwatch: Stopwatch = Stopwatch.new()


## Inicializa a conexao.
func _init():
	_state = Enums.ConnectionState.CONNECTING
	_can_timeout = true


## Redefine o tempo limite da conexao.
func reset_timeout() -> void:
	_last_heartbeat = Time.get_ticks_msec()


## Envia uma mensagem.
## Se voce pretende continuar usando a instancia da mensagem apos chamar este metodo, voce deve definir `should_release` para `false`. `Message.release()` pode ser usado para retornar manualmente a mensagem para o pool posteriormente.
## - `message`: A mensagem a ser enviada.
## - `should_release`: Retorna ou nao a mensagem ao pool apos o envio.
func send(message: Message, should_release: bool = true) -> void:
	if message.send_mode == Enums.MessageSendMode.UNRELIABLE:
		_send_d(message.bytes, message.written_length)
	else:
		var _sequence_id := _next_sequence_id  # Obtem o proximo ID da sequencia
		PendingMessage.create_and_send(_sequence_id, message, self)

	if should_release:
		message.release()


@warning_ignore("unused_parameter")
## Envia dados.
## - `data_buffer`: O array que contem os dados.
## - `amount`: O numero de bytes no array que deve ser enviado.
func _send_d(data_buffer: PackedByteArray, amount: int) -> void:
	pass


## Atualiza ACKs e determina se a mensagem e duplicada.
## - `_sequence_id`: ID da sequencia da mensagem.
## - `returns`: Se a mensagem deve ou nao ser tratada.
func reliable_handle(_sequence_id: int) -> bool:
	var do_handle := true
	# Atualizar ACKs
	var sequence_gap := Helper.get_sequence_gap(_sequence_id, _last_received_seq_id)
	if sequence_gap > 0:
		# O ID da sequencia recebida e mais recente que o anterior
		if sequence_gap > 64:
			(
				NetworkLogger
				. Log(
					Enums.LogTypes.WARNING,
					peer.log_name,
					(
						"O intervalo entre os IDs de sequencia recebidos era muito grande ("
						+ str(sequence_gap)
						+ ")! Se a perda de pacotes da conexao, latencia ou sua taxa de envio de mensagens confiaveis aumentar muito mais, os IDs de sequencia podem comecar a ficar fora dos limites do filtro duplicado."
					)
				)
			)

		_duplicate_filter_bitfield <<= sequence_gap
		if sequence_gap <= 16:
			var shifted_bits: int = _acks_bitfield << sequence_gap
			_acks_bitfield = shifted_bits  # De ao bitfield ACKs os primeiros 2 bytes dos bits deslocados
			_duplicate_filter_bitfield |= shifted_bits >> 16  # OU os ultimos 6 bytes dos bits deslocados no campo de bits do filtro duplicado

			do_handle = _update_acks_bitfield(sequence_gap)
			_last_received_seq_id = _sequence_id
		elif sequence_gap <= 80:
			var shifted_bits: int = _acks_bitfield << (sequence_gap - 16)
			_acks_bitfield = 0  # Redefina o campo de bits ACKs, pois todos os seus bits estao sendo movidos para o campo de bits do filtro duplicado
			_duplicate_filter_bitfield |= shifted_bits  # OU os bits deslocados no campo de bits do filtro duplicado

			do_handle = _update_duplicate_filter_bitfield(sequence_gap)
	elif sequence_gap < 0:
		# O ID da sequencia recebida e mais antigo que o anterior (mensagem fora de ordem)
		sequence_gap = -sequence_gap  # Torna o sequence_gap positivo
		if sequence_gap <= 16:  # Se a sequencia OF da mensagem ainda estiver dentro do intervalo de valores do campo de bit ACK
			do_handle = _update_acks_bitfield(sequence_gap)
		elif sequence_gap <= 80:  # Se for uma mensagem "antiga" e seu ID de sequencia nao estiver mais dentro do intervalo de valores do bitfield ACK (mas estiver dentro do intervalo do filtro duplicado)
			do_handle = _update_duplicate_filter_bitfield(sequence_gap)
	else:  # O ID da sequencia recebida e igual ao anterior (mensagem duplicada)
		do_handle = false

	_send_ack(_sequence_id)
	return do_handle


## Limpa o lado local da conexao.
## - `was_rejected`: Se a conexao foi rejeitada ou nao.
func local_disconnect(was_rejected: bool = false) -> void:
	if was_rejected:
		_state = Enums.ConnectionState.REJECTED
	else:
		_state = Enums.ConnectionState.NOT_CONNECTED

	for pending_message in pending_messages.values() as Array[PendingMessage]:
		pending_message.clear(false)

	pending_messages.clear()


## Atualiza o campo de bits ACKs e determina se deve ou nao manipular a mensagem.
## - `sequence_gap`: O intervalo entre o ID de sequencia recem-recebido e o ultimo ID de sequencia recebido anteriormente.
## - `returns`: Se a mensagem deve ou nao ser tratada, com base em se e ou nao uma duplicata.
func _update_acks_bitfield(sequence_gap: int) -> bool:
	var seq_id_bit := 1 << sequence_gap - 1  # Calcula qual bit corresponde ao ID da sequencia e define-o como 1
	if (_acks_bitfield & seq_id_bit) == 0:
		# Se nao recebemos esta mensagem antes
		_acks_bitfield |= seq_id_bit  # Defina o bit correspondente ao ID da sequencia como 1 porque recebemos esse ID
		return true  # A mensagem era "nova", trate-a
	else:  # Se recebemos esta mensagem antes
		return false  # A mensagem era uma duplicata, nao trate disso


## Atualiza o bitfield do filtro duplicado e determina se deve ou nao manipular a mensagem.
## - `sequence_gap`: O intervalo entre o ID de sequencia recem-recebido e o ultimo ID de sequencia recebido anteriormente.
## - `returns`: Se a mensagem deve ou nao ser tratada, com base em se e ou nao uma duplicata.
func _update_duplicate_filter_bitfield(sequence_gap: int) -> bool:
	var seq_id_bit := 1 << (sequence_gap - 1 - 16)  # Calcula qual bit corresponde ao ID da sequencia e define-o como 1
	if (_duplicate_filter_bitfield & seq_id_bit) == 0:
		# Se nao recebemos esta mensagem antes
		_duplicate_filter_bitfield |= seq_id_bit  # Defina o bit correspondente ao ID da sequencia como 1 porque recebemos esse ID
		return true  # A mensagem era "nova", trate-a
	else:  # Se recebemos esta mensagem antes
		return false  # A mensagem era uma duplicata, nao trate disso


## Atualiza quais mensagens recebemos ACKs.
## - `remote_last_received_seq_id`: O ultimo ID de sequencia que a outra extremidade recebeu.
## - `remote_acks_bit_field`: Uma lista redundante de IDs de sequencia que a outra extremidade recebeu (ou nao).
func update_received_acks(remote_last_received_seq_id: int, remote_acks_bit_field: int) -> void:
	var sequence_gap := Helper.get_sequence_gap(remote_last_received_seq_id, _last_acked_seq_id)
	if sequence_gap > 0:
		# O ultimo ID de sequencia que a outra ponta recebeu e mais recente que o anterior
		for i in range(1, sequence_gap):  # NOTE: o loop comeca em 1, o que significa que so e executado se o intervalo nos IDs de sequencia for maior que 1
			_acked_messages_bitfield <<= 1  # Desloca os bits para a esquerda para abrir espaco para um ack anterior
			_check_message_ack_status(_last_acked_seq_id - 16 + i, _left_bit)  # Verifica o status de ACK do ID de sequencia mais antigo no bitfield (antes de ser removido)
		_acked_messages_bitfield <<= 1  # Muda os bits para a esquerda para abrir espaco para o ultimo ack
		_acked_messages_bitfield |= (remote_acks_bit_field | 1 << (sequence_gap - 1))  # Combine os campos de bit e certifique-se de que o bit correspondente ao ACK esteja definido como 1
		_last_acked_seq_id = remote_last_received_seq_id

		_check_message_ack_status(_last_acked_seq_id - 16, _left_bit)  # Verifica o status de ACK do ID de sequencia mais antigo no bitfield
	elif sequence_gap < 0:
		# TODO: remover? Acho que este caso nunca e executado
		# O ID de sequencia mais recente que a outra extremidade recebeu e mais antigo que o anterior (reconhecimento fora de ordem)
		sequence_gap = (-sequence_gap - 1)  # Porque o deslocamento de bits e baseado em 0
		var acked_bit := 1 << sequence_gap  # Calcula qual bit corresponde ao ID da sequencia e define-o como 1
		_acked_messages_bitfield |= acked_bit  # Define o bit correspondente ao ID da sequencia
		if pending_messages.has(remote_last_received_seq_id):
			var pending_message: PendingMessage = pending_messages[remote_last_received_seq_id]
			pending_message.clear()  # A mensagem foi entregue com sucesso, remova-a das mensagens pendentes.
		else:
			# O ultimo ID de sequencia que a outra ponta recebeu e o mesmo que o anterior (confirmacao duplicada)
			_acked_messages_bitfield |= remote_acks_bit_field  # Combina os campos de bits
			_check_message_ack_status(_last_acked_seq_id - 16, _left_bit)  # Verifica o status de ACK do ID de sequencia mais antigo no bitfield


## Verifique o status de confirmacao do ID de sequencia fornecido.
## -`sequence_id`: O ID da sequencia cujo status de reconhecimento deve ser verificado.
## -`bit`: O bit correspondente a posicao do ID da sequencia no campo de bit.
func _check_message_ack_status(sequence_id: int, bit: int) -> void:
	if (_acked_messages_bitfield & bit) == 0:
		# A mensagem foi perdida
		if pending_messages.has(sequence_id):
			var pending_message: PendingMessage = pending_messages[sequence_id]
			pending_message.retry_send()
		else:
			# A mensagem foi entregue com sucesso
			if pending_messages.has(sequence_id):
				var pending_message: PendingMessage = pending_messages[sequence_id]
				pending_message.clear()


## Marca imediatamente o `PendingMessage` de um determinado ID de sequencia como entregue.
## - `seq_id`: O ID da sequencia que foi confirmado.
func ack_message(seq_id: int) -> void:
	if pending_messages.has(seq_id):
		var pending_message: PendingMessage = pending_messages[seq_id]
		pending_message.clear()


## Coloca a conexao no estado pendente.
func set_pending() -> void:
	if is_connecting:
		_state = Enums.ConnectionState.PENDING
		reset_timeout()


# region Messages
## Envia uma mensagem de confirmacao para o ID de sequencia fornecido.
## - `for_seq_id`: O ID da sequencia a ser confirmado.
func _send_ack(for_seq_id: int) -> void:
	var header: Enums.MessageHeader
	if for_seq_id == _last_received_seq_id:
		header = Enums.MessageHeader.ACK
	else:
		header = Enums.MessageHeader.ACK_EXTRA

	var message: Message = Message.create(header)
	message.add_short(_last_received_seq_id)  # ID da ultima sequencia remota
	message.add_short(_acks_bitfield)  # Acks

	if for_seq_id != _last_received_seq_id:
		message.add_short(for_seq_id)

	send(message)


## Lida com uma mensagem de confirmacao.
## - `message`: A mensagem de confirmacao a ser tratada.
func handle_ack(message: Message) -> void:
	var remote_last_received_seq_id := message.get_short()
	var remote_acks_bit_field := message.get_short()

	ack_message(remote_last_received_seq_id)  # Marca-o imediatamente como entregue para que nenhum reenvio seja acionado enquanto aguarda o bit do ID da sequencia atingir o final do campo de bit
	update_received_acks(remote_last_received_seq_id, remote_acks_bit_field)


## Lida com uma mensagem de confirmacao para um ID de sequencia diferente do ultimo recebido.
## - `message`: A mensagem de confirmacao a ser tratada.
func handle_ack_extra(message: Message) -> void:
	var remote_last_received_seq_id: int = message.get_short()
	var remote_acks_bit_field: int = message.get_short()
	var acked_seq_id: int = message.get_short()

	ack_message(acked_seq_id)  # Marca-o imediatamente como entregue para que nenhum reenvio seja acionado enquanto aguarda o bit do ID da sequencia atingir o final do campo de bit
	update_received_acks(remote_last_received_seq_id, remote_acks_bit_field)


# region Server
## Envia uma mensagem de boas-vindas.
func send_welcome() -> void:
	var message := Message.create(Enums.MessageHeader.WELCOME)
	message.add_short(id)

	send(message)


## Manipula uma mensagem de boas-vindas no servidor.
## - `message`: A mensagem de boas-vindas a ser tratada.
func handle_welcome_response(message: Message) -> void:
	var _id := message.get_short()
	if id != _id:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR,
			peer.log_name,
			"O cliente assumiu o ID " + str(_id) + " em vez de " + str(id) + "!"
		)

	_state = Enums.ConnectionState.CONNECTED
	reset_timeout()


## Lida com uma mensagem de heartbeat.
## - `message`: A mensagem de pulsacao a ser tratada.
func handle_heartbeat(message: Message) -> void:
	_respond_heartbeat(message.get_byte())
	RTT = message.get_short()

	reset_timeout()


## Envia uma mensagem de heartbeat.
func _respond_heartbeat(ping_id: int) -> void:
	var message: Message = Message.create(Enums.MessageHeader.HEARTBEAT)
	message.add_byte(ping_id)

	send(message)


#endregion


# region Client
## Manipula uma mensagem de boas-vindas no cliente.
## - `message`: A mensagem de boas-vindas a ser tratada.
func handle_welcome(message: Message) -> void:
	id = message.get_short()
	_state = Enums.ConnectionState.CONNECTED
	reset_timeout()

	_respond_welcome()


## Envia uma mensagem de boas-vindas.
func _respond_welcome() -> void:
	var message: Message = Message.create(Enums.MessageHeader.WELCOME)
	message.add_short(id)

	send(message)


## Envia uma mensagem de heartbeat.
func send_heartbeat() -> void:
	_pending_ping_id = _last_ping_id
	_last_ping_id += 1
	_pending_ping_stopwatch.restart()

	var message: Message = Message.create(Enums.MessageHeader.HEARTBEAT)
	message.add_byte(_pending_ping_id)
	message.add_short(RTT)

	send(message)


## Lida com uma mensagem de heartbeat.
## - `message`: A mensagem de pulsacao a ser tratada.
func handle_heartbeat_response(message: Message) -> void:
	var ping_id: int = message.get_byte()

	if _pending_ping_id == ping_id:
		RTT = max(1, _pending_ping_stopwatch.get_elapsed_milliseconds())

	reset_timeout()
#endregion
#endregion
