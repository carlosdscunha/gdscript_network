## Contem diversos metodos auxiliares.
class_name Helper


static func correct_form(amount: int, singular: String, plural = "") -> String:
	if plural == "":
		plural = singular + "s"

	if amount == 1:
		return singular
	else:
		return plural


static func get_sequence_gap(seqId1: int, seqId2: int) -> int:
	var gap = seqId1 - seqId2

	if abs(gap) <= 32768:
		return gap
	else:
		var a
		var b

		if seqId1 <= 32768:
			a = 65536 + seqId1
		else:
			a = seqId1

		if seqId2 <= 32768:
			b = 65536 + seqId2
		else:
			b = seqId2

		return a - b
