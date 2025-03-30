//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

import UIKit

// Namespace to avoid ambiguity with HomeViewController
extension iOS.Views {
    enum Home {}
}

// Extension to add protocol conformance to HomeViewController - properly qualified
extension iOS.Views.Home.HomeViewController {
    // Note: All drag and drop methods have been moved to FileDragAndDrop.swift
    // to avoid duplicate method declarations
}

// This creates the namespace
extension iOS {
    enum Views {
        enum Home {
            // Create a typealias to the actual HomeViewController
            typealias HomeViewController = BackdoorApp.HomeViewController
        }
    }
}
