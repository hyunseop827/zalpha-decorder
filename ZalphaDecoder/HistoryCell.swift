//
//  HistoryCell.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Storyboard-backed card cell that displays one decode history summary.
final class HistoryCell: UITableViewCell {
    static let reuseIdentifier = "HistoryCell"

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var metadataLabel: UILabel!
    @IBOutlet weak var inputTitleLabel: UILabel!
    @IBOutlet weak var inputPreviewLabel: UILabel!
    @IBOutlet weak var outputTitleLabel: UILabel!
    @IBOutlet weak var outputPreviewLabel: UILabel!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var chevronImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureRuntimeStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        metadataLabel.text = nil
        inputTitleLabel.text = nil
        inputPreviewLabel.text = nil
        outputTitleLabel.text = nil
        outputPreviewLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        AppTheme.updateShadowPath(for: cardView)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        let animations = {
            self.cardView.transform = highlighted
                ? CGAffineTransform(scaleX: 0.985, y: 0.985)
                : .identity
            self.cardView.alpha = highlighted ? 0.86 : 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.16, animations: animations)
        } else {
            animations()
        }
    }

    /// Applies the history item text to the storyboard labels.
    func configure(with item: HistoryItem) {
        let sourceLanguage = DecodeLanguage.localizedDisplayName(for: item.sourceLanguage)
        let targetLanguage = DecodeLanguage.localizedDisplayName(for: item.targetLanguage)

        metadataLabel.text = "\(HistoryDateFormatter.shortDateTime.string(from: item.createdAt)) · \(TranslationStyle.localizedDisplayName(for: item.style))"
        inputTitleLabel.text = AppStrings.History.inputTitle(sourceLanguage)
        inputPreviewLabel.text = item.inputText
        outputTitleLabel.text = AppStrings.History.outputTitle(targetLanguage)
        outputPreviewLabel.text = item.outputText
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
        dividerView.backgroundColor = AppTheme.borderColor
        cardView.backgroundColor = AppTheme.cardBackgroundColor
        cardView.layer.borderColor = AppTheme.borderColor.cgColor
        AppTheme.applyShadow(AppTheme.listCardShadow, to: cardView)
    }
}
