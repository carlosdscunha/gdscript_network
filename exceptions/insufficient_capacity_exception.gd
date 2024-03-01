## A excecao que e lancada quando uma `Message` nao contem bytes nao lidos suficientes para adicionar um determinado valor.
class_name InsufficientCapacityException extends Exception

## A mensagem com capacidade restante insuficiente.
var network_message: Message = null
## O nome do tipo que nao pode ser adicionado a mensagem.
var type_name: String = ""
## O numero de bytes disponiveis que o tipo requer para ser adicionado com sucesso.
var required_bytes: int = 0


## Inicializa uma nova instancia `InsufficientCapacityException`.
## - `new()`
## - `new(_message: String)`
## - `new(_message: String, _inner: Exception)`
## - `new(_message: String, _type_name: String, _required_bytes: int)`
## - `new(_message: String, _array_length: int, _type_name: String, _required_bytes: int, _total_required_bytes: int = -1)`
func _init(
	_message: Variant = null,
	_inner_or_type_name_or_array_length: Variant = null,
	_required_bytes_or_type_name: Variant = null,
	_required_bytes: int = -1,
	_total_required_bytes: int = -1
):
	if typeof(_message) == TYPE_STRING and _inner_or_type_name_or_array_length == null:
		super._init(_message)
	elif typeof(_message) == TYPE_STRING and _inner_or_type_name_or_array_length is Exception:
		super._init(_message, _inner_or_type_name_or_array_length)
	elif (
		_message is Message
		and typeof(_inner_or_type_name_or_array_length) == TYPE_STRING
		and typeof(_required_bytes_or_type_name) == TYPE_INT
	):
		super._init(
			InsufficientCapacityException._get_error_message(
				_message, _inner_or_type_name_or_array_length, _required_bytes_or_type_name
			)
		)
		network_message = _message
		required_bytes = _required_bytes_or_type_name
		type_name = _inner_or_type_name_or_array_length
	elif (
		_message is Message
		and typeof(_inner_or_type_name_or_array_length) == TYPE_INT
		and typeof(_required_bytes_or_type_name) == TYPE_STRING
		and typeof(_required_bytes) == TYPE_INT
	):
		super._init(
			InsufficientCapacityException._get_error_message(
				_message,
				_inner_or_type_name_or_array_length,
				_required_bytes_or_type_name,
				_required_bytes,
				_total_required_bytes
			)
		)
		network_message = _message
		if _total_required_bytes == -1:
			required_bytes = _inner_or_type_name_or_array_length * _required_bytes
		else:
			required_bytes = _total_required_bytes
		type_name = _required_bytes_or_type_name + "[]"


## Constroi a mensagem de erro a partir das informacoes fornecidas.
## - `returns`: A mensagem de erro.
## - `_get_error_message(_message: Message, _type_name: String, _required_bytes: int)-> String;`
## - `_get_error_message(_message: Message, _array_length: int, _type_name: String, _required_bytes: int = -1, _total_required_bytes: int = -1)-> String;`
static func _get_error_message(
	_message: Message,
	_type_name_or_array_length: Variant,
	_required_bytes_or_type_name: Variant,
	_required_bytes: int = -1,
	_total_required_bytes: int = -1
) -> String:
	if (
		_message is Message
		and typeof(_type_name_or_array_length) == TYPE_STRING
		and typeof(_required_bytes_or_type_name) == TYPE_INT
	):
		return (
			"Nao e possivel adicionar um valor do tipo '"
			+ _type_name_or_array_length
			+ "' (requer "
			+ str(_required_bytes_or_type_name)
			+ " "
			+ Helper.correct_form(_required_bytes_or_type_name, "byte")
			+ ") para uma mensagem com "
			+ str(_message.unwritten_length)
			+ " "
			+ Helper.correct_form(_message.unwritten_length, "byte")
			+ " de capacidade restante!"
		)
	elif (
		_message is Message
		and typeof(_type_name_or_array_length) == TYPE_INT
		and typeof(_required_bytes_or_type_name) == TYPE_STRING
		and typeof(_required_bytes) == TYPE_INT
	):
		if _total_required_bytes == -1:
			_total_required_bytes = _type_name_or_array_length * _required_bytes

		return (
			"Nao e possivel adicionar um array do tipo '"
			+ str(_required_bytes_or_type_name)
			+ "[]' com "
			+ str(_type_name_or_array_length)
			+ " "
			+ Helper.correct_form(_type_name_or_array_length, "element")
			+ " "
			+ "(requer "
			+ str(_total_required_bytes)
			+ " "
			+ Helper.correct_form(_total_required_bytes, "byte")
			+ ") para uma mensagem com "
			+ str(_message.unwritten_length)
			+ " "
			+ Helper.correct_form(_message.unwritten_length, "byte")
			+ " de capacidade restante!"
		)

	return ""
