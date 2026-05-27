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
    case invalidResponse
}

/// Parsed Gemini response containing the final decoded output and optional notes.
struct DecodeResult: Decodable {
    let result: String
    let notes: [String]
}

/// Thin Firebase AI Logic wrapper that builds decode prompts and returns cleaned model text.
final class AIService {
    private lazy var model = FirebaseAI.firebaseAI(backend: .googleAI()).generativeModel(
        modelName: "gemini-3.1-flash-lite",
        safetySettings: [
            SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh)
        ]
    )

    /// Sends the user's text to Gemini and returns the decoded result with optional notes.
    func decode(text: String, sourceLanguage: String, targetLanguage: String, style: TranslationStyle) async throws -> DecodeResult {
        let taskInstruction = sourceLanguage == targetLanguage
            ? "Rewrite or decode the following text in \(targetLanguage) using the selected style."
            : "Translate or decode the following text from \(sourceLanguage) to \(targetLanguage)."
        let prompt = """
        \(taskInstruction)
        Preserve the original meaning.
        Keep the result concise and direct. Do not add hedging, extra context, or emotional explanation that is not in the input.
        If the original text contains profanity or harsh wording, preserve the emotional intent but reduce the intensity.
        Do not reproduce strong profanity directly.
        Do not add stronger profanity, hate slurs, threats, sexualized insults, or targeted abuse.
        If the original wording is too intense, soften it into style-appropriate wording instead of refusing.
        \(style.promptInstruction)
        Return only a valid JSON object. Do not use markdown. Do not wrap the JSON in code fences.
        The JSON object must have this shape:
        {
          "result": "final decoded translation",
          "notes": [
            "short note 1",
            "short note 2",
            "short note 3"
          ]
        }
        The result must contain only the final decoded translation.
        Notes must be written in English, focus on specific source expressions, and contain at most 3 short items.
        Notes should explain only slang, idioms, profanity, meme expressions, abbreviations, or culturally loaded phrases.
        Do not explain ordinary literal words such as nouns, names, pronouns, or basic verbs.
        If a phrase mixes literal words and slang, choose the smallest meaningful slang or idiomatic expression.
        For example, in "인생 조졌다", explain only "조졌다", not "인생 조졌다".
        For example, in "야 나 진짜 인생 망했다 ㄹㅇ", explain "망했다" and "ㄹㅇ", not "인생".
        Prefer notes in this format: "\"source expression\" means \"meaning\", translated as \"target expression\"."
        Keep each note under 70 characters when possible.
        Do not write broad notes like "translated a colloquial expression" or "reframed emotional intensity".
        If no notes are needed, return an empty notes array.

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

        guard let data = text.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        do {
            let decodedResult = try JSONDecoder().decode(DecodeResult.self, from: data)
            let trimmedResult = decodedResult.result.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedResult.isEmpty else {
                throw AIServiceError.emptyResponse
            }

            return DecodeResult(
                result: trimmedResult,
                notes: decodedResult.notes
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .prefix(3)
                    .map { String($0) }
            )
        } catch let error as AIServiceError {
            throw error
        } catch {
            print("Firebase AI Logic invalid JSON response:", text)
            throw AIServiceError.invalidResponse
        }
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
            Remove profanity and turn harsh wording into calm, professional language.
            Keep it direct, not overly dramatic or verbose.
            Example tone: "My life feels ruined."
            """
        case .plain:
            return """
            Style: Plain.
            Use normal, natural, easy-to-understand wording. Avoid slang, jokes, profanity, and extra flavor.
            Keep it close to how an ordinary person would say it.
            Example tone: "My life is ruined."
            """
        case .casual:
            return """
            Style: Casual.
            Use natural friend-to-friend wording. Be relaxed and conversational. Use contractions in English when natural.
            If the input has strong profanity, soften it into mild casual phrases like "messed up", "screwed up", or "this sucks".
            Example tone: "I'm so screwed."
            """
        case .genZalpha:
            return """
            Style: Zalpha.
            Use Gen Z / Gen Alpha / brainrot / meme-like wording. Slang, exaggeration, and playful dramatic wording are allowed, but preserve the meaning and do not explain the slang.
            If the input has strong profanity, soften it into meme-style phrases like "cooked", "not it", "ain't it", or "I'm done".
            Emoji can be used and allowed.
            Example tone: "Bro, I'm cooked. 🥀"
            """
        }
    }
}
