## Contem dados de evento para quando um cliente se conecta ao servidor.
class_name ServerConnectedEventArgs

## O cliente recem-conectado.
var client: Connection


## Inicializa os dados do evento.
## - `_client`: O cliente recem-conectado.
func _init(_client: Connection):
	client = _client
