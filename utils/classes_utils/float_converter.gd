class_name FloatConverter

var byte0: int
var byte1: int
var byte2: int
var byte3: int


func _init(value: float = 0) -> void:
	byte0 = 0
	byte1 = 0
	byte2 = 0
	byte3 = 0
	set_float_value(value)


func float_value() -> float:
	var bytes := PackedByteArray()
	bytes.append(byte0)
	bytes.append(byte1)
	bytes.append(byte2)
	bytes.append(byte3)
	return bytes.decode_float(0)


func set_float_value(value: float) -> void:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	byte0 = bytes[0]
	byte1 = bytes[1]
	byte2 = bytes[2]
	byte3 = bytes[3]
