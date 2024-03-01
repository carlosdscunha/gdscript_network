## Fornece funcionalidade para ativar/desativar a retransmissao automatica de mensagens por tipo de mensagem.
class_name MessageRelayFilter

## O numero de bits que um int consiste.
const bits_per_int: int = sizeof.INT * 8
## Um array que armazena todos os bits que representam se as mensagens de um determinado ID devem ser retransmitidas ou nao.
var filter: PackedInt32Array = PackedInt32Array()


# Construtor que define o tamanho do filtro.
func _init(size: int):
	_set_(size)


## Define o tamanho do filtro.
## - `size`: Qual o tamanho do filtro.
func _set_(size: int) -> void:
	var new_size: int
	if size % bits_per_int > 0:
		new_size = int(float(size) / bits_per_int) + 1
	else:
		new_size = int(float(size) / bits_per_int)

	filter.resize(new_size)


## Ativa a retransmissao automatica para o ID da mensagem fornecido.
## - `for_message_id`: O ID da mensagem para habilitar a retransmissao.
func enable_relay(for_message_id: int) -> void:
	filter[int(float(for_message_id) / bits_per_int)] |= 1 << (for_message_id % bits_per_int)


## Desativa a retransmissao automatica para o ID da mensagem fornecido.
## - `for_message_id`: O ID da mensagem para habilitar a retransmissao.
func disable_relay(for_message_id: int) -> void:
	filter[int(float(for_message_id) / bits_per_int)] &= ~(1 << (for_message_id % bits_per_int))


## Verifica se as mensagens com o ID fornecido devem ou nao ser retransmitidas.
## -  `for_message_id`: O ID da mensagem a ser verificado.
## -  `returns`: Se as mensagens com o ID fornecido devem ou nao ser retransmitidas.
func should_relay(for_message_id: int) -> bool:
	return (
		(filter[int(float(for_message_id) / bits_per_int)] & (1 << (for_message_id % bits_per_int)))
		!= 0
	)
