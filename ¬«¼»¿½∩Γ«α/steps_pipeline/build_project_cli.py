# CLI version of build_project (non-destructive)

from pathlib import Path
import argparse
import subprocess
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

def run(cmd):
    print(f">>> {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=PROJECT_ROOT)
    if result.returncode != 0:
        print("ERROR")
        sys.exit(result.returncode)

def main():
    parser = argparse.ArgumentParser(description="Build CODESYS project")
    parser.add_argument("--xml", default="Система умного дома.xml")
    parser.add_argument("--out", default=None)
    parser.add_argument("--logs", default=None)
    args = parser.parse_args()

    script = SCRIPT_DIR / "build_project.py"

    cmd = f'{sys.executable} "{script}"'

    if args.xml:
        cmd += f' --xml "{args.xml}"'
    if args.out:
        cmd += f' --out "{args.out}"'
    if args.logs:
        cmd += f' --logs "{args.logs}"'

    run(cmd)

    print("CLI BUILD OK")

if __name__ == "__main__":
    main()
