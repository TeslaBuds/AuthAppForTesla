//
//  NetworkController.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation

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

    public init(data: Data?, response: HTTPURLResponse?, error: NSError?) {
        if let error {
            self = .failure(FailureDataResponse(data: data, response: response, error: error))
        } else {
            self = .success(SuccessDataResponse(data: data ?? Data(), response: response))
        }
    }
}

class NetworkController {
    public static let shared = NetworkController()

    private init() {
        // Private initializer, so no accidental class instantiations outside singleton can happen
    }

    func get(_ url: String, token: String? = nil, apiKey: String? = nil, completion: @escaping (_ result: DataResult) -> Void) {
        Task {
            let response = await get(url, token: token, apiKey: apiKey)
            completion(response)
        }
    }

    func get(_ url: String, token: String? = nil, apiKey: String? = nil) async -> DataResult {
        return await execute(.get, url, parameters: nil, token: token, apiKey: apiKey)
    }

    func post(_ url: String, parameters: [String: Any]?, token: String? = nil, apiKey: String? = nil, completion: @escaping (_ result: DataResult) -> Void) {
        Task {
            let response = await post(url, parameters: parameters, token: token, apiKey: apiKey)
            completion(response)
        }
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
        
        let configuration = URLSessionConfiguration.ephemeral
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
