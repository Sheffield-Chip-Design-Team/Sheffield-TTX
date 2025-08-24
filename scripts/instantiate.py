#!/usr/bin/env python3
from parse import *

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("Usage: python3 instantiate.py <verilog_files>")
        sys.exit(1)

    # Combine all arguments into a single string and split by newlines
    all_args = " ".join(sys.argv[1:])
    file_list = [f.strip() for f in all_args.split("\n") if f.strip()]

    if not file_list:
        print("No Verilog files found")
        sys.exit(1)

    # Parse all files together
    try:
        ast, _ = parse(file_list, debug=False)
    except Exception as e:
        print(f"Error parsing files: {e}")
        sys.exit(1)

    declared_signals = set()
    modules = extract_module_info(ast)
    for module_name, ports in modules:
        print(f"  // {module_name}")
        print(generate_instantiation(module_name, ports, declared_signals))
        print(" ")

    cleanup_pyverilog_artifacts()
