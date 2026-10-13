# Qwen 3.6 branch release notes

This branch is a TurboFieldfare 0.9.1 continuation of
[NeelM0906's Qwen 3.6 pull request](https://github.com/drumih/turbo-fieldfare/pull/29).
It preserves the original project's Apache-2.0 license and Andrey Mikhaylov's
TurboFieldfare authorship while crediting NeelM0906 for the initial Qwen
architecture, installer, tokenizer, runtime, and test work.

## What this branch adds

- Rebase of the Qwen implementation onto upstream TurboFieldfare 0.9.1.
- Qwen-specific TensorOps full attention for long-prompt prefill.
- Selectable prefill chunks from 128 through 4096 tokens.
- A 64-slot LFU expert-cache option for higher-memory Macs.
- Fast in-process Mac app inference, with isolated decode still available.
- Qwen prefill and decode phase diagnostics.
- 8K through 256K selectable context capacities, subject to host memory.
- Documentation of the MTP speculative-decoding feasibility result.

## M3 Air results

Measured on a fanless 24 GB M3 MacBook Air with Qwen 3.6 35B-A3B 4-bit,
64 LFU expert slots, FP16 KV, and RDADVISE off. These are branch-development
measurements rather than the upstream community protocol, so the exact prompt,
chunk setting, output length, and run state are included rather than collapsed
into one headline number.

| Workload | Setting | Result |
| --- | --- | ---: |
| Interactive email-style run, 48 prompt / 813 output tokens | 64 slots, 2048 prefill, fast app mode | 16.3 tok/s decode, 49.83 s decode, 5.00 GB peak |
| Long synthesis, 2,940 prompt tokens | 4096 prefill, TensorOps | 24.64 s prefill, down from 35.46 s tiled |
| Tripled document, 8,816 prompt tokens | 4096 prefill, TensorOps | 82.01 s prefill, down from 232.53 s tiled |
| Fivefold document, about 14.7K prompt tokens | 4096 prefill, TensorOps | 140.75 s prefill, down from 570.42 s tiled |

The long-prompt reductions were 30.5%, 64.7%, and 75.3% respectively. The
larger win at longer prompts is expected because tiled full attention becomes
the dominant quadratic cost. Peak footprint for the measured long runs stayed
near 5.8 GB.

For the full attribution and caveats, see
[Qwen prefill profiling](QWEN36_PREFILL_PROFILE.md). For the older M5
community-protocol decode figures, see [Benchmarks](BENCHMARKS.md).

## Recommended M3 Air profile

The branch keeps conservative defaults for compatibility. For the tested
24 GB M3 Air profile:

- Use 64 expert-cache slots when roughly 5-6 GB of model footprint is
  acceptable.
- Use 2048-token prefill chunks for the stable general-purpose profile.
- Keep 4096 selectable for long prompts; it uses roughly 514 MB of persistent
  prefill scratch and can expose thermal drift on a fanless Mac.
- Keep RDADVISE off for sustained generation.
- Use Fast app inference for maximum throughput.

Larger configured contexts allocate successfully, but prompt processing is
not free: full attention still grows with prompt length even after TensorOps.
The measured context and prefill envelope is documented in
[Qwen prefill profiling](QWEN36_PREFILL_PROFILE.md#context-scaling-envelope).

## Known limitations

- Qwen is text-only in this branch; its vision tower is not packaged.
- The 64-slot and large-prefill profiles intentionally exceed the original
  ~2 GB resident-memory target.
- The model checkpoint is about 19.5 GB after repacking and is downloaded
  separately from Hugging Face.
- MTP speculative decoding did not pass the promotion gate on this 24 GB M3
  Air. See [MTP feasibility](QWEN36_MTP_FEASIBILITY.md).
- Model output can be incorrect. Verify important answers.

## Validation

Before publication, the branch is checked with the repository's serial test
suite, release build, and Markdown link checker. Model weights and private chat
history are excluded from the repository.
