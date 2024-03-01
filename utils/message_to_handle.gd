## Armazena informacoes sobre uma mensagem que precisa ser tratada.
class_name MessageToHandle

## A mensagem que precisa ser tratada.
var message: Message

## O tipo de cabecalho da mensagem.
var header: Enums.MessageHeader

## A conexao na qual a mensagem foi recebida.
var from_connection: Connection


## Lida com a inicializacao.
## - `_message`: A mensagem que precisa ser tratada.
## - `_header`: O tipo de cabecalho da mensagem.
## - `_from_connection`: A conexao na qual a mensagem foi recebida.
func _init(_message: Message, _header: Enums.MessageHeader, _from_connection: Connection):
	message = _message
	header = _header
	from_connection = _from_connection
