class_name DoubleConverter

var byte0: int
var byte1: int
var byte2: int
var byte3: int
var byte4: int
var byte5: int
var byte6: int
var byte7: int


func _init(value: float = 0) -> void:
	byte0 = 0
	byte1 = 0
	byte2 = 0
	byte3 = 0
	byte4 = 0
	byte5 = 0
	byte6 = 0
	byte7 = 0
	set_double_value(value)


func double_value() -> float:
	var bytes := PackedByteArray()
	bytes.append(byte0)
	bytes.append(byte1)
	bytes.append(byte2)
	bytes.append(byte3)
	bytes.append(byte4)
	bytes.append(byte5)
	bytes.append(byte6)
	bytes.append(byte7)
	return bytes.decode_double(0)


func set_double_value(value: float) -> void:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	byte0 = bytes[0]
	byte1 = bytes[1]
	byte2 = bytes[2]
	byte3 = bytes[3]
	byte4 = bytes[4]
	byte5 = bytes[5]
	byte6 = bytes[6]
	byte7 = bytes[7]
