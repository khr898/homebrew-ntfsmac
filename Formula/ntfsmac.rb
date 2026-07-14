class Ntfsmac < Formula
  desc "NTFS read/write on Apple Silicon macOS via a libkrun microVM (ntfs-3g over NFS)"
  homepage "https://github.com/khr898/ntfsmac"
  # By default, download the prebuilt CLI binaries and scripts packaged in the GitHub release
  # to make installation extremely fast and robust (no local compiler toolchains required).
  url "https://github.com/khr898/ntfsmac/releases/download/v1.0.140726/ntfsmac-cli.tar.gz"
  sha256 "3e1306c02318c7d79d6252a1be76983b29479a5e7fc88b187be38cdee358d9b8"
  license "MIT"

  # `brew install --HEAD` compiles from the latest main branch source code.
  head do
    url "https://github.com/khr898/ntfsmac.git", branch: "main"

    depends_on "lld" => :build
    depends_on "llvm" => :build
    depends_on "util-linux" => :build
    depends_on "xz" => :build
  end

  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
    if build.head?
      system "build/build-all.sh"
      system "build/sign.sh"
    end

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

  def caveats
    <<~EOS
      If you have the standalone anylinuxfs formula installed, link conflicts can be resolved by running:
        brew unlink anylinuxfs
        brew link --overwrite ntfsmac
    EOS
  end

  test do
    output = shell_output("#{bin}/ntfsmac diagnose --json")
    assert_match(/"healthy"/, output)
  end
end
