# homebrew-ntfsmac

Homebrew tap for [ntfsmac](https://github.com/khr898/ntfsmac) — NTFS read/write on
Apple Silicon macOS. CLI only; the GUI ships as a separate ad-hoc-signed DMG (never
a cask — no paid Developer ID, no notarization).

## Install

```sh
brew tap khr898/ntfsmac
brew install ntfsmac
```

`Formula/ntfsmac.rb` is a source-build formula (no bottle) pinned to a specific
`khr898/ntfsmac` commit via `revision:` — every install builds that exact,
reviewed revision, not whatever is currently on `main`. `brew install --HEAD`
opts into building the moving `main` branch instead, for local dev/testing only.

## Requirements

- Apple Silicon (arm64) Mac
- macOS Ventura (13) or later
- Xcode Command Line Tools (for the source build)

## Uninstall

```sh
brew uninstall ntfsmac
brew untap khr898/ntfsmac
```

`post_uninstall` also removes `~/.anylinuxfs` (rootfs cache) and
`~/Library/Logs/anylinuxfs*.log`.

## Updating the formula

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
