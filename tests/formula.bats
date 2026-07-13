#!/usr/bin/env bats
# tests/formula.bats — 2-brew-formula acceptance (ntfsmac PLAN.md §6, L4), moved here
# from the main ntfsmac repo's tests/cli/formula.bats: the formula lives in this tap
# repo now, not the main repo, so its own test travels with it.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FORMULA="$REPO_ROOT/Formula/ntfsmac.rb"
}

@test "Formula/ntfsmac.rb exists" {
  [ -f "$FORMULA" ]
}

@test "formula targets the khr898/ntfsmac tap source, not homebrew-core or a fork" {
  run grep -c 'github.com/khr898/ntfsmac' "$FORMULA"
  [ "$status" -eq 0 ]
}

@test "formula does not produce a cask (L4)" {
  run grep -c '^cask ' "$FORMULA"
  [ "$status" -ne 0 ]
}

@test "formula requires arm64 (L7)" {
  run grep -c 'depends_on arch: :arm64' "$FORMULA"
  [ "$status" -eq 0 ]
}

@test "formula has no literal YOURUSERNAME placeholder (L10)" {
  run grep -c 'YOURUSERNAME' "$FORMULA"
  [ "$status" -ne 0 ]
}

@test "formula post-install strips com.apple.quarantine" {
  run grep -c 'com.apple.quarantine' "$FORMULA"
  [ "$status" -eq 0 ]
}

@test "post_uninstall cleans up the rootfs cache and logs brew itself never touches" {
  run grep -c 'def post_uninstall' "$FORMULA"
  [ "$status" -eq 0 ]
  run grep -c '.anylinuxfs' "$FORMULA"
  [ "$status" -eq 0 ]
}

@test "declares the build-only toolchain a source-build install actually needs (xz, llvm/lld)" {
  run grep -c 'depends_on "xz" => :build' "$FORMULA"
  [ "$status" -eq 0 ]
  run grep -c 'depends_on "llvm" => :build' "$FORMULA"
  [ "$status" -eq 0 ]
}

@test "brew audit --strict is clean" {
  if ! command -v brew >/dev/null 2>&1; then
    skip "brew not installed in this environment"
  fi
  # `brew audit` refuses a bare path — it needs the formula resolvable by name inside a
  # real tap (a git repo). Register a scratch tap, copy the formula in, audit, clean up.
  local tap_dir was_tapped=0
  tap_dir="$(brew --repository)/Library/Taps/khr898/homebrew-ntfsmac"
  if [[ -d "$tap_dir" ]]; then
    was_tapped=1
  else
    brew tap-new khr898/ntfsmac >/dev/null 2>&1
  fi
  cp "$FORMULA" "$tap_dir/Formula/ntfsmac.rb"

  run brew audit --strict khr898/ntfsmac/ntfsmac

  if [[ $was_tapped -eq 0 ]]; then
    brew untap khr898/ntfsmac >/dev/null 2>&1
  fi

  [ "$status" -eq 0 ]
}
