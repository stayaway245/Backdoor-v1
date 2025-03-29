//
//  NetworkManager+NonDecodable.swift
//  backdoor
//
//  Created by mentat on 3/29/25.
//

import Foundation

// Interface needed for NetworkManager+NonDecodable
// These need to be defined in NetworkManager.swift
extension NetworkManager {
    // Make internal access methods to handle non-Decodable responses
    
    // We'll need to reimplement the entire logic because we don't have direct access
    // to private members in the NetworkManager class
    
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
        // Create a type-erased wrapper around the completion handler
        let wrappedCompletion: (Result<[String: Any], Error>) -> Void = { result in
            switch result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        // Use the existing performRequest method with [String: Any] as the generic parameter
        return performRequest(request, caching: caching, completion: wrappedCompletion)
    }
}
