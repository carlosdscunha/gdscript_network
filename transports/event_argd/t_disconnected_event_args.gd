## Contem dados de eventos para quando o transporte de um servidor ou cliente inicia ou detecta uma desconexao.
class_name TDisconnectedEventArgs

## A conexao fechada.
var connection: Connection
## O motivo da desconexao.
var reason: Enums.DisconnectReason


## Inicializa os dados do evento.
## - `_connection`: A conexao fechada.
## - `_reason`: O motivo da desconexao.
func _init(_connection: Connection, _reason: Enums.DisconnectReason):
	connection = _connection
	reason = _reason
