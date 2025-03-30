//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

//
//  FileProcessingError.swift
//  backdoor
//
//  Created by Mentat AI on 3/27/25
//  Copyright (c) 2025 BackdoorBDG
//

import Foundation

/// Shared error type to use across file processing operations
enum FileProcessingError: Error, LocalizedError {
    case missingFile(String)
    case fileIOError(Error)
    case invalidPath
    case unsupportedFileExtension(String)
    case decompressionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingFile(let name):
            return "Missing file: \(name)"
        case .fileIOError(let error):
            return "File I/O error: \(error.localizedDescription)"
        case .invalidPath:
            return "Invalid file path"
        case .unsupportedFileExtension(let ext):
            return "Unsupported file extension: \(ext)"
        case .decompressionFailed(let reason):
            return "Decompression failed: \(reason)"
        }
    }
}
