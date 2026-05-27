//
//  AIService.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import FirebaseAILogic
import Foundation

/// Normalized AI errors that the UI can map to user-facing messages.
enum AIServiceError: Error {
    case emptyResponse
    case blocked
    case rateLimited
}

/// Thin Firebase AI Logic wrapper that builds decode prompts and returns cleaned model text.
final class AIService {
    private lazy var model = FirebaseAI.firebaseAI(backend: .googleAI()).generativeModel(
        modelName: "gemini-3.1-flash-lite",
        safetySettings: [
            SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh)
        ]
    )

    /// Sends the user's text to Gemini and returns only the cleaned decoded result.
    func decode(text: String, sourceLanguage: String, targetLanguage: String, style: TranslationStyle) async throws -> String {
        let taskInstruction = sourceLanguage == targetLanguage
            ? "Rewrite or decode the following text in \(targetLanguage) using the selected style."
            : "Translate or decode the following text from \(sourceLanguage) to \(targetLanguage)."
        let prompt = """
        \(taskInstruction)
        Preserve the original meaning.
        If the original text contains profanity, preserve the emotional intent but prefer mild, non-hateful wording.
        For Casual or Zalpha style, light common profanity may be preserved when needed for meaning.
        Do not add stronger profanity, hate slurs, threats, or sexualized insults.
        If the original wording is too intense, soften it instead of refusing.
        \(style.promptInstruction)
        Return only the final decoded translation. No markdown. No explanation. No notes.

        Text:
        \(text)
        """
        let response: GenerateContentResponse
        do {
            response = try await model.generateContent(prompt)
        } catch GenerateContentError.promptBlocked {
            throw AIServiceError.blocked
        } catch GenerateContentError.responseStoppedEarly {
            throw AIServiceError.blocked
        } catch GenerateContentError.internalError(let underlying) {
            if isRateLimitError(underlying) {
                throw AIServiceError.rateLimited
            }

            throw GenerateContentError.internalError(underlying: underlying)
        }

        let text = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !text.isEmpty else {
            throw AIServiceError.emptyResponse
        }

        return text
    }

    /// Detects Firebase quota errors so the UI can show a clearer rate-limit message.
    private func isRateLimitError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let description = nsError.localizedDescription

        return nsError.code == 429
            || description.contains("Quota exceeded")
            || description.contains("RESOURCE_EXHAUSTED")
            || description.contains("resourceExhausted")
    }
}

/// Prompt instructions for each user-visible style option.
private extension TranslationStyle {
    var promptInstruction: String {
        switch self {
        case .formal:
            return """
            Style: Formal.
            Use polished, respectful, professional wording suitable for email, school, or workplace.
            Example tone: "I believe I made a serious mistake. What should I do?"
            """
        case .plain:
            return """
            Style: Plain.
            Use simple, direct, easy-to-understand wording. Avoid slang, jokes, and extra flavor.
            Example tone: "I really messed up. What should I do?"
            """
        case .casual:
            return """
            Style: Casual.
            Use natural friend-to-friend wording. Be relaxed and conversational. Use contractions in English when natural.
            Example tone: "I really screwed up. What do I do now?"
            """
        case .genZalpha:
            return """
            Style: Zalpha.
            Use Gen Z / Gen Alpha / brainrot / meme-like wording. Slang is always allowed, but preserve the meaning and do not explain the slang.
            Emoji can be used and allowed.
            Example tone: "Bro, I'm actually cooked. What do I even do?"
            """
        }
    }
}
