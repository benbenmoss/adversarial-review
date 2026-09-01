# Contributing

## Bug reports / feature requests

Open an issue. Include Claude Code version, OS, and repro steps for bugs.

## Pull requests

1. Fork, branch off `main`.
2. Keep changes focused -- one fix or feature per PR.
3. Run the validate workflow locally before pushing:
   ```
   python3 -c "import json; [json.load(open(f)) for f in ['.claude-plugin/marketplace.json', '.claude-plugin/plugin.json', 'hooks/hooks.json']]"
   bash -n hooks/*.sh
   ```
4. Open the PR against `main`. CI (`validate`) must pass before merge.

## Scope

This plugin does one thing: adversarial review of the local working tree. PRs adding unrelated functionality (remote/PR review, new hook triggers unrelated to the review flow, config surface for its own sake) will likely get pushback -- open an issue first to discuss before investing time.

## Code style

Match the existing style in `hooks/` and `skills/` -- no comments explaining what code does, only why when it's non-obvious.
