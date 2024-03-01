## Contem dados de evento para quando um cliente nao local se desconecta do servidor.
class_name ClientDisconnectedEventArgs

## O ID numerico do cliente que se desconectou.
var id: int


## Inicializa os dados do evento.
## - `_id`: O ID numerico do cliente que se desconectou.
func _init(_id: int):
	id = _id
