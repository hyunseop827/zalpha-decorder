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

    let accentColor = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)
    let aiService = AIService()
    var isDecoding = false
    var hasShownStartupSplash = false
    private let maximumInputLength = 100
    var toastLabel: ToastLabel?
    var toastHideWorkItem: DispatchWorkItem?
    private var selectedStyle: TranslationStyle = .clean
    private var sourceLanguage: Language = .korean
    private var targetLanguage: Language = .english

    override func viewDidLoad() {
        super.viewDidLoad()

        inputTextView.delegate = self
        configureInterface()
        registerForThemeChanges()
        updateStyleSelection()
        updateLanguageInterface()
        updateCharacterCount()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showStartupSplashIfNeeded()
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
        guard !isDecoding else { return }

        Task { [weak self] in
            await self?.runGreetingDecode()
        }
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

    @objc func dismissKeyboard() {
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

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: inputTextView)
    }

    func updateStyleSelection() {
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

    func updateLanguageInterface() {
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

    private func updateCharacterCount() {
        let count = inputTextView.text.count
        characterCountLabel.text = "\(count)/\(maximumInputLength)"
    }
}
