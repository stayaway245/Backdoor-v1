//
//  NetworkManager+NonDecodable.swift
//  backdoor
//
//  Created by mentat on 3/29/25.
//

import Foundation

// Extension to NetworkManager to handle non-Decodable responses
extension NetworkManager {
    /// Perform a network request without Decodable decoding
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
        // Determine whether to use caching
        let useCache = caching ?? (_configuration.useCache && request.httpMethod?.uppercased() == "GET")
        
        // Check if request is already in progress
        let existingTask = operationQueueAccessQueue.sync { activeOperations[request] }
        if let existingTask = existingTask {
            Debug.shared.log(message: "Request already in progress: \(request.url?.absoluteString ?? "Unknown URL")", type: .debug)
            return existingTask
        }
        
        // Check cache if caching is enabled
        if useCache {
            if let cachedResponse = getCachedResponse(for: request) {
                Debug.shared.log(message: "Cache hit: \(request.url?.absoluteString ?? "Unknown URL")", type: .debug)
                
                do {
                    // Parse JSON data to dictionary
                    if let jsonObject = try JSONSerialization.jsonObject(with: cachedResponse.data) as? [String: Any] {
                        completion(.success(jsonObject))
                        return nil
                    } else {
                        throw NetworkError.decodingError(NSError(domain: "JSONError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
                    }
                } catch {
                    Debug.shared.log(message: "Failed to parse cached response: \(error)", type: .error)
                    // Continue with network request if parsing fails
                }
            }
        }
        
        // Create network task
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Remove from active operations
            let _ = self.operationQueueAccessQueue.sync {
                self.activeOperations.removeValue(forKey: request)
            }
            
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
            
            // Cache the response if needed
            if useCache {
                self.cacheResponse(data: data, for: request)
            }
            
            // Parse the response
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(jsonObject))
                } else {
                    throw NetworkError.decodingError(NSError(domain: "JSONError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
                }
            } catch {
                Debug.shared.log(message: "Failed to parse response: \(error.localizedDescription)", type: .error)
                completion(.failure(NetworkError.decodingError(error)))
            }
        }
        
        // Add to active operations
        operationQueueAccessQueue.sync {
            activeOperations[request] = task
        }
        
        // Start the task
        task.resume()
        
        return task
    }
}
