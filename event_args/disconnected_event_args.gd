## Contem dados de eventos para quando o cliente se desconecta de um servidor.
class_name DisconnectedEventArgs

## O motivo da desconexao.
var reason: Enums.DisconnectReason
## Dados adicionais relacionados a desconexao (se houver).
var message: Message


## Inicializa os dados do evento.
## - `_reason`: O motivo da desconexao.
## - `_message`: Dados adicionais relacionados a desconexao (se houver).
func _init(_reason: Enums.DisconnectReason, _message: Message):
	reason = _reason
	message = _message
