//
//  NetworkController.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import TeslaAuthKit

public class Response {
    public var headers: [AnyHashable: Any] {
        fullResponse?.allHeaderFields ?? [AnyHashable: Any]()
    }

    public var statusCode: Int {
        fullResponse?.statusCode ?? 0
    }

    public let fullResponse: HTTPURLResponse?

    init(response: HTTPURLResponse?) {
        fullResponse = response
    }
}

public class DataResponse: Response {
    public var data: Data

    init(data: Data, response: HTTPURLResponse?) {
        self.data = data
        super.init(response: response)
    }

    public var dictionaryBody: [String: Any] {
        let body = try? JSONSerialization.jsonObject(with: data, options: [])

        if let dictionary = body as? [String: Any] {
            return dictionary
        } else {
            return [String: Any]()
        }
    }
}

public class SuccessDataResponse: DataResponse {}

public class FailureDataResponse: DataResponse {
    public let error: NSError

    init(data: Data?, response: HTTPURLResponse?, error: NSError) {
        self.error = error

        super.init(data: data ?? Data(), response: response)
    }
}

public enum DataResult {
    case success(SuccessDataResponse)

    case failure(FailureDataResponse)

    public var error: NSError? {
        switch self {
        case .success:
            nil
        case let .failure(response):
            response.error
        }
    }

    /// A response is a success only when it arrived with a 2xx status.
    /// Any other HTTP status is a failure carrying that status and the
    /// body, so callers can read Tesla's `error` / `error_description`
    /// (AuthAppForTesla#48: every status used to count as success, so
    /// "Test Token" passed dead tokens and the 400/401 branches never ran).
    public init(data: Data?, response: HTTPURLResponse?, error: NSError?) {
        if let error {
            self = .failure(FailureDataResponse(data: data, response: response, error: error))
        } else if let response, !(200..<300).contains(response.statusCode) {
            self = .failure(FailureDataResponse(data: data, response: response, error: Self.httpError(response, data: data)))
        } else {
            self = .success(SuccessDataResponse(data: data ?? Data(), response: response))
        }
    }

    /// An error for a non-2xx response: domain "HTTP", the status as code,
    /// and Tesla's `error_description` (or `error`) as the description.
    static func httpError(_ response: HTTPURLResponse, data: Data?) -> NSError {
        let body = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any] ?? [:]
        let description = (body["error_description"] as? String)
            ?? (body["error"] as? String)
            ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        return NSError(domain: "HTTP", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: description])
    }

    /// True when no HTTP response arrived at all (offline, timeout, DNS).
    public var isTransportFailure: Bool {
        if case .failure(let response) = self { return response.fullResponse == nil }
        return false
    }
}

class NetworkController {
    public static let shared = NetworkController(configuration: .ephemeral)

    private let configuration: URLSessionConfiguration

    /// Tests pass a configuration whose `protocolClasses` stub the network.
    init(configuration: URLSessionConfiguration) {
        self.configuration = configuration
    }

    func get(_ url: String, token: String? = nil, apiKey: String? = nil) async -> DataResult {
        return await execute(.get, url, parameters: nil, token: token, apiKey: apiKey)
    }

    func post(_ url: String, parameters: [String: Any]?, token: String? = nil, apiKey: String? = nil) async -> DataResult {
        return await execute(.post, url, parameters: parameters, token: token, apiKey: apiKey)
    }
    
    private enum HttpMethod {
        case post
        case get
    }
    
    private func execute(_ method: HttpMethod, _ url: String, parameters: [String: Any]?, token: String? = nil, apiKey: String? = nil) async -> DataResult {
        guard let url = URL(string: url) else {
            return DataResult(data: nil, response: nil, error: NSError.teslaError("Invalid url: \(url)"))
        }
        
        let session = URLSession(configuration: configuration)
        var request = URLRequest(url: url)
        request.httpMethod = method == .get ? "GET" : "POST"
        request.setValue(getUserAgentString(), forHTTPHeaderField: "User-Agent")
        request.setValue(getXTeslaUserAgent(), forHTTPHeaderField: "X-Tesla-User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        if let apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        }
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            if let parametersDictionary = parameters {
                let jsonData = try JSONSerialization.data(withJSONObject: parametersDictionary)
                request.httpBody = jsonData // formattedParameters.data(using: .utf8)
            }
        } catch let error as NSError {
            print(error.description)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            return DataResult(data: data, response: response as? HTTPURLResponse, error: nil)
        } catch {
            return DataResult(data: nil, response: nil, error: error as NSError?)
        }
    }
    
    func getUserAgentString() -> String {
        "\(kUserAgent)/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
    }

    func getXTeslaUserAgent() -> String {
        "\(kXTeslaUserAgent)/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
    }

}

extension NSError {
    static func teslaError(_ message: String) -> NSError {
        let error = NSError(domain: "AuthAppForTesla", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
        return error
    }
}
