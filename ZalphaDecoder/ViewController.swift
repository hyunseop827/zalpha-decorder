//
//  ViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var inputCardView: UIView!
    @IBOutlet weak var outputCardView: UIView!
    @IBOutlet weak var notesCardView: UIView!

    @IBOutlet weak var sourceLanguageButton: UIButton!
    @IBOutlet weak var swapLanguageButton: UIButton!
    @IBOutlet weak var targetLanguageButton: UIButton!

    @IBOutlet weak var cleanStyleButton: UIButton!
    @IBOutlet weak var plainStyleButton: UIButton!
    @IBOutlet weak var casualStyleButton: UIButton!
    @IBOutlet weak var genZalphaStyleButton: UIButton!
    @IBOutlet weak var decodeButton: UIButton!

    @IBOutlet weak var styleLabel: UILabel!
    @IBOutlet weak var inputLanguageLabel: UILabel!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var characterCountLabel: UILabel!
    @IBOutlet weak var outputLanguageLabel: UILabel!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var notesIconButton: UIButton!
    @IBOutlet weak var notesTitleLabel: UILabel!
    @IBOutlet weak var notesBodyLabel: UILabel!

    private enum TranslationStyle {
        case clean
        case plain
        case casual
        case genZalpha
    }

    private enum Language: CaseIterable {
        case english
        case korean

        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .korean:
                return "한국어"
            }
        }
    }

    private let accentColor = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)
    private let maximumInputLength = 100
    private var toastLabel: ToastLabel?
    private var toastHideWorkItem: DispatchWorkItem?
    private var selectedStyle: TranslationStyle = .clean
    private var sourceLanguage: Language = .korean
    private var targetLanguage: Language = .english

    override func viewDidLoad() {
        super.viewDidLoad()

        inputTextView.delegate = self
        configureStaticText()
        configureInterface()
        registerForThemeChanges()
        updateStyleSelection()
        updateCharacterCount()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    @IBAction func styleButtonTapped(_ sender: UIButton) {
        switch sender {
        case cleanStyleButton:
            selectedStyle = .clean
        case plainStyleButton:
            selectedStyle = .plain
        case casualStyleButton:
            selectedStyle = .casual
        case genZalphaStyleButton:
            selectedStyle = .genZalpha
        default:
            selectedStyle = .clean
        }

        updateStyleSelection()
    }

    @IBAction func decodeButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
    }

    @IBAction func swapLanguageButtonTapped(_ sender: UIButton) {
        swap(&sourceLanguage, &targetLanguage)
        updateLanguageInterface()
    }

    @IBAction func copyButtonTapped(_ sender: UIButton) {
        let output = outputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return }

        UIPasteboard.general.string = output
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Saved to clipboard.")
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView == inputTextView, textView.text.count > maximumInputLength {
            textView.text = String(textView.text.prefix(maximumInputLength))
        }

        updateCharacterCount()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard textView == inputTextView else { return true }
        guard let currentText = textView.text, let stringRange = Range(range, in: currentText) else {
            return false
        }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        guard updatedText.count > maximumInputLength else { return true }

        let replacedLength = currentText[stringRange].count
        let remainingCount = maximumInputLength - (currentText.count - replacedLength)
        guard remainingCount > 0 else { return false }

        let allowedText = String(text.prefix(remainingCount))
        textView.text = currentText.replacingCharacters(in: stringRange, with: allowedText)
        updateCharacterCount()
        return false
    }

    private func configureStaticText() {
        cleanStyleButton.setTitle("Clean", for: .normal)
        plainStyleButton.setTitle("Plain", for: .normal)
        casualStyleButton.setTitle("Casual", for: .normal)
        genZalphaStyleButton.setTitle("Zalpha", for: .normal)

        notesTitleLabel.text = "Decode Notes"
        notesBodyLabel.text = "• \"ㄹㅇ\" means \"really\"\n• \"망했다\" was translated as \"messed up\""
        outputTextView.text = "I feel like I really messed up my life. What should I do?"
    }

    private func configureInterface() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = labelColor

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        configureDynamicColors()
        configureCards()
        configureLanguageButtons()
        configureStyleButtons()
        configureDecodeButton()
        configureTextViews()
        configureUtilityButtons()
        configureLabels()
        configureKeyboardDismissal()
        updateLanguageInterface()
    }

    private func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: ViewController, _) in
            viewController.configureDynamicColors()
            viewController.updateStyleSelection()
            viewController.updateShadowPaths()
        }
    }

    private func configureDynamicColors() {
        view.backgroundColor = pageBackgroundColor
        scrollView.backgroundColor = pageBackgroundColor
        contentView.backgroundColor = pageBackgroundColor

        [mainCardView, inputCardView, outputCardView, notesCardView].forEach {
            $0?.backgroundColor = cardBackgroundColor
            $0?.layer.borderColor = borderColor.cgColor
        }

        inputTextView.backgroundColor = .clear
        outputTextView.backgroundColor = .clear
        inputTextView.textColor = labelColor
        outputTextView.textColor = labelColor

        styleLabel.textColor = labelColor
        [inputLanguageLabel, outputLanguageLabel, characterCountLabel, notesTitleLabel].forEach {
            $0?.textColor = secondaryLabelColor
        }
        notesBodyLabel.textColor = labelColor
        toastLabel?.backgroundColor = toastBackgroundColor
        toastLabel?.textColor = toastTextColor

        [sourceLanguageButton, targetLanguageButton].forEach {
            $0?.setTitleColor(labelColor, for: .normal)
            $0?.tintColor = accentColor
            $0?.backgroundColor = controlBackgroundColor
            $0?.layer.borderColor = borderColor.cgColor
        }

        copyButton.tintColor = labelColor
        notesIconButton.tintColor = accentColor
        navigationController?.navigationBar.tintColor = labelColor
    }

    private func configureCards() {
        applyCardStyle(to: mainCardView, cornerRadius: 18, shadowOpacity: isDarkMode ? 0.12 : 0.16, shadowRadius: 9)
        applyCardStyle(to: inputCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.18, shadowRadius: 6)
        applyCardStyle(to: outputCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.18, shadowRadius: 6)
        applyCardStyle(to: notesCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.16, shadowRadius: 6)
    }

    private func configureLanguageButtons() {
        [sourceLanguageButton, targetLanguageButton].forEach {
            $0?.configuration = nil
            $0?.setImage(UIImage(systemName: "globe"), for: .normal)
            $0?.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            $0?.showsMenuAsPrimaryAction = true
            $0?.changesSelectionAsPrimaryAction = false
            $0?.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            $0?.titleLabel?.adjustsFontSizeToFitWidth = true
            $0?.titleLabel?.minimumScaleFactor = 0.8
            $0?.contentHorizontalAlignment = .center
            $0?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
            $0?.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            $0?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            $0?.layer.cornerRadius = 24
            $0?.layer.borderWidth = 1
            $0?.semanticContentAttribute = .forceLeftToRight
            $0?.clipsToBounds = false
            applySmallShadow(to: $0)
        }

        swapLanguageButton.configuration = nil
        swapLanguageButton.setImage(UIImage(systemName: "arrow.left.arrow.right"), for: .normal)
        swapLanguageButton.tintColor = accentColor
        swapLanguageButton.backgroundColor = controlBackgroundColor
        swapLanguageButton.layer.cornerRadius = 24
        swapLanguageButton.layer.borderWidth = 1
        swapLanguageButton.layer.borderColor = borderColor.cgColor
        swapLanguageButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        applySmallShadow(to: swapLanguageButton)
    }

    private func configureStyleButtons() {
        [cleanStyleButton, plainStyleButton, casualStyleButton, genZalphaStyleButton].forEach {
            $0?.configuration = nil
            $0?.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            $0?.titleLabel?.adjustsFontSizeToFitWidth = true
            $0?.titleLabel?.minimumScaleFactor = 0.8
            $0?.layer.cornerRadius = 17
            $0?.layer.borderWidth = 1
            $0?.clipsToBounds = false
            applySmallShadow(to: $0)
        }
    }

    private func configureDecodeButton() {
        decodeButton.configuration = nil
        decodeButton.setTitle("Decode", for: .normal)
        decodeButton.setTitleColor(.white, for: .normal)
        decodeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        decodeButton.backgroundColor = accentColor
        decodeButton.layer.cornerRadius = 22
    }

    private func configureTextViews() {
        inputTextView.font = .systemFont(ofSize: 20, weight: .semibold)
        outputTextView.font = .systemFont(ofSize: 21, weight: .bold)
        inputTextView.returnKeyType = .default
        inputTextView.inputAccessoryView = nil
        outputTextView.isEditable = false
        outputTextView.isSelectable = true

        [inputTextView, outputTextView].forEach {
            $0?.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            $0?.textContainer.lineFragmentPadding = 0
        }
    }

    private func configureUtilityButtons() {
        copyButton.configuration = nil
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)

        notesIconButton.configuration = nil
        notesIconButton.setImage(UIImage(systemName: "lightbulb.max"), for: .normal)
        notesIconButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        notesIconButton.isUserInteractionEnabled = false
    }

    private func configureLabels() {
        styleLabel.font = .systemFont(ofSize: 23, weight: .semibold)
        inputLanguageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        outputLanguageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        characterCountLabel.font = .systemFont(ofSize: 13, weight: .regular)
        notesTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        notesBodyLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        notesBodyLabel.numberOfLines = 0
    }

    private func configureKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: inputTextView)
    }

    private func updateStyleSelection() {
        let styles: [(TranslationStyle, UIButton)] = [
            (.clean, cleanStyleButton),
            (.plain, plainStyleButton),
            (.casual, casualStyleButton),
            (.genZalpha, genZalphaStyleButton)
        ]

        styles.forEach { style, button in
            let isSelected = style == selectedStyle
            button.backgroundColor = isSelected ? accentColor : controlBackgroundColor
            button.setTitleColor(isSelected ? .white : labelColor, for: .normal)
            button.layer.borderColor = isSelected ? UIColor.clear.cgColor : borderColor.cgColor
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }

    private func updateLanguageInterface() {
        configureLanguageButton(sourceLanguageButton, language: sourceLanguage)
        configureLanguageButton(targetLanguageButton, language: targetLanguage)
        sourceLanguageButton.menu = makeLanguageMenu(selectedLanguage: sourceLanguage, changesSource: true)
        targetLanguageButton.menu = makeLanguageMenu(selectedLanguage: targetLanguage, changesSource: false)
        inputLanguageLabel.text = "Input - \(sourceLanguage.displayName)"
        outputLanguageLabel.text = "Output - \(targetLanguage.displayName)"
    }

    private func configureLanguageButton(_ button: UIButton, language: Language) {
        button.setTitle(language.displayName, for: .normal)
        button.setTitleColor(labelColor, for: .normal)
        button.tintColor = accentColor
        button.accessibilityLabel = language.displayName
    }

    private func makeLanguageMenu(selectedLanguage: Language, changesSource: Bool) -> UIMenu {
        let actions = Language.allCases.map { language in
            UIAction(
                title: language.displayName,
                state: language == selectedLanguage ? .on : .off
            ) { [weak self] _ in
                self?.setLanguage(language, changesSource: changesSource)
            }
        }

        return UIMenu(children: actions)
    }

    private func setLanguage(_ language: Language, changesSource: Bool) {
        if changesSource {
            sourceLanguage = language
            targetLanguage = oppositeLanguage(of: language)
        } else {
            targetLanguage = language
            sourceLanguage = oppositeLanguage(of: language)
        }

        updateLanguageInterface()
    }

    private func oppositeLanguage(of language: Language) -> Language {
        language == .english ? .korean : .english
    }

    private func showToast(_ message: String) {
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

    private func makeToastLabel() -> ToastLabel {
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

    private func updateCharacterCount() {
        let count = inputTextView.text.count
        characterCountLabel.text = "\(count)/\(maximumInputLength)"
    }

    private func updateShadowPaths() {
        [mainCardView, inputCardView, outputCardView, notesCardView, sourceLanguageButton, swapLanguageButton, targetLanguageButton, cleanStyleButton, plainStyleButton, casualStyleButton, genZalphaStyleButton].forEach {
            guard let view = $0 else { return }
            view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        }
    }

    private func applyCardStyle(to view: UIView, cornerRadius: CGFloat, shadowOpacity: Float, shadowRadius: CGFloat) {
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = shadowRadius
        view.clipsToBounds = false
    }

    private func applySmallShadow(to view: UIView?) {
        view?.layer.shadowColor = UIColor.black.cgColor
        view?.layer.shadowOpacity = isDarkMode ? 0.10 : 0.18
        view?.layer.shadowOffset = CGSize(width: 0, height: 2)
        view?.layer.shadowRadius = 3
    }

    private var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    private var pageBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)
                : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        }
    }

    private var cardBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)
                : UIColor.white
        }
    }

    private var controlBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
                : UIColor.white
        }
    }

    private var borderColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.14)
                : UIColor(white: 0.0, alpha: 0.16)
        }
    }

    private var labelColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }
    }

    private var secondaryLabelColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.58)
                : UIColor(white: 0.0, alpha: 0.42)
        }
    }

    private var toastBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.90)
                : UIColor(white: 0.0, alpha: 0.86)
        }
    }

    private var toastTextColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        }
    }
}

private final class ToastLabel: UILabel {
    private let insets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
