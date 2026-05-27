//
//  HistoryDetailViewController+Styling.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Runtime styling for the storyboard-backed history detail screen.
extension HistoryDetailViewController {

    /// Applies dynamic colors and layer styles that cannot be fully represented in Storyboard.
    func configureStoryboardViews() {
        view.backgroundColor = pageBackgroundColor
        scrollView?.backgroundColor = pageBackgroundColor
        contentView?.backgroundColor = pageBackgroundColor
        metadataLabel?.textColor = secondaryLabelColor
        inputTitleLabel?.textColor = secondaryLabelColor
        outputTitleLabel?.textColor = secondaryLabelColor
        emptyNotesLabel?.textColor = .secondaryLabel
        configureCards()
    }

    /// Re-applies dynamic colors when light or dark appearance changes.
    func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: HistoryDetailViewController, _) in
            viewController.configureStoryboardViews()
            viewController.renderItem()
            viewController.updateShadowPaths()
        }
    }

    /// Updates card shadow paths after Auto Layout resolves final sizes.
    func updateShadowPaths() {
        [inputCardView, outputCardView, notesCardView].forEach { view in
            guard let view else { return }
            view.layer.shadowPath = UIBezierPath(
                roundedRect: view.bounds,
                cornerRadius: view.layer.cornerRadius
            ).cgPath
        }
    }

    private func configureCards() {
        [inputCardView, outputCardView, notesCardView].forEach {
            applyCardStyle(to: $0)
        }
    }

    private func applyCardStyle(to view: UIView?) {
        guard let view else { return }

        view.backgroundColor = cardBackgroundColor
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = isDarkMode ? 0.08 : 0.14
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    var pageBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
                : UIColor.systemGray6
        }
    }

    var cardBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
                : UIColor.white
        }
    }

    var borderColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.14)
                : UIColor(white: 0, alpha: 0.12)
        }
    }

    var secondaryLabelColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.62)
                : UIColor(white: 0, alpha: 0.52)
        }
    }

    var toastBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.92)
                : UIColor(white: 0.05, alpha: 0.92)
        }
    }

    var toastTextColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
    }
}
