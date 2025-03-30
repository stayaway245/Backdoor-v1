// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import Foundation
import UIKit

class PopupViewController: UIViewController {
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupStackView()
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }

    func configureButtons(_ buttons: [UIButton]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for button in buttons {
            stackView.addArrangedSubview(button)
        }
    }
}

class PopupViewControllerButton: UIButton {
    var onTap: (() -> Void)?
    private var originalBackgroundColor: UIColor?

    init(title: String, color: UIColor, titleColor: UIColor? = .white) {
        super.init(frame: .zero)
        setupButton(title: title, color: color, titlecolor: titleColor!)
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpInside)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpOutside)
        addTarget(self, action: #selector(buttonCancelled), for: .touchCancel)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton(title: String.localized("DEFAULT"), color: .systemBlue, titlecolor: .white)
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpInside)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpOutside)
        addTarget(self, action: #selector(buttonCancelled), for: .touchCancel)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    private func setupButton(title: String, color: UIColor, titlecolor: UIColor) {
        setTitle(title, for: .normal)
        originalBackgroundColor = color
        backgroundColor = color
        setTitleColor(titlecolor, for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        if #available(iOS 15.0, *) {
            var config = configuration ?? UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
            configuration = config
        } else {
            contentEdgeInsets = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
        }
    }

    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.backgroundColor = self.originalBackgroundColor?.withAlphaComponent(0.6)
        }
    }

    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.1) {
            self.backgroundColor = self.originalBackgroundColor
        }
    }

    @objc private func buttonCancelled() {
        UIView.animate(withDuration: 0.1) {
            self.backgroundColor = self.originalBackgroundColor
        }
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}
