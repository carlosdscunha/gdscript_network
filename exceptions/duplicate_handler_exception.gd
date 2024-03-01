## A excecao que e lancada quando varios metodos com `MessageHandlerAttributes` sao definidos para lidar com mensagens com o mesmo ID <i>e</i> tem a mesma assinatura de metodo.
class_name DuplicateHandlerException
extends Exception

## O ID da mensagem com varios metodos de manipulador.
var id: int
## /**O tipo que contem o primeiro metodo manipulador. */
var declaring_type_name1: String
## /**O nome do primeiro metodo manipulador. */
var handler_method_name1: String
## /**O tipo que contem o segundo metodo do manipulador. */
var declaring_type_name2: String
## /**O nome do segundo metodo manipulador. */
var handler_method_name2: String


## Inicializa uma nova instancia `DuplicateHandlerException`.
## - `new(_)`
## - `new(_message: String)`
## - `new(_message: String, _inner: Exception)`
## - `new(_id: int, _method1: GetFunctionInfo, _method2: GetFunctionInfo)`
func _init(_message_id: Variant = null, _inner_method1: Variant = null, _method2: Variant = null):
	if typeof(_message_id) == TYPE_STRING and _inner_method1 == null:
		super._init(_message_id)
	elif typeof(_message_id) == TYPE_STRING and _inner_method1 is Exception:
		super._init(_message_id, _inner_method1)
	elif (
		typeof(_message_id) == TYPE_INT
		and _inner_method1 is GetFunctionInfo
		and _method2 is GetFunctionInfo
	):
		super._init(
			DuplicateHandlerException.get_error_message(_message_id, _inner_method1, _method2)
		)
		id = _message_id
		declaring_type_name1 = _inner_method1.declaring_type_name
		handler_method_name1 = _inner_method1.function_name
		declaring_type_name2 = _method2.declaring_type_name
		handler_method_name2 = _method2.function_name


static func get_error_message(
	_id: int, _method1: GetFunctionInfo, _method2: GetFunctionInfo
) -> String:
	return (
		"Message handler method '"
		+ _method1.declaring_type_name
		+ "."
		+ _method1.function_name
		+ "' e '"
		+ _method2.declaring_type_name
		+ "."
		+ _method2.function_name
		+ "' sao ambos configurados para lidar com mensagens com ID "
		+ str(_id)
		+ "! Somente um O metodo do manipulador e permitido por ID de mensagem!"
	)
