import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Mistral subscription API response
public struct MistralSubscriptionResponse: Decodable, Sendable {
    public let monthlyBudget: Double?
    public let currentMonthUsage: Double?
    public let planName: String?

    private enum CodingKeys: String, CodingKey {
        case monthlyBudget = "monthly_budget"
        case currentMonthUsage = "current_month_usage"
        case planName = "plan_name"
    }
}

/// Complete Mistral usage snapshot
public struct MistralUsageSnapshot: Sendable {
    public let monthlyBudget: Double?
    public let currentMonthUsage: Double
    public let planName: String?
    public let updatedAt: Date

    public init(
        monthlyBudget: Double?,
        currentMonthUsage: Double,
        planName: String?,
        updatedAt: Date)
    {
        self.monthlyBudget = monthlyBudget
        self.currentMonthUsage = currentMonthUsage
        self.planName = planName
        self.updatedAt = updatedAt
    }

    /// Usage percentage (0-100), nil when no budget is set
    public var usedPercent: Double? {
        guard let budget = self.monthlyBudget, budget > 0 else { return nil }
        return min(100, max(0, (self.currentMonthUsage / budget) * 100))
    }

    /// Remaining budget in dollars, nil when no budget is set
    public var remaining: Double? {
        guard let budget = self.monthlyBudget else { return nil }
        return max(0, budget - self.currentMonthUsage)
    }

    public func toUsageSnapshot() -> UsageSnapshot {
        let primary: RateWindow? = if let usedPercent {
            RateWindow(
                usedPercent: usedPercent,
                windowMinutes: nil,
                resetsAt: nil,
                resetDescription: nil)
        } else {
            nil
        }

        let usageStr = String(format: "$%.2f", self.currentMonthUsage)
        let loginMethod: String = if let planName, !planName.isEmpty {
            "\(planName) · \(usageStr) this month"
        } else {
            "Usage: \(usageStr) this month"
        }

        let identity = ProviderIdentitySnapshot(
            providerID: .mistral,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: loginMethod)

        return UsageSnapshot(
            primary: primary,
            secondary: nil,
            updatedAt: self.updatedAt,
            identity: identity)
    }
}

/// Fetches usage stats from the Mistral API
public struct MistralUsageFetcher: Sendable {
    private static let log = CodexBarLog.logger(LogCategories.mistralUsage)
    private static let requestTimeoutSeconds: TimeInterval = 15

    /// Fetches subscription/usage from Mistral using the provided API key
    public static func fetchUsage(
        apiKey: String,
        environment: [String: String] = ProcessInfo.processInfo.environment) async throws -> MistralUsageSnapshot
    {
        guard !apiKey.isEmpty else {
            throw MistralUsageError.invalidCredentials
        }

        let baseURL = MistralSettingsReader.apiURL(environment: environment)
        let subscriptionURL = baseURL
            .deletingLastPathComponent()
            .appendingPathComponent("billing")
            .appendingPathComponent("subscription")

        var request = URLRequest(url: subscriptionURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Self.requestTimeoutSeconds

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MistralUsageError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            Self.log.error("Mistral API returned \(httpResponse.statusCode)")
            throw MistralUsageError.apiError("HTTP \(httpResponse.statusCode)")
        }

        do {
            let decoder = JSONDecoder()
            let sub = try decoder.decode(MistralSubscriptionResponse.self, from: data)

            return MistralUsageSnapshot(
                monthlyBudget: sub.monthlyBudget,
                currentMonthUsage: sub.currentMonthUsage ?? 0,
                planName: sub.planName,
                updatedAt: Date())
        } catch let error as DecodingError {
            Self.log.error("Mistral JSON decoding error: \(error.localizedDescription)")
            throw MistralUsageError.parseFailed(error.localizedDescription)
        } catch let error as MistralUsageError {
            throw error
        } catch {
            Self.log.error("Mistral parsing error: \(error.localizedDescription)")
            throw MistralUsageError.parseFailed(error.localizedDescription)
        }
    }
}

/// Errors that can occur during Mistral usage fetching
public enum MistralUsageError: LocalizedError, Sendable {
    case invalidCredentials
    case networkError(String)
    case apiError(String)
    case parseFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "Invalid Mistral API credentials"
        case let .networkError(message):
            "Mistral network error: \(message)"
        case let .apiError(message):
            "Mistral API error: \(message)"
        case let .parseFailed(message):
            "Failed to parse Mistral response: \(message)"
        }
    }
}
