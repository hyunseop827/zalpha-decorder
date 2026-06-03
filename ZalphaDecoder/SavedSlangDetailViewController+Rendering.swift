//
//  SavedSlangDetailViewController+Rendering.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Renders dynamic Saved Slang detail list content into storyboard stack views.
extension SavedSlangDetailViewController {

    func renderValues(_ values: [String], in stackView: UIStackView, emptyText: String) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let visibleValues = values.prefix(SavedSlangLimits.maximumVariantCount)
        guard !visibleValues.isEmpty else {
            stackView.addArrangedSubview(makeValueLabel(emptyText, isEmptyState: true))
            return
        }

        visibleValues.enumerated().forEach { index, value in
            stackView.addArrangedSubview(makeValueLabel("\(index + 1). \(value)", isEmptyState: false))
        }
    }

    func renderExamples(_ examples: [SavedSlangExample]) {
        examplesStackView.arrangedSubviews.forEach {
            examplesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let visibleExamples = Array(examples.prefix(SavedSlangLimits.maximumExampleCount))
        exampleCopyTexts = visibleExamples.map(\.sentence)
        exampleIDs = visibleExamples.map(\.id)

        guard !visibleExamples.isEmpty else {
            examplesStackView.addArrangedSubview(makeValueLabel(AppStrings.SavedSlang.noExamples, isEmptyState: true))
            return
        }

        visibleExamples.enumerated().forEach { index, example in
            examplesStackView.addArrangedSubview(makeExampleView(example, index: index))
        }
    }

    private func makeValueLabel(_ text: String, isEmptyState: Bool) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15, weight: isEmptyState ? .medium : .semibold)
        label.textColor = isEmptyState ? AppTheme.secondaryLabelColor : AppTheme.labelColor
        return label
    }

    private func makeExampleView(_ example: SavedSlangExample, index: Int) -> UIView {
        let containerView = UIView()
        AppTheme.applySurfaceStyle(
            to: containerView,
            backgroundColor: AppTheme.exampleSurfaceBackgroundColor,
            cornerRadius: 10,
            borderWidth: 0
        )

        let sentenceLabel = UILabel()
        sentenceLabel.text = example.sentence
        sentenceLabel.numberOfLines = 0
        sentenceLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        sentenceLabel.textColor = AppTheme.labelColor

        let meaningLabel = UILabel()
        meaningLabel.text = example.meaning
        meaningLabel.numberOfLines = 0
        meaningLabel.font = .systemFont(ofSize: 13, weight: .medium)
        meaningLabel.textColor = AppTheme.secondaryLabelColor

        let textStackView = UIStackView(arrangedSubviews: [sentenceLabel, meaningLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4

        let copyButton = UIButton(type: .system)
        copyButton.setImage(UIImage(systemName: "document.on.document"), for: .normal)
        copyButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(scale: .small), forImageIn: .normal)
        copyButton.tintColor = AppTheme.accentColor
        copyButton.tag = index
        copyButton.widthAnchor.constraint(equalToConstant: 26).isActive = true
        copyButton.heightAnchor.constraint(equalToConstant: 26).isActive = true
        copyButton.addTarget(self, action: #selector(copyExampleButtonTapped(_:)), for: .touchUpInside)

        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(scale: .small), forImageIn: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.tag = index
        deleteButton.widthAnchor.constraint(equalToConstant: 26).isActive = true
        deleteButton.heightAnchor.constraint(equalToConstant: 26).isActive = true
        deleteButton.addTarget(self, action: #selector(deleteExampleButtonTapped(_:)), for: .touchUpInside)

        let actionStackView = UIStackView(arrangedSubviews: [copyButton, deleteButton])
        actionStackView.axis = .horizontal
        actionStackView.alignment = .center
        actionStackView.spacing = 4

        let rowStackView = UIStackView(arrangedSubviews: [textStackView, actionStackView])
        rowStackView.axis = .horizontal
        rowStackView.alignment = .top
        rowStackView.spacing = 10
        rowStackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(rowStackView)
        NSLayoutConstraint.activate([
            rowStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            rowStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            rowStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            rowStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        return containerView
    }
}
