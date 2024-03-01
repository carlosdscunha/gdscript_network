## Fornece envio base &#38; receba funcionalidade para `TcpServer` e `TcpClient`.
class_name TcpPeer

## Invocado quando uma desconexao e iniciada ou detectada pelo transporte.
## `event EventHandler<DisconnectedEventArgs> Disconnected;`
signal disconnected(e: DisconnectedEventArgs)

## Um array na qual os dados de entrada sao recebidos.
var receive_buffer: PackedByteArray
## Um array do qual os dados de saida sao enviados.
var send_buffer: PackedByteArray

## O tamanho padrao usado para os buffers de envio e recebimento do soquete.
const _default_socket_buffer_size: int = 1024 * 1024  # 1MB
## O tamanho a ser usado para os buffers de envio e recebimento do soquete.
var _socket_buffer_size: int
@warning_ignore("unused_private_class_variable")
## O soquete principal, usado para escutar conexoes ou para enviar e receber dados.
var _socket = null
## O tamanho minimo que pode ser usado para os buffers de envio e recebimento do soquete.
const _min_socket_buffer_size: int = 256 * 1024  # 256KB


## Inicializa o transporte.
## - `socket_buffer_size`: Qual deve ser o tamanho dos buffers de envio e recebimento do soquete.
func _init(socket_buffer_size: int = _default_socket_buffer_size):
	if socket_buffer_size < _min_socket_buffer_size:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			(
				"[socket_buffer_size]: O tamanho minimo do buffer de soquete e "
				+ str(_min_socket_buffer_size)
				+ "!"
			)
		)

	_socket_buffer_size = socket_buffer_size
	# Precisa de espaco para a mensagem inteira mais o comprimento da mensagem (ja que e TCP)
	receive_buffer = PackedByteArray()
	receive_buffer.resize(Message.max_size + sizeof.SHORT)
	send_buffer = PackedByteArray()
	send_buffer.resize(Message.max_size + sizeof.SHORT)


@warning_ignore("unused_parameter")
## Trata os dados recebidos.
## - `amount`: O numero de bytes que foram recebidos.
## - `from_connection`: A conexao da qual os dados foram recebidos.
func _on_data_received(amount: int, from_connection: TcpConnection) -> void:
	pass


## Invoca o evento `disconnected`.
## - `connection`: A conexao fechada.
## - `reason`: O motivo da desconexao.
func _on_disconnected(connection: Connection, reason: Enums.DisconnectReason) -> void:
	if not disconnected.is_null():
		disconnected.emit(TDisconnectedEventArgs.new(connection, reason))
