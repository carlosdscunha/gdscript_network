class_name FInfos

var type_name: StringName
var message_handlers: Array[MessageHandlerInfo]


func _init(_type_name: StringName = ""):
	type_name = _type_name
	message_handlers = []
