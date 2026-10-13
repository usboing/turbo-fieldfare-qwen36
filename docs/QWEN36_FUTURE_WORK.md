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

## Chat history

- Provide a persistent, browsable history of previous chats.
- Support reopening, renaming, searching, and deleting conversations.
- Define retention and storage controls separately from long-term memory.
- Preserve compatibility with existing conversation files and migrations.

## Window layouts

- Add convenient window-size presets for half-screen and one-third-screen
  layouts.
- Ensure the chat, composer, model status, and settings remain usable at each
  supported width.
- Preserve the user's chosen size and position across launches when possible.

## Upstream review

- Check the upstream and original Qwen-port repositories for new relevant pull
  requests or changes since the last review.
- Compare any new work with the rebased implementation before publishing.
- Record whether useful fixes, performance improvements, or compatibility
  changes should be incorporated.
