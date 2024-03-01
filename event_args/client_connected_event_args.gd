## Contem dados de evento para quando um cliente nao local se conecta ao servidor.
class_name ClientConnectedEventArgs

## O ID numerico do cliente conectado.
var id: int


## Inicializa os dados do evento.
## - `_id`: O ID numerico do cliente conectado.
func _init(_id: int):
	id = _id
