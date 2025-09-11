# 2.0.2 (August 10, 2023)
# 2.0.2 (August 10, 2023)

# 3.0.0 (September 11, 2025)

## Features

- New `MultiStringReplace::Automaton` API to compile patterns once and reuse for faster repeated match/replace.

## Performance

- Faster replace path: cached Ruby method IDs, fewer API calls, preallocated buffers, and deferred string allocation for no-match fast path.
- Optimized trie setup/clear and memory copies.

## Stability and build

- Fixed Bundler conflicts on Ruby 3.4+; Rakefile avoids dual-Bundler loading.
- Added GC marking to prevent crashes with the new Automaton.
- Safer behavior when replacement is missing; falls back to original substring.

## Tooling

- Benchmark script now supports `-f/--file`, `-n/--iters`, and `-A/--automaton` flags.
- Added GitHub Actions CI across Ruby 3.0–3.4.

## Bug fixes:

  - Prevent segfault with some binary characters. [#10](https://github.com/jedld/multi_string_replace/pull/10)
  
# 3.0.1 (September 11, 2025)

## Security/Hardening

- Avoid runtime eval during extension init; use `rb_define_module` instead of `rb_eval_string_protect`.

## Tests

- Add consistency spec to compare Automaton#replace with module .replace over randomized inputs.
