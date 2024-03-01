class_name List

var _items: Array
var _capacity: int


## Inicializa uma instancia de Lista.
## - `capacity`: A capacidade inicial da lista (opcional).
func _init(capacity_: int = 0):
	_items = []
	_capacity = capacity_


## Retorna o numero de elementos na lista.
var count: int:
	get:
		return _items.size()

##  Obtem a capacidade atual da lista.
##  Define a capacidade da lista.
var capacity: int:
	get:
		return _capacity
	set(value):
		if value < count:
			_items.resize(value)
		_capacity = value


## Adiciona um elemento a lista.
## - `item`: O elemento a ser adicionado.
func add(item: Variant) -> void:
	ensure_capacity(count + 1)
	_items.append(item)


## Obtem o elemento da lista no indice especificado.
## - `index`: O indice do elemento a ser obtido.
## - `returns`: O elemento no indice especificado.
func get_value(index: int, default: Variant = null) -> Variant:
	if index >= 0 and index < count:
		default = _items[index]
	else:
		print("A lista nao contem um elemento no indice " + str(index))

	return default


func insert(position: int, value: Variant) -> int:
	return _items.insert(position, value)


## Remove a primeira ocorrencia do elemento especificado da lista.
## - `item`: O elemento a ser removido.
## - `returns`: Um valor bool indicando se o elemento foi removido com sucesso.
func remove(item: Variant) -> bool:
	var index := _items.find(item)
	if index != -1:
		_items = _items.slice(0, index) + _items.slice(index + 1)
		return true
	return false


## Remove o elemento no indice especificado da lista.
## - `index`: O indice do elemento a ser removido.
## - `returns`: Um valor bool indicando se o elemento foi removido com sucesso.
func remove_at(index: int) -> bool:
	if index >= 0 and index < count:
		_items.remove_at(index)
		return true
	return false


## Remove uma faixa de elementos da lista com base no indice e na contagem fornecidos.
## - `index`: O indice inicial da faixa a ser removida.
## - `_count`: O numero de elementos a serem removidos.
func remove_range(index: int, _count: int) -> void:
	print("Index:", index, "Count:", _count, "List Count:", count)
	if index < 0 or _count < 0 or index + _count > count or index >= count:
		print("Indice ou contagem invalidos.")
		return

	var new_items := _items.slice(0, index)
	new_items += _items.slice(index + _count, count)
	_items = new_items


## Remove todos os elementos da lista.
func clear() -> void:
	_items.clear()


## Verifica se a lista contem o elemento especificado.
## - `item`: O elemento a ser verificado.
## - `returns`: Um valor bool indicando se a lista contem o elemento.
func contains(item: Variant) -> bool:
	return _items.find(item) != -1


## Obtem o elemento da lista no indice especificado, ou null se o indice estiver fora dos limites da lista.
## - `index`: O indice do elemento a ser obtido.
## - `returns`: O elemento no indice especificado, ou null se o indice estiver fora dos limites da lista.
func get_item(index: int) -> Variant:
	if index >= 0 and index < count:
		return _items[index]
	return null


## Retorna uma copia da lista como um array.
## - `returns`: Um array contendo os elementos da lista.
func values() -> Array:
	return _items


## Garante a capacidade da lista para acomodar uma capacidade fornecida.
func ensure_capacity(capacity_: int) -> void:
	if capacity_ > _capacity:
		var new_capacity: int = max(_capacity * 2, capacity_)
		var new_items: Array = []
		for i in range(_items.size()):
			new_items.append(_items[i])
		_items = new_items
		_capacity = new_capacity


func get_to_dictionary() -> Dictionary:
	return {"type_name": "List", "capacity": capacity, "count": count, "_items": _items}
