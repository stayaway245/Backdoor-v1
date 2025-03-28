//
//  DonationTableViewCell.swift
//  backdoor
//
//  Created by mentat on 3/28/25.
//

import UIKit

/// A table view cell that shows donation information and buttons
class DonationTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let donateButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - View Setup
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Setup container view with rounded corners
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Setup title label
        titleLabel.text = "Support Development"
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Setup subtitle label
        subtitleLabel.text = "If you enjoy using Backdoor, please consider supporting future development"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Setup donate button
        donateButton.setTitle("Donate", for: .normal)
        donateButton.backgroundColor = .systemBlue
        donateButton.setTitleColor(.white, for: .normal)
        donateButton.layer.cornerRadius = 8
        donateButton.translatesAutoresizingMaskIntoConstraints = false
        donateButton.addTarget(self, action: #selector(donateTapped), for: .touchUpInside)
        containerView.addSubview(donateButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            donateButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            donateButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            donateButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.6),
            donateButton.heightAnchor.constraint(equalToConstant: 44),
            donateButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func donateTapped() {
        // Open donation link
        if let url = URL(string: "https://github.com/sponsors/khcrysalis") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Prepare for Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset any state if needed
    }
}