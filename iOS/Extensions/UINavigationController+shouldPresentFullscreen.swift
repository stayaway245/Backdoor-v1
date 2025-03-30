//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

//
//  UINavigationController+shouldPresentFullscreen.swift
//  backdoor
//
//  Created by samara on 9.12.2024.
//

extension UINavigationController {
	func shouldPresentFullScreen() {
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.modalPresentationStyle = .formSheet
		} else {
			self.modalPresentationStyle = .fullScreen
		}
	}
}
