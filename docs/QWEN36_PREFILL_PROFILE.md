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
| Tripled document, reverse-order control first | 2048 | 5 | 235.70 s | 157.09 s | 28.62 s | 5.52 GB |
| Tripled document, reverse-order candidate second | 4096 | 3 | 239.88 s | 162.10 s | 14.82 s | 5.82 GB |

The 2,940-token case improved by 13.4%, with the reduction in redundant expert
fetching accounting for most of the gain. The same-session 8,816-token pair
favoured 4096 by 14.6%, and its expert-fetch wait was 49% lower. However, both
long measurements were slower than the earlier 2048 baseline and the later run
was slowest across most GPU buckets. This run-order drift is consistent with
the sustained thermal behaviour observed on the fanless M3 Air. That made the
reverse-order comparison necessary before deciding whether to promote 4096.

The reverse-order pair produced the opposite winner: 2048 led 4096 by 1.8%
when it ran first. Comparing the first run from each ordered pair reduces the
state bias and gives 232.53 s at 4096 versus 235.70 s at 2048, a marginal 1.3%
4096 advantage. Expert-fetch wait was repeatable and approximately halved by
4096 in both pairs, but it overlaps queued GPU work and therefore did not map
directly to the same wall-time saving. macOS recorded no thermal or performance
warning, though that coarse flag does not exclude clock or temperature drift
visible in iStat. The promotion decision is therefore to keep 4096 selectable
and experimental, while retaining 2048 as the stable general-purpose setting.

## Context scaling envelope

Configured-context smoke tests used the same three-token prompt, 64 LFU expert
slots, 2048-token chunks, FP16 KV, and RDADVISE off. Every allocation and
one-token generation completed correctly, and short-prompt prefill stayed at
8.56–8.57 seconds regardless of the configured window.

| Configured context | Peak footprint |
| ---: | ---: |
| 16,384 | 2.30 GB |
| 32,768 | 2.63 GB |
| 65,536 | 3.31 GB |

The 64K window therefore adds about 1.0 GB over 16K in the allocation smoke
test and is practical on the 24 GB machine. Actual workload memory is higher
because routed experts and prefill scratch become resident during a real run.

A fivefold frozen document produced 14,656 prompt tokens and completed at a
16K context with 4096-token chunks:

| Chunks | Prefill wall | DeltaNet + router GPU | Full attention + router GPU | Shared experts GPU | Routed experts GPU | Expert fetch wait | Peak footprint |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4 | 570.42 s | 28.81 s | 453.56 s | 14.84 s | 66.59 s | 21.60 s | 5.80 GB |

Full attention was 79.5% of prefill wall time. From 8,816 to 14,656 tokens,
prompt length grew 1.66x while full-attention time grew 2.88x, confirming the
quadratic curve. Extrapolating that measured curve puts a near-bound 32K run
around 38–42 minutes and a 64K run around 2.5–3 hours. Those runs are deferred
until the Qwen full-attention path is optimized; allocation and correctness do
not justify spending hours re-measuring the known tiled-attention bottleneck.
