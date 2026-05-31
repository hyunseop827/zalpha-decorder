//
//  ViewController+Styling.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Groups runtime UI styling that depends on state, trait changes, or layer configuration.
extension ViewController {

    /// Runs the full runtime styling setup for the storyboard-backed interface.
    func configureInterface() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = labelColor

        configureDynamicColors()
        configureCards()
        configureLanguageButtons()
        configureStyleButtons()
        configureDecodeButton()
        configureTextContainers()
        configureUtilityButtons()
        configureKeyboardDismissal()
        configureNotesCardInteraction()
        configureLoadingOverlay()
    }

    /// Re-applies dynamic colors and shadows when the system light/dark appearance changes.
    func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: ViewController, _) in
            viewController.configureDynamicColors()
            viewController.updateStyleSelection()
            viewController.updateShadowPaths()
        }
    }

    /// Applies colors that depend on the current light or dark mode.
    func configureDynamicColors() {
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
        loadingOverlayView.backgroundColor = loadingOverlayColor
        loadingTitleLabel.textColor = labelColor
        loadingActivityIndicator.color = accentColor
        loadingCardView?.backgroundColor = cardBackgroundColor
        loadingCardView?.layer.borderColor = borderColor.cgColor
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

    /// Applies card corner radius, border, and shadow layer styling.
    func configureCards() {
        applyCardStyle(to: mainCardView, cornerRadius: 18, shadowOpacity: isDarkMode ? 0.12 : 0.16, shadowRadius: 9)
        applyCardStyle(to: inputCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.18, shadowRadius: 6)
        applyCardStyle(to: outputCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.18, shadowRadius: 6)
        applyCardStyle(to: notesCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.16, shadowRadius: 6)
    }

    /// Configures the source, swap, and target language buttons.
    func configureLanguageButtons() {
        [sourceLanguageButton, targetLanguageButton].forEach {
            $0?.configuration = nil
            $0?.showsMenuAsPrimaryAction = true
            $0?.changesSelectionAsPrimaryAction = false
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
        swapLanguageButton.tintColor = accentColor
        swapLanguageButton.backgroundColor = controlBackgroundColor
        swapLanguageButton.layer.cornerRadius = 24
        swapLanguageButton.layer.borderWidth = 1
        swapLanguageButton.layer.borderColor = borderColor.cgColor
        applySmallShadow(to: swapLanguageButton)
    }

    /// Configures shared typography and layer styling for the style buttons.
    func configureStyleButtons() {
        let buttons: [UIButton] = [
            cleanStyleButton,
            plainStyleButton,
            casualStyleButton,
            genZalphaStyleButton
        ]

        buttons.forEach { button in
            button.configuration = nil
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.8
            button.layer.cornerRadius = 17
            button.layer.borderWidth = 1
            button.clipsToBounds = false
            applySmallShadow(to: button)
        }
    }

    /// Configures the main Decode action button.
    func configureDecodeButton() {
        decodeButton.configuration = nil
        decodeButton.backgroundColor = accentColor
        decodeButton.layer.cornerRadius = 22
    }

    /// Normalizes text view padding so the storyboard cards keep consistent spacing.
    func configureTextContainers() {
        [inputTextView, outputTextView].forEach {
            $0?.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            $0?.textContainer.lineFragmentPadding = 0
        }
    }

    /// Configures icon-only utility buttons such as copy and notes.
    func configureUtilityButtons() {
        copyButton.configuration = nil

        notesIconButton.configuration = nil
        notesIconButton.isUserInteractionEnabled = false
    }

    /// Adds a background tap gesture used to dismiss the keyboard.
    func configureKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    /// Makes the Decode Notes card open the current decode detail.
    func configureNotesCardInteraction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notesCardTapped))
        notesCardView.addGestureRecognizer(tapGesture)
        notesCardView.isUserInteractionEnabled = true
        notesCardView.accessibilityTraits.insert(.button)
        notesCardView.accessibilityLabel = AppStrings.Decode.notesDetailAccessibilityLabel
    }

    /// Configures the full-screen blocking overlay shown during Decode requests.
    func configureLoadingOverlay() {
        loadingOverlayView.isHidden = true
        loadingOverlayView.alpha = 0
        loadingTitleLabel.text = AppStrings.Decode.loadingTitle
        loadingActivityIndicator.stopAnimating()

        loadingCardView?.layer.cornerRadius = 16
        loadingCardView?.layer.cornerCurve = .continuous
        loadingCardView?.layer.borderWidth = 1
        loadingCardView?.layer.shadowColor = UIColor.black.cgColor
        loadingCardView?.layer.shadowOpacity = isDarkMode ? 0.18 : 0.14
        loadingCardView?.layer.shadowOffset = CGSize(width: 0, height: 4)
        loadingCardView?.layer.shadowRadius = 12
    }

    /// Updates shadow paths after views have final bounds.
    func updateShadowPaths() {
        [mainCardView, inputCardView, outputCardView, notesCardView, sourceLanguageButton, swapLanguageButton, targetLanguageButton, cleanStyleButton, plainStyleButton, casualStyleButton, genZalphaStyleButton, loadingCardView].forEach {
            guard let view = $0 else { return }
            view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        }
    }

    /// Applies the common rounded card layer style.
    func applyCardStyle(to view: UIView, cornerRadius: CGFloat, shadowOpacity: Float, shadowRadius: CGFloat) {
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

    /// Applies the common subtle button shadow style.
    func applySmallShadow(to view: UIView?) {
        view?.layer.shadowColor = UIColor.black.cgColor
        view?.layer.shadowOpacity = isDarkMode ? 0.10 : 0.18
        view?.layer.shadowOffset = CGSize(width: 0, height: 2)
        view?.layer.shadowRadius = 3
    }

    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    var loadingCardView: UIView? {
        loadingTitleLabel.superview?.superview
    }

    var pageBackgroundColor: UIColor {
        AppTheme.pageBackgroundColor
    }

    var cardBackgroundColor: UIColor {
        AppTheme.cardBackgroundColor
    }

    var controlBackgroundColor: UIColor {
        AppTheme.controlBackgroundColor
    }

    var borderColor: UIColor {
        AppTheme.borderColor
    }

    var loadingOverlayColor: UIColor {
        AppTheme.loadingOverlayColor
    }

    var labelColor: UIColor {
        AppTheme.labelColor
    }

    var secondaryLabelColor: UIColor {
        AppTheme.secondaryLabelColor
    }

    var toastBackgroundColor: UIColor {
        AppTheme.toastBackgroundColor
    }

    var toastTextColor: UIColor {
        AppTheme.toastTextColor
    }

    var accentColor: UIColor {
        AppTheme.accentColor
    }
}
