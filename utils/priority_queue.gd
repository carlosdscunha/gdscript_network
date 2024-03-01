class_name PriorityQueue

const DEFAULT_CAPACITY: int = 8

var count: int:
	get:
		return entries.size()

var entries: Array[Entry]


func _init():
	entries = []


func enqueue(_element: Variant, _priority: Variant) -> void:
	var entry := Entry.new(_element, _priority)
	var index := 0

	while index < entries.size():
		if _priority < entries[index].priority:
			entries.insert(index, entry)
			return

		index += 1
	entries.append(entry)


func dequeue() -> Variant:
	var entry := entries[0]
	entries.remove_at(0)
	return entry.element


func peek_priority() -> Variant:
	return entries[0].priority


func clear() -> void:
	entries.clear()
