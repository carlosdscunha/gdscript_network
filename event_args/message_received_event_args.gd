## Contem dados de evento para quando uma mensagem e recebida.
class_name MessageReceivedEventArgs

## A conexao da qual a mensagem foi recebida.
var from_connection: Connection
## O ID da mensagem.
var message_id: int
## A mensagem recebida.
var message: Message


## Inicializa os dados do evento.
## - `_from_connection`: A conexao da qual a mensagem foi recebida.
## - `_message_id`: O ID da mensagem.
## - `_message`: A mensagem recebida.
func _init(_from_connection: Connection, _message_id: int, _message: Message):
	from_connection = _from_connection
	message_id = _message_id
	message = _message
