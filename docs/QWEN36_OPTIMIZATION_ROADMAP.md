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
4. **Complete — Test 4096-token chunks.** Correctness and the full 1,425-test
   package gate pass.
   At 2,940 tokens, one 4096 chunk measured 35.46 s versus the frozen 40.96 s
   two-chunk baseline. The order-balanced 8,816-token comparison split: 4096
   won when first, while 2048 won narrowly when first. Keep 4096 selectable and
   experimental; retain 2048 as the stable general-purpose setting.
5. **Complete — Scale through 16K/32K/64K.** All three context allocations and
   tiny generations pass; the 64K setting used a 3.31 GB peak versus 2.30 GB at
   16K. A 14,656-token prompt completed correctly in 570.42 s with a 5.80 GB
   peak, but tiled full attention consumed 453.56 s (79.5%). Defer near-bound
   32K/64K timing until attention is optimized; current estimates are about
   40 minutes and 2.5–3 hours respectively.
6. **Complete — Optimize the measured prefill bottleneck.** The attribution
   selected Qwen-compatible TensorOps full attention. The first real-model
   validations reduced 2,940-token prefill from 35.46 s to 24.64 s and
   8,816-token prefill from 232.53 s to 82.01 s. All eligible attention layers
   used TensorOps with no tiled fallback. An equivalent 14.7K-token fixture
   fell from 570.42 s to 140.75 s (4.05x faster). The full 1,426-test package
   gate passed.
7. **Complete — Validate and promote the prefill winner.** Long-context,
   memory, full package, real-output quality, and retained-KV continuation
   gates pass. The continuation reused 76 cached tokens and followed its email
   revision instructions. The release Mac app and decode service used by the
   TurboFieldfare Qwen 3.6 launcher were rebuilt after validation.
8. **In progress — Benchmark the 0.8B Qwen MTP drafter in MLX.** The official
   4-bit drafter is 0.495 GB but requires a separate compatible 20.43 GB MLX
   target. MLX is not installed and the Mac currently has 33 GiB free; an
   existing 20 GB Qwen GGUF cache could be replaced rather than keeping both.
   After the storage choice, measure proposal speed, acceptance, memory,
   end-to-end gain, and greedy-output equivalence because upstream speculative
   decoding has had correctness regressions.
9. **Pending — Prototype and validate speculative decoding.** Add safe KV and
   DeltaNet rollback, batched verification, sampling, cancellation, and
   conversation tests only if the feasibility result is worthwhile.
10. **Pending — Promote the final stable build.** Keep normal decoding and the
    2048 prefill path as fallbacks, document the result, and update the app.
