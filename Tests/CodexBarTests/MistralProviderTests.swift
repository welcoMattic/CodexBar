import Foundation
import Testing
@testable import CodexBarCore

@Suite(.serialized)
struct MistralSettingsReaderTests {
    @Test
    func api_token_reads_from_environment() {
        let token = MistralSettingsReader.apiToken(environment: ["MISTRAL_API_KEY": "sk-test-abc123"])
        #expect(token == "sk-test-abc123")
    }

    @Test
    func api_token_returns_nil_when_missing() {
        let token = MistralSettingsReader.apiToken(environment: [:])
        #expect(token == nil)
    }

    @Test
    func api_token_returns_nil_for_empty_value() {
        let token = MistralSettingsReader.apiToken(environment: ["MISTRAL_API_KEY": ""])
        #expect(token == nil)
    }

    @Test
    func api_token_trims_whitespace() {
        let token = MistralSettingsReader.apiToken(environment: ["MISTRAL_API_KEY": "  sk-test  "])
        #expect(token == "sk-test")
    }

    @Test
    func api_token_strips_wrapping_quotes() {
        let token = MistralSettingsReader.apiToken(environment: ["MISTRAL_API_KEY": "\"sk-test\""])
        #expect(token == "sk-test")
    }

    @Test
    func api_url_defaults_to_production() {
        let url = MistralSettingsReader.apiURL(environment: [:])
        #expect(url.absoluteString == "https://api.mistral.ai/v1")
    }

    @Test
    func api_url_can_be_overridden() {
        let url = MistralSettingsReader.apiURL(environment: ["MISTRAL_API_URL": "https://custom.mistral.test/v1"])
        #expect(url.absoluteString == "https://custom.mistral.test/v1")
    }
}

@Suite(.serialized)
struct MistralUsageSnapshotTests {
    @Test
    func to_usage_snapshot_with_budget_sets_primary_window() {
        let snapshot = MistralUsageSnapshot(
            monthlyBudget: 100,
            currentMonthUsage: 25,
            planName: "Build",
            updatedAt: Date(timeIntervalSince1970: 1_739_841_600))

        let usage = snapshot.toUsageSnapshot()

        #expect(usage.primary?.usedPercent == 25)
        #expect(usage.identity?.loginMethod == "Build · $25.00 this month")
        #expect(usage.identity?.providerID == .mistral)
    }

    @Test
    func to_usage_snapshot_without_budget_omits_primary_window() {
        let snapshot = MistralUsageSnapshot(
            monthlyBudget: nil,
            currentMonthUsage: 12.50,
            planName: nil,
            updatedAt: Date(timeIntervalSince1970: 1_739_841_600))

        let usage = snapshot.toUsageSnapshot()

        #expect(usage.primary == nil)
        #expect(usage.identity?.loginMethod == "Usage: $12.50 this month")
    }

    @Test
    func used_percent_clamps_to_100() {
        let snapshot = MistralUsageSnapshot(
            monthlyBudget: 10,
            currentMonthUsage: 15,
            planName: nil,
            updatedAt: Date())

        #expect(snapshot.usedPercent == 100)
    }

    @Test
    func remaining_budget_clamps_to_zero() {
        let snapshot = MistralUsageSnapshot(
            monthlyBudget: 10,
            currentMonthUsage: 15,
            planName: nil,
            updatedAt: Date())

        #expect(snapshot.remaining == 0)
    }

    @Test
    func zero_budget_returns_nil_percent() {
        let snapshot = MistralUsageSnapshot(
            monthlyBudget: 0,
            currentMonthUsage: 5,
            planName: nil,
            updatedAt: Date())

        #expect(snapshot.usedPercent == nil)
    }
}

@Suite(.serialized)
struct MistralTokenResolverTests {
    @Test
    func mistral_token_resolves_from_environment() {
        let token = ProviderTokenResolver.mistralToken(environment: ["MISTRAL_API_KEY": "sk-test"])
        #expect(token == "sk-test")
    }

    @Test
    func mistral_token_returns_nil_when_missing() {
        let token = ProviderTokenResolver.mistralToken(environment: [:])
        #expect(token == nil)
    }

    @Test
    func mistral_resolution_returns_environment_source() {
        let resolution = ProviderTokenResolver.mistralResolution(environment: ["MISTRAL_API_KEY": "sk-test"])
        #expect(resolution?.source == .environment)
        #expect(resolution?.token == "sk-test")
    }
}
