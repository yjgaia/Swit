public class RequestInfo {
	let headers: Headers
	let uri: String
	let method: String
	let params: [String: String]
	let ip: String
	let cookies: [String: String]

	init(
		headers: Headers,
		uri: String,
		method: String,
		params: [String: String],
		ip: String,
		cookies: [String: String]
	) {
		self.headers = headers
		self.uri = uri
		self.method = method
		self.params = params
		self.ip = ip
		self.cookies = cookies
	}
}
