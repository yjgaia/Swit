public class WebServer {
	private let port: UInt16
	private let requestListener: RequestInfo -> Void
	private let socketListen: Socket

	private var clientSockets: Set<Socket> = []

	init(port: UInt16, requestListener: RequestInfo -> Void) {
		self.port = port
		self.requestListener = requestListener

		socketListen = Socket.socketListen(port)

		while let socket: Socket = socketListen.acceptClientSocket() {
			clientSockets.insert(socket)

			let request: Request = Request(socket: socket)

			if request.method != "" {

				socket.writeUTF8("HTTP/1.1 200 OK\r\n")

				let length = 4
		        socket.writeUTF8("Content-Length: \(length)\r\n")

				socket.writeUTF8("Content-Type: text/html\r\n")
				socket.writeUTF8("\r\n")

		        socket.writeUInt8([UInt8]("TEST".utf8))
			}

			socket.release()
			clientSockets.remove(socket)
		}
	}
}
