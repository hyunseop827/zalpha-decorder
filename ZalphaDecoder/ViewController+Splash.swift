//
//  ViewController+Splash.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

extension ViewController {

    func showStartupSplashIfNeeded() {
        guard !hasShownStartupSplash else { return }
        hasShownStartupSplash = true

        let containerView: UIView = navigationController?.view ?? view
        let overlayView = UIView()
        overlayView.backgroundColor = .systemBackground
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlayView)

        let logoImageView = UIImageView(image: UIImage(named: "LaunchScreenLogo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(logoImageView)

        let preferredWidthConstraint = logoImageView.widthAnchor.constraint(equalToConstant: 300)
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            logoImageView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            logoImageView.widthAnchor.constraint(lessThanOrEqualTo: overlayView.widthAnchor, multiplier: 0.8),
            preferredWidthConstraint,
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 880.0 / 2380.0)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                overlayView.alpha = 0
            } completion: { _ in
                overlayView.removeFromSuperview()
            }
        }
    }
}
