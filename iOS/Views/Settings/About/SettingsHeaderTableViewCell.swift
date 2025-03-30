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
import UIKit
class HeaderTableViewCell: UITableViewCell {
	let titleLabel = UILabel()
	let versionLabel = UILabel()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupViews()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupViews()
	}

	private func setupViews() {
		contentView.addSubview(titleLabel)
		contentView.addSubview(versionLabel)

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		versionLabel.translatesAutoresizingMaskIntoConstraints = false
		
		titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
		titleLabel.textColor = UIColor.label

		versionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		versionLabel.textColor = UIColor.secondaryLabel

		NSLayoutConstraint.activate([
			titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
			titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
			titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

			versionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
			versionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
			versionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
			versionLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
			versionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
		])
	}

	func configure(withTitle title: String, versionString: String) {
		titleLabel.text = title.capitalized
		versionLabel.text = versionString
	}
}
