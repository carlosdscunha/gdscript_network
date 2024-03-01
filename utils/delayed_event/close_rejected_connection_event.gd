## Fecha a conexao fornecida quando invocada.
class_name CloseRejectedConnectionEvent
extends DelayedEvent

## O transporte ao qual a conexao pertence.
#TODO: ""
var transport: TcpServer

## A conexao para fechar.
var connection: Connection


## Inicializa o evento.
## - `_transport`: O transporte ao qual a conexao pertence.
## - `_connection`: A conexao para fechar.
func _init(_transport: TcpServer, _connection: Connection):
	transport = _transport
	connection = _connection


func invoke():
	transport.close(connection)
