/// Socket.swift는 Swifter(https://github.com/glock45/swifter, BSD-3 License) 코드를 참고하여 만들었음을 밝힙니다.

#if os(Linux)
	import Glibc
#else
	import Foundation
#endif

public class Socket : Hashable {

	private let socketFileDescriptor: Int32

	init(socketFileDescriptor: Int32) {
		self.socketFileDescriptor = socketFileDescriptor
	}

	public class func socketListen(port: UInt16) -> Socket {

		#if os(Linux)
			let socketFileDescriptor = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
		#else
			let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
		#endif

		var value: Int32 = 1
		setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32)))
		Socket.setNoSigPipe(socketFileDescriptor)

		#if os(Linux)
			var addr = sockaddr_in()
			addr.sin_family = sa_family_t(AF_INET)
			addr.sin_port = Socket.htonsPort(port)
			addr.sin_addr = in_addr(s_addr: in_addr_t(0))
			addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
		#else
			var addr = sockaddr_in()
			addr.sin_len = __uint8_t(sizeof(sockaddr_in))
			addr.sin_family = sa_family_t(AF_INET)
			addr.sin_port = Socket.htonsPort(port)
			addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
			addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
		#endif

		var bind_addr = sockaddr()
		memcpy(&bind_addr, &addr, Int(sizeof(sockaddr_in)))
		bind(socketFileDescriptor, &bind_addr, socklen_t(sizeof(sockaddr_in)))
		listen(socketFileDescriptor, SOMAXCONN)

		return Socket(socketFileDescriptor: socketFileDescriptor)
	}

	public func release() {
		Socket.release(socketFileDescriptor)
	}

	public func shutdwn() {
		Socket.shutdwn(socketFileDescriptor)
	}

	public func acceptClientSocket() -> Socket {

		#if os(Linux)
			var addr = sockaddr()
		#else
			var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
		#endif

		var len: socklen_t = 0
		let clientSocket = accept(socketFileDescriptor, &addr, &len)
		Socket.setNoSigPipe(clientSocket)

		return Socket(socketFileDescriptor: clientSocket)
	}

	public func writeUTF8(string: String) {
		writeUInt8([UInt8](string.utf8))
	}

	public func writeUInt8(data: [UInt8]) {

		data.withUnsafeBufferPointer { pointer in

			var sent = 0

			while sent < data.count {

				#if os(Linux)
					let s = send(socketFileDescriptor, pointer.baseAddress + sent, Int(data.count - sent), Int32(MSG_NOSIGNAL))
				#else
					let s = write(socketFileDescriptor, pointer.baseAddress + sent, Int(data.count - sent))
				#endif

				if s == -1 {
					break
				}

				sent += s
			}
		}
	}

	public func read() -> Int {

		var buffer = [UInt8](count: 1, repeatedValue: 0);
		let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)

		if next <= 0 {
			return next
		}
		return Int(buffer[0])
	}

	public func readLine() -> String {

		var characters: String = ""
		var n = 0

		repeat {
			n = self.read()
			if (n > 13) {
				characters.append(Character(UnicodeScalar(n)))
			}
		} while n > 0 && n != 10

		return characters
	}

	public func peername() -> String {

		var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))
		getpeername(self.socketFileDescriptor, &addr, &len)

		var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
		getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST)

		return String.fromCString(hostBuffer)!
	}

	private class func descriptionOfLastError() -> String {
		return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
	}

	private class func setNoSigPipe(socket: Int32) {

		#if os(Linux)
			// ingore.
		#else
			var no_sig_pipe: Int32 = 1;
			setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)));
		#endif
	}

	private class func shutdwn(socket: Int32) {

		#if os(Linux)
			shutdown(socket, Int32(SHUT_RDWR))
		#else
			Darwin.shutdown(socket, SHUT_RDWR)
		#endif
	}

	private class func release(socket: Int32) {

		#if os(Linux)
			shutdown(socket, Int32(SHUT_RDWR))
		#else
			Darwin.shutdown(socket, SHUT_RDWR)
		#endif

		close(socket)
	}

	private class func htonsPort(port: UInt16) -> UInt16 {

		#if os(Linux)
			return htons(port)
		#else
			let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
			return isLittleEndian ? _OSSwapInt16(port) : port

		#endif
	}

	public var hashValue: Int {
		return Int(self.socketFileDescriptor)
	}
}

public func ==(socket1: Socket, socket2: Socket) -> Bool {
	return socket1.hashValue == socket2.hashValue
}
