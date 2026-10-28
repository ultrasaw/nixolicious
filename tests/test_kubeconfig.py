import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "dotfiles/kubeconfig.zsh"


@unittest.skipUnless(shutil.which("zsh") and shutil.which("kubectl") and shutil.which("jq"),
                     "requires zsh, kubectl and jq")
class KubeconfigTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        (self.home / ".kube").mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        KUBECONFIG="/nonexistent/inherited-config")

    def config(self, filename, selected, contexts, timestamp):
        path = self.home / ".kube" / filename
        path.write_text(json.dumps({
            "apiVersion": "v1", "kind": "Config",
            "current-context": selected,
            "contexts": [{"name": name, "context": {"cluster": name, "user": name}}
                         for name in contexts] or None,
            "clusters": [{"name": name, "cluster": {"server": "https://example.invalid"}}
                         for name in contexts],
            "users": [{"name": name, "user": {"token": "test-token"}}
                      for name in contexts],
        }))
        os.utime(path, (timestamp, timestamp))
        return path

    def refresh(self):
        result = subprocess.run(
            ["zsh", "-f", "-c", 'source "$1" || exit; print -r -- "${KUBECONFIG-unset}"',
             "test", str(SCRIPT)],
            env=self.env, text=True, capture_output=True, check=True,
        )
        self.assertEqual(result.stderr, "")
        path = result.stdout.strip()
        if path == "unset":
            return None
        self.assertEqual(stat.S_IMODE(Path(path).stat().st_mode), 0o600)
        return json.loads(Path(path).read_text())

    def test_newest_valid_selection_wins_and_all_contexts_merge(self):
        self.config("old.yaml", "old", ["old"], 100)
        self.config("new.yaml", "new", ["new"], 200)
        merged = self.refresh()
        self.assertEqual(merged["current-context"], "new")
        self.assertEqual({c["name"] for c in merged["contexts"]}, {"old", "new"})

    def test_stale_selection_falls_back_without_changing_sources(self):
        stale = self.config("new.yaml", "missing", [], 200)
        self.config("old.yaml", "old", ["old"], 100)
        original = stale.read_bytes()
        self.assertEqual(self.refresh()["current-context"], "old")
        self.assertEqual(stale.read_bytes(), original)

    def test_context_may_be_defined_in_another_file(self):
        self.config("new.yaml", "shared", [], 200)
        self.config("old.yaml", "missing", ["shared"], 100)
        self.assertEqual(self.refresh()["current-context"], "shared")

    def test_no_valid_selection_is_left_empty(self):
        self.config("new.yaml", "missing", ["available"], 200)
        self.assertEqual(self.refresh()["current-context"], "")

    def test_default_config_is_a_fallback(self):
        self.config("new.yaml", "missing", [], 200)
        self.config("config", "default", ["default"], 300)
        self.assertEqual(self.refresh()["current-context"], "default")

    def test_no_context_definitions_is_left_empty(self):
        self.config("new.yaml", "missing", [], 200)
        self.assertEqual(self.refresh()["current-context"], "")

    def test_relative_certificate_paths_are_flattened(self):
        path = self.config("new.yaml", "new", ["new"], 200)
        certificate = self.home / ".kube" / "ca.crt"
        certificate.write_text("test-certificate")
        source = json.loads(path.read_text())
        source["clusters"][0]["cluster"]["certificate-authority"] = "ca.crt"
        path.write_text(json.dumps(source))
        cluster = self.refresh()["clusters"][0]["cluster"]
        self.assertNotIn("certificate-authority", cluster)
        self.assertIn("certificate-authority-data", cluster)

    def test_removed_file_is_not_kept_in_merge(self):
        removed = self.config("new.yaml", "new", ["new"], 200)
        self.config("old.yaml", "old", ["old"], 100)
        self.refresh()
        removed.unlink()
        merged = self.refresh()
        self.assertEqual(merged["current-context"], "old")
        self.assertEqual([c["name"] for c in merged["contexts"]], ["old"])

    def test_no_files_unsets_inherited_kubeconfig(self):
        self.assertIsNone(self.refresh())


if __name__ == "__main__":
    unittest.main()
