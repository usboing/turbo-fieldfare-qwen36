# Qwen 3.6 prefill attribution

Measured on 2026-09-29 on the 24 GB M3 MacBook Air with the installed Qwen
3.6 35B-A3B 4-bit model. Both runs used the release CLI, 64 LFU expert slots,
2048-token prefill chunks, FP16 KV, RDADVISE off, and one greedy output token.
No other local-model process was running; `memory_pressure -Q` reported 71%
free before the runs.

| Prompt | Chunks | Prefill wall | DeltaNet + router GPU | Full attention + router GPU | Shared experts GPU | Routed experts GPU | Expert fetch wait |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Frozen long synthesis, 2,940 tokens | 2 | 40.96 s | 5.85 s | 12.59 s | 3.11 s | 13.83 s | 9.13 s |
| Tripled frozen document, 8,816 tokens | 5 | 227.16 s | 16.89 s | 149.90 s | 9.09 s | 40.86 s | 28.06 s |

All 70 full-attention dispatches used the causal-tiled implementation; none
used TensorOps. Full-attention GPU time grew by 11.9x when the prompt grew by
3.0x, raising its share of prefill wall time from about 31% to 66%. DeltaNet
and expert GPU time scaled much closer to prompt length. This identifies full
attention as the dominant long-context prefill bottleneck and confirms that a
Qwen-compatible TensorOps attention path is worth investigating.

The CPU expert-fetch and route-grouping buckets are wall time. They may overlap
queued shared-expert GPU work and therefore must not be added to the GPU
buckets as though every row were a disjoint part of total wall time.

## Experimental 4096-token chunks

The 4096-token candidate passed its focused runtime, server, app, scratch, and
KV-ring tests. It raises persistent prefill scratch from 257,327,488 bytes at
2048 to 514,326,912 bytes at 4096.

| Prompt and run | Chunk size | Chunks | Prefill wall | Full attention + router GPU | Expert fetch wait | Peak footprint |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Frozen long synthesis, earlier baseline | 2048 | 2 | 40.96 s | 12.59 s | 9.13 s | not recorded |
| Frozen long synthesis, candidate | 4096 | 1 | 35.46 s | 11.65 s | 1.53 s | 5.79 GB |
| Tripled document, earlier baseline | 2048 | 5 | 227.16 s | 149.90 s | 28.06 s | not recorded |
| Tripled document, same-session candidate | 4096 | 3 | 232.53 s | 157.59 s | 14.63 s | 5.80 GB |
| Tripled document, later same-session control | 2048 | 5 | 272.15 s | 179.22 s | 28.63 s | 5.54 GB |

The 2,940-token case improved by 13.4%, with the reduction in redundant expert
fetching accounting for most of the gain. The same-session 8,816-token pair
favoured 4096 by 14.6%, and its expert-fetch wait was 49% lower. However, both
long measurements were slower than the earlier 2048 baseline and the later run
was slowest across most GPU buckets. This run-order drift is consistent with
the sustained thermal behaviour observed on the fanless M3 Air. Treat 4096 as
promising but experimental until an order-balanced comparison separates chunk
geometry from thermal and system-state effects.
