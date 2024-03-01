class_name Stopwatch

enum StopwatchState { STOPPED, RUNNING }

var _elapsed: float = 0
var _startTimeStamp: float = NAN
var _state: StopwatchState = StopwatchState.STOPPED


# Retorna o tempo em milissegundos a partir do objeto Date
func get_timestamp_milliseconds() -> float:
	return Time.get_ticks_msec()


func is_running() -> bool:
	return _state


# Construtor
func _init():
	reset()


# Inicia o cronometro
func start() -> void:
	if _state == StopwatchState.STOPPED:
		_startTimeStamp = get_timestamp_milliseconds()
		_state = StopwatchState.RUNNING


# Para o cronometro e atualiza o tempo decorrido
func stop() -> void:
	if _state == StopwatchState.RUNNING:
		var currentTime = get_timestamp_milliseconds()
		var lapTime = currentTime - _startTimeStamp
		_elapsed += lapTime
		_state = StopwatchState.STOPPED


# Redefine o cronometro para o estado inicial
func reset() -> void:
	_elapsed = 0
	_state = StopwatchState.STOPPED
	_startTimeStamp = NAN


# Reinicia o cronometro
func restart() -> void:
	reset()
	start()


# Registra um lap e retorna o tempo decorrido ate o lap atual
func lap() -> float:
	if _state == StopwatchState.RUNNING:
		var currentTime = get_timestamp_milliseconds()
		var lapTime = currentTime - _startTimeStamp
		_startTimeStamp = currentTime
		_elapsed += lapTime
		return lapTime
	else:
		return 0


# Retorna o tempo decorrido do lap atual em milissegundos
func get_current_lap_milliseconds() -> float:
	if _state == StopwatchState.RUNNING:
		return get_timestamp_milliseconds() - _startTimeStamp

	return 0


# Retorna o tempo decorrido do lap atual como um objeto TimeSpan
func get_current_lap() -> TimeSpan:
	var lapMilliseconds = get_current_lap_milliseconds()
	return TimeSpan.new_from_milliseconds(lapMilliseconds)


# Retorna o tempo decorrido em milissegundos
func get_elapsed_milliseconds() -> float:
	var elapsedMilliseconds = _elapsed

	if _state == StopwatchState.RUNNING:
		elapsedMilliseconds += get_current_lap_milliseconds()

	return elapsedMilliseconds


# Retorna o tempo decorrido como um objeto TimeSpan
func get_elapsed() -> TimeSpan:
	var elapsedMilliseconds = get_elapsed_milliseconds()
	return TimeSpan.new_from_milliseconds(elapsedMilliseconds)
