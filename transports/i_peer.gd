## Define metodos, propriedades e eventos que cada servidor de transporte
class_name IPeer

## Invocado quando os dados sao recebidos pelo transporte.
## `event EventHandler<DataReceivedEventArgs> DataReceived;`
signal data_received(e: DataReceivedEventArgs)

## Invocado quando uma desconexao e iniciada ou detectada pelo transporte.
## `event EventHandler<DisconnectedEventArgs> Disconnected;`
signal disconnected(e: DisconnectedEventArgs)


## Inicia o tratamento de qualquer mensagem recebida.
func poll():
	pass
