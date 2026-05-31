//
//  FirebaseAITextClient.swift
//  ZalphaDecoder
//

import FirebaseAILogic
import Foundation

internal protocol AITextGenerating {
    func generateRawText(prompt: String, task: AITextGenerationTask) async throws -> String
}

enum AITextGenerationTask {
    case decode
    case example
}

final class FirebaseAITextClient: AITextGenerating {
    private let firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())

    private lazy var decodeModel = firebaseAI.generativeModel(
        modelName: "gemini-3.1-flash-lite",
        generationConfig: Self.decodeGenerationConfig,
        safetySettings: safetySettings
    )

    private lazy var exampleModel = firebaseAI.generativeModel(
        modelName: "gemini-3.1-flash-lite",
        generationConfig: Self.exampleGenerationConfig,
        safetySettings: safetySettings
    )

    private let safetySettings = [
        SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh)
    ]

    private static let decodeGenerationConfig = GenerationConfig(
        temperature: 0.35,
        topP: 0.85,
        candidateCount: 1,
        maxOutputTokens: 700,
        responseMIMEType: "application/json"
    )

    private static let exampleGenerationConfig = GenerationConfig(
        temperature: 0.85,
        topP: 0.95,
        candidateCount: 1,
        maxOutputTokens: 220,
        responseMIMEType: "application/json"
    )

    func generateRawText(prompt: String, task: AITextGenerationTask) async throws -> String {
        let response: GenerateContentResponse
        do {
            response = try await model(for: task).generateContent(prompt)
        } catch GenerateContentError.promptBlocked {
            throw AIServiceError.blocked
        } catch GenerateContentError.responseStoppedEarly {
            throw AIServiceError.blocked
        } catch GenerateContentError.internalError(let underlying) {
            throw classifyInternalError(underlying)
        } catch let error as URLError {
            print("Firebase AI Logic network error:", error)
            throw AIServiceError.networkUnavailable
        } catch {
            if let mappedError = mapUnderlyingError(error) {
                throw mappedError
            }

            throw error
        }

        let rawText = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !rawText.isEmpty else {
            throw AIServiceError.emptyResponse
        }

        return rawText
    }

    private func model(for task: AITextGenerationTask) -> GenerativeModel {
        switch task {
        case .decode:
            return decodeModel
        case .example:
            return exampleModel
        }
    }

    private func classifyInternalError(_ error: Error) -> AIServiceError {
        mapUnderlyingError(error) ?? .serviceUnavailable
    }

    private func mapUnderlyingError(_ error: Error) -> AIServiceError? {
        let nsError = error as NSError
        let description = "\(error) \(nsError.localizedDescription)".lowercased()

        if nsError.code == 429
            || description.contains("429")
            || description.contains("quota exceeded")
            || description.contains("resource_exhausted")
            || description.contains("resourceexhausted")
            || description.contains("rate limit")
            || description.contains("too many requests") {
            return .rateLimited
        }

        if nsError.code == URLError.notConnectedToInternet.rawValue
            || nsError.code == URLError.networkConnectionLost.rawValue
            || nsError.code == URLError.timedOut.rawValue
            || description.contains("not connected")
            || description.contains("offline")
            || description.contains("network")
            || description.contains("timed out")
            || description.contains("timeout")
            || description.contains("urlerror")
            || description.contains("dns")
            || description.contains("cannot connect")
            || description.contains("connection lost") {
            return .networkUnavailable
        }

        if description.contains("403")
            || description.contains("404")
            || description.contains("service_disabled")
            || description.contains("gen_ai_config_not_found")
            || description.contains("api key")
            || description.contains("permission_denied")
            || description.contains("permissiondenied")
            || description.contains("not_found")
            || description.contains("notfound")
            || description.contains("missing a configured gemini")
            || description.contains("has not been used in project") {
            return .configuration
        }

        if description.contains("500")
            || description.contains("502")
            || description.contains("503")
            || description.contains("504")
            || description.contains("unavailable")
            || description.contains("deadline_exceeded")
            || description.contains("deadlineexceeded")
            || description.contains("temporarily unavailable") {
            return .serviceUnavailable
        }

        return nil
    }
}
