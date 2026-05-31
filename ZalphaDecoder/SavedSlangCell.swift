//
//  SavedSlangCell.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Storyboard-backed card cell that displays one saved slang summary.
final class SavedSlangCell: UITableViewCell {
    static let reuseIdentifier = "SavedSlangCell"

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var expressionLabel: UILabel!
    @IBOutlet weak var meaningLabel: UILabel!
    @IBOutlet weak var metadataLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureRuntimeStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        expressionLabel.text = nil
        meaningLabel.text = nil
        metadataLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        AppTheme.updateShadowPath(for: cardView)
    }

    /// Applies the saved slang item text to the storyboard labels.
    func configure(with item: SavedSlang) {
        expressionLabel.text = item.sourceExpression
        meaningLabel.text = AppStrings.SavedSlang.meaningPreview(item.meanings.first ?? "")
        metadataLabel.text = AppStrings.SavedSlang.metadata(
            sourceLanguage: item.sourceLanguage,
            meaningLanguage: item.meaningLanguage,
            date: HistoryDateFormatter.shortDateTime.string(from: item.updatedAt)
        )
        applyDynamicColors()
    }

    private func configureRuntimeStyle() {
        AppTheme.applyCardStyle(
            to: cardView,
            cornerRadius: 14,
            shadow: AppTheme.listCardShadow
        )

        applyDynamicColors()
    }

    private func applyDynamicColors() {
        expressionLabel.textColor = AppTheme.accentColor
        cardView.backgroundColor = AppTheme.cardBackgroundColor
        cardView.layer.borderColor = AppTheme.borderColor.cgColor
        AppTheme.applyShadow(AppTheme.listCardShadow, to: cardView)
    }
}
