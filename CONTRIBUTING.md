# Contributing to homebrew-ntfsmac

This tap tracks a single formula, `Formula/ntfsmac.rb`, source-built from
[khr898/ntfsmac](https://github.com/khr898/ntfsmac) pinned to a specific commit.
There's no build here to bootstrap — the workflow is: bump the pin, run the
tests, open a PR.

## Updating the formula pin

When `khr898/ntfsmac`'s `main` branch gets a commit that should be installable:

1. Edit `Formula/ntfsmac.rb`:
   - `url ... revision:` — set to the new commit SHA
   - `version` — update the `0.1.0-<short-sha>` suffix to match
2. Run the test suite (below) locally before opening a PR.
3. Do not touch `head "..."` (`branch: "main"`) — that's the fixed `--HEAD`
   dev-build path, not the pin.

## Running tests

```sh
brew install bats-core   # once, if not already installed
bats tests/formula.bats
```

The last test (`brew audit --strict is clean`) needs a local `brew` install and
registers a scratch tap under `Library/Taps/khr898/homebrew-ntfsmac` to audit
against — it cleans up after itself, and self-skips if `brew` isn't present.

To actually exercise a real install end-to-end (slow — runs the full
`build/build-all.sh` cross-compile in the `khr898/ntfsmac` repo):

```sh
brew install --build-from-source khr898/ntfsmac/ntfsmac
```

## Formula conventions (don't break these)

- No cask, ever — the GUI is a separate ad-hoc-signed DMG, never distributed
  through this tap.
- `depends_on arch: :arm64` and `depends_on macos: :ventura` stay as-is —
  Apple Silicon only.
- Build-only deps (`llvm`, `xz`) stay tagged `=> :build`.
- No `YOURUSERNAME` or other placeholders — `khr898` is the real, intended
  identity for this project.

## Reporting issues

Use the issue templates under `.github/ISSUE_TEMPLATE/` — pick "Install/build
failure" for anything going wrong with `brew install`, or "Feature request"
otherwise.

## Using Claude Code

No project-specific `CLAUDE.md` here — this is a 5-file tap repo and the
formula + this file are the whole picture. If you're using Claude Code,
point it at `Formula/ntfsmac.rb` and `tests/formula.bats` directly.
