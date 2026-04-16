from pathlib import Path
import argparse
import subprocess
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

def run(cmd):
    print(">>>", " ".join(cmd))
    result = subprocess.run(cmd, cwd=PROJECT_ROOT)
    if result.returncode != 0:
        print("ERROR")
        sys.exit(result.returncode)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--xml", default="компилятор/Система умного дома.xml")
    parser.add_argument("--out", default="компилятор/out")
    parser.add_argument("--logs", default="компилятор/logs")
    args = parser.parse_args()

    out = Path(PROJECT_ROOT / args.out)
    logs = Path(PROJECT_ROOT / args.logs)

    out.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)

    # ВАЖНО: прокидываем параметры в старый билд
    base = SCRIPT_DIR / "build_project.py"

    cmd = [
        sys.executable,
        str(base),
        "--xml", args.xml,
        "--out", args.out,
        "--logs", args.logs
    ]

    run(cmd)

    print("BUILD_V2_OK")

if __name__ == "__main__":
    main()
