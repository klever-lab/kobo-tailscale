"""Exercise the real installer in isolated Linux user, mount and network namespaces."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
ARCHIVE = Path(os.environ.get("KOBO_TAILSCALE_ARCHIVE", "missing-verified-archive"))
TOOLS = "sh id dirname grep cut pidof readlink awk sha256sum tar gzip mktemp mkdir chmod cp mv ln rm env setsid mknod timeout sleep cat".split()


class InstallerSecurityTests(unittest.TestCase):
    def setUp(self):
        if not shutil.which("bwrap") or not ARCHIVE.is_file():
            self.fail("Requires bubblewrap and KOBO_TAILSCALE_ARCHIVE pointing to the pinned official ARM archive")
        self.temp = tempfile.TemporaryDirectory(prefix="kobo-security-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in ("bin", "local", "rules", "onboard/.kobo"):
            (self.root / name).mkdir(parents=True)
        self.payload = self.root / "onboard/kobo-tailscale/clara-bw"
        shutil.copytree(REPO / "clara-bw", self.payload)
        shutil.copyfile(ARCHIVE, self.payload / "tailscale_1.104.7_arm.tgz")
        self.version("4.46.23852", "391")
        for name in TOOLS:
            if not shutil.which(name):
                self.fail("Missing test tool: " + name)
            (self.root / "bin" / name).symlink_to("/real-bin/" + name)
        self.command("uname", "printf 'armv7l\\n'\n")
        self.space(200000)

    def command(self, name, body):
        path = self.root / "bin" / name
        if path.is_symlink():
            path.unlink()
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def version(self, firmware, model):
        (self.root / "onboard/.kobo/version").write_text(
            f"TEST-SERIAL,4.9.77,{firmware},4.9.77,4.9.77,00000000-0000-0000-0000-000000000{model}\n"
        )

    def space(self, available):
        self.command("df", f"printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\\nfixture 300000 1 {available} 1%% /usr/local\\n'\n")

    def run_script(self, name):
        args = [
            "bwrap", "--unshare-all", "--uid", "0", "--gid", "0", "--die-with-parent",
            "--ro-bind", "/usr", "/usr", "--ro-bind", "/usr/bin", "/real-bin",
            "--bind", str(self.root / "bin"), "/usr/bin",
            "--bind", str(self.root / "local"), "/usr/local",
            "--symlink", "usr/bin", "/bin", "--symlink", "usr/lib", "/lib",
            "--symlink", "usr/lib", "/lib64", "--proc", "/proc", "--dev", "/dev",
            "--tmpfs", "/tmp", "--dir", "/var/run", "--dir", "/etc/udev",
            "--bind", str(self.root / "rules"), "/etc/udev/rules.d",
            "--bind", str(self.root / "onboard"), "/mnt/onboard", "--chdir", "/tmp",
            "/bin/sh", "/mnt/onboard/kobo-tailscale/clara-bw/" + name,
        ]
        return subprocess.run(args, capture_output=True, text=True, timeout=30)

    def rejected_without_installing(self, text):
        result = self.run_script("install-tailscale.sh")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(text, result.stdout + result.stderr)
        self.assertEqual(list((self.root / "local").iterdir()), [])
        self.assertEqual(list((self.root / "rules").iterdir()), [])

    def test_tampered_archive_is_rejected_before_extraction_or_system_writes(self):
        (self.payload / "tailscale_1.104.7_arm.tgz").write_bytes(b"not the publisher's archive")
        self.rejected_without_installing("FAILED")

    def test_tampered_download_is_rejected_before_system_writes(self):
        (self.payload / "tailscale_1.104.7_arm.tgz").unlink()
        self.command("wget", 'printf "tampered download" > "$2"\n')
        self.rejected_without_installing("FAILED")

    def test_a_verified_fresh_download_can_be_installed(self):
        (self.payload / "tailscale_1.104.7_arm.tgz").rename(self.root / "onboard/download.tgz")
        self.command("wget", 'cp /mnt/onboard/download.tgz "$2"\n')
        result = self.run_script("install-tailscale.sh")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.root / "local/tailscale/bin/tailscaled").is_file())
        self.assertFalse((self.payload / "tailscale_1.104.7_arm.tgz.partial").exists())

    def test_low_system_space_is_rejected(self):
        self.space(89999)
        self.rejected_without_installing("free system storage")

    def test_unreviewed_firmware_is_rejected(self):
        self.version("5.0.0", "391")
        self.rejected_without_installing("firmware 4.x")

    def test_another_model_is_rejected(self):
        self.version("4.46.23852", "999")
        self.rejected_without_installing("not a Clara BW")

    def test_usb_visible_identity_cannot_be_silently_replaced(self):
        identity = self.root / "onboard/tailscale/tailscaled.state"
        identity.parent.mkdir()
        identity.write_text("existing enrolled identity")
        self.rejected_without_installing("older USB-visible identity")
        self.assertEqual(identity.read_text(), "existing enrolled identity")

    def test_private_state_cannot_be_redirected_to_usb_storage(self):
        redirected = self.root / "onboard/exposed-state"
        redirected.mkdir()
        private_root = self.root / "local/tailscale"
        private_root.mkdir()
        (private_root / "state").symlink_to("/mnt/onboard/exposed-state")
        result = self.run_script("install-tailscale.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink", result.stderr)
        self.assertEqual(list(redirected.iterdir()), [])

    def test_install_and_uninstall_preserve_private_identity_and_unrelated_files(self):
        identity = self.root / "local/tailscale/state/tailscaled.state"
        identity.parent.mkdir(parents=True)
        identity.write_text("existing private enrolled identity")
        unrelated = self.root / "local/firmware-owned-file"
        unrelated.write_text("keep")
        result = self.run_script("install-tailscale.sh")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for name in ("tailscale", "tailscale/state", "tailscale/bin", "tailscale/bin/tailscale", "tailscale/bin/tailscaled"):
            self.assertEqual((self.root / "local" / name).stat().st_mode & 0o777, 0o700)
        self.assertEqual(identity.read_text(), "existing private enrolled identity")
        self.assertFalse((self.root / "onboard/tailscale").exists())
        self.assertTrue((self.root / "rules/98-tailscale.rules").is_file())
        result = self.run_script("uninstall-tailscale.sh")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(identity.read_text(), "existing private enrolled identity")
        self.assertEqual(unrelated.read_text(), "keep")
        self.assertFalse((self.root / "rules/98-tailscale.rules").exists())
        self.assertFalse((self.root / "local/tailscale/bin/tailscaled").exists())


if __name__ == "__main__":
    unittest.main()
