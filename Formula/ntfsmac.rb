class Ntfsmac < Formula
  desc "NTFS read/write on Apple Silicon macOS via a libkrun microVM (ntfs-3g over NFS)"
  homepage "https://github.com/khr898/ntfsmac"
  license "MIT"
  # Pinned to an exact commit, not the moving `main` branch — every `brew install ntfsmac`
  # must build a specific, reviewed revision, not whatever happens to be on main at install
  # time. `revision:` pins Homebrew's git download strategy to this exact commit object
  # (git's own content-addressing verifies it, no separate sha256 needed the way a tarball
  # `url`/`sha256` pair would require — there's no tagged release archive to checksum yet).
  # Bump this alongside every formula update that should track a newer ntfsmac commit.
  url "https://github.com/khr898/ntfsmac.git",
      revision: "55eb658a5469b57770039a6c96bea2c05d371522"
  version "0.1.0-55eb658"

  # `brew install --HEAD` still opts into the old moving-branch behavior for local dev/testing
  # against latest main — never the default path a real user's `brew install ntfsmac` takes.
  head "https://github.com/khr898/ntfsmac.git", branch: "main"

  # Source-build formula (head-only, no bottle) — every `brew install ntfsmac` runs the full
  # build-all.sh cross-compile, not just this project's own dev machine. `xz` provides `xzcat`
  # (vendored anylinuxfs's cc_linux script extracts its Debian sysroot packages with it);
  # `llvm` provides `lld` (`-fuse-ld=lld`, required by krun-init-blob's build.rs). Both build-
  # only: the installed binaries don't need either at runtime. brew audit --strict requires
  # every string-named dependency ordered before the symbol-keyed ones below (arch:, macos:).
  depends_on "llvm" => :build
  depends_on "xz" => :build
  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
    system "build/build-all.sh"
    system "build/sign.sh"

    bin.install "vendor/bin/anylinuxfs"
    libexec.install "vendor/bin/gvproxy"
    libexec.install "vendor/bin/vmnet-helper"
    libexec.install "vendor/bin/vmproxy"
    libexec.install "vendor/bin/init-rootfs"
    libexec.install "vendor/kernel/Image"
    libexec.install "vendor/kernel/Image-4K"
    # init-rootfs's own copyLinuxModules() reads modules.squashfs from
    # prefixDir/lib/, not prefixDir/libexec/ — see install.sh for the same fix.
    lib.install "vendor/kernel/modules.squashfs"

    (libexec/"ntfsmac/commands").install Dir["cli/commands/*.sh"]
    (libexec/"ntfsmac/lib").install Dir["cli/lib/*.sh"]
    Dir[libexec/"ntfsmac/commands/*.sh"].each { |f| chmod 0755, f }

    (bin/"ntfsmac").write <<~SH
      #!/bin/bash
      set -u
      LIBEXEC="#{libexec}/ntfsmac"
      sub="${1:-}"
      [[ $# -gt 0 ]] && shift
      case "$sub" in
        mount) exec "$LIBEXEC/commands/mount.sh" "$@" ;;
        unmount) exec "$LIBEXEC/commands/unmount.sh" "$@" ;;
        diagnose) exec "$LIBEXEC/commands/diagnose.sh" "$@" ;;
        *) echo "usage: ntfsmac <mount|unmount|diagnose> [args...]" >&2; exit 1 ;;
      esac
    SH
  end

  def post_install
    quarantined = [bin/"anylinuxfs", libexec/"gvproxy", libexec/"vmnet-helper",
                   libexec/"vmproxy", libexec/"init-rootfs", bin/"ntfsmac"]
    quarantined.each do |f|
      next unless f.exist?

      quiet_system "xattr", "-d", "com.apple.quarantine", f.to_s
    end
  end

  # `brew uninstall` removes the Cellar tree + this Formula's own bin/libexec symlinks on its
  # own (standard Homebrew behavior, no ghost risk there) — but it has no idea about runtime
  # state anylinuxfs itself creates outside the Cellar (~/.anylinuxfs rootfs cache, per-run
  # logs). Mirrors cli/commands/uninstall.sh's remove_rootfs_cache/remove_logs (minus prefix
  # removal, which brew already owns) so a brew-tap uninstall leaves the same zero leftovers
  # an install.sh uninstall does. Runs unprivileged as the invoking user — never touches
  # /usr/local/ntfsmac or the GUI's privileged helper, both outside this Formula's own scope.
  def post_uninstall
    rm_r "#{Dir.home}/.anylinuxfs", force: true
    Dir.glob("#{Dir.home}/Library/Logs/anylinuxfs*.log").each { |f| rm f, force: true }
  end

  test do
    output = shell_output("#{bin}/ntfsmac diagnose --json")
    assert_match(/"healthy"/, output)
  end
end
