//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

//
//

import Foundation

// Extension to NetworkManager for batch requests that don't need Decodable conformance
extension NetworkManager {
    /// Perform a network request without requiring Decodable conformance
    /// - Parameters:
    ///   - request: The URL request to perform
    ///   - caching: Whether to use caching (default is based on configuration)
    ///   - completion: Completion handler with the result
    /// - Returns: A cancellable task identifier
    @discardableResult
    func performRequestWithoutDecoding(
        _ request: URLRequest,
        caching: Bool? = nil,
        completion: @escaping (Result<Any, Error>) -> Void
    ) -> URLSessionTask? {
        // Create a completely separate URLSession data task
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Handle network error
            if let error = error {
                Debug.shared.log(message: "Network request failed: \(error.localizedDescription)", type: .error)
                completion(.failure(error))
                return
            }
            
            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NetworkError.httpError(statusCode: httpResponse.statusCode)
                Debug.shared.log(message: "HTTP error: \(httpResponse.statusCode)", type: .error)
                completion(.failure(error))
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            // Parse the response using JSONSerialization instead of JSONDecoder
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(jsonObject))
                } else if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any] {
                    completion(.success(jsonArray))
                } else {
                    let jsonObject = try JSONSerialization.jsonObject(with: data)
                    completion(.success(jsonObject))
                }
            } catch {
                Debug.shared.log(message: "Failed to parse response: \(error.localizedDescription)", type: .error)
                completion(.failure(NetworkError.decodingError(error)))
            }
        }
        
        // Start the task
        task.resume()
        
        return task
    }
}
