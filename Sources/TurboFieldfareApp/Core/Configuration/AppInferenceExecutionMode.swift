import Foundation

/// Selects where the native app owns its inference session.
///
/// The decode service remains the default. The in-process option can be saved
/// from the app's runtime settings or selected for one launch via the environment.
public enum AppInferenceExecutionMode: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case inProcess = "in-process"
    case decodeService = "decode-service"

    public static let preferenceKey = "inferenceMode"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .inProcess: "Fast"
        case .decodeService: "Isolated"
        }
    }

    public static func selected(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        defaults: UserDefaults = UserDefaults(suiteName: "TurboFieldfare") ?? .standard
    ) -> AppInferenceExecutionMode {
        if let override = environment["TURBO_FIELDFARE_INFERENCE_MODE"],
           let mode = AppInferenceExecutionMode(rawValue: override) {
            return mode
        }
        return defaults.string(forKey: preferenceKey)
            .flatMap(AppInferenceExecutionMode.init(rawValue:)) ?? .decodeService
    }
}
