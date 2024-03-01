## Fornece funcionalidade para converter dados em bytes e vice-versa.
class_name Message

## O numero maximo de bytes necessarios para o cabecalho de uma mensagem.
## 1 byte para o cabecalho atual, 2 bytes para o ID da sequencia (somente para mensagens confiaveis), 2 bytes para o ID da mensagem. As mensagens enviadas de forma nao confiavel usarao 2 bytes a menos que este valor para o cabecalho.
const max_header_size: int = 5
## O numero maximo de bytes que uma mensagem pode conter, incluindo o `max_header_size`.
static var max_size := max_header_size + 1225
## O numero maximo de bytes de dados de carga util que uma mensagem pode conter. Este valor representa quantos bytes podem ser adicionados a uma mensagem <i>sobre</i> o `max_header_size`.
static var max_payload_size: int:
	get:
		return max_size - max_header_size
	set(value):
		if Peer.active_count > 0:
			(
				NetworkLogger
				. Log(
					Enums.LogTypes.ERROR,
					"Alterar o tamanho maximo da mensagem nao e permitido enquanto um Server ou Client estiver em execucao!"
				)
			)
		else:
			if value < 0:
				(
					NetworkLogger
					. Log(
						Enums.LogTypes.ERROR,
						(
							"O tamanho maximo da carga util nao pode ser negativo! Definindo-o como 0 em vez do valor fornecido ("
							+ str(value)
							+ ")."
						)
					)
				)
				max_size = max_header_size
			else:
				max_size = max_header_size + value

			trim_pool()  # Quando ActiveSocketCount e 0, isso limpa o _pool

## Quantas mensagens adicionar ao _pool para cada instancia `Server` ou `Client` iniciada.
## As alteracaes nao afetarao as instancias `Server` e `Client` que ja estao em execucao ate que sejam reiniciadas.
static var instances_per_peer: int = 4
## Um conjunto de instancias de mensagens reutilizaveis.
## `Array - Message`
static var _pool: Array[Message] = []
static var _capacity := instances_per_peer * 2

## O modo de envio da mensagem.
var send_mode: Enums.MessageSendMode
## Quantos bytes a mais podem ser recuperados da mensagem.
var unread_length: int:
	get:
		return _write_pos - _read_pos
## Quantos bytes foram adicionados a mensagem.
var written_length: int:
	get:
		return _write_pos
## Quantos bytes a mais podem ser adicionados a mensagem.
var unwritten_length: int:
	get:
		return bytes.size() - _write_pos
## Os dados da mensagem.
var bytes: PackedByteArray

## A posicao no array de bytes em que os proximos bytes serao gravados.
var _write_pos: int = 0
## A posicao no array de bytes a partir da qual os proximos bytes serao lidos.
var _read_pos: int = 0


## Inicializa uma instancia `Message` reutilizavel.
## - `_maxSize`: A quantidade maxima de bytes que a mensagem pode conter.
func _init(_maxSize: int):
	bytes.resize(max_size)


#region Pooling
## Corta o _pool de mensagens para um tamanho mais apropriado para quantas instancias `Server` e/ou `Client` estao em execucao no momento.
static func trim_pool() -> void:
	if Peer.active_count == 0:
		# Nao ha servidores ou clientes em execucao, esvazie a lista e redefina a capacidade
		_pool.clear()
		_capacity = instances_per_peer * 2  # x2 para algum espaco de buffer para instancias de Message extras, se necessario
	else:
		# Redefina a capacidade do _pool e o numero de instancias de mensagens no _pool para o que e apropriado para quantos servidores e clientes estao ativos
		var ideal_instance_amount: int = Peer.active_count * instances_per_peer
		if _pool.size() > ideal_instance_amount:
			var index := Peer.active_count * instances_per_peer
			var count := _pool.size() - ideal_instance_amount
			_pool = _pool.slice(0, index) + _pool.slice(index + count, _pool.size())
			_capacity = ideal_instance_amount * 2


## Obtem uma instancia de mensagem utilizavel.
## - `create()`
## Obtem uma instancia de mensagem que pode ser usada para envio.
## - `create(sendMode: Enums.MessageSendMode, id: int)`
## - `create(header: Enums.MessageHeader)`
static func create(sendMode_header: Variant = null, id: int = -1) -> Message:
	if sendMode_header == null:
		return _retrieve_from_pool()._prepare_for_use()

	elif sendMode_header is Enums.MessageSendMode and id != -1:
		return (
			_retrieve_from_pool()
			. _prepare_for_use_header(sendMode_header as Enums.MessageHeader)
			. add_short(id)
		)

	elif sendMode_header is Enums.MessageHeader and id == -1:
		return _retrieve_from_pool()._prepare_for_use_header(sendMode_header)

	else:
		NetworkLogger.log_warning(
			["sendMode_header types para Enums.MessageSendMode ou Enums.MessageHeader."], 1
		)
		return null


## Obtem uma instancia de mensagem diretamente do _pool sem fazer nenhuma configuracao extra.
## Como esta instancia da mensagem e retornada diretamente do _pool, ela contera todos os dados e configuracoes anteriores. Usar esta instancia sem prepara-la adequadamente provavelmente resultara em um comportamento inesperado.
## - `returns`: Uma instancia de mensagem.
static func create_raw() -> Message:
	return _retrieve_from_pool()


## Recupera uma instancia de mensagem do _pool. Se nenhuma estiver disponivel, uma nova instancia sera criada.
## - `returns`: Uma instancia de mensagem pronta para ser usada para envio ou manipulacao.
static func _retrieve_from_pool() -> Message:
	var message: Message
	if _pool.size() > 0:
		message = _pool[0]
		_pool.remove_at(0)
	else:
		message = Message.new(max_size)

	return message


## Retorna a instancia da mensagem ao _pool interno para que possa ser reutilizada.
func release() -> void:
	if _pool.size() < _capacity:
		# Existe Pool e ha espaco
		if not _pool.has(self):
			_pool.append(self)  # Adicione apenas se ainda nao estiver na lista, caso contrario, este metodo sendo chamado duas vezes seguidas por qualquer motivo pode causar problemas *serios*


#endregion


#region Functions
## Prepara a mensagem a ser utilizada.
## - `returns`: A mensagem, pronta para ser usada.
func _prepare_for_use() -> Message:
	_read_pos = 0
	_write_pos = 0
	return self


## Prepara a mensagem a ser utilizada.
## - `header`: O cabecalho da mensagem.
## - `returns`: A mensagem, pronta para ser usada.
func _prepare_for_use_header(header: Enums.MessageHeader) -> Message:
	set_header(header)
	return self


## Prepara a mensagem a ser usada para tratamento.
## - `header`: O cabecalho da mensagem.
## - `content_length`: O numero de bytes que esta mensagem contem e que pode ser recuperado.
## - `returns`: A mensagem, pronta para ser usada para manipulacao.
func prepare_for_use(header: Enums.MessageHeader, content_length: int) -> Message:
	set_header(header)
	_write_pos = content_length
	return self


## Define o byte do cabecalho da mensagem para o `header` fornecido e determina o `Enums.MessageSendMode` apropriado e as posicoes de leitura/gravacao.
## - `header`: O cabecalho a ser usado para esta mensagem.
func set_header(header: Enums.MessageHeader) -> void:
	bytes[0] = header
	if header >= Enums.MessageHeader.RELIABLE:
		_read_pos = 3
		_write_pos = 3
		send_mode = Enums.MessageSendMode.RELIABLE
	else:
		_read_pos = 1
		_write_pos = 1
		send_mode = Enums.MessageSendMode.UNRELIABLE


#endregion


#region  Add & Retrieve Data
#region Byte
## Adiciona um unico `byte` a mensagem.
## - `value`: O `byte` a adicionar.
## - `returns`: A mensagem a qual o `byte` foi adicionado.
func add_byte(value: int) -> Message:
	if unwritten_length < 1:
		NetworkLogger.Log(
			Enums.LogTypes.THROW, InsufficientCapacityException.new(self, _byte_name, 1).message
		)

	bytes[_write_pos] = value
	_write_pos += 1
	return self


func get_byte() -> int:
	if unread_length < 1:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_byte_name))
		return 0

	var pos := _read_pos
	_read_pos += 1
	return bytes[pos]


func add_bytes(array: PackedByteArray, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	if unwritten_length < array.size():
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, array.size(), _byte_name, 1).message
		)

	# for i in range(array.size()):
	# 	bytes[_write_pos] = array[i]
	# 	_write_pos += 1
	ArrayUtil.copy(array, 0, bytes, _write_pos, array.size())
	_write_pos += array.size()
	return self


func get_bytes(
	amount: int = -1, into_array: PackedByteArray = PackedByteArray(), start_index: int = 0
):
	if amount == -1:
		return get_bytes(_get_array_length())
	elif into_array.size() == 0:
		var array: PackedByteArray = PackedByteArray()
		array.resize(amount)
		_read_bytes(amount, array)
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _byte_name
						)
					)
					. message
				)
			)

		_read_bytes(amount, into_array, start_index)


func _read_bytes(amount: int, into_array: PackedByteArray, start_index: int = 0) -> void:
	if unread_length < amount:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _byte_name)
		)
		amount = unread_length

	# for i in range(amount):
	# 	into_array[start_index + i] = bytes[_read_pos]
	# 	_read_pos += 1
	ArrayUtil.copy(bytes, _read_pos, into_array, start_index, amount)
	_read_pos += amount


#endregion


#region Bool
func add_bool(value: bool) -> Message:
	if unwritten_length < sizeof.BOOL:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _bool_name, sizeof.BOOL).message
		)

	if value:
		bytes[_write_pos] = 1
	else:
		bytes[_write_pos] = 0

	_write_pos += 1
	return self


func get_bool() -> bool:
	if unread_length < sizeof.BOOL:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_bool_name, "false"))
		return false

	var pos = _read_pos
	_read_pos += 1

	return bytes[pos] == 1


func add_bools(array: Array[bool], includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	var byteLength: int
	if (array.size() % 8) == 0:
		byteLength = int(float(array.size()) / 8)
	else:
		byteLength = int(float(array.size()) / 8 + 1)

	if unread_length < byteLength:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, array.size(), _bool_name, 1, byteLength).message
		)

	var isLengthMultipleOf8 = array.size() % 8 == 0
	for i in range(byteLength):
		var next_byte = 0
		var bits_to_write = 8
		if i + 1 == byteLength and not isLengthMultipleOf8:
			bits_to_write = array.size() % 8

		for bit in range(bits_to_write):
			if array[i * 8 + bit]:
				next_byte |= 1 << bit
			else:
				next_byte |= 0 << bit

		bytes[_write_pos + i] = next_byte

	_write_pos += byteLength
	return self


func get_bools(amount: int = -1, into_array: Array[bool] = [], start_index: int = 0):
	if amount == -1:
		return get_bools(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: Array[bool] = []
		array.resize(amount)

		var byte_amount: int
		if amount % 8 == 0:
			byte_amount = int(float(amount) / 8)
		else:
			byte_amount = int(float(amount) / 8 + 1)
		if unread_length < byte_amount:
			NetworkLogger.Log(
				Enums.LogTypes.ERROR, _not_enough_bytes_error(array.size(), _bool_name)
			)
			byte_amount = unread_length

		_read_bools(byte_amount, array)
		return array
	elif into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _bool_name
						)
					)
					. message
				)
			)

		var byte_amount: int
		if amount % 8 == 0:
			byte_amount = int(float(amount) / 8)
		else:
			byte_amount = int(float(amount) / 8 + 1)
		if unread_length < byte_amount:
			NetworkLogger.Log(
				Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _bool_name)
			)

		_read_bools(byte_amount, into_array, start_index)


func _read_bools(byteAmount: int, into_array: Array[bool], start_index: int = 0) -> void:
	var isLengthMultipleOf8 = into_array.size() % 8 == 0
	for i in range(byteAmount):
		var bits_to_read = 8
		if i + 1 == byteAmount and not isLengthMultipleOf8:
			bits_to_read = into_array.size() % 8

			for bit in range(bits_to_read):
				into_array[start_index + (i * 8 + bit)] = ((bytes[_read_pos + i] >> bit) & 1) == 1

	_read_pos += byteAmount


#endregion


# region Short
func add_short(value: int) -> Message:
	if unwritten_length < sizeof.SHORT:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _short_name, sizeof.SHORT).message
		)

	Converter.from_short(value, bytes, _write_pos)
	_write_pos += sizeof.SHORT
	return self


func get_short() -> int:
	if unread_length < sizeof.SHORT:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_short_name))
		return 0

	var value := Converter.to_short(bytes, _read_pos)
	_read_pos += sizeof.SHORT
	return value


func add_shorts(array: PackedInt32Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	if unwritten_length < array.size() * sizeof.SHORT:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, array.size(), sizeof.SHORT).message
		)

	for i in range(array.size()):
		add_short(array[i])

	return self


func get_shorts(
	amount: int = -1, into_array: PackedInt32Array = PackedInt32Array(), start_index: int = 0
):
	if amount == -1:
		return get_shorts(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedInt32Array = PackedInt32Array()
		array.resize(amount)
		_read_shorts(amount, array)
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _short_name
						)
					)
					. message
				)
			)

		_read_shorts(amount, into_array, start_index)


func _read_shorts(amount: int, into_array: PackedInt32Array, start_index: int = 0) -> void:
	if unread_length < amount * sizeof.SHORT:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _short_name)
		)
		amount = int(float(unread_length) / sizeof.SHORT)

	for i in range(amount):
		into_array[start_index + i] = Converter.to_short(bytes, _read_pos)
		_read_pos += sizeof.SHORT


#endregion


#region Int
func add_int(value: int) -> Message:
	if unwritten_length < sizeof.INT:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _int_name, sizeof.INT).message
		)

	Converter.from_int(value, bytes, _write_pos)
	_write_pos += sizeof.INT
	return self


func get_int() -> int:
	if unread_length < sizeof.INT:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_int_name))
		return 0

	var value := Converter.to_int(bytes, _read_pos)
	_read_pos += sizeof.INT
	return value


func add_ints(array: PackedInt32Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	if unwritten_length < array.size() * sizeof.INT:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, array.size(), _int_name, sizeof.INT).message
		)

	for i in range(array.size()):
		add_int(array[i])

	return self


func get_ints(
	amount: int = -1, into_array: PackedInt32Array = PackedInt32Array(), start_index: int = 0
):
	if amount == -1:
		return get_ints(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedInt32Array = PackedInt32Array()
		array.resize(amount)
		_read_ints(amount, array)
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _int_name
						)
					)
					. message
				)
			)

		_read_ints(amount, into_array, start_index)


func _read_ints(amount: int, into_array: PackedInt32Array, start_index: int = 0) -> void:
	if unread_length < amount * sizeof.INT:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _int_name)
		)
		amount = int(float(unread_length) / sizeof.INT)

	for i in range(amount):
		into_array[start_index + i] = Converter.to_int(bytes, _read_pos)
		_read_pos += sizeof.INT


#endregion


#region long
func add_long(value: int) -> Message:
	if unwritten_length < sizeof.LONG:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _long_name, sizeof.LONG).message
		)

	Converter.from_long(value, bytes, _write_pos)
	_write_pos += sizeof.LONG
	return self


func get_long() -> int:
	if unread_length < sizeof.LONG:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_long_name))
		return 0

	var value: int = Converter.to_long(bytes, _read_pos)
	_read_pos += sizeof.LONG
	return value


func add_longs(array: PackedInt64Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	if unwritten_length < array.size() * sizeof.LONG:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, array.size(), _long_name, sizeof.LONG).message
		)

	for i in range(array.size()):
		add_long(array[i])

	return self


func get_longs(
	amount: int = -1, into_array: PackedInt64Array = PackedInt64Array(), start_index: int = 0
):
	if amount == -1:
		return get_longs(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedInt64Array = PackedInt64Array()
		array.resize(amount)
		_read_longs(amount, array)
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _long_name
						)
					)
					. message
				)
			)

		_read_longs(amount, into_array, start_index)


func _read_longs(amount: int, into_array: PackedInt64Array, start_index: int = 0) -> void:
	if unread_length < amount * sizeof.LONG:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _long_name)
		)
		amount = int(float(unread_length) / sizeof.LONG)

	for i in range(amount):
		into_array[start_index + i] = Converter.to_long(bytes, _read_pos)
		_read_pos += sizeof.LONG


#endregion


#region Float
func add_float(value: float) -> Message:
	if unwritten_length < sizeof.FLOAT:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _float_name, sizeof.FLOAT).message
		)

	Converter.from_float(value, bytes, _write_pos)
	_write_pos += sizeof.FLOAT
	return self


func get_float() -> float:
	if unread_length < sizeof.FLOAT:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_float_name))
		return 0

	var value: float = Converter.to_float(bytes, _read_pos)
	_read_pos += sizeof.FLOAT
	return value


func add_floats(array: PackedFloat32Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	if unwritten_length < array.size() * sizeof.FLOAT:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, array.size(), _float_name, sizeof.FLOAT).message
		)

	for i in range(array.size()):
		add_float(array[i])

	return self


func get_floats(
	amount: int = -1, into_array: PackedFloat32Array = PackedFloat32Array(), start_index: int = 0
):
	if amount == -1:
		return get_floats(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedFloat32Array = PackedFloat32Array()
		array.resize(amount)
		_read_floats(amount, array)
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _float_name
						)
					)
					. message
				)
			)

		_read_floats(amount, into_array, start_index)


func _read_floats(amount: int, into_array: PackedFloat32Array, start_index: int = 0) -> void:
	if unread_length < amount * sizeof.FLOAT:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _float_name)
		)
		amount = int(float(unread_length) / sizeof.FLOAT)

	for i in range(amount):
		into_array[start_index + i] = Converter.to_float(bytes, _read_pos)
		_read_pos += sizeof.FLOAT


#endregion


#region Double
func add_double(value: float) -> Message:
	if unwritten_length < sizeof.DOUBLE:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _double_name, sizeof.DOUBLE).message
		)

	Converter.from_double(value, bytes, _write_pos)
	_write_pos += sizeof.DOUBLE
	return self


func get_double() -> float:
	if unread_length < sizeof.DOUBLE:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_double_name))
		return 0

	var value: float = Converter.to_double(bytes, _read_pos)
	_read_pos += sizeof.DOUBLE
	return value


func add_doubles(array: PackedFloat64Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	if unwritten_length < array.size() * sizeof.DOUBLE:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			(
				InsufficientCapacityException
				. new(self, array.size(), _double_name, sizeof.DOUBLE)
				. message
			)
		)

	for i in range(array.size()):
		add_double(array[i])

	return self


func get_doubles(
	amount: int = -1, into_array: PackedFloat64Array = PackedFloat64Array(), start_index: int = 0
):
	if amount == -1:
		return get_doubles(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedFloat64Array = PackedFloat64Array()
		array.resize(amount)
		_read_doubles(amount, array)
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _double_name
						)
					)
					. message
				)
			)

		_read_doubles(amount, into_array, start_index)


func _read_doubles(amount: int, into_array: PackedFloat64Array, start_index: int = 0) -> void:
	if unread_length < amount * sizeof.DOUBLE:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(into_array.size(), _double_name)
		)
		amount = int(float(unread_length) / sizeof.DOUBLE)

	for i in range(amount):
		into_array[start_index + i] = Converter.to_double(bytes, _read_pos)
		_read_pos += sizeof.DOUBLE


#endregion


#region String
func add_string(value: String) -> Message:
	var string_bytes: PackedByteArray = hex_to_byte_array(value)
	var required_bytes: int

	if string_bytes.size() <= oneByteLengthThreshold:
		required_bytes = string_bytes.size() + 1
	else:
		required_bytes = string_bytes.size() + 2

	if unwritten_length < required_bytes:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _string_name, required_bytes).message
		)

	add_bytes(string_bytes)

	return self


func get_string() -> String:
	var length: int = _get_array_length()
	if unread_length < length:
		NetworkLogger.Log(
			Enums.LogTypes.ERROR, _not_enough_bytes_error(_string_name, "shortened string")
		)
		length = unread_length

	var bytes_slice: PackedByteArray = bytes.slice(_read_pos, _read_pos + length)
	var value: String = bytes_slice.get_string_from_utf8()
	_read_pos += length

	return value


func add_strings(array: PackedStringArray, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	for i in range(array.size()):
		add_string(array[i])

	return self


func get_strings(
	amount: int = -1, into_array: PackedStringArray = PackedStringArray(), start_index: int = 0
):
	if amount == -1:
		return get_strings(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedStringArray = PackedStringArray()
		array.resize(amount)
		for i in range(array.size()):
			array[i] = get_string()
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, _string_name
						)
					)
					. message
				)
			)

		for i in range(amount):
			into_array[start_index + i] = get_string()


#endregion


#region Vector2
func add_vector2(value: Vector2) -> Message:
	return add_float(value.x).add_float(value.y)


func get_vector2() -> Vector2:
	return Vector2(get_float(), get_float())


func add_vector2s(array: PackedVector2Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	for i in range(array.size()):
		add_vector2(array[i])

	return self


func get_vector2s(
	amount: int = -1, into_array: PackedVector2Array = PackedVector2Array(), start_index: int = 0
):
	if amount == -1:
		return get_vector2s(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedVector2Array = PackedVector2Array()
		array.resize(amount)
		for i in range(array.size()):
			array[i] = get_vector2()
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, "vector2"
						)
					)
					. message
				)
			)

		for i in range(amount):
			into_array[start_index + i] = get_vector2()


#endregion


#region Vector3
func add_vector3(value: Vector3) -> Message:
	return add_float(value.x).add_float(value.y).add_float(value.z)


func get_vector3() -> Vector3:
	return Vector3(get_float(), get_float(), get_float())


func add_vector3s(array: PackedVector3Array, includeLength: bool = true) -> Message:
	if includeLength:
		_add_array_length(array.size())

	for i in range(array.size()):
		add_vector3(array[i])

	return self


func get_vector3s(
	amount: int = -1, into_array: PackedVector3Array = PackedVector3Array(), start_index: int = 0
):
	if amount == -1:
		return get_vector3s(_get_array_length())
	elif amount != -1 and into_array.size() == 0:
		var array: PackedVector3Array = PackedVector3Array()
		array.resize(amount)
		for i in range(array.size()):
			array[i] = get_vector3()
		return array
	elif amount != -1 and into_array.size() != 0:
		if start_index + amount > into_array.size():
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				(
					ArgumentException
					. new(
						"amount",
						_array_not_long_enough_error(
							amount, into_array.size(), start_index, "vector3"
						)
					)
					. message
				)
			)

		for i in range(amount):
			into_array[start_index + i] = get_vector3()


#endregion

#region  Array Lengths
const oneByteLengthThreshold: int = 0b0111_1111
const twoByteLengthThreshold: int = 0b0111_1111_1111_1111


func _add_array_length(length: int) -> void:
	if unwritten_length < 1:
		var byt: int
		if length <= oneByteLengthThreshold:
			byt = 1
		else:
			byt = 2
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			InsufficientCapacityException.new(self, _array_length_name, byt).message
		)

	if length <= oneByteLengthThreshold:
		bytes[_write_pos] = length
		_write_pos += 1
	else:
		if length > twoByteLengthThreshold:
			(
				NetworkLogger
				. Log(
					Enums.LogTypes.THROW,
					"length",
					(
						" As mensagens nao suportam a inclusao automatica de comprimentos de array para arrays com mais de "
						+ str(twoByteLengthThreshold)
						+ " elementos! Envie um array menor ou defina o parametro 'includeLength' como falso no metodo add e passe manualmente o comprimento do array para o metodo get."
					)
				)
			)

		if unwritten_length < 2:
			NetworkLogger.Log(
				Enums.LogTypes.THROW,
				InsufficientCapacityException.new(self, _array_length_name, 2).message
			)

		length |= 0b1000_0000_0000_0000
		bytes[_write_pos] = length >> 8
		_write_pos += 1
		bytes[_write_pos] = length
		_write_pos += 1


func _get_array_length() -> int:
	if unread_length < 1:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_array_length_name))
		return 0

	if (bytes[_read_pos] & 0b1000_0000) == 0:
		return get_byte()

	if unread_length < 2:
		NetworkLogger.Log(Enums.LogTypes.ERROR, _not_enough_bytes_error(_array_length_name))
		return 0

	var pos: int = _read_pos
	_read_pos += 2
	return ((bytes[pos] << 8) | bytes[pos + 1]) & 0b0111_1111_1111_1111


func hex_to_byte_array(value: String) -> PackedByteArray:
	var hex: String = value.to_utf8_buffer().hex_encode()
	var hex_length = hex.length()
	if hex_length % 2 == 1:
		NetworkLogger.Log(Enums.LogTypes.THROW, "Not even length hex input")
		return PackedByteArray()

	var byte_length = int(float(hex_length) / 2)
	var result = PackedByteArray()
	result.resize(byte_length)

	for byte_index in range(byte_length):
		var hex_index = byte_index * 2
		var hex_couple = hex.substr(hex_index, 2)
		result[byte_index] = ("0x" + hex_couple).hex_to_int()

	return result

#endregion
#endregion


#region Error Messaging
## O nome de um valor `byte`.
const _byte_name: String = "byte"
## O nome de um valor `sbyte`.
const _sbyte_name: String = "sbyte"
## O nome de um valor `bool`.
const _bool_name: String = "bool"
## O nome de um valor `short`.
const _short_name: String = "short"
## O nome de um valor `int`.
const _int_name: String = "int"
## O nome de um valor `long`.
const _long_name: String = "long"
## O nome de um valor `float`.
const _float_name: String = "float"
## O nome de um valor `double`.
const _double_name: String = "double"
## O nome de um valor `String`.
const _string_name: String = "String"
## O nome de um valor de comprimento de array.
const _array_length_name: String = "array length"


func _not_enough_bytes_error(
	valueName_arrayLength: Variant, defaultReturn_valueName: String = "0"
) -> String:
	if typeof(valueName_arrayLength) == TYPE_STRING:
		return (
			"A mensagem contem apenas "
			+ str(unread_length)
			+ Helper.correct_form(unread_length, "byte")
			+ " nao lido, o que nao e suficiente para recuperar um valor do tipo '"
			+ valueName_arrayLength
			+ "'! Retornando "
			+ defaultReturn_valueName
			+ "."
		)
	elif typeof(valueName_arrayLength) == TYPE_INT:
		return (
			"A mensagem contem apenas"
			+ str(unread_length)
			+ Helper.correct_form(unread_length, "byte")
			+ " nao lido, o que nao e suficiente para recuperar"
			+ valueName_arrayLength
			+ " "
			+ Helper.correct_form(valueName_arrayLength, defaultReturn_valueName)
			+ "! O array retornada contera elementos padrao."
		)

	return ""


func _array_not_long_enough_error(
	amount: int, arrayLength: int, start_index: int, valueName: String, pluralValueName: String = ""
) -> String:
	if pluralValueName == "":
		pluralValueName = str(valueName) + "s"

	return (
		"A quantidade de "
		+ pluralValueName
		+ " a ser recuperada ("
		+ str(amount)
		+ ") e maior que o numero de elementos do indice inicial ("
		+ str(start_index)
		+ ") ate o final do array fornecido (comprimento: "
		+ str(arrayLength)
		+ ")!"
	)

#endregion
