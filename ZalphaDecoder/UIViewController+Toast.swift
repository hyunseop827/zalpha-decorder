//
//  UIViewController+Toast.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Contract for view controllers that display reusable toast messages.
protocol ToastPresenting: AnyObject where Self: UIViewController {
    var toastLabel: ToastLabel? { get set }
    var toastHideWorkItem: DispatchWorkItem? { get set }
    var toastBackgroundColor: UIColor { get }
    var toastTextColor: UIColor { get }
}

extension ViewController: ToastPresenting {}
extension HistoryDetailViewController: ToastPresenting {}

/// Shared toast presentation behavior for storyboard-backed screens.
extension ToastPresenting {

    /// Shows a single temporary toast, replacing any currently visible toast.
    func showToast(_ message: String) {
        toastHideWorkItem?.cancel()

        let label = toastLabel ?? makeToastLabel()
        label.text = message
        label.alpha = 0
        label.transform = CGAffineTransform(translationX: 0, y: 8)
        view.bringSubviewToFront(label)

        UIView.animate(withDuration: 0.2) {
            label.alpha = 1
            label.transform = .identity
        }

        let workItem = DispatchWorkItem { [weak label] in
            UIView.animate(withDuration: 0.2) {
                label?.alpha = 0
                label?.transform = CGAffineTransform(translationX: 0, y: 8)
            }
        }
        toastHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    /// Creates and pins the reusable toast label near the bottom safe area.
    func makeToastLabel() -> ToastLabel {
        let label = ToastLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = toastBackgroundColor
        label.textColor = toastTextColor
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])

        toastLabel = label
        return label
    }
}

/// Padded label used by the toast view.
final class ToastLabel: UILabel {
    private let insets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    /// Draws text inside the custom padding area.
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
