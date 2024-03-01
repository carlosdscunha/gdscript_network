## Contem dados de evento para quando o transporte de um servidor ou cliente recebe dados.
class_name DataReceivedEventArgs

## Um array contendo os dados recebidos.
var data_buffer: PackedByteArray
## O numero de bytes que foram recebidos.
var amount: int
## A conexao da qual os dados foram recebidos.
var from_connection: Connection


## Inicializa os dados do evento.
## - `_data_buffer`: Um array contendo os dados recebidos.
## - `_amount`: O numero de bytes que foram recebidos.
## - `_from_connection`: A conexao da qual os dados foram recebidos.
func _init(_data_buffer: PackedByteArray, _amount: int, _from_connection: Connection):
	data_buffer = _data_buffer
	amount = _amount
	from_connection = _from_connection
