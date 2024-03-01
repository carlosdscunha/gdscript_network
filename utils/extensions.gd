class_name Extensions


# Toma o endereco IP e o numero da porta do RemoteInfo e os converte em uma string, considerando se o endereco e um endereco IPv4 ou IPv6.
static func to_string_based_on_ip_format(remoteEndPoint: IPEndPoint) -> String:
	if ":" in remoteEndPoint.address:
		# IPv6 address
		if remoteEndPoint.address.begins_with("::ffff:"):
			# IPv4 mapped to IPv6
			var ipv4Address = remoteEndPoint.address.substr(7)
			return ipv4Address + ":" + str(remoteEndPoint.port)
		else:
			# IPv6
			return "[" + remoteEndPoint.address + "]:" + str(remoteEndPoint.port)
	else:
		# IPv4 address
		return remoteEndPoint.address + ":" + str(remoteEndPoint.port)
