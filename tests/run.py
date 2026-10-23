"""Run the Luau state, bundled UI and capture helper using the official CLI."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from build import bundle

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau", help="Path to the official Luau CLI")
args = parser.parse_args()
generated = ROOT / "tests/.generated_runner.luau"
capture_generated = ROOT / "tests/.generated_capture.luau"
try:
    content = bundle()
    actual = (ROOT / "delta.lua").read_text(encoding="utf-8")
    if actual != content:
        raise SystemExit("delta.lua is stale. Run python3 build.py first.")
    template = (ROOT / "tests/ui.spec.luau").read_text(encoding="utf-8")
    generated.write_text(template.replace("-- BUNDLE_PLACEHOLDER", content), encoding="utf-8")
    capture_template = (ROOT / "tests/capture.spec.luau").read_text(encoding="utf-8")
    capture_source = (ROOT / "capture-delta.lua").read_text(encoding="utf-8")
    capture_generated.write_text(capture_template.replace("-- CAPTURE_PLACEHOLDER", capture_source), encoding="utf-8")
    for test in ["tests/core.spec.luau", "tests/.generated_runner.luau", "tests/.generated_capture.luau"]:
        subprocess.run([args.luau, test], cwd=ROOT, check=True)
finally:
    generated.unlink(missing_ok=True)
    capture_generated.unlink(missing_ok=True)
