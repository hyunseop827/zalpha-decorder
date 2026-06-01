//
//  SavedSlangDetailViewController+Styling.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Groups runtime styling for the storyboard-backed Saved Slang detail screen.
extension SavedSlangDetailViewController {

    func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: SavedSlangDetailViewController, _) in
            viewController.configureDynamicColors()
            viewController.updateShadowPaths()
        }
    }

    func configureDynamicColors() {
        view.backgroundColor = AppTheme.pageBackgroundColor
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = .systemRed }
        scrollView.backgroundColor = AppTheme.pageBackgroundColor
        contentView.backgroundColor = AppTheme.pageBackgroundColor
        expressionLabel.textColor = AppTheme.accentColor
        expressionCopyButton.tintColor = AppTheme.accentColor
        metadataLabel.textColor = AppTheme.secondaryLabelColor
        meaningsTitleLabel?.textColor = AppTheme.labelColor
        originalExpressionsTitleLabel?.textColor = AppTheme.labelColor
        examplesTitleLabel?.textColor = AppTheme.labelColor
        generateExamplesButton.tintColor = AppTheme.accentColor
        examplesLoadingOverlayView.backgroundColor = AppTheme.loadingOverlayColor
        examplesLoadingCardView.backgroundColor = AppTheme.cardBackgroundColor
        examplesLoadingCardView.layer.borderColor = AppTheme.borderColor.cgColor
        examplesLoadingIndicator.color = AppTheme.accentColor
        examplesLoadingLabel.text = AppStrings.SavedSlang.examplesLoadingTitle
        examplesLoadingLabel.textColor = AppTheme.labelColor

        [meaningsCardView, translationsCardView, examplesCardView].forEach {
            $0?.backgroundColor = AppTheme.cardBackgroundColor
            $0?.layer.borderColor = AppTheme.borderColor.cgColor
            AppTheme.applyShadow(AppTheme.detailCardShadow, to: $0)
        }
        AppTheme.applyShadow(AppTheme.loadingCardShadow, to: examplesLoadingCardView)

        toastLabel?.backgroundColor = AppTheme.toastBackgroundColor
        toastLabel?.textColor = AppTheme.toastTextColor
    }

    func configureCards() {
        [meaningsCardView, translationsCardView, examplesCardView].forEach {
            AppTheme.applyCardStyle(
                to: $0,
                cornerRadius: 14,
                shadow: AppTheme.detailCardShadow
            )
        }
        generateExamplesButton.layer.cornerRadius = 12
        generateExamplesButton.layer.cornerCurve = .continuous
        examplesLoadingOverlayView.isHidden = true
        examplesLoadingOverlayView.alpha = 0
        AppTheme.applyCardStyle(
            to: examplesLoadingCardView,
            cornerRadius: 16,
            shadow: AppTheme.loadingCardShadow
        )
    }

    func updateShadowPaths() {
        AppTheme.updateShadowPaths(for: [
            meaningsCardView,
            translationsCardView,
            examplesCardView,
            examplesLoadingCardView
        ])
    }
}
