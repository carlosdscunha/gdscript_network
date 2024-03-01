## Contem dados de eventos para quando o transporte de um servidor estabelece com sucesso uma conexao com um cliente.
class_name ConnectedEventArgs

## A conexao recem-estabelecida.
var connection: Connection


## Inicializa os dados do evento.
## - `_connection`: A conexao recem-estabelecida.
func _init(_connection: Connection):
	connection = _connection
