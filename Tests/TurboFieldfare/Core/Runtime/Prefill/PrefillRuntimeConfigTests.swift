import Testing
@testable import TurboFieldfare

@Suite struct PrefillRuntimeConfigTests {
    @Test(arguments: [32, 64, 128, 256, 512, 768, 1024, 1536, 2048, 4096])
    func productionUsesCompleteChunkedPath(_ chunkTokens: Int) throws {
        let config = PrefillRuntimeConfig.production(chunkTokens: chunkTokens)
        #expect(config.mode == .chunked)
        #expect(config.chunkTokens == chunkTokens)
    }

    @Test func offDisablesChunkedPrefill() {
        let config = PrefillRuntimeConfig.off
        #expect(config.mode == .off)
        #expect(!config.enabled)
    }

    @Test func plannerUsesConfiguredChunkSize() {
        let spans = PrefillChunkPlanner.spans(
            tokenCount: 130,
            startPosition: 7,
            config: .production(chunkTokens: 64))
        #expect(spans.map(\.tokenCount) == [64, 64, 2])
        #expect(spans.map(\.startPosition) == [7, 71, 135])
    }

    @Test func diagnosticsPreserveUnknownValues() {
        let diagnostics = PrefillExecutionDiagnostics(
            config: .production(chunkTokens: 128),
            executedMode: .unsupported,
            kvStorageMode: nil,
            unsupportedReason: "unavailable")
        #expect(diagnostics.kvStorageMode == nil)
        #expect(diagnostics.chunkCompleteness == .unsupported)
        #expect(diagnostics.unsupportedReason == "unavailable")
    }

    @Test func diagnosticsCarryPrefillAttribution() throws {
        let performance = PrefillPerformanceDiagnostics(
            tokenCount: 2_334,
            chunkCount: 2,
            totalMilliseconds: 28_370,
            deltaNetAndRouterGPUMilliseconds: 4_000,
            softmaxAttentionAndRouterGPUMilliseconds: 2_000,
            tensorOpsFullAttentionDispatches: 0,
            tiledFullAttentionDispatches: 20,
            sharedExpertGPUMilliseconds: 3_000,
            routedExpertGPUMilliseconds: 7_000,
            expertFetchWaitMilliseconds: 11_000,
            routeGroupingMilliseconds: 60,
            layerTailGPUMilliseconds: 300,
            finalHeadGPUMilliseconds: 12)
        let diagnostics = PrefillExecutionDiagnostics(
            config: .production(chunkTokens: 2_048),
            executedMode: .chunked,
            kvStorageMode: .fp16,
            performance: performance)

        #expect(diagnostics.performance == performance)
        #expect(try #require(diagnostics.performance).tiledFullAttentionDispatches == 20)
    }
}
