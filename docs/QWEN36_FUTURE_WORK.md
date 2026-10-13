# Qwen 3.6 future work

The performance optimization roadmap is complete. Keep the following product
and release work as the next project phase.

## Publish and share

- Prepare the project for publication on GitHub.
- Review the repository for private data, generated artifacts, large files,
  licenses, attribution, installation instructions, and reproducible builds.
- Write a clear README covering the Qwen 3.6 port, supported hardware,
  installation, model setup, benchmark methodology, results, limitations, and
  the differences from upstream TurboFieldfare.
- Publish a Reddit post explaining the project, measured improvements, final
  M3 Air results, tradeoffs, and links to the repository.

## Instructions and persistent memory

- Add configurable user instructions that are applied consistently to new
  chats and generations.
- Add persistent memory across conversations for user preferences and useful
  facts.
- Define explicit controls to view, edit, disable, and delete stored memory.
- Keep instructions, memory, and ordinary conversation history distinct.
- Design privacy, storage, prompt-injection, context-budget, and migration
  behavior before implementation.
- Validate retained-KV behavior and prompt caching when instructions or memory
  change between turns.
