import Foundation
import Metal

/// Keeps the GPU clocked up across decode's expert-read gaps.
public final class GPUClockHold: @unchecked Sendable {
    static let iterationsPerThread: UInt32 = 50_000
    static let commandBuffersInFlight = 2
    private let worker: GPUClockHoldWorker

    public init(device: MTLDevice, library: MTLLibrary) throws {
        worker = try GPUClockHoldWorker(device: device, library: library)
    }

    deinit { worker.stop() }
    public func touch(seconds: Double) { worker.touch(seconds: seconds) }
    public func stop() { worker.stop() }
    public var isActive: Bool { worker.isActive }
    public var submittedCommandBuffers: UInt64 { worker.submittedCommandBuffers }
    public var activeSeconds: Double { worker.activeSeconds }
}

private final class GPUClockHoldWorker: @unchecked Sendable {
    private let queue: MTLCommandQueue
    private let pipeline: MTLComputePipelineState
    private let sink: MTLBuffer
    private let inFlight = DispatchSemaphore(value: GPUClockHold.commandBuffersInFlight)
    private let condition = NSCondition()
    private var deadlineNanos: UInt64 = 0
    private var stopped = false
    private var submitted: UInt64 = 0
    private var activeNanos: UInt64 = 0
    private var activeSinceNanos: UInt64?

    init(device: MTLDevice, library: MTLLibrary) throws {
        guard let queue = device.makeCommandQueue() else { throw MetalError.noQueue }
        queue.label = "gpu-clock-hold"
        guard let function = library.makeFunction(name: "gpu_clock_hold") else {
            throw MetalError.missingFunction("gpu_clock_hold")
        }
        guard let sink = device.makeBuffer(length: 16, options: .storageModePrivate) else {
            throw MetalError.missingShaderResource("gpu_clock_hold sink buffer")
        }
        self.queue = queue
        self.pipeline = try device.makeComputePipelineState(function: function)
        self.sink = sink
        let thread = Thread { [self] in
            while submitOneOrWait() {}
        }
        thread.name = "gpu-clock-hold"
        thread.qualityOfService = .userInitiated
        thread.start()
    }

    func touch(seconds: Double) {
        let now = Self.now()
        let requested = now &+ UInt64(max(0, seconds) * 1e9)
        condition.lock()
        if !stopped {
            deadlineNanos = max(deadlineNanos, requested)
            if activeSinceNanos == nil { activeSinceNanos = now }
            condition.signal()
        }
        condition.unlock()
    }

    func stop() {
        condition.lock()
        stopped = true
        closeActiveWindowLocked(at: Self.now())
        condition.broadcast()
        condition.unlock()
    }

    var isActive: Bool {
        condition.lock()
        defer { condition.unlock() }
        return !stopped && Self.now() < deadlineNanos
    }

    var submittedCommandBuffers: UInt64 {
        condition.lock()
        defer { condition.unlock() }
        return submitted
    }

    var activeSeconds: Double {
        condition.lock()
        defer { condition.unlock() }
        var nanos = activeNanos
        if let since = activeSinceNanos { nanos &+= Self.now() &- since }
        return Double(nanos) / 1e9
    }

    private func submitOneOrWait() -> Bool {
        condition.lock()
        while !stopped && Self.now() >= deadlineNanos {
            closeActiveWindowLocked(at: Self.now())
            condition.wait()
        }
        if stopped {
            condition.unlock()
            return false
        }
        condition.unlock()

        inFlight.wait()
        condition.lock()
        let stoppedWhileWaiting = stopped
        condition.unlock()
        guard !stoppedWhileWaiting,
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            inFlight.signal()
            return !stoppedWhileWaiting
        }
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(sink, offset: 0, index: 0)
        var iterations = GPUClockHold.iterationsPerThread
        encoder.setBytes(&iterations, length: MemoryLayout<UInt32>.size, index: 1)
        encoder.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1),
                                     threadsPerThreadgroup: MTLSize(width: 32, height: 1, depth: 1))
        encoder.endEncoding()
        let inFlight = self.inFlight
        commandBuffer.addCompletedHandler { _ in inFlight.signal() }
        commandBuffer.commit()

        condition.lock()
        if !stopped { submitted &+= 1 }
        condition.unlock()
        return true
    }

    private func closeActiveWindowLocked(at now: UInt64) {
        if let since = activeSinceNanos {
            activeNanos &+= now &- since
            activeSinceNanos = nil
        }
    }

    private static func now() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }
}
