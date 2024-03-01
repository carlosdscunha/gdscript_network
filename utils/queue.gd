class_name Queue

## Retorna o numero de elementos na fila
var count: int:
	get:
		return _queue_data.size()

var _queue_data: Array  # Array para armazenar os elementos da fila
var _capacity: int


func _init(capacity: int = 0):
	_queue_data = Array()
	_capacity = capacity


## Adiciona um elemento ao final da fila
func enqueue(item) -> void:
	if _capacity == 0 or len(_queue_data) < _capacity:
		_queue_data.push_back(item)


## Remove e retorna o elemento do inicio da fila
func dequeue() -> Variant:
	return _queue_data.pop_front()


## Verifica se a fila esta vazia
func is_empty() -> bool:
	return _queue_data.is_empty()
