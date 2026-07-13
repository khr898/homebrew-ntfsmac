---
name: Install / build failure
about: brew install, build-from-source, or post-install failure for the ntfsmac formula
title: "[install] "
labels: bug
assignees: ''
---

## What failed

<!-- e.g. `brew install ntfsmac` fails during build/build-all.sh, or
post_install quarantine strip fails, or `brew audit --strict` fails. -->

## Steps to reproduce

```sh
brew tap khr898/ntfsmac
brew install ntfsmac
```

## Full output

<!-- Paste the full terminal output, not a snippet. For build failures,
attach or paste the relevant section of `brew install --verbose ntfsmac`. -->

```
paste here
```

## Environment

- macOS version:
- Chip (must be Apple Silicon / arm64):
- `brew --version`:
- `Formula/ntfsmac.rb` revision pin (from this tap, or your own fork):
- Installed via `brew install ntfsmac` or `brew install --HEAD ntfsmac`:

## Additional context

<!-- Anything else — e.g. did `brew audit --strict khr898/ntfsmac/ntfsmac`
pass locally? Any prior anylinuxfs/vmnet-helper state on this machine? -->
