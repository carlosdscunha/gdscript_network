## Contem dados de eventos para quando um cliente se desconecta do servidor.
class_name ServerDisconnectedEventArgs

## O cliente que desconectou.
var client: Connection
## O motivo da desconexao.
var reason: Enums.DisconnectReason


## Inicializa os dados do evento.
## - `_client`: O cliente que desconectou.
## - `_reason`: O motivo da desconexao.
func _init(_client: Connection, _reason: Enums.DisconnectReason):
	client = _client
	reason = _reason
