## Contem dados de eventos para quando uma tentativa de conexao com um servidor falha.
class_name ConnectionFailedEventArgs

## Dados adicionais relacionados a tentativa de conexao com falha (se houver).
var message: Message


## Inicializa os dados do evento.
## -`_messgae`: Dados adicionais relacionados a tentativa de conexao com falha (se houver).
func _init(_message: Message):
	message = _message
