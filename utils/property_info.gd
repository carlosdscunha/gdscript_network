class_name PropertyInfo

var type_name: StringName
var name: StringName
var mh_info: MessageHandlerInfo


func _init(_type_name: StringName, property_name: StringName, _mh_info: MessageHandlerInfo):
	type_name = _type_name
	name = property_name
	mh_info = _mh_info
