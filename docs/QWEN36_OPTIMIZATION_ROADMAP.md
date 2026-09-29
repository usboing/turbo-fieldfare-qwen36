# Qwen 3.6 optimization roadmap

This is the short progress view for the Qwen 3.6 work on the M3 Air. The
working 2048-token build stays usable while candidates are developed and
validated separately.

1. **Complete — Freeze the 2048 baseline.** Commit `dbdae2a`; 2,334 prompt
   tokens measured 28.37 s / 81.5 tok/s in the app.
2. **Complete — Add detailed prefill profiling.** Attribute wall and GPU
   time to Qwen DeltaNet/full-attention setup, shared experts, routed experts,
   expert fetches, layer tails, and the final head. Report the selected full
   attention path. The full package gate passed with 1,423 tests.
3. **Complete — Validate the profiler and benchmark 2K/8K.** Full package and
   focused tests passed. Real 2,940- and 8,816-token profiles identified tiled
   full attention as 31% and 66% of wall time respectively; see
   `QWEN36_PREFILL_PROFILE.md`.
4. **In progress — Test 4096-token chunks.** Compare against 2048 with memory,
   temperature, power, and throttling recorded; do not promote a marginal win.
5. **Pending — Scale through 16K/32K/64K.** Check correctness, memory,
   sustained thermals, prefill time, and decode rate near each context bound.
6. **Pending — Optimize the measured prefill bottleneck.** Choose Qwen
   TensorOps full attention, DeltaNet, or expert I/O only after attribution.
7. **Pending — Validate and promote the prefill winner.** Run quality,
   continuation, long-context, memory, and full package gates before updating
   the daily app.
8. **Pending — Benchmark the 0.8B Qwen MTP drafter in MLX.** Measure proposal
   speed, acceptance, memory, and end-to-end gain on this Mac.
9. **Pending — Prototype and validate speculative decoding.** Add safe KV and
   DeltaNet rollback, batched verification, sampling, cancellation, and
   conversation tests only if the feasibility result is worthwhile.
10. **Pending — Promote the final stable build.** Keep normal decoding and the
    2048 prefill path as fallbacks, document the result, and update the app.
