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

        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
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
        metadataLabel.text = "\(HistoryDateFormatter.shortDateTime.string(from: item.createdAt)) · \(item.style)"
        inputTitleLabel.text = "Input - \(item.sourceLanguage)"
        inputPreviewLabel.text = item.inputText
        outputTitleLabel.text = "Output - \(item.targetLanguage)"
        outputPreviewLabel.text = item.outputText
        applyDynamicColors()
    }

    private func configureRuntimeStyle() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        clipsToBounds = false

        cardView.layer.cornerRadius = 14
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowRadius = 5
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.clipsToBounds = false

        applyDynamicColors()
    }

    private func applyDynamicColors() {
        metadataLabel.textColor = .secondaryLabel
        inputTitleLabel.textColor = .secondaryLabel
        outputTitleLabel.textColor = .secondaryLabel
        inputPreviewLabel.textColor = .label
        outputPreviewLabel.textColor = .label
        chevronImageView.tintColor = .tertiaryLabel
        dividerView.backgroundColor = borderColor
        cardView.backgroundColor = cardBackgroundColor
        cardView.layer.borderColor = borderColor.cgColor
        cardView.layer.shadowOpacity = isDarkMode ? 0.08 : 0.12
    }

    private var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    private var cardBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1)
                : UIColor.white
        }
    }

    private var borderColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.13)
                : UIColor(white: 0, alpha: 0.10)
        }
    }
}
