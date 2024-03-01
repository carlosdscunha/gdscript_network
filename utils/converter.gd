## Fornece funcionalidade para converter bytes em varios tipos de valor e vice-versa.
class_name Converter

const IS_BIG_ENDIAN = false


#region Short
#region Gravar
static func from_short(value: int, array: PackedByteArray, start_index: int) -> void:
	if IS_BIG_ENDIAN:
		for i in range(sizeof.SHORT):
			array[start_index + i] = value >> (8 * (sizeof.SHORT - i - 1))
	else:
		for i in range(sizeof.SHORT):
			array[start_index + i] = value >> (8 * i)


#endregion
#region Ler
static func to_short(array: PackedByteArray, start_index: int) -> int:
	var result: int = 0
	if IS_BIG_ENDIAN:
		for i in range(sizeof.SHORT):
			result |= array[start_index + i] << (8 * (sizeof.SHORT - i - 1))
	else:
		for i in range(sizeof.SHORT):
			result |= array[start_index + i] << (8 * i)
	return result


#endregion
#endregion


#region Int
#region Gravar
static func from_int(value: int, array: PackedByteArray, start_index: int) -> void:
	if IS_BIG_ENDIAN:
		for i in range(sizeof.INT):
			array[start_index + i] = value >> (8 * (sizeof.INT - i - 1))
	else:
		for i in range(sizeof.INT):
			array[start_index + i] = value >> (8 * i)


#endregion
#region  Ler
static func to_int(array: PackedByteArray, start_index: int) -> int:
	var result: int = 0
	if IS_BIG_ENDIAN:
		for i in range(sizeof.INT):
			result |= array[start_index + i] << (8 * (sizeof.INT - i - 1))
	else:
		for i in range(sizeof.INT):
			result |= array[start_index + i] << (8 * i)
	return result


#endregion
#endregion


#region Long
#region Gravar
static func from_long(value: int, array: PackedByteArray, start_index: int) -> void:
	if IS_BIG_ENDIAN:
		for i in range(sizeof.LONG):
			array[start_index + i] = value >> (8 * (sizeof.LONG - i - 1))
	else:
		for i in range(sizeof.LONG):
			array[start_index + i] = value >> (8 * i)


#endregion
#region  Ler
static func to_long(array: PackedByteArray, start_index: int) -> int:
	var result: int = 0
	if IS_BIG_ENDIAN:
		for i in range(sizeof.LONG):
			result |= array[start_index + i] << (8 * (sizeof.LONG - i - 1))
	else:
		for i in range(sizeof.LONG):
			result |= array[start_index + i] << (8 * i)
	return result


#endregion
#endregion


#region Float
#region Gravar
static func from_float(value: float, array: PackedByteArray, start_index: int) -> void:
	var converter: FloatConverter = FloatConverter.new(value)

	if IS_BIG_ENDIAN:
		array[start_index + 3] = converter.byte0
		array[start_index + 2] = converter.byte1
		array[start_index + 1] = converter.byte2
		array[start_index] = converter.byte3
	else:
		array[start_index] = converter.byte0
		array[start_index + 1] = converter.byte1
		array[start_index + 2] = converter.byte2
		array[start_index + 3] = converter.byte3


#endregion
#region Ler
static func to_float(array: PackedByteArray, start_index: int) -> float:
	var converter: FloatConverter = FloatConverter.new()

	if IS_BIG_ENDIAN:
		converter.byte3 = array[start_index]
		converter.byte2 = array[start_index + 1]
		converter.byte1 = array[start_index + 2]
		converter.byte0 = array[start_index + 3]
		return converter.float_value()
	else:
		converter.byte0 = array[start_index]
		converter.byte1 = array[start_index + 1]
		converter.byte2 = array[start_index + 2]
		converter.byte3 = array[start_index + 3]
		return converter.float_value()


#endregion
#endregion


#region Double
#region Gravar
static func from_double(value: float, array: PackedByteArray, start_index: int) -> void:
	var converter = DoubleConverter.new(value)

	if IS_BIG_ENDIAN:
		array[start_index + 7] = converter.byte0
		array[start_index + 6] = converter.byte1
		array[start_index + 5] = converter.byte2
		array[start_index + 4] = converter.byte3
		array[start_index + 3] = converter.byte4
		array[start_index + 2] = converter.byte5
		array[start_index + 1] = converter.byte6
		array[start_index] = converter.byte7
	else:
		array[start_index] = converter.byte0
		array[start_index + 1] = converter.byte1
		array[start_index + 2] = converter.byte2
		array[start_index + 3] = converter.byte3
		array[start_index + 4] = converter.byte4
		array[start_index + 5] = converter.byte5
		array[start_index + 6] = converter.byte6
		array[start_index + 7] = converter.byte7


#endregion
#region Ler
static func to_double(array: PackedByteArray, start_index: int) -> float:
	var converter = DoubleConverter.new()

	if IS_BIG_ENDIAN:
		converter.byte7 = array[start_index]
		converter.byte6 = array[start_index + 1]
		converter.byte5 = array[start_index + 2]
		converter.byte4 = array[start_index + 3]
		converter.byte3 = array[start_index + 4]
		converter.byte2 = array[start_index + 5]
		converter.byte1 = array[start_index + 6]
		converter.byte0 = array[start_index + 7]
		return converter.double_value()
	else:
		converter.byte0 = array[start_index]
		converter.byte1 = array[start_index + 1]
		converter.byte2 = array[start_index + 2]
		converter.byte3 = array[start_index + 3]
		converter.byte4 = array[start_index + 4]
		converter.byte5 = array[start_index + 5]
		converter.byte6 = array[start_index + 6]
		converter.byte7 = array[start_index + 7]
		return converter.double_value()
#endregion
#endregion
