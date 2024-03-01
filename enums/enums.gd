class_name Enums

enum LogTypes { DEBUG, INFO, WARNING, ERROR, THROW }

## O estado de uma conexao.
enum ConnectionState {
	## Nao conectado. Nenhuma conexao foi estabelecida ou a conexao foi encerrada.
	NOT_CONNECTED,
	## Conectando. Ainda tentando estabelecer uma conexao.
	CONNECTING,
	## A conexao esta pendente. O servidor ainda esta determinando se a conexao deve ou nao ser permitida.
	PENDING,
	## Conectado. Uma conexao foi estabelecida com sucesso.
	CONNECTED,
	## Nao conectado. Uma tentativa de conexao foi feita, mas foi rejeitada.
	REJECTED,
}

## O motivo pelo qual a tentativa de conexao foi rejeitada.
enum RejectReason {
	## Nenhuma resposta foi recebida do servidor (porque o cliente nao tem conexao com a Internet, o servidor esta offline, nenhum servidor esta escutando no endpoint de destino, etc.).
	NO_CONNECTION,
	## O cliente ja esta conectado.
	ALREADY_CONNECTED,
	## O servidor esta cheio.
	SERVER_FULL,
	## A tentativa de conexao foi rejeitada.
	REJECTED,
	## A tentativa de conexao foi rejeitada e dados personalizados podem ter sido incluidos na mensagem de rejeicao.
	CUSTOM,
}

## O motivo da desconexao.
enum DisconnectReason {
	## Nenhuma conexao foi estabelecida.
	NEVER_CONNECTED,
	## A tentativa de conexao foi rejeitada pelo servidor.
	CONNECTION_REJECTED,
	## O transporte ativo detectou um problema com a conexao.
	TRANSPORT_ERROR,
	## A conexao expirou.
	##
	## Isso tambam funciona como o motivo de fallback-se um cliente se desconectar e a mensagem contendo o motivo <i>real</i> for perdida na transmissao, nao pode ser reenviado pois a conexao ja tera sido encerrada.
	## Como resultado, a outra extremidade sera cronometrada encerra a conexao apos um curto periodo de tempo e isso sera usado como o motivo.
	TIMED_OUT,
	## O cliente foi desconectado a forca pelo servidor.
	KICKED,
	## O servidor foi desligado.
	SERVER_STOPPED,
	## A desconexao foi iniciada pelo cliente.
	DISCONNECTED,
}

## O tipo de cabecalho de uma `Message`
enum MessageHeader {
	## Uma mensagem de usuario nao confiavel.
	UNRELIABLE,
	## Uma mensagem de confirmacao interna nao confiavel.
	ACK,
	## Uma mensagem de confirmacao interna nao confiavel, usada ao reconhecer um ID de sequencia diferente do ultimo recebido.
	ACK_EXTRA,
	## Uma mensagem interna de conexao nao confiavel.
	CONNECT,
	## Uma mensagem interna de rejeicao de conexao nao confiavel.
	REJECT,
	## Uma mensagem interna de pulsacao nao confiavel.
	HEARTBEAT,
	## Uma mensagem de desconexao interna nao confiavel.
	DISCONNECT,
	## Uma mensagem de usuario confiavel.
	RELIABLE,
	## Uma mensagem interna confiavel de boas-vindas.
	WELCOME,
	## Uma mensagem interna confiavel conectada ao cliente.
	CLIENT_CONNECTED,
	## Uma mensagem interna confiavel de cliente desconectado.
	CLIENT_DISCONNECTED,
}

## O modo de envio de uma `Message`.
enum MessageSendMode {
	## Modo de envio nao confiavel.
	UNRELIABLE = MessageHeader.UNRELIABLE,
	## Modo de envio confiavel.
	RELIABLE = MessageHeader.RELIABLE,
}

## O tipo de soquete a ser criado.
enum SocketMode {
	## Modo duplo. Funciona com IPv4 e IPv6.
	BOTH,
	## Modo somente IPv4.
	IP_V4_ONLY,
	## Modo somente IPv6.
	IP_V6_ONLY
}
