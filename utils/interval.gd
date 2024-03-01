class_name Interval extends Node

static var singleton: Interval

var timers: Dictionary = {}


func _init(_parent: Node):
	name = "Interval"
	singleton = self

	_parent.get_window().add_child.call_deferred(self)


func new_callback(callback: Callable, wait_time: float = 1.0, one_shot: bool = false):
	var timer := Timer.new()
	timer.name = callback.get_method()
	timer.connect("timeout", callback)
	timer.wait_time = wait_time
	timer.one_shot = one_shot

	add_child(timer)

	timer.start()
	timers[callback.get_method()] = timer


func stop_callback(callback: Callable):
	if timers.has(callback.get_method()):
		var timer: Timer = timers[callback.get_method()]
		if timer.is_stopped():
			timer.stop()
		timer.queue_free()
		timers.erase(callback.get_method())
