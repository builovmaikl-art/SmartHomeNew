from pathlib import Path
import argparse
import importlib.util
import shutil
import sys


def load_module(module_name: str, file_path: Path):
    spec = importlib.util.spec_from_file_location(module_name, str(file_path))
    if spec is None or spec.loader is None:
        raise RuntimeError(f'Cannot load module from {file_path}')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def resolve_methods_v2_path(project_root: Path) -> Path:
    py = project_root / 'steps' / 'MASTER_PIPELINE' / '001_universal_pou_builder_METHODS_V2.py'
    txt = project_root / 'steps' / 'MASTER_PIPELINE' / '001_universal_pou_builder_METHODS_V2.py.txt'
    if py.exists():
        return py
    if txt.exists():
        return txt
    raise FileNotFoundError(f'METHODS_V2 builder not found: {py} / {txt}')


def run_build_003_v2(v2_module, project_root: Path, base_xml: Path, xml_003: Path, log_001: Path):
    v2_module.INPUT_XML = base_xml
    v2_module.OUTPUT_XML = xml_003
    v2_module.LOG_FILE = log_001
    v2_module.ROOT_DIR = project_root
    rc = v2_module.main()
    if rc not in (None, 0):
        raise RuntimeError(f'METHODS_V2 build_003 failed with rc={rc}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--xml', default=None, help='Путь к базовому XML. Если не указан, будет найден рядом со скриптом.')
    parser.add_argument('--out', default='out', help='Каталог результатов. По умолчанию: ./out рядом со скриптом.')
    parser.add_argument('--logs', default='logs', help='Каталог логов. По умолчанию: ./logs рядом со скриптом.')
    args = parser.parse_args()

    script_file = Path(__file__).resolve()
    compiler_dir = script_file.parent
    project_root = compiler_dir.parent.resolve()

    baseline_path = compiler_dir / 'import_codesys_FINAL.py'
    if not baseline_path.exists():
        raise FileNotFoundError(f'Baseline entrypoint not found: {baseline_path}')

    baseline = load_module('baseline_import_codesys_final', baseline_path)
    methods_v2_path = resolve_methods_v2_path(project_root)
    methods_v2 = load_module('methods_v2_builder', methods_v2_path)

    compiler_dir, project_root, base_xml, xml_003, xml_004, result_xml, log_001, log_004 = baseline.script_layout(script_file, args.xml, args.out, args.logs)

    print(f'COMPILER_DIR={compiler_dir}')
    print(f'PROJECT_ROOT={project_root}')
    print(f'BASE_XML={base_xml}')
    print(f'OUT_003={xml_003}')
    print(f'OUT_004={xml_004}')
    print(f'OUT_RESULT={result_xml}')
    print(f'LOG_001={log_001}')
    print(f'LOG_004={log_004}')
    print(f'METHODS_V2_BUILDER={methods_v2_path}')

    run_build_003_v2(methods_v2, project_root, base_xml, xml_003, log_001)
    print('STEP_001_OK')

    baseline.build_004(project_root, xml_003, xml_004, log_004)
    print('STEP_004_OK')

    shutil.copyfile(xml_004, result_xml)
    print(f'FINAL_RESULT_OK={result_xml}')
    print('BUILD_OK')


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'BUILD_ERROR: {e}')
        sys.exit(1)
