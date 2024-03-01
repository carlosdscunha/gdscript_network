class_name TimeSpan

var milliseconds: float = 0


static func new_from_milliseconds(ms: float) -> TimeSpan:
	var timespan = TimeSpan.new()
	timespan.milliseconds = ms
	return timespan
