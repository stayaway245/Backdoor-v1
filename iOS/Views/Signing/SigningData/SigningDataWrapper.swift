//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

//
//  SigningDataWrapper.swift
//  backdoor
//
//  Created by samara on 25.10.2024.
//

import Foundation

class SigningMainDataWrapper: ObservableObject {
	@Published var mainOptions: MainSigningOptions

	init(mainOptions: MainSigningOptions) {
		self.mainOptions = mainOptions
	}
}

class SigningDataWrapper: ObservableObject {
	@Published var signingOptions: SigningOptions

	init(signingOptions: SigningOptions) {
		self.signingOptions = signingOptions
	}
}
