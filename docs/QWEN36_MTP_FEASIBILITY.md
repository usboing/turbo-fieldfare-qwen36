# Qwen 3.6 MTP feasibility on the M3 Air

Tested 2026-10-12 on the 24 GB M3 MacBook Air. This is a feasibility result,
not a TurboFieldfare implementation.

## Setup

- Target: `mlx-community/Qwen3.6-35B-A3B-4bit` (20.43 GB download)
- Drafter: `mlx-community/Qwen3.6-35B-A3B-MTP-4bit` (0.8B, 4-bit)
- Runtime: mlx-vlm 0.7.6, MLX 0.32.3
- Sampling: temperature 0, thinking disabled
- MTP block size: 2
- Hardware: M3 MacBook Air, 24 GB unified memory

The normal fully resident target exceeded MLX's recommended working-set limit
and failed during a 25-token prefill with a Metal out-of-memory error. The
checkpoint was therefore repacked with `mlx_vlm.moe_offload` and tested with a
4 GB routed-expert cache. The offloaded layout kept roughly 2.2 GB resident and
streamed roughly 17 GB of routed experts.

## Results

| Workload | Ordinary decode | MTP decode | Change | Draft acceptance | Peak memory | Greedy output |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 120-word explanatory prose | 5.524 tok/s | 4.889 tok/s | -11.5% | 70.0% | 6.385 -> 6.962 GB | Diverged |
| Count 1 through 50 | 8.935 tok/s | 9.486 tok/s | +6.2% | 100.0% | 6.383 -> 6.962 GB | Identical |
| Professional email reply | 4.993 tok/s | 4.890 tok/s | -2.1% | 84.3% | 6.414 -> 6.963 GB | Diverged |

The counting control completed correctly with no skipped or reordered numbers.
It demonstrates that the drafter is functional and can help when every drafted
token is accepted. Natural-language generation did not reach that threshold:
drafter and batched-verification overhead outweighed the saved target rounds.

## Decision

Do not prototype MTP inside TurboFieldfare from the current result. It does not
provide a dependable speedup for the email and prose workloads that matter,
adds memory, and fails the temperature-zero output-equivalence gate. Keep the
normal TurboFieldfare decode path and the promoted TensorOps prefill path as the
stable build. Re-evaluate MTP if upstream exactness is fixed or a future path
substantially reduces proposal and verification overhead.
