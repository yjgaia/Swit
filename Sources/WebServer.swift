public class WebServer {
	let port: Int
	let requestListener: (requestInfo: RequestInfo) -> Void

	init(port: Int, requestListener: (requestInfo: RequestInfo) -> Void) {
		self.port = port
		self.requestListener = requestListener;
		start()
	}

	private class func start() {
    }
}
