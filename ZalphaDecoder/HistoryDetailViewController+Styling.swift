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
        view.backgroundColor = AppTheme.pageBackgroundColor
        scrollView?.backgroundColor = AppTheme.pageBackgroundColor
        contentView?.backgroundColor = AppTheme.pageBackgroundColor
        metadataLabel?.textColor = secondaryLabelColor
        inputTitleLabel?.textColor = secondaryLabelColor
        outputTitleLabel?.textColor = secondaryLabelColor
        notesTitleLabel?.text = AppStrings.Main.notesTitle
        notesTitleLabel?.textColor = AppTheme.labelColor
        emptyNotesLabel?.textColor = AppTheme.secondaryLabelColor
        configureSaveAllNotesButton()
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
        AppTheme.updateShadowPaths(for: [inputCardView, outputCardView, notesCardView])
    }

    private func configureCards() {
        [inputCardView, outputCardView, notesCardView].forEach {
            applyCardStyle(to: $0)
        }
    }

    func configureSaveAllNotesButton() {
        saveAllNotesButton?.setTitle(AppStrings.History.saveAll, for: .normal)

        var attributedTitle = AttributedString(AppStrings.History.saveAll)
        attributedTitle.font = .systemFont(ofSize: 14, weight: .semibold)

        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = attributedTitle
        configuration.baseBackgroundColor = AppTheme.accentColor
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)

        saveAllNotesButton?.configuration = configuration
    }

    private func applyCardStyle(to view: UIView?) {
        AppTheme.applyCardStyle(
            to: view,
            backgroundColor: AppTheme.detailCardBackgroundColor,
            borderColor: AppTheme.detailBorderColor,
            cornerRadius: 14,
            shadow: AppTheme.detailCardShadow
        )
    }

    var secondaryLabelColor: UIColor {
        AppTheme.detailSecondaryLabelColor
    }

    var toastBackgroundColor: UIColor {
        AppTheme.detailToastBackgroundColor
    }

    var toastTextColor: UIColor {
        AppTheme.toastTextColor
    }
}
